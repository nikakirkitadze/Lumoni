import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Displays a single EQ statement inside a premium glass card with
/// a category badge, statement number, and fade-in animation.
class EQStatementCard extends StatefulWidget {
  const EQStatementCard({
    super.key,
    required this.statement,
    required this.statementNumber,
    required this.totalStatements,
  });

  /// The EQ statement model to display.
  final EQQuestionModel statement;

  /// 1-based index of this statement.
  final int statementNumber;

  /// Total number of statements in the session.
  final int totalStatements;

  @override
  State<EQStatementCard> createState() => _EQStatementCardState();
}

class _EQStatementCardState extends State<EQStatementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant EQStatementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statement.id != widget.statement.id) {
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category badge and statement counter.
              Row(
                children: [
                  _CategoryBadge(category: widget.statement.category),
                  const Spacer(),
                  Text(
                    '${widget.statementNumber} / ${widget.totalStatements}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Statement text.
              Text(
                widget.statement.statement,
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Instruction hint.
              Text(
                'Rate how much you agree with this statement',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small colored badge showing the EQ category name.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final label =
        AppConstants.eqCategoryLabels[category] ?? category;
    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _categoryIcon(category),
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a unique color for each EQ category.
  static Color _categoryColor(String category) {
    switch (category) {
      case AppConstants.eqCategorySelfAwareness:
        return AppColors.accent;
      case AppConstants.eqCategorySelfRegulation:
        return AppColors.success;
      case AppConstants.eqCategoryMotivation:
        return AppColors.warning;
      case AppConstants.eqCategoryEmpathy:
        return const Color(0xFFEC4899); // Pink.
      case AppConstants.eqCategorySocialSkills:
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Returns a representative icon for each EQ category.
  static IconData _categoryIcon(String category) {
    switch (category) {
      case AppConstants.eqCategorySelfAwareness:
        return Icons.visibility_rounded;
      case AppConstants.eqCategorySelfRegulation:
        return Icons.shield_rounded;
      case AppConstants.eqCategoryMotivation:
        return Icons.bolt_rounded;
      case AppConstants.eqCategoryEmpathy:
        return Icons.favorite_rounded;
      case AppConstants.eqCategorySocialSkills:
        return Icons.people_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }
}
