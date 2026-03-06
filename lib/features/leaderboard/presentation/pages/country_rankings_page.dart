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

class CountryRankingsPage extends StatefulWidget {
  const CountryRankingsPage({super.key});

  @override
  State<CountryRankingsPage> createState() => _CountryRankingsPageState();
}

class _CountryRankingsPageState extends State<CountryRankingsPage> {
  final ScrollController _scrollController = ScrollController();

  static const List<String> _countryCodes = <String>[
    'US',
    'GB',
    'DE',
    'FR',
    'IN',
    'CA',
    'JP',
    'AU',
    'GE',
    'BR',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final filterCubit = context.read<LeaderboardFilterCubit>();
      if (filterCubit.state.scopeType != LeaderboardScopeType.country) {
        await filterCubit.setCountry(filterCubit.state.countryCode ?? 'US');
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
        if (filter.scopeType != LeaderboardScopeType.country) return;
        context.read<LeaderboardListCubit>().load(filter, forceRefresh: true);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Country Rankings'),
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
                title: 'No Country Rankings Yet',
                message:
                    'Not enough validated participants for this country and period yet. Try another country or keep competing.',
                onTap: () => _pickCountry(context, filter.countryCode ?? 'US'),
                ctaLabel: 'Change Country',
              );
            }

            if (state.status == LeaderboardListStatus.error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    state.errorMessage ?? 'Failed to load country leaderboard.',
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
                      Row(
                        children: [
                          Expanded(
                            child: LeaderboardFilterBar(
                              filter: filter,
                              onMetricChanged: context
                                  .read<LeaderboardFilterCubit>()
                                  .setMetric,
                              onPeriodChanged: context
                                  .read<LeaderboardFilterCubit>()
                                  .setPeriod,
                              onScopeChanged: (scope) async {
                                if (scope == LeaderboardScopeType.global) {
                                  await context
                                      .read<LeaderboardFilterCubit>()
                                      .setScope(LeaderboardScopeType.global);
                                  if (context.mounted) {
                                    context.go(RoutePaths.leaderboardGlobal);
                                  }
                                  return;
                                }
                                await context
                                    .read<LeaderboardFilterCubit>()
                                    .setScope(scope);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _pickCountry(context, filter.countryCode ?? 'US'),
                          icon: const Icon(Icons.public, size: 16),
                          label: Text('Country: ${filter.countryCode ?? 'US'}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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

  Future<void> _pickCountry(BuildContext context, String current) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) {
        return ListView.builder(
          itemCount: _countryCodes.length,
          itemBuilder: (context, index) {
            final code = _countryCodes[index];
            return ListTile(
              title: Text(
                code,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: current == code
                  ? const Icon(Icons.check, color: AppColors.accent)
                  : null,
              onTap: () => Navigator.of(context).pop(code),
            );
          },
        );
      },
    );

    if (selected == null || !context.mounted) return;
    await context.read<LeaderboardFilterCubit>().setCountry(selected);
  }
}
