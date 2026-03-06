import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/results/presentation/cubits/results_state.dart';
import 'package:lumoni/features/share_card/data/models/share_card_config.dart';

/// Renders the share card visual based on [config] and [results].
///
/// This widget is meant to be wrapped in a [RepaintBoundary] for image capture.
/// It sizes itself according to the selected aspect ratio while maintaining a
/// fixed width of 340 logical pixels (scaled up by pixel ratio on export).
class ShareCardTemplate extends StatelessWidget {
  const ShareCardTemplate({
    super.key,
    required this.results,
    required this.config,
  });

  final ResultsLoaded results;
  final ShareCardConfig config;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      height: 340 / config.aspectRatio.value,
      decoration: BoxDecoration(
        gradient: config.style.backgroundGradient,
        borderRadius: AppSpacing.borderRadiusXl,
        border: Border.all(
          color: config.style.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: config.style.accentColor.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppSpacing.borderRadiusXl,
        child: Stack(
          children: [
            // Decorative background elements per style
            _buildBackgroundDecoration(),

            // Main content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader(),
                  _buildScoreSection(),
                  if (config.showCategoryBreakdown) _buildCategoryBreakdown(),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── Background Decoration ────────────────────────────

  Widget _buildBackgroundDecoration() {
    switch (config.style) {
      case ShareCardStyle.neon:
        return Positioned.fill(
          child: CustomPaint(painter: _NeonGridPainter(config.style.accentColor)),
        );
      case ShareCardStyle.glass:
        return Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  config.style.accentColor.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      case ShareCardStyle.royal:
        return Positioned.fill(
          child: CustomPaint(
            painter: _RoyalPatternPainter(config.style.accentColor),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────── Header ──────────────────────────────────────────

  Widget _buildHeader() {
    final isGradientStyle = config.style == ShareCardStyle.gradient;
    final textColor =
        isGradientStyle ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isGradientStyle
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textTertiary;

    return Column(
      children: [
        // Logo + brand
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: isGradientStyle
                    ? const LinearGradient(
                        colors: [Colors.white, Color(0xFFE0E0E0)],
                      )
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.psychology_rounded,
                color: isGradientStyle ? AppColors.primary : Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              AppConstants.appName,
              style: AppTypography.heading4.copyWith(
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Intelligence Assessment',
          style: AppTypography.captionSmall.copyWith(
            color: subtitleColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                config.style.accentColor.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────── Score Section ────────────────────────────────────

  Widget _buildScoreSection() {
    switch (config.cardType) {
      case ShareCardType.iqScore:
        return _buildIQScoreDisplay();
      case ShareCardType.eqScore:
        return _buildEQScoreDisplay();
      case ShareCardType.combinedProfile:
        return _buildCombinedDisplay();
    }
  }

  Widget _buildIQScoreDisplay() {
    final isGradientStyle = config.style == ShareCardStyle.gradient;

    return Column(
      children: [
        Text(
          'IQ SCORE',
          style: AppTypography.overline.copyWith(
            color: _scoreAccentColor,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${results.iqScore}',
          style: AppTypography.scoreHero.copyWith(
            fontSize: 64,
            foreground: isGradientStyle
                ? (Paint()..color = Colors.white)
                : (Paint()
                  ..shader = LinearGradient(
                    colors: _scoreGradientColors,
                  ).createShader(const Rect.fromLTWH(0, 0, 100, 70))),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Classification badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _scoreAccentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _scoreAccentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            results.iqClassification,
            style: AppTypography.bodyMedium.copyWith(
              color: _scoreAccentColor,
            ),
          ),
        ),
        if (config.showPercentile) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Top ${(100 - results.iqPercentile).toStringAsFixed(0)}%',
            style: AppTypography.caption.copyWith(
              color: _scoreAccentColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEQScoreDisplay() {
    final isGradientStyle = config.style == ShareCardStyle.gradient;

    return Column(
      children: [
        Text(
          'EQ SCORE',
          style: AppTypography.overline.copyWith(
            color: _scoreAccentColor,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${results.eqScore.round()}',
          style: AppTypography.scoreHero.copyWith(
            fontSize: 64,
            foreground: isGradientStyle
                ? (Paint()..color = Colors.white)
                : (Paint()
                  ..shader = LinearGradient(
                    colors: _scoreGradientColors,
                  ).createShader(const Rect.fromLTWH(0, 0, 100, 70))),
          ),
        ),
        Text(
          '/100',
          style: AppTypography.bodySmall.copyWith(
            color: isGradientStyle
                ? Colors.white.withValues(alpha: 0.6)
                : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _scoreAccentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _scoreAccentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            results.eqClassification,
            style: AppTypography.bodyMedium.copyWith(
              color: _scoreAccentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCombinedDisplay() {
    final isGradientStyle = config.style == ShareCardStyle.gradient;
    final labelColor = isGradientStyle
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // IQ
        Column(
          children: [
            Text(
              'IQ',
              style: AppTypography.overline.copyWith(
                color: _scoreAccentColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${results.iqScore}',
              style: AppTypography.scoreLarge.copyWith(
                foreground: isGradientStyle
                    ? (Paint()..color = Colors.white)
                    : (Paint()
                      ..shader = LinearGradient(
                        colors: _scoreGradientColors,
                      ).createShader(const Rect.fromLTWH(0, 0, 60, 40))),
              ),
            ),
            Text(
              results.iqClassification,
              style: AppTypography.captionSmall.copyWith(color: labelColor),
            ),
          ],
        ),
        // Divider
        Container(
          width: 1,
          height: 60,
          color: config.style.borderColor,
        ),
        // EQ
        Column(
          children: [
            Text(
              'EQ',
              style: AppTypography.overline.copyWith(
                color: _scoreAccentColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '${results.eqScore.round()}',
              style: AppTypography.scoreLarge.copyWith(
                foreground: isGradientStyle
                    ? (Paint()..color = Colors.white)
                    : (Paint()
                      ..shader = LinearGradient(
                        colors: _scoreGradientColors,
                      ).createShader(const Rect.fromLTWH(0, 0, 60, 40))),
              ),
            ),
            Text(
              results.eqClassification,
              style: AppTypography.captionSmall.copyWith(color: labelColor),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────── Category Breakdown ───────────────────────────────

  Widget _buildCategoryBreakdown() {
    final labels = results.isIQ
        ? AppConstants.iqCategoryLabels
        : AppConstants.eqCategoryLabels;
    final isGradientStyle = config.style == ShareCardStyle.gradient;
    final labelColor = isGradientStyle
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    final valueColor = isGradientStyle ? Colors.white : AppColors.textPrimary;
    final barBgColor = isGradientStyle
        ? Colors.white.withValues(alpha: 0.15)
        : AppColors.surface;

    return Column(
      children: results.categoryScores.entries.map((entry) {
        final label = labels[entry.key] ?? entry.key;
        final score = entry.value;
        final normalizedScore = (score / 100).clamp(0.0, 1.0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTypography.captionSmall.copyWith(
                      color: labelColor,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${score.round()}',
                    style: AppTypography.captionSmall.copyWith(
                      color: valueColor,
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
                  color: barBgColor,
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
                          gradient: LinearGradient(
                            colors: _barGradientColors,
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
      }).toList(),
    );
  }

  // ─────────────────── Footer ──────────────────────────────────────────

  Widget _buildFooter() {
    final isGradientStyle = config.style == ShareCardStyle.gradient;
    final subtitleColor = isGradientStyle
        ? Colors.white.withValues(alpha: 0.5)
        : AppColors.textTertiary;

    return Column(
      children: [
        // Divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                config.style.borderColor.withValues(alpha: 0.5),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _formatDate(results.session.completedAt ?? DateTime.now()),
          style: AppTypography.captionSmall.copyWith(
            color: subtitleColor,
            fontSize: 10,
          ),
        ),
        if (config.showWatermark) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Tested with ${AppConstants.appName}',
            style: AppTypography.captionSmall.copyWith(
              color: subtitleColor,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────── Style Helpers ───────────────────────────────────

  Color get _scoreAccentColor {
    switch (config.style) {
      case ShareCardStyle.classic:
        return results.isIQ ? AppColors.accent : AppColors.secondary400;
      case ShareCardStyle.minimal:
        return AppColors.textSecondary;
      case ShareCardStyle.neon:
        return config.style.accentColor;
      case ShareCardStyle.gradient:
        return Colors.white;
      case ShareCardStyle.glass:
        return AppColors.accent;
      case ShareCardStyle.royal:
        return config.style.accentColor;
    }
  }

  List<Color> get _scoreGradientColors {
    switch (config.style) {
      case ShareCardStyle.classic:
        return results.isIQ
            ? [AppColors.primary, AppColors.accent]
            : [AppColors.secondary, AppColors.primary];
      case ShareCardStyle.minimal:
        return [AppColors.textPrimary, AppColors.textSecondary];
      case ShareCardStyle.neon:
        return [config.style.accentColor, const Color(0xFF00DDFF)];
      case ShareCardStyle.gradient:
        return [Colors.white, Colors.white];
      case ShareCardStyle.glass:
        return [AppColors.accent, AppColors.primary];
      case ShareCardStyle.royal:
        return [config.style.accentColor, const Color(0xFFFFA500)];
    }
  }

  List<Color> get _barGradientColors {
    switch (config.style) {
      case ShareCardStyle.classic:
        return results.isIQ
            ? [AppColors.primary, AppColors.accent]
            : [AppColors.secondary, AppColors.primary];
      case ShareCardStyle.minimal:
        return [AppColors.textTertiary, AppColors.textSecondary];
      case ShareCardStyle.neon:
        return [config.style.accentColor, const Color(0xFF00DDFF)];
      case ShareCardStyle.gradient:
        return [Colors.white.withValues(alpha: 0.8), Colors.white];
      case ShareCardStyle.glass:
        return [AppColors.accent, AppColors.primary];
      case ShareCardStyle.royal:
        return [config.style.accentColor, const Color(0xFFFFA500)];
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ─────────────────── Custom Painters ────────────────────────────────────────

/// Draws a subtle neon grid overlay for the Neon style.
class _NeonGridPainter extends CustomPainter {
  _NeonGridPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws subtle diamond pattern for the Royal style.
class _RoyalPatternPainter extends CustomPainter {
  _RoyalPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        final path = Path()
          ..moveTo(x, y - 10)
          ..lineTo(x + 10, y)
          ..lineTo(x, y + 10)
          ..lineTo(x - 10, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
