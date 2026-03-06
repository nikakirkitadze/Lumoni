import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/results/domain/entities/improvement_tip.dart';

/// A glass card displaying a single improvement tip with icon, title,
/// description, and category tag.
class ImprovementCard extends StatelessWidget {
  const ImprovementCard({
    super.key,
    required this.tip,
    this.index = 0,
  });

  /// The improvement tip to display.
  final ImprovementTip tip;

  /// Card index, used for slight gradient variation.
  final int index;

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(tip.category);
    final categoryLabel = _categoryLabel(tip.category);
    final categoryIcon = _categoryIcon(tip.category);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      gradient: LinearGradient(
        colors: [
          categoryColor.withValues(alpha: 0.08),
          AppColors.glassFill,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: categoryColor.withValues(alpha: 0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category icon container.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withValues(alpha: 0.2),
                      categoryColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: AppSpacing.borderRadiusMd,
                ),
                child: Icon(
                  categoryIcon,
                  size: 20,
                  color: categoryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),

              // Title and difficulty.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: AppTypography.heading6,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _DifficultyBadge(difficulty: tip.difficulty),
                        const SizedBox(width: AppSpacing.xs),
                        _CategoryTag(
                          label: categoryLabel,
                          color: categoryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description.
          Text(
            tip.description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the accent color for a given category.
  Color _categoryColor(String category) {
    switch (category) {
      case AppConstants.iqCategoryPattern:
        return AppColors.primary;
      case AppConstants.iqCategoryLogical:
        return AppColors.accent;
      case AppConstants.iqCategoryMath:
        return AppColors.warning;
      case AppConstants.iqCategoryVerbal:
        return AppColors.success;
      case AppConstants.iqCategorySpatial:
        return AppColors.secondary;
      case AppConstants.eqCategorySelfAwareness:
        return AppColors.accent;
      case AppConstants.eqCategorySelfRegulation:
        return AppColors.primary;
      case AppConstants.eqCategoryMotivation:
        return AppColors.warning;
      case AppConstants.eqCategoryEmpathy:
        return const Color(0xFFEC4899);
      case AppConstants.eqCategorySocialSkills:
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  /// Human-readable category label.
  String _categoryLabel(String category) {
    return AppConstants.iqCategoryLabels[category] ??
        AppConstants.eqCategoryLabels[category] ??
        category;
  }

  /// Icon for each category.
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
        return Icons.lightbulb_rounded;
    }
  }
}

/// Small badge showing the difficulty level.
class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final TipDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      TipDifficulty.beginner => AppColors.success,
      TipDifficulty.intermediate => AppColors.warning,
      TipDifficulty.advanced => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        difficulty.label,
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Small category tag chip.
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.captionSmall.copyWith(
          color: color,
          fontSize: 9,
        ),
      ),
    );
  }
}
