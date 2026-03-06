import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';

class LeaderboardSnapshot extends Equatable {
  const LeaderboardSnapshot({
    required this.id,
    required this.metric,
    required this.scopeType,
    required this.scopeValue,
    required this.period,
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.totalEligible,
    required this.status,
    this.highlights = const [],
  });

  final String id;
  final LeaderboardMetric metric;
  final LeaderboardScopeType scopeType;
  final String scopeValue;
  final LeaderboardPeriod period;
  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int totalEligible;
  final String status;
  final List<LeaderboardHighlight> highlights;

  bool get isReady => status == 'ready';

  @override
  List<Object?> get props => [
    id,
    metric,
    scopeType,
    scopeValue,
    period,
    generatedAt,
    windowStart,
    windowEnd,
    totalEligible,
    status,
    highlights,
  ];
}

class LeaderboardHighlight extends Equatable {
  const LeaderboardHighlight({
    required this.uid,
    required this.displayName,
    required this.rank,
    required this.score,
    this.badge,
  });

  final String uid;
  final String displayName;
  final int rank;
  final double score;
  final String? badge;

  @override
  List<Object?> get props => [uid, displayName, rank, score, badge];
}
