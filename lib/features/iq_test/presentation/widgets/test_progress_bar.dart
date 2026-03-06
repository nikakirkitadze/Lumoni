import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// A linear progress bar showing test completion with question dots.
///
/// Displays "Question X of Y" text, an animated gradient fill, and small
/// dots indicating answered / unanswered / current status.
class TestProgressBar extends StatelessWidget {
  const TestProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.answeredIndices,
  });

  /// Zero-based index of the current question.
  final int currentIndex;

  /// Total number of questions in the test.
  final int totalQuestions;

  /// Set of question indices that have been answered.
  final Set<int> answeredIndices;

  @override
  Widget build(BuildContext context) {
    final progress =
        totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row: label + count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Question ${currentIndex + 1} of $totalQuestions',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${answeredIndices.length} answered',
              style: AppTypography.caption.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Animated fill bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Track
                    Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Fill
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: AppColors.progressGradient,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Question dots
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dot sizing based on available width
              final maxDotSize = 8.0;
              final minDotSize = 4.0;
              final maxGap = 4.0;
              final minGap = 1.5;

              final availableWidth = constraints.maxWidth;
              var dotSize = maxDotSize;
              var gap = maxGap;

              // Scale down if too many dots
              final totalWidth =
                  totalQuestions * dotSize + (totalQuestions - 1) * gap;
              if (totalWidth > availableWidth) {
                final ratio = availableWidth /
                    (totalQuestions * (minDotSize + minGap) - minGap);
                dotSize =
                    (minDotSize * ratio).clamp(minDotSize, maxDotSize);
                gap = (minGap * ratio).clamp(minGap, maxGap);
              }

              // If still overflowing, use scrollable row
              final fits =
                  totalQuestions * dotSize + (totalQuestions - 1) * gap <=
                      availableWidth;

              final dotsRow = Row(
                mainAxisAlignment:
                    fits ? MainAxisAlignment.center : MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(totalQuestions, (index) {
                  final isAnswered = answeredIndices.contains(index);
                  final isCurrent = index == currentIndex;

                  Color dotColor;
                  double size;

                  if (isCurrent) {
                    dotColor = AppColors.accent;
                    size = dotSize + 1;
                  } else if (isAnswered) {
                    dotColor = AppColors.primary;
                    size = dotSize;
                  } else {
                    dotColor = AppColors.border;
                    size = dotSize - 1;
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < totalQuestions - 1 ? gap : 0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.accent.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              );

              if (!fits) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: dotsRow,
                );
              }

              return Center(child: dotsRow);
            },
          ),
        ),
      ],
    );
  }
}
