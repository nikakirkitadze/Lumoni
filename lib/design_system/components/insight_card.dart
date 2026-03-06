import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// A card for displaying daily insights with an icon, gradient accent, and
/// optional action button.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.iconColor,
    this.accentGradient,
    this.onTap,
    this.actionLabel,
    this.tag,
    this.tagColor,
  });

  /// Headline of the insight.
  final String title;

  /// Body text.
  final String description;

  /// Leading icon.
  final IconData? icon;

  /// Icon color override.
  final Color? iconColor;

  /// Accent gradient applied to the left border / icon background.
  final Gradient? accentGradient;

  /// Tap callback for the card (or its action button).
  final VoidCallback? onTap;

  /// Optional action button label (e.g. "Read more").
  final String? actionLabel;

  /// Optional tag badge (e.g. "New", "IQ", "EQ").
  final String? tag;

  /// Tag badge color.
  final Color? tagColor;

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = accentGradient ?? AppColors.primaryGradient;
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gradient accent strip on the left.
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: effectiveGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              // Content area.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: icon + title + optional tag.
                      Row(
                        children: [
                          if (icon != null) ...[
                            _IconBadge(
                              icon: icon!,
                              color: effectiveIconColor,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.heading6,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (tag != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _TagBadge(
                              label: tag!,
                              color: tagColor ?? AppColors.accent,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Description.
                      Text(
                        description,
                        style: AppTypography.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Action row.
                      if (actionLabel != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Text(
                              actionLabel!,
                              style: AppTypography.buttonSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular icon badge with a tinted background.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppSpacing.borderRadiusSm,
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// Small tag badge displayed in the top-right of the card.
class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
