import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';

/// A single feature comparison row used in the paywall.
///
/// Displays a feature icon, name, the free-tier limitation, and
/// the premium benefit with a green checkmark.
class FeatureComparisonRow extends StatelessWidget {
  const FeatureComparisonRow({
    super.key,
    required this.icon,
    required this.featureName,
    required this.freeText,
    required this.premiumText,
    this.showDivider = true,
  });

  /// Icon representing the feature.
  final IconData icon;

  /// Name of the feature.
  final String featureName;

  /// Description of the free tier limitation.
  final String freeText;

  /// Description of the premium benefit.
  final String premiumText;

  /// Whether to show a bottom divider.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Feature icon.
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Feature name.
              Expanded(
                flex: 3,
                child: Text(
                  featureName,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Free column.
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        freeText,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Premium column.
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        premiumText,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: AppColors.border.withValues(alpha: 0.3),
          ),
      ],
    );
  }
}
