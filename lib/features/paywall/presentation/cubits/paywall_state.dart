import 'package:equatable/equatable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Represents every possible state for the paywall feature.
sealed class PaywallState extends Equatable {
  const PaywallState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any offerings have been loaded.
final class PaywallInitial extends PaywallState {
  const PaywallInitial();
}

/// Offerings are currently being fetched from RevenueCat.
final class PaywallLoading extends PaywallState {
  const PaywallLoading();
}

/// Offerings loaded successfully and ready for display.
final class PaywallLoaded extends PaywallState {
  /// Available offerings from RevenueCat.
  final Offerings offerings;

  /// The currently selected package for purchase.
  final Package? selectedPackage;

  const PaywallLoaded({
    required this.offerings,
    this.selectedPackage,
  });

  @override
  List<Object?> get props => [offerings, selectedPackage];

  /// Returns a copy with optional field overrides.
  PaywallLoaded copyWith({
    Offerings? offerings,
    Package? selectedPackage,
  }) {
    return PaywallLoaded(
      offerings: offerings ?? this.offerings,
      selectedPackage: selectedPackage ?? this.selectedPackage,
    );
  }
}

/// A purchase is currently in progress.
final class PaywallPurchasing extends PaywallState {
  const PaywallPurchasing();
}

/// A purchase completed successfully.
final class PaywallPurchased extends PaywallState {
  const PaywallPurchased();
}

/// Purchases were successfully restored.
final class PaywallRestored extends PaywallState {
  const PaywallRestored();
}

/// Fallback state when RevenueCat is not configured.
///
/// Renders the paywall UI with placeholder prices and selectable plans
/// so the user can see the subscription options.
final class PaywallPreview extends PaywallState {
  /// The currently selected plan: `'annual'` or `'monthly'`.
  final String selectedPlan;

  const PaywallPreview({this.selectedPlan = 'annual'});

  @override
  List<Object?> get props => [selectedPlan];

  PaywallPreview copyWith({String? selectedPlan}) {
    return PaywallPreview(selectedPlan: selectedPlan ?? this.selectedPlan);
  }
}

/// An error occurred during a paywall operation.
final class PaywallError extends PaywallState {
  final String message;

  const PaywallError(this.message);

  @override
  List<Object?> get props => [message];
}
