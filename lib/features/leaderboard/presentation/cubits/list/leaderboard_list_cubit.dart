import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';
import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/list/leaderboard_list_state.dart';

class LeaderboardListCubit extends Cubit<LeaderboardListState> {
  LeaderboardListCubit({required LeaderboardRepository repository})
    : _repository = repository,
      super(const LeaderboardListState());

  final LeaderboardRepository _repository;
  LeaderboardFilter? _activeFilter;

  Future<void> load(
    LeaderboardFilter filter, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _activeFilter == filter &&
        (state.status == LeaderboardListStatus.loaded ||
            state.status == LeaderboardListStatus.empty)) {
      return;
    }

    _activeFilter = filter;
    emit(
      state.copyWith(
        status: LeaderboardListStatus.loading,
        entries: const [],
        snapshot: null,
        currentPage: 0,
        hasMore: true,
        clearError: true,
      ),
    );

    try {
      final snapshot = await _repository.getLatestSnapshot(filter);
      if (snapshot == null || !snapshot.isReady) {
        emit(
          state.copyWith(
            status: LeaderboardListStatus.empty,
            hasMore: false,
            snapshot: snapshot,
          ),
        );
        return;
      }

      final firstPage = await _repository.getLeaderboardPage(
        snapshotId: snapshot.id,
        page: 0,
      );

      if (firstPage.isEmpty) {
        emit(
          state.copyWith(
            status: LeaderboardListStatus.empty,
            snapshot: snapshot,
            hasMore: false,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: LeaderboardListStatus.loaded,
          snapshot: snapshot,
          entries: firstPage,
          currentPage: 0,
          hasMore: firstPage.length >= AppConstants.defaultPageSize,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaderboardListStatus.error,
          errorMessage: e.toString(),
          hasMore: false,
        ),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isPaginating || !state.hasMore) {
      return;
    }

    final snapshot = state.snapshot;
    if (snapshot == null) {
      return;
    }

    emit(state.copyWith(isPaginating: true));

    try {
      final nextPage = state.currentPage + 1;
      final entries = await _repository.getLeaderboardPage(
        snapshotId: snapshot.id,
        page: nextPage,
      );

      if (entries.isEmpty) {
        emit(state.copyWith(isPaginating: false, hasMore: false));
        return;
      }

      emit(
        state.copyWith(
          isPaginating: false,
          currentPage: nextPage,
          hasMore: entries.length >= AppConstants.defaultPageSize,
          entries: [...state.entries, ...entries],
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isPaginating: false,
          hasMore: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() async {
    final filter = _activeFilter;
    if (filter == null) return;
    await load(filter, forceRefresh: true);
  }
}
