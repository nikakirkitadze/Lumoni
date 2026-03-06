import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/tier_badge/tier_badge_state.dart';

class TierBadgeCubit extends Cubit<TierBadgeState> {
  TierBadgeCubit({required LeaderboardRepository repository})
    : _repository = repository,
      super(const TierBadgeInitial());

  final LeaderboardRepository _repository;

  Future<void> load({String? currentTierId}) async {
    emit(const TierBadgeLoading());

    try {
      final tiers = await _repository.getTierCatalog();
      emit(TierBadgeLoaded(tiers: tiers, currentTierId: currentTierId));
    } catch (e) {
      emit(TierBadgeError(e.toString()));
    }
  }
}
