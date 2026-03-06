import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/features/leaderboard/data/models/leaderboard_entry_model.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/friends/presentation/cubits/friend_rankings_state.dart';

class FriendRankingsCubit extends Cubit<FriendRankingsState> {
  FriendRankingsCubit({
    required FirebaseFunctions functions,
    required AuthService authService,
  })  : _functions = functions,
        _authService = authService,
        super(const FriendRankingsState());

  final FirebaseFunctions _functions;
  final AuthService _authService;

  LeaderboardMetric _lastMetric = LeaderboardMetric.iq;
  LeaderboardPeriod _lastPeriod = LeaderboardPeriod.weekly;

  Future<void> load({
    LeaderboardMetric? metric,
    LeaderboardPeriod? period,
  }) async {
    _lastMetric = metric ?? _lastMetric;
    _lastPeriod = period ?? _lastPeriod;

    emit(state.copyWith(
      status: FriendRankingsStatus.loading,
      clearError: true,
    ));

    try {
      final callable = _functions.httpsCallable('getFriendLeaderboard');
      final result = await callable.call<Map<String, dynamic>>({
        'metric': _lastMetric.value,
        'period': _lastPeriod.value,
      });

      final data = result.data;
      final rawEntries =
          (data['entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final totalEligible = (data['totalEligible'] as num?)?.toInt() ?? 0;

      final currentUid = _authService.currentUser?.uid ?? '';
      final entries = rawEntries
          .map((map) =>
              LeaderboardEntryModel.fromMap(map, currentUserId: currentUid))
          .toList();

      if (totalEligible == 0 && entries.isEmpty) {
        emit(state.copyWith(
          status: FriendRankingsStatus.noFriends,
          entries: const [],
          totalEligible: 0,
          clearCaller: true,
        ));
        return;
      }

      if (entries.isEmpty) {
        emit(state.copyWith(
          status: FriendRankingsStatus.empty,
          entries: const [],
          totalEligible: totalEligible,
          clearCaller: true,
        ));
        return;
      }

      // Find the caller's entry for the pinned card
      final callerEntry = entries.cast<LeaderboardEntryModel?>().firstWhere(
            (e) => e?.isCurrentUser == true,
            orElse: () => null,
          );

      emit(state.copyWith(
        status: FriendRankingsStatus.loaded,
        entries: entries,
        totalEligible: totalEligible,
        callerEntry: callerEntry,
      ));
    } catch (e) {
      debugPrint('[FriendRankingsCubit] load failed: $e');
      emit(state.copyWith(
        status: FriendRankingsStatus.error,
        errorMessage: 'Failed to load friend rankings.',
      ));
    }
  }

  Future<void> refresh() async {
    await load(metric: _lastMetric, period: _lastPeriod);
  }
}
