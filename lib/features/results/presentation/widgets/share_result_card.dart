import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/results/presentation/cubits/results_state.dart';

/// A beautifully designed card that represents the test result in a
/// format suitable for sharing. This widget can be captured as an image
/// using [RepaintBoundary] and rendered to a bitmap.
class ShareResultCard extends StatelessWidget {
  const ShareResultCard({
    super.key,
    required this.results,
    this.repaintKey,
  });

  /// The loaded results state containing all score data.
  final ResultsLoaded results;

  /// Optional global key for [RepaintBoundary] image capture.
  final GlobalKey? repaintKey;

  @override
  Widget build(BuildContext context) {
    final labels = results.isIQ
        ? AppConstants.iqCategoryLabels
        : AppConstants.eqCategoryLabels;

    Widget card = Container(
      width: 340,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1145),
            AppColors.background,
            Color(0xFF0D1B2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App logo and branding.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppConstants.appName,
                style: AppTypography.heading4.copyWith(
                  foreground: Paint()
                    ..shader = AppColors.primaryGradient.createShader(
                      const Rect.fromLTWH(0, 0, 100, 30),
                    ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Intelligence Assessment',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Divider.
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primary.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Score display.
          if (results.isIQ) ...[
            Text(
              'IQ SCORE',
              style: AppTypography.overline.copyWith(
                color: AppColors.accent,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${results.iqScore}',
              style: AppTypography.scoreHero.copyWith(
                fontSize: 56,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ).createShader(const Rect.fromLTWH(0, 0, 80, 60)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                results.iqClassification,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary300,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Top ${(100 - results.iqPercentile).toStringAsFixed(0)}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.accent,
              ),
            ),
          ] else ...[
            Text(
              'EQ SCORE',
              style: AppTypography.overline.copyWith(
                color: AppColors.secondary400,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${results.eqScore.round()}',
              style: AppTypography.scoreHero.copyWith(
                fontSize: 56,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                  ).createShader(const Rect.fromLTWH(0, 0, 80, 60)),
              ),
            ),
            Text(
              '/100',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                results.eqClassification,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondary300,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Mini category breakdown.
          ...results.categoryScores.entries.map((entry) {
            final label = labels[entry.key] ?? entry.key;
            final score = entry.value;
            final normalizedScore = (score / 100).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${score.round()}',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppSpacing.borderRadiusFull,
                    ),
                    child: ClipRRect(
                      borderRadius: AppSpacing.borderRadiusFull,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: normalizedScore,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: results.isIQ
                                  ? AppColors.accentGradient
                                  : AppColors.primaryGradient,
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
          }),

          const SizedBox(height: AppSpacing.lg),

          // Divider.
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.border.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Date and branding.
          Text(
            _formatDate(results.session.completedAt ?? DateTime.now()),
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tested with ${AppConstants.appName}',
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    if (repaintKey != null) {
      card = RepaintBoundary(
        key: repaintKey,
        child: card,
      );
    }

    return card;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
