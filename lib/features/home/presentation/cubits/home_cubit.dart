import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/features/home/data/repositories/home_repository.dart';
import 'package:lumoni/features/home/domain/entities/daily_insight.dart';
import 'package:lumoni/features/home/presentation/cubits/home_state.dart';

/// Cubit that manages the state of the home dashboard.
///
/// Orchestrates fetching of user data, recent test sessions, daily insight,
/// and weekly progress chart data through [HomeRepository].
class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  final String _userId;

  HomeCubit({
    required String userId,
    HomeRepository? repository,
  })  : _userId = userId,
        _repository = repository ??
            HomeRepository(
              firestoreService: getIt<FirestoreService>(),
              localStorageService: getIt<LocalStorageService>(),
            ),
        super(const HomeInitial());

  /// Loads all dashboard data in parallel.
  ///
  /// Emits [HomeLoading] immediately, then fetches user data, recent
  /// sessions, and weekly progress concurrently. On success emits
  /// [HomeLoaded]; on failure emits [HomeError].
  Future<void> loadDashboard() async {
    emit(const HomeLoading());

    try {
      // Fetch all data sources concurrently for speed.
      final results = await Future.wait([
        _repository.getUser(_userId),
        _repository.getRecentSessions(_userId),
        _repository.getWeeklyProgress(_userId),
      ]);

      final user = results[0] as dynamic;
      final recentSessions = results[1] as List;
      final weeklyProgress = results[2] as List;

      emit(HomeLoaded(
        user: user,
        recentSessions: List.unmodifiable(recentSessions),
        dailyInsight: DailyInsight.ofTheDay(),
        weeklyProgress: List.unmodifiable(weeklyProgress),
      ));
    } catch (e) {
      emit(HomeError(
        e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  /// Silently refreshes all dashboard data without showing a loading state.
  ///
  /// If the current state is [HomeLoaded], the UI continues to display
  /// stale data while fresh data loads in the background. On success the
  /// state is replaced with the new data; on failure the existing data
  /// is kept.
  Future<void> refreshData() async {
    try {
      final results = await Future.wait([
        _repository.getUser(_userId),
        _repository.getRecentSessions(_userId),
        _repository.getWeeklyProgress(_userId),
      ]);

      final user = results[0] as dynamic;
      final recentSessions = results[1] as List;
      final weeklyProgress = results[2] as List;

      emit(HomeLoaded(
        user: user,
        recentSessions: List.unmodifiable(recentSessions),
        dailyInsight: DailyInsight.ofTheDay(),
        weeklyProgress: List.unmodifiable(weeklyProgress),
      ));
    } catch (_) {
      // Keep existing state on silent refresh failure.
    }
  }
}
