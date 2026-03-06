import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/features/paywall/presentation/cubits/paywall_state.dart';

/// Manages the paywall feature state.
///
/// Handles loading RevenueCat offerings, selecting packages,
/// purchasing subscriptions, and restoring previous purchases.
class PaywallCubit extends Cubit<PaywallState> {
  PaywallCubit() : super(const PaywallInitial());

  final SubscriptionService _subscriptionService = getIt<SubscriptionService>();

  /// Loads available subscription offerings from RevenueCat.
  ///
  /// Emits [PaywallLoading] immediately, then [PaywallLoaded] on success.
  /// The annual package is pre-selected if available.
  Future<void> loadOfferings() async {
    emit(const PaywallLoading());

    try {
      final offerings = await _subscriptionService.getOfferings();

      if (offerings == null || offerings.current == null) {
        emit(const PaywallError(
          'No subscription plans are currently available. Please try again later.',
        ));
        return;
      }

      // Pre-select the annual package if available, otherwise monthly.
      Package? defaultPackage;
      final current = offerings.current!;
      if (current.annual != null) {
        defaultPackage = current.annual;
      } else if (current.monthly != null) {
        defaultPackage = current.monthly;
      } else if (current.availablePackages.isNotEmpty) {
        defaultPackage = current.availablePackages.first;
      }

      emit(PaywallLoaded(
        offerings: offerings,
        selectedPackage: defaultPackage,
      ));
    } catch (e) {
      debugPrint('[PaywallCubit] Error loading offerings: $e');
      // Fall back to preview mode so the UI is still interactive.
      emit(const PaywallPreview());
    }
  }

  /// Selects a package for purchase (live mode).
  void selectPackage(Package package) {
    final currentState = state;
    if (currentState is PaywallLoaded) {
      emit(currentState.copyWith(selectedPackage: package));
    }
  }

  /// Selects a plan in preview mode.
  void selectPreviewPlan(String plan) {
    final currentState = state;
    if (currentState is PaywallPreview) {
      emit(currentState.copyWith(selectedPlan: plan));
    }
  }

  /// Purchases the currently selected package.
  ///
  /// Emits [PaywallPurchasing] during the purchase flow, then
  /// [PaywallPurchased] on success.
  Future<void> purchase() async {
    final currentState = state;

    // In preview mode, subscriptions are not yet available.
    if (currentState is PaywallPreview) {
      emit(const PaywallError(
        'Subscriptions are not available yet. Please try again later.',
      ));
      // Return to preview so the UI stays interactive.
      emit(const PaywallPreview());
      return;
    }

    if (currentState is! PaywallLoaded) return;

    final package = currentState.selectedPackage;
    if (package == null) {
      emit(const PaywallError('Please select a subscription plan.'));
      return;
    }

    emit(const PaywallPurchasing());

    try {
      await _subscriptionService.purchasePackage(package);
      emit(const PaywallPurchased());
    } catch (e) {
      debugPrint('[PaywallCubit] Error purchasing: $e');
      final errorMessage = e.toString().toLowerCase();

      // If the purchase was cancelled, go back to loaded state.
      if (errorMessage.contains('cancel')) {
        emit(currentState);
        return;
      }

      emit(PaywallError(_friendlyMessage(e)));
    }
  }

  /// Restores previously purchased subscriptions.
  ///
  /// Emits [PaywallLoading] during the restore, then [PaywallRestored]
  /// if an active subscription is found.
  Future<void> restorePurchases() async {
    emit(const PaywallLoading());

    try {
      await _subscriptionService.restorePurchases();

      if (_subscriptionService.isPremium) {
        emit(const PaywallRestored());
      } else {
        emit(const PaywallError(
          'No active subscription found. If you believe this is an error, '
          'please contact support.',
        ));
      }
    } catch (e) {
      debugPrint('[PaywallCubit] Error restoring purchases: $e');
      emit(PaywallError(_friendlyMessage(e)));
    }
  }

  /// Converts raw exceptions to user-friendly messages.
  String _friendlyMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    if (message.contains('cancel')) {
      return 'Purchase was cancelled.';
    }
    if (message.contains('not available') || message.contains('no offerings')) {
      return 'Subscription plans are not available right now. Please try again later.';
    }
    return 'Something went wrong. Please try again.';
  }
}
