import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';

/// A compact card that displays a single recent test score.
///
/// Shows the test type badge, score, date, and a mini category-breakdown
/// bar, all rendered on a frosted glass background.
class RecentScoreCard extends StatelessWidget {
  final TestSessionModel session;
  final VoidCallback? onTap;

  const RecentScoreCard({
    super.key,
    required this.session,
    this.onTap,
  });

  bool get _isIQ => session.testType == TestType.iq;

  Color get _accentColor => _isIQ ? AppColors.primary : AppColors.secondary;

  String get _scoreDisplay {
    final score = session.score;
    if (score == null) return '--';
    return _isIQ ? score.round().toString() : score.toStringAsFixed(1);
  }

  String get _dateLabel {
    final completed = session.completedAt;
    if (completed == null) return '';
    final now = DateTime.now();
    final diff = now.difference(completed);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(completed);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: AppColors.glassBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Type badge & date ────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeBadge(),
                Text(
                  _dateLabel,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Score ────────────────────────────────────────────
            Text(
              _scoreDisplay,
              style: AppTypography.scoreLarge.copyWith(
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _isIQ ? 'IQ Score' : 'EQ Score',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Category breakdown bars ──────────────────────────
            if (session.categoryScores.isNotEmpty)
              _buildCategoryBars(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        _isIQ ? 'IQ' : 'EQ',
        style: AppTypography.captionSmall.copyWith(
          color: _accentColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCategoryBars() {
    final entries = session.categoryScores.entries.take(5).toList();
    final maxScore = _isIQ ? 145.0 : 100.0;

    return Column(
      children: entries.map((entry) {
        final fraction = (entry.value / maxScore).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 3,
                    backgroundColor:
                        AppColors.surface.withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _accentColor.withValues(alpha: 0.7),
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
}
