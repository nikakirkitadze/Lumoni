import 'package:equatable/equatable.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardUserRank extends Equatable {
  const LeaderboardUserRank({
    required this.uid,
    required this.rank,
    required this.rankScore,
    required this.percentile,
    required this.tier,
    required this.totalEligible,
    this.validatedCount = 0,
    this.isVisible = true,
    this.isEligible = true,
    this.unrankedReason,
    this.neighborhood = const [],
  });

  final String uid;
  final int rank;
  final double rankScore;
  final double percentile;
  final String tier;
  final int totalEligible;
  final int validatedCount;
  final bool isVisible;
  final bool isEligible;
  final String? unrankedReason;
  final List<LeaderboardEntry> neighborhood;

  @override
  List<Object?> get props => [
    uid,
    rank,
    rankScore,
    percentile,
    tier,
    totalEligible,
    validatedCount,
    isVisible,
    isEligible,
    unrankedReason,
    neighborhood,
  ];
}
