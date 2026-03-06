import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_user_rank.dart';

sealed class UserRankState extends Equatable {
  const UserRankState();

  @override
  List<Object?> get props => [];
}

final class UserRankInitial extends UserRankState {
  const UserRankInitial();
}

final class UserRankLoading extends UserRankState {
  const UserRankLoading();
}

final class UserRankLoaded extends UserRankState {
  const UserRankLoaded(this.rank);

  final LeaderboardUserRank rank;

  @override
  List<Object?> get props => [rank];
}

final class UserRankUnranked extends UserRankState {
  const UserRankUnranked({this.reason});

  final String? reason;

  @override
  List<Object?> get props => [reason];
}

final class UserRankHidden extends UserRankState {
  const UserRankHidden();
}

final class UserRankError extends UserRankState {
  const UserRankError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
