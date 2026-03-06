import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/app/router.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/filter/leaderboard_filter_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/list/leaderboard_list_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/list/leaderboard_list_state.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/user_rank/user_rank_cubit.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/user_rank/user_rank_state.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_empty_state.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_filter_bar.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/leaderboard_row_tile.dart';
import 'package:lumoni/features/leaderboard/presentation/widgets/your_rank_card.dart';

class GlobalRankingsPage extends StatefulWidget {
  const GlobalRankingsPage({super.key});

  @override
  State<GlobalRankingsPage> createState() => _GlobalRankingsPageState();
}

class _GlobalRankingsPageState extends State<GlobalRankingsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final filterCubit = context.read<LeaderboardFilterCubit>();
      if (filterCubit.state.scopeType != LeaderboardScopeType.global) {
        await filterCubit.setScope(LeaderboardScopeType.global);
      }
      if (!mounted) return;
      await context.read<LeaderboardListCubit>().load(filterCubit.state);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent * 0.8;
    if (_scrollController.position.pixels >= threshold) {
      context.read<LeaderboardListCubit>().loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeaderboardFilterCubit, LeaderboardFilter>(
      listener: (context, filter) {
        if (filter.scopeType != LeaderboardScopeType.global) return;
        context.read<LeaderboardListCubit>().load(filter, forceRefresh: true);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Global Rankings'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
        ),
        body: BlocConsumer<LeaderboardListCubit, LeaderboardListState>(
          listener: (context, state) {
            if (state.snapshot == null) return;
            final uid = getIt<AuthService>().currentUser?.uid;
            if (uid == null) return;
            context.read<UserRankCubit>().load(
              snapshotId: state.snapshot!.id,
              userId: uid,
            );
          },
          builder: (context, state) {
            final filter = context.watch<LeaderboardFilterCubit>().state;

            if (state.status == LeaderboardListStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state.status == LeaderboardListStatus.empty) {
              return LeaderboardEmptyState(
                onTap: () => context.push(RoutePaths.iqTestIntro),
              );
            }

            if (state.status == LeaderboardListStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    state.errorMessage ?? 'Failed to load leaderboard.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Stack(
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: context.read<LeaderboardListCubit>().refresh,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.massive,
                    ),
                    children: [
                      LeaderboardFilterBar(
                        filter: filter,
                        onMetricChanged: context
                            .read<LeaderboardFilterCubit>()
                            .setMetric,
                        onPeriodChanged: context
                            .read<LeaderboardFilterCubit>()
                            .setPeriod,
                        onScopeChanged: (scope) async {
                          if (scope == LeaderboardScopeType.friends) {
                            if (context.mounted) {
                              context.go(RoutePaths.friendRankings);
                            }
                            return;
                          }
                          if (scope == LeaderboardScopeType.country) {
                            await context
                                .read<LeaderboardFilterCubit>()
                                .setCountry(filter.countryCode ?? 'US');
                            if (context.mounted) {
                              context.go(RoutePaths.leaderboardCountry);
                            }
                            return;
                          }
                          await context.read<LeaderboardFilterCubit>().setScope(
                            scope,
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ...state.entries.map(
                        (entry) => LeaderboardRowTile(
                          entry: entry,
                          onTap: () {
                            final snapshotId = state.snapshot?.id;
                            if (snapshotId == null) return;
                            context.push(
                              '${RoutePaths.leaderboardRankDetail}?snapshotId=$snapshotId&uid=${entry.uid}',
                            );
                          },
                        ),
                      ),
                      if (state.isPaginating)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: BlocBuilder<UserRankCubit, UserRankState>(
                    builder: (context, rankState) {
                      if (rankState is UserRankLoaded) {
                        return YourRankCard(
                          rank: rankState.rank,
                          onDetailsTap: () {
                            final snapshotId = state.snapshot?.id;
                            if (snapshotId == null) return;
                            context.push(
                              '${RoutePaths.leaderboardRankDetail}?snapshotId=$snapshotId',
                            );
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
