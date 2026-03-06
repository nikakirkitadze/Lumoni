import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:lumoni/core/constants/app_constants.dart';

/// Exception thrown by [SubscriptionService] operations.
class SubscriptionException implements Exception {
  final String message;
  final Object? originalError;

  const SubscriptionException(this.message, {this.originalError});

  @override
  String toString() => 'SubscriptionException: $message';
}

/// Service wrapping RevenueCat for subscription management.
///
/// Handles SDK initialization, entitlement checking, purchases,
/// restore, and user identification.
class SubscriptionService {
  bool _initialized = false;

  final StreamController<bool> _premiumController =
      StreamController<bool>.broadcast();

  /// Stream that emits the current premium status whenever it changes.
  Stream<bool> get isPremiumStream => _premiumController.stream;

  bool _isPremium = false;

  /// Current cached premium status (synchronous access).
  bool get isPremium => _isPremium;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Initializes the RevenueCat SDK with the platform-appropriate API key.
  ///
  /// Optionally pass [userId] to identify the user in RevenueCat.
  Future<void> initialize({String? userId}) async {
    if (_initialized) return;

    try {
      final apiKey = Platform.isIOS
          ? AppConstants.revenueCatApiKeyiOS
          : AppConstants.revenueCatApiKeyAndroid;

      final configuration = PurchasesConfiguration(apiKey);
      if (userId != null) {
        configuration.appUserID = userId;
      }

      await Purchases.configure(configuration);

      // Listen for customer info updates.
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

      // Fetch initial status.
      await checkSubscriptionStatus();

      _initialized = true;
      debugPrint('[SubscriptionService] RevenueCat initialized successfully.');
    } catch (e) {
      debugPrint('[SubscriptionService] Initialization failed: $e');
      throw SubscriptionException(
        'Failed to initialize subscription service',
        originalError: e,
      );
    }
  }

  /// Callback for RevenueCat customer info updates.
  void _onCustomerInfoUpdated(CustomerInfo info) {
    _updatePremiumStatus(info);
  }

  /// Refreshes the subscription status from RevenueCat.
  ///
  /// Returns true if the user currently has an active premium entitlement.
  Future<bool> checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);
      return _isPremium;
    } catch (e) {
      debugPrint('[SubscriptionService] Error checking status: $e');
      return _isPremium;
    }
  }

  /// Extracts and broadcasts the premium status from [CustomerInfo].
  void _updatePremiumStatus(CustomerInfo info) {
    final hadPremium = _isPremium;
    _isPremium = info.entitlements.active
        .containsKey(AppConstants.premiumEntitlementId);

    if (_isPremium != hadPremium) {
      _premiumController.add(_isPremium);
      debugPrint('[SubscriptionService] Premium status changed: $_isPremium');
    }
  }

  /// Fetches the available subscription offerings from RevenueCat.
  ///
  /// Returns null if there are no offerings configured.
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        debugPrint('[SubscriptionService] No current offering found.');
      }
      return offerings;
    } catch (e) {
      throw SubscriptionException(
        'Failed to fetch offerings',
        originalError: e,
      );
    }
  }

  /// Purchases the given [package].
  ///
  /// Returns the updated [CustomerInfo] on success.
  /// Throws [SubscriptionException] if the purchase fails or is cancelled.
  Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      _updatePremiumStatus(result);
      return result;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        throw const SubscriptionException(
          'Purchase was cancelled.',
          originalError: 'purchase-cancelled',
        );
      }

      throw SubscriptionException(
        'Purchase failed: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      throw SubscriptionException(
        'Purchase failed unexpectedly.',
        originalError: e,
      );
    }
  }

  /// Restores previously purchased subscriptions.
  ///
  /// Returns the restored [CustomerInfo].
  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatus(customerInfo);
      return customerInfo;
    } catch (e) {
      throw SubscriptionException(
        'Failed to restore purchases.',
        originalError: e,
      );
    }
  }

  /// Identifies the user in RevenueCat (e.g. after sign-in).
  Future<void> identify(String userId) async {
    try {
      final result = await Purchases.logIn(userId);
      _updatePremiumStatus(result.customerInfo);
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to identify user: $e');
    }
  }

  /// Resets the RevenueCat user to anonymous (e.g. on sign-out).
  Future<void> reset() async {
    try {
      final info = await Purchases.logOut();
      _updatePremiumStatus(info);
    } catch (e) {
      debugPrint('[SubscriptionService] Failed to reset user: $e');
    }
  }

  /// Returns the active subscription's expiration date, or null.
  ///
  /// Lifetime purchases will return null since they don't expire.
  Future<DateTime?> getExpirationDate() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement =
          info.entitlements.active[AppConstants.premiumEntitlementId];
      if (entitlement == null) return null;
      final expirationStr = entitlement.expirationDate;
      return expirationStr != null ? DateTime.tryParse(expirationStr) : null;
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting expiration: $e');
      return null;
    }
  }

  /// Returns the active entitlement's product identifier, or null.
  Future<String?> getActiveProductId() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final entitlement =
          info.entitlements.active[AppConstants.premiumEntitlementId];
      return entitlement?.productIdentifier;
    } catch (e) {
      debugPrint('[SubscriptionService] Error getting product ID: $e');
      return null;
    }
  }

  /// Disposes resources.
  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdated);
    _premiumController.close();
  }
}
