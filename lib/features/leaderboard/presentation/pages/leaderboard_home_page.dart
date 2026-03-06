import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/app/router.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/filter/leaderboard_filter_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/home/leaderboard_home_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/home/leaderboard_home_state.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/privacy/leaderboard_privacy_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/privacy/leaderboard_privacy_state.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_empty_state.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_filter_bar.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_top_highlights.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/tier_badge_chip.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/your_rank_card.dart';

class LeaderboardHomePage extends StatefulWidget {
  const LeaderboardHomePage({super.key});

  @override
  State<LeaderboardHomePage> createState() => _LeaderboardHomePageState();
}

class _LeaderboardHomePageState extends State<LeaderboardHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<LeaderboardFilterCubit>().loadCachedFilter();
      if (!mounted) return;
      final filter = context.read<LeaderboardFilterCubit>().state;
      await context.read<LeaderboardHomeCubit>().load(filter);
      if (!mounted) return;
      await context.read<LeaderboardPrivacyCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaderboardFilterCubit, LeaderboardFilter>(
      listener: (context, filter) {
        context.read<LeaderboardHomeCubit>().load(filter);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<LeaderboardHomeCubit, LeaderboardHomeState>(
            builder: (context, homeState) {
              return switch (homeState.status) {
                LeaderboardHomeStatus.initial ||
                LeaderboardHomeStatus.loading => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                LeaderboardHomeStatus.empty => _buildEmptyState(context),
                LeaderboardHomeStatus.error => _buildError(
                  context,
                  homeState.errorMessage,
                ),
                LeaderboardHomeStatus.loaded => _buildLoaded(
                  context,
                  homeState,
                ),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, LeaderboardHomeState homeState) {
    final filter = context.watch<LeaderboardFilterCubit>().state;

    return RefreshIndicator(
      onRefresh: () => context.read<LeaderboardHomeCubit>().load(filter),
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: AppTypography.heading3.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Compete with validated performance only.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showPrivacySheet(context),
                    icon: const Icon(
                      Icons.privacy_tip_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: LeaderboardFilterBar(
                filter: filter,
                onMetricChanged: context
                    .read<LeaderboardFilterCubit>()
                    .setMetric,
                onPeriodChanged: context
                    .read<LeaderboardFilterCubit>()
                    .setPeriod,
                onScopeChanged: (scope) async {
                  if (scope == LeaderboardScopeType.country &&
                      (filter.countryCode == null ||
                          filter.countryCode!.isEmpty)) {
                    await context.read<LeaderboardFilterCubit>().setCountry(
                      'US',
                    );
                    return;
                  }
                  await context.read<LeaderboardFilterCubit>().setScope(scope);
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                0,
              ),
              child: YourRankCard(
                rank: homeState.userRank,
                onDetailsTap: () {
                  final snapshotId = homeState.snapshot?.id;
                  if (snapshotId == null) return;
                  context.push(
                    '${RoutePaths.leaderboardRankDetail}?snapshotId=$snapshotId',
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Global Rankings',
                      variant: AppButtonVariant.primary,
                      onPressed: () =>
                          context.push(RoutePaths.leaderboardGlobal),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      label: 'Country Rankings',
                      variant: AppButtonVariant.solid,
                      onPressed: () =>
                          context.push(RoutePaths.leaderboardCountry),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Top Performers',
                    style: AppTypography.heading6.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (homeState.userRank != null)
                    TierBadgeChip(tier: homeState.userRank!.tier),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: LeaderboardTopHighlights(entries: homeState.topEntries),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                0,
              ),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier Ladder',
                      style: AppTypography.heading6.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Unlock elite badges as your validated percentile climbs.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'View Tier Details',
                      variant: AppButtonVariant.outlined,
                      onPressed: () =>
                          context.push(RoutePaths.leaderboardTierDetail),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.of(context).padding.bottom + AppSpacing.massive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              message ?? 'Failed to load leaderboard.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                final filter = context.read<LeaderboardFilterCubit>().state;
                context.read<LeaderboardHomeCubit>().load(filter);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LeaderboardEmptyState(
      onTap: () => context.push(RoutePaths.iqTestIntro),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    final state = context.read<LeaderboardPrivacyCubit>().state;
    if (state is! LeaderboardPrivacyLoaded) {
      context.read<LeaderboardPrivacyCubit>().load();
      return;
    }

    bool anonymousMode = state.settings.anonymousMode;
    bool hideProfile = state.settings.hideProfile;
    bool shareCountry = state.settings.shareInCountry;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leaderboard Privacy',
                    style: AppTypography.heading5.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile.adaptive(
                    value: anonymousMode,
                    activeThumbColor: AppColors.accent,
                    title: Text(
                      'Anonymous Mode',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Show alias instead of display name.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (value) =>
                        setSheetState(() => anonymousMode = value),
                  ),
                  SwitchListTile.adaptive(
                    value: hideProfile,
                    activeThumbColor: AppColors.accent,
                    title: Text(
                      'Hide Public Profile',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'You still see your own rank privately.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (value) =>
                        setSheetState(() => hideProfile = value),
                  ),
                  SwitchListTile.adaptive(
                    value: shareCountry,
                    activeThumbColor: AppColors.accent,
                    title: Text(
                      'Appear in Country Ranking',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Disable to stay in global-only visibility.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onChanged: (value) =>
                        setSheetState(() => shareCountry = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Save',
                    variant: AppButtonVariant.primary,
                    width: double.infinity,
                    onPressed: () async {
                      final updated = state.settings.copyWith(
                        anonymousMode: anonymousMode,
                        hideProfile: hideProfile,
                        shareInCountry: shareCountry,
                      );
                      await context.read<LeaderboardPrivacyCubit>().save(
                        updated,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
