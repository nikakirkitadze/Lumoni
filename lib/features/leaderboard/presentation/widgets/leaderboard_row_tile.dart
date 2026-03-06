import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardRowTile extends StatelessWidget {
  const LeaderboardRowTile({super.key, required this.entry, this.onTap});

  final LeaderboardEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;

    return GlassCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      borderColor: entry.isCurrentUser
          ? AppColors.accent.withValues(alpha: 0.6)
          : AppColors.glassBorder,
      gradient: isTopThree
          ? LinearGradient(
              colors: [
                AppColors.warning.withValues(alpha: 0.16),
                AppColors.primary.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : AppColors.glassGradient,
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              _rankLabel(entry.rank),
              style: AppTypography.heading6.copyWith(
                color: isTopThree
                    ? AppColors.warningLight
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: entry.isCurrentUser
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tier ${entry.tier} • ${entry.percentile.toStringAsFixed(1)}th pct',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.rankScore.toStringAsFixed(1),
                style: AppTypography.heading6.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${entry.validatedCount} validated',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _rankLabel(int rank) {
    if (rank == 1) return 'TOP1';
    if (rank == 2) return 'TOP2';
    if (rank == 3) return 'TOP3';
    return '#$rank';
  }
}
