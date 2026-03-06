import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_user_rank.dart';

class YourRankCard extends StatelessWidget {
  const YourRankCard({super.key, required this.rank, this.onDetailsTap});

  final LeaderboardUserRank? rank;
  final VoidCallback? onDetailsTap;

  @override
  Widget build(BuildContext context) {
    if (rank == null) {
      return GlassCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rank',
              style: AppTypography.heading6.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Complete validated sessions to unlock your leaderboard position.',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      borderColor: AppColors.accent.withValues(alpha: 0.55),
      gradient: LinearGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.14),
          AppColors.primary.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Rank',
                style: AppTypography.heading6.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onDetailsTap,
                child: Text(
                  'Details',
                  style: AppTypography.buttonSmall.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                '#${rank!.rank}',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${rank!.percentile.toStringAsFixed(1)}th percentile',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tier ${rank!.tier} • ${rank!.validatedCount} validated sessions',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                rank!.rankScore.toStringAsFixed(1),
                style: AppTypography.heading5.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
