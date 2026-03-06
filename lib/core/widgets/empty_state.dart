import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';

/// A centered empty-state widget showing an icon, title, message, and
/// optional action button.
///
/// Used when a list or screen has no data to display.
class EmptyState extends StatelessWidget {
  /// The icon displayed in the center.
  final IconData icon;

  /// Title text.
  final String title;

  /// Descriptive message below the title.
  final String message;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback invoked when the action button is tapped.
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container.
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.primary400,
              ),
            ),

            const SizedBox(height: 24),

            // Title.
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

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

            // Action button.
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Convenience factory for empty test history.
  factory EmptyState.noTests({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.psychology_outlined,
      title: 'No Tests Yet',
      message:
          'Start your first intelligence test to see your results here.',
      actionLabel: 'Take a Test',
      onAction: onAction,
    );
  }

  /// Convenience factory for empty results.
  factory EmptyState.noResults({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.analytics_outlined,
      title: 'No Results',
      message: 'Complete a test to see your detailed results and insights.',
      actionLabel: 'Get Started',
      onAction: onAction,
    );
  }

  /// Convenience factory for empty insights.
  factory EmptyState.noInsights() {
    return const EmptyState(
      icon: Icons.lightbulb_outline_rounded,
      title: 'No Insights Yet',
      message:
          'Complete multiple tests to unlock personalized insights about '
          'your intelligence profile.',
    );
  }

  /// Convenience factory for search with no results.
  factory EmptyState.noSearchResults() {
    return const EmptyState(
      icon: Icons.search_off_rounded,
      title: 'No Results Found',
      message: 'Try adjusting your search or filters.',
    );
  }
}
