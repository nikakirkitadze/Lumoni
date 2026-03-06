import 'package:flutter/material.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardTopHighlights extends StatelessWidget {
  const LeaderboardTopHighlights({super.key, required this.entries});

  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 138,
      child: Row(
        children: List.generate(
          entries.length > 3 ? 3 : entries.length,
          (index) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index < 2 ? AppSpacing.sm : 0),
              child: _HighlightCard(entry: entries[index]),
            ),
          ),
        ),
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: _tierAccent(entry.rank),
      gradient: LinearGradient(
        colors: [
          _tierAccent(entry.rank).withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _rankBadge(entry.rank),
            style: AppTypography.heading4.copyWith(
              color: _tierAccent(entry.rank),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.rankScore.toStringAsFixed(1),
            style: AppTypography.heading6.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _tierAccent(int rank) {
    if (rank == 1) return AppColors.warningLight;
    if (rank == 2) return AppColors.accent;
    if (rank == 3) return AppColors.secondary400;
    return AppColors.primary;
  }

  String _rankBadge(int rank) {
    switch (rank) {
      case 1:
        return 'TOP 1';
      case 2:
        return 'TOP 2';
      case 3:
        return 'TOP 3';
      default:
        return '#$rank';
    }
  }
}
