import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_privacy_settings.dart';

sealed class LeaderboardPrivacyState extends Equatable {
  const LeaderboardPrivacyState();

  @override
  List<Object?> get props => [];
}

final class LeaderboardPrivacyInitial extends LeaderboardPrivacyState {
  const LeaderboardPrivacyInitial();
}

final class LeaderboardPrivacyLoading extends LeaderboardPrivacyState {
  const LeaderboardPrivacyLoading();
}

final class LeaderboardPrivacyLoaded extends LeaderboardPrivacyState {
  const LeaderboardPrivacyLoaded(this.settings);

  final LeaderboardPrivacySettings settings;

  @override
  List<Object?> get props => [settings];
}

final class LeaderboardPrivacySaving extends LeaderboardPrivacyState {
  const LeaderboardPrivacySaving(this.settings);

  final LeaderboardPrivacySettings settings;

  @override
  List<Object?> get props => [settings];
}

final class LeaderboardPrivacySaved extends LeaderboardPrivacyState {
  const LeaderboardPrivacySaved(this.settings);

  final LeaderboardPrivacySettings settings;

  @override
  List<Object?> get props => [settings];
}

final class LeaderboardPrivacyError extends LeaderboardPrivacyState {
  const LeaderboardPrivacyError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
