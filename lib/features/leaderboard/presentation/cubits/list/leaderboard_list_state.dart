import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_snapshot.dart';

enum LeaderboardListStatus { initial, loading, loaded, empty, error }

class LeaderboardListState extends Equatable {
  const LeaderboardListState({
    this.status = LeaderboardListStatus.initial,
    this.entries = const <LeaderboardEntry>[],
    this.snapshot,
    this.isPaginating = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.errorMessage,
  });

  final LeaderboardListStatus status;
  final List<LeaderboardEntry> entries;
  final LeaderboardSnapshot? snapshot;
  final bool isPaginating;
  final bool hasMore;
  final int currentPage;
  final String? errorMessage;

  LeaderboardListState copyWith({
    LeaderboardListStatus? status,
    List<LeaderboardEntry>? entries,
    LeaderboardSnapshot? snapshot,
    bool? isPaginating,
    bool? hasMore,
    int? currentPage,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardListState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      snapshot: snapshot ?? this.snapshot,
      isPaginating: isPaginating ?? this.isPaginating,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    snapshot,
    isPaginating,
    hasMore,
    currentPage,
    errorMessage,
  ];
}
