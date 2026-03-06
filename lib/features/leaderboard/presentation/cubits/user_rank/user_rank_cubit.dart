import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/user_rank/user_rank_state.dart';

class UserRankCubit extends Cubit<UserRankState> {
  UserRankCubit({required LeaderboardRepository repository})
    : _repository = repository,
      super(const UserRankInitial());

  final LeaderboardRepository _repository;

  Future<void> load({
    required String snapshotId,
    required String userId,
  }) async {
    emit(const UserRankLoading());

    try {
      final rank = await _repository.getUserRank(
        snapshotId: snapshotId,
        userId: userId,
      );

      if (rank == null || !rank.isEligible) {
        emit(UserRankUnranked(reason: rank?.unrankedReason));
        return;
      }

      if (!rank.isVisible) {
        emit(const UserRankHidden());
        return;
      }

      emit(UserRankLoaded(rank));
    } catch (e) {
      emit(UserRankError(e.toString()));
    }
  }
}
