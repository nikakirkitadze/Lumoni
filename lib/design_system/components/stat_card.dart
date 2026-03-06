import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// A small stat card that displays a metric value with a label, and optional
/// trend indicator.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendPositive,
    this.gradient,
    this.onTap,
    this.width,
  });

  /// Metric label (e.g. "IQ Score", "Tests Taken").
  final String label;

  /// Metric value (e.g. "128", "14").
  final String value;

  /// Optional icon displayed above the value.
  final IconData? icon;

  /// Icon color override.
  final Color? iconColor;

  /// Trend text (e.g. "+5", "-2%"). When provided, shown below the value.
  final String? trend;

  /// Whether the trend is positive. Determines color (green/red).
  final bool? trendPositive;

  /// Optional gradient overlay behind the icon area.
  final Gradient? gradient;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Fixed width. When `null`, the card sizes to its content.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon row.
            if (icon != null) ...[
              _GradientIcon(
                icon: icon!,
                color: iconColor ?? AppColors.primary,
                gradient: gradient,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // Value.
            Text(value, style: AppTypography.statValue),
            const SizedBox(height: AppSpacing.xxs),
            // Label.
            Text(
              label,
              style: AppTypography.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Trend.
            if (trend != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _TrendBadge(
                text: trend!,
                isPositive: trendPositive ?? true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({
    required this.icon,
    required this.color,
    this.gradient,
  });

  final IconData icon;
  final Color color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color.withValues(alpha: 0.12) : null,
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Icon(
        icon,
        size: 20,
        color: gradient != null ? AppColors.textOnPrimary : color,
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({
    required this.text,
    required this.isPositive,
  });

  final String text;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.success : AppColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: AppTypography.captionSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
