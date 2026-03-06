import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';
import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/home/leaderboard_home_state.dart';

class LeaderboardHomeCubit extends Cubit<LeaderboardHomeState> {
  LeaderboardHomeCubit({
    required LeaderboardRepository repository,
    required AuthService authService,
  }) : _repository = repository,
       _authService = authService,
       super(const LeaderboardHomeState());

  final LeaderboardRepository _repository;
  final AuthService _authService;

  Future<void> load(LeaderboardFilter filter) async {
    emit(
      state.copyWith(status: LeaderboardHomeStatus.loading, clearError: true),
    );

    try {
      final snapshot = await _repository.getLatestSnapshot(filter);
      if (snapshot == null || !snapshot.isReady) {
        emit(state.copyWith(status: LeaderboardHomeStatus.empty));
        return;
      }

      final topEntries = await _repository.getLeaderboardPage(
        snapshotId: snapshot.id,
        page: 0,
      );

      final uid = _authService.currentUser?.uid;
      final userRank = uid == null
          ? null
          : await _repository.getUserRank(snapshotId: snapshot.id, userId: uid);

      emit(
        state.copyWith(
          status: topEntries.isEmpty
              ? LeaderboardHomeStatus.empty
              : LeaderboardHomeStatus.loaded,
          snapshot: snapshot,
          topEntries: topEntries.take(3).toList(growable: false),
          userRank: userRank,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LeaderboardHomeStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
