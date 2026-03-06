import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/design_system/design_system.dart';

/// Paywall page using RevenueCat's native paywall UI.
///
/// Displays the paywall configured in the RevenueCat dashboard.
/// Handles purchase completion, restore, and dismissal automatically.
class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PaywallView(
      displayCloseButton: true,
      onPurchaseCompleted: (customerInfo, storeTransaction) {
        // Refresh the subscription status in our service.
        getIt<SubscriptionService>().checkSubscriptionStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome to Lumoni Pro!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
      onRestoreCompleted: (customerInfo) {
        getIt<SubscriptionService>().checkSubscriptionStatus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription restored successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
      onDismiss: () {
        context.pop();
      },
    );
  }
}
