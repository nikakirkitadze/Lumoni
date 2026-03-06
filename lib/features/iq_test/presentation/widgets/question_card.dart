import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Displays a single IQ question with a number badge, category chip,
/// difficulty dots, question text, and optional image area.
///
/// Wraps its content in a fade-in animation for smooth transitions.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
  });

  /// The question model to display.
  final IQQuestionModel question;

  /// One-based question number.
  final int questionNumber;

  /// Total number of questions (used for display context).
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: question number + category badge + difficulty
        Row(
          children: [
            // Question number badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusFull,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Q$questionNumber',
                style: AppTypography.buttonSmall.copyWith(
                  color: AppColors.primary300,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Category chip
            _CategoryChip(category: question.category),
            const Spacer(),

            // Difficulty dots
            _DifficultyDots(difficulty: question.difficulty),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Question text
        Text(
          question.question,
          style: AppTypography.heading4.copyWith(
            color: AppColors.textPrimary,
            height: 1.45,
          ),
        ),

        // Optional image
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusMd,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: Image.network(
                question.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) {
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textTertiary,
                          size: 32,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Image unavailable',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 120,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A small chip that displays the question category with an icon.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  IconData get _icon {
    switch (category) {
      case AppConstants.iqCategoryPattern:
        return Icons.grid_view_rounded;
      case AppConstants.iqCategoryLogical:
        return Icons.psychology_rounded;
      case AppConstants.iqCategoryMath:
        return Icons.calculate_rounded;
      case AppConstants.iqCategoryVerbal:
        return Icons.text_fields_rounded;
      case AppConstants.iqCategorySpatial:
        return Icons.view_in_ar_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  String get _label {
    return AppConstants.iqCategoryLabels[category] ?? category;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            _label,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays difficulty as 1-5 filled dots.
class _DifficultyDots extends StatelessWidget {
  const _DifficultyDots({required this.difficulty});

  final int difficulty;

  Color _dotColor(int index) {
    if (index >= difficulty) return AppColors.border;
    if (difficulty <= 2) return AppColors.success;
    if (difficulty <= 3) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Lvl ',
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        ...List.generate(5, (index) {
          return Padding(
            padding: EdgeInsets.only(left: index > 0 ? 3 : 0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _dotColor(index),
              ),
            ),
          );
        }),
      ],
    );
  }
}
