import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Displays category scores with animated progress bars that fill in
/// sequentially with a stagger delay.
class CategoryBreakdown extends StatefulWidget {
  const CategoryBreakdown({
    super.key,
    required this.categoryScores,
    required this.isIQ,
    this.staggerDelay = const Duration(milliseconds: 150),
    this.barDuration = const Duration(milliseconds: 800),
  });

  /// Map of category key to score (0-100 scale).
  final Map<String, double> categoryScores;

  /// Whether these are IQ categories or EQ categories.
  final bool isIQ;

  /// Delay between each bar's animation start.
  final Duration staggerDelay;

  /// Duration for each bar's fill animation.
  final Duration barDuration;

  @override
  State<CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<CategoryBreakdown>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startStaggeredAnimation();
  }

  void _initAnimations() {
    final count = widget.categoryScores.length;
    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: widget.barDuration,
      );
      final animation = CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      );
      _controllers.add(controller);
      _animations.add(animation);
    }
  }

  Future<void> _startStaggeredAnimation() async {
    for (int i = 0; i < _controllers.length; i++) {
      if (!mounted) return;
      _controllers[i].forward();
      if (i < _controllers.length - 1) {
        await Future.delayed(widget.staggerDelay);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.categoryScores.entries.toList();
    final labels = widget.isIQ
        ? AppConstants.iqCategoryLabels
        : AppConstants.eqCategoryLabels;
    final categories = widget.isIQ
        ? AppConstants.iqCategories
        : AppConstants.eqCategories;

    // Sort entries by the canonical category order.
    entries.sort((a, b) {
      final aIndex = categories.indexOf(a.key);
      final bIndex = categories.indexOf(b.key);
      return aIndex.compareTo(bIndex);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: AppTypography.heading5,
        ),
        const SizedBox(height: AppSpacing.md),
        ...List.generate(entries.length, (index) {
          if (index >= _animations.length) return const SizedBox.shrink();

          final entry = entries[index];
          final label = labels[entry.key] ?? entry.key;
          final score = entry.value;
          final normalizedScore = (score / 100).clamp(0.0, 1.0);
          final icon = _categoryIcon(entry.key);
          final barColor = _scoreColor(score);

          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, _) {
              final animatedValue = _animations[index].value;
              final currentScore = (score * animatedValue).round();

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Opacity(
                  opacity: animatedValue.clamp(0.0, 1.0),
                  child: Row(
                    children: [
                      // Category icon.
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Icon(
                          icon,
                          size: 18,
                          color: barColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),

                      // Name and bar.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label,
                                  style: AppTypography.bodyMedium,
                                ),
                                Text(
                                  '$currentScore',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: barColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xxs),

                            // Animated progress bar.
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: AppSpacing.borderRadiusFull,
                              ),
                              child: ClipRRect(
                                borderRadius: AppSpacing.borderRadiusFull,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor:
                                        (normalizedScore * animatedValue)
                                            .clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            barColor,
                                            barColor.withValues(alpha: 0.7),
                                          ],
                                        ),
                                        borderRadius:
                                            AppSpacing.borderRadiusFull,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                barColor.withValues(alpha: 0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    );
  }

  /// Returns a color based on the score: green for strong, yellow for
  /// average, red-orange for weak areas.
  Color _scoreColor(double score) {
    if (score >= 75) return AppColors.success;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }

  /// Returns an icon for each category.
  IconData _categoryIcon(String category) {
    switch (category) {
      // IQ categories.
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

      // EQ categories.
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
