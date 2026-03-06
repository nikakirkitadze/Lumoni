import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_snapshot.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_user_rank.dart';

enum LeaderboardHomeStatus { initial, loading, loaded, empty, error }

class LeaderboardHomeState extends Equatable {
  const LeaderboardHomeState({
    this.status = LeaderboardHomeStatus.initial,
    this.snapshot,
    this.topEntries = const <LeaderboardEntry>[],
    this.userRank,
    this.errorMessage,
  });

  final LeaderboardHomeStatus status;
  final LeaderboardSnapshot? snapshot;
  final List<LeaderboardEntry> topEntries;
  final LeaderboardUserRank? userRank;
  final String? errorMessage;

  LeaderboardHomeState copyWith({
    LeaderboardHomeStatus? status,
    LeaderboardSnapshot? snapshot,
    List<LeaderboardEntry>? topEntries,
    LeaderboardUserRank? userRank,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardHomeState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      topEntries: topEntries ?? this.topEntries,
      userRank: userRank ?? this.userRank,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    snapshot,
    topEntries,
    userRank,
    errorMessage,
  ];
}
