import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_privacy_settings.dart';
import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:lumoni/features/leaderboard/presentation/cubits/privacy/leaderboard_privacy_state.dart';

class LeaderboardPrivacyCubit extends Cubit<LeaderboardPrivacyState> {
  LeaderboardPrivacyCubit({
    required LeaderboardRepository repository,
    required AuthService authService,
  }) : _repository = repository,
       _authService = authService,
       super(const LeaderboardPrivacyInitial());

  final LeaderboardRepository _repository;
  final AuthService _authService;

  Future<void> load() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      emit(const LeaderboardPrivacyError('Please sign in to manage privacy.'));
      return;
    }

    emit(const LeaderboardPrivacyLoading());

    try {
      final settings = await _repository.getPrivacySettings(userId: userId);
      emit(LeaderboardPrivacyLoaded(settings));
    } catch (e) {
      emit(LeaderboardPrivacyError(e.toString()));
    }
  }

  Future<void> save(LeaderboardPrivacySettings settings) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      emit(const LeaderboardPrivacyError('Please sign in to manage privacy.'));
      return;
    }

    emit(LeaderboardPrivacySaving(settings));

    try {
      await _repository.updatePrivacySettings(
        userId: userId,
        settings: settings,
      );
      emit(LeaderboardPrivacySaved(settings));
      emit(LeaderboardPrivacyLoaded(settings));
    } catch (e) {
      emit(LeaderboardPrivacyError(e.toString()));
    }
  }
}
