import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/app/router.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/filter/leaderboard_filter_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_row_tile.dart';
import 'package:lumoni/features/friends/presentation/cubits/friend_rankings_cubit.dart';
import 'package:lumoni/features/friends/presentation/cubits/friend_rankings_state.dart';
import 'package:lumoni/features/friends/presentation/widgets/friend_empty_state.dart';

class FriendRankingsPage extends StatefulWidget {
  const FriendRankingsPage({super.key});

  @override
  State<FriendRankingsPage> createState() => _FriendRankingsPageState();
}

class _FriendRankingsPageState extends State<FriendRankingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final filter = context.read<LeaderboardFilterCubit>().state;
      context.read<FriendRankingsCubit>().load(
            metric: filter.metric,
            period: filter.period,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Friend Rankings'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),
      body: BlocBuilder<FriendRankingsCubit, FriendRankingsState>(
        builder: (context, state) {
          return switch (state.status) {
            FriendRankingsStatus.initial ||
            FriendRankingsStatus.loading =>
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            FriendRankingsStatus.noFriends => FriendEmptyState(
                title: 'No Friends Yet',
                message:
                    'Add friends to compete on your personal leaderboard.',
                ctaLabel: 'Add Friends',
                onTap: () => context.push(RoutePaths.friends),
              ),
            FriendRankingsStatus.empty => FriendEmptyState(
                title: 'No Eligible Friends',
                message:
                    'Your friends need to complete validated sessions to appear here.',
                ctaLabel: 'Invite Friends',
                onTap: () => context.push(RoutePaths.friends),
              ),
            FriendRankingsStatus.error => _buildError(state.errorMessage),
            FriendRankingsStatus.loaded => _buildLoaded(context, state),
          };
        },
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'Failed to load friend rankings.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.outlined,
              onPressed: () =>
                  context.read<FriendRankingsCubit>().refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, FriendRankingsState state) {
    final filter = context.watch<LeaderboardFilterCubit>().state;

    return Stack(
      children: [
        RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<FriendRankingsCubit>().refresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.massive,
            ),
            children: [
              // Metric selector
              _MetricPeriodBar(
                metric: filter.metric,
                period: filter.period,
                onMetricChanged: (metric) {
                  context.read<LeaderboardFilterCubit>().setMetric(metric);
                  context.read<FriendRankingsCubit>().load(metric: metric);
                },
                onPeriodChanged: (period) {
                  context.read<LeaderboardFilterCubit>().setPeriod(period);
                  context.read<FriendRankingsCubit>().load(period: period);
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Entries
              ...state.entries.map(
                (entry) => LeaderboardRowTile(entry: entry),
              ),

              // Small friend count prompt
              if (state.totalEligible <= 3)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: GlassCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.group_add_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Invite more friends to make competition exciting!',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(RoutePaths.friends),
                          child: Text(
                            'Invite',
                            style: AppTypography.buttonSmall.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Pinned rank card at bottom
        if (state.callerEntry != null)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: _CallerRankCard(entry: state.callerEntry!),
          ),
      ],
    );
  }
}

// ─────────────────── Metric / Period Bar ──────────────────────────────────────

class _MetricPeriodBar extends StatelessWidget {
  const _MetricPeriodBar({
    required this.metric,
    required this.period,
    required this.onMetricChanged,
    required this.onPeriodChanged,
  });

  final LeaderboardMetric metric;
  final LeaderboardPeriod period;
  final ValueChanged<LeaderboardMetric> onMetricChanged;
  final ValueChanged<LeaderboardPeriod> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: LeaderboardMetric.values
              .map(
                (m) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: m == LeaderboardMetric.iq ? AppSpacing.xs : 0,
                    ),
                    child: _Chip(
                      label: m.label,
                      selected: metric == m,
                      onTap: () => onMetricChanged(m),
                      isPrimary: true,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LeaderboardPeriod.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final p = LeaderboardPeriod.values[index];
              return _Chip(
                label: p.label,
                selected: period == p,
                onTap: () => onPeriodChanged(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: isPrimary ? AppSpacing.sm : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: selected && isPrimary ? AppColors.primaryGradient : null,
          color: selected && !isPrimary
              ? AppColors.accent.withValues(alpha: 0.18)
              : (selected ? null : AppColors.surface),
          borderRadius:
              isPrimary ? AppSpacing.borderRadiusMd : AppSpacing.borderRadiusFull,
          border: Border.all(
            color: selected
                ? (isPrimary
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.accent.withValues(alpha: 0.6))
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: (isPrimary ? AppTypography.button : AppTypography.labelSmall)
                .copyWith(
              color: selected
                  ? (isPrimary ? AppColors.textOnPrimary : AppColors.accent)
                  : AppColors.textSecondary,
              fontWeight: isPrimary ? null : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Caller Rank Card ────────────────────────────────────────

class _CallerRankCard extends StatelessWidget {
  const _CallerRankCard({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.accent.withValues(alpha: 0.55),
      gradient: LinearGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.14),
          AppColors.primary.withValues(alpha: 0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${entry.percentile.toStringAsFixed(1)}th pct • Tier ${entry.tier}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.rankScore.toStringAsFixed(1),
            style: AppTypography.heading5.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
