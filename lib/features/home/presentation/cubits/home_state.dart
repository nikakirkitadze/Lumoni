import 'package:equatable/equatable.dart';

import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/models/user_model.dart';
import 'package:lumoni/features/home/domain/entities/daily_insight.dart';

/// Represents the weekly progress data point for a single day.
class DayProgress extends Equatable {
  final DateTime date;
  final double? iqScore;
  final double? eqScore;

  const DayProgress({
    required this.date,
    this.iqScore,
    this.eqScore,
  });

  @override
  List<Object?> get props => [date, iqScore, eqScore];
}

/// Base state for the home dashboard.
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data has been loaded.
final class HomeInitial extends HomeState {
  const HomeInitial();
}

/// Dashboard data is currently being fetched.
final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// Dashboard data loaded successfully.
final class HomeLoaded extends HomeState {
  /// The current user's profile data.
  final UserModel user;

  /// The user's most recent completed test sessions (up to 10).
  final List<TestSessionModel> recentSessions;

  /// Today's daily insight.
  final DailyInsight dailyInsight;

  /// Weekly progress data (last 7 days).
  final List<DayProgress> weeklyProgress;

  const HomeLoaded({
    required this.user,
    required this.recentSessions,
    required this.dailyInsight,
    required this.weeklyProgress,
  });

  @override
  List<Object?> get props => [
        user,
        recentSessions,
        dailyInsight,
        weeklyProgress,
      ];

  /// Returns a copy with optional field overrides.
  HomeLoaded copyWith({
    UserModel? user,
    List<TestSessionModel>? recentSessions,
    DailyInsight? dailyInsight,
    List<DayProgress>? weeklyProgress,
  }) {
    return HomeLoaded(
      user: user ?? this.user,
      recentSessions: recentSessions ?? this.recentSessions,
      dailyInsight: dailyInsight ?? this.dailyInsight,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
    );
  }
}

/// An error occurred while loading dashboard data.
final class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
