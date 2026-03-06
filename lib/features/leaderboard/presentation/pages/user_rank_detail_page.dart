import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/user_rank/user_rank_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/user_rank/user_rank_state.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_row_tile.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/tier_badge_chip.dart';

class UserRankDetailPage extends StatefulWidget {
  const UserRankDetailPage({
    super.key,
    required this.snapshotId,
    required this.userId,
  });

  final String snapshotId;
  final String userId;

  @override
  State<UserRankDetailPage> createState() => _UserRankDetailPageState();
}

class _UserRankDetailPageState extends State<UserRankDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserRankCubit>().load(
        snapshotId: widget.snapshotId,
        userId: widget.userId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Your Rank Details'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocBuilder<UserRankCubit, UserRankState>(
        builder: (context, state) {
          return switch (state) {
            UserRankInitial() || UserRankLoading() => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            UserRankUnranked(:final reason) => _buildNotice(
              context,
              reason ?? 'Not yet ranked. Complete more validated sessions.',
            ),
            UserRankHidden() => _buildNotice(
              context,
              'Your profile is hidden from public rankings.',
            ),
            UserRankError(:final message) => _buildNotice(context, message),
            UserRankLoaded(:final rank) => ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                GlassCard(
                  borderColor: AppColors.accent.withValues(alpha: 0.55),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.accent.withValues(alpha: 0.11),
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
                            '#${rank.rank}',
                            style: AppTypography.heading2.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          TierBadgeChip(tier: rank.tier),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${rank.percentile.toStringAsFixed(1)}th percentile',
                        style: AppTypography.heading6.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rank score: ${rank.rankScore.toStringAsFixed(1)}',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Validated sessions: ${rank.validatedCount} • Eligible users: ${rank.totalEligible}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Nearby Rivals',
                  style: AppTypography.heading6.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (rank.neighborhood.isEmpty)
                  Text(
                    'No nearby rivals available yet.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  ...rank.neighborhood.map(
                    (entry) => LeaderboardRowTile(entry: entry),
                  ),
              ],
            ),
          };
        },
      ),
    );
  }

  Widget _buildNotice(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
