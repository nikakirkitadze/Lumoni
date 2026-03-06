import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/insights/presentation/cubits/insights_state.dart';

/// A card that displays a single strength or weakness category with
/// score, trend arrow, icon, and brief insight text.
class StrengthWeaknessCard extends StatelessWidget {
  const StrengthWeaknessCard({
    super.key,
    required this.insight,
    required this.isStrength,
  });

  /// The category insight data.
  final CategoryInsight insight;

  /// Whether this card represents a strength (green) or weakness (orange).
  final bool isStrength;

  @override
  Widget build(BuildContext context) {
    final accentColor = isStrength ? AppColors.success : AppColors.warning;
    final icon = _categoryIcon(insight.category);
    final trendIcon = insight.isImproving
        ? Icons.trending_up_rounded
        : insight.isDeclining
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;
    final trendColor = insight.isImproving
        ? AppColors.success
        : insight.isDeclining
            ? AppColors.error
            : AppColors.textTertiary;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      gradient: LinearGradient(
        colors: [
          accentColor.withValues(alpha: 0.06),
          AppColors.glassFill,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: accentColor.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      accentColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Category name and badge.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.label,
                      style: AppTypography.heading6,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isStrength ? 'Strength' : 'Needs Work',
                        style: AppTypography.captionSmall.copyWith(
                          color: accentColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Score and trend.
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    insight.averageScore.round().toString(),
                    style: AppTypography.statValue.copyWith(
                      color: accentColor,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendIcon,
                        size: 14,
                        color: trendColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _trendLabel(insight.trend),
                        style: AppTypography.captionSmall.copyWith(
                          color: trendColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Insight text.
          Text(
            insight.insightText,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Score bar.
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusFull,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: (insight.averageScore / 100).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _trendLabel(double trend) {
    final absTrend = trend.abs().round();
    if (trend > 2) return '+$absTrend';
    if (trend < -2) return '-$absTrend';
    return 'Stable';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case AppConstants.iqCategoryPattern:
        return Icons.grid_view_rounded;
      case AppConstants.iqCategoryLogical:
        return Icons.account_tree_rounded;
      case AppConstants.iqCategoryMath:
        return Icons.calculate_rounded;
      case AppConstants.iqCategoryVerbal:
        return Icons.text_fields_rounded;
      case AppConstants.iqCategorySpatial:
        return Icons.view_in_ar_rounded;
      case AppConstants.eqCategorySelfAwareness:
        return Icons.self_improvement_rounded;
      case AppConstants.eqCategorySelfRegulation:
        return Icons.shield_rounded;
      case AppConstants.eqCategoryMotivation:
        return Icons.rocket_launch_rounded;
      case AppConstants.eqCategoryEmpathy:
        return Icons.favorite_rounded;
      case AppConstants.eqCategorySocialSkills:
        return Icons.people_rounded;
      default:
        return Icons.insights_rounded;
    }
  }
}
