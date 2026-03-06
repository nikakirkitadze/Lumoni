import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';

enum FriendRankingsStatus { initial, loading, loaded, empty, noFriends, error }

class FriendRankingsState extends Equatable {
  const FriendRankingsState({
    this.status = FriendRankingsStatus.initial,
    this.entries = const [],
    this.totalEligible = 0,
    this.callerEntry,
    this.errorMessage,
  });

  final FriendRankingsStatus status;
  final List<LeaderboardEntry> entries;
  final int totalEligible;
  final LeaderboardEntry? callerEntry;
  final String? errorMessage;

  FriendRankingsState copyWith({
    FriendRankingsStatus? status,
    List<LeaderboardEntry>? entries,
    int? totalEligible,
    LeaderboardEntry? callerEntry,
    String? errorMessage,
    bool clearError = false,
    bool clearCaller = false,
  }) {
    return FriendRankingsState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      totalEligible: totalEligible ?? this.totalEligible,
      callerEntry: clearCaller ? null : (callerEntry ?? this.callerEntry),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        entries,
        totalEligible,
        callerEntry,
        errorMessage,
      ];
}
