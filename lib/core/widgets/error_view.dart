import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';

/// A centered error display widget with an icon, message, and retry button.
///
/// Used as a full-screen or inline error state throughout the app.
class ErrorView extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// An optional title above the message.
  final String? title;

  /// The icon shown above the text content.
  final IconData icon;

  /// Callback invoked when the user taps the retry button.
  /// If null, the retry button is hidden.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// Optional secondary action below the retry button.
  final Widget? secondaryAction;

  const ErrorView({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon.
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: 24),

            // Title.
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            // Message.
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Retry button.
            if (onRetry != null)
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    retryLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Secondary action.
            if (secondaryAction != null) ...[
              const SizedBox(height: 12),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }

  /// Convenience factory for network errors.
  factory ErrorView.network({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'No Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Convenience factory for generic server errors.
  factory ErrorView.server({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'Something Went Wrong',
      message: 'We encountered an unexpected error. Please try again later.',
      icon: Icons.cloud_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Convenience factory for permission errors.
  factory ErrorView.permission({VoidCallback? onRetry}) {
    return ErrorView(
      title: 'Access Denied',
      message: 'You don\'t have permission to view this content.',
      icon: Icons.lock_outline_rounded,
      onRetry: onRetry,
      retryLabel: 'Go Back',
    );
  }
}
