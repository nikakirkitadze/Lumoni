import 'package:equatable/equatable.dart';

class LeaderboardEntry extends Equatable {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.rank,
    required this.rankScore,
    required this.percentile,
    required this.tier,
    this.countryCode,
    this.bestScore,
    this.consistency,
    this.recency,
    this.difficulty,
    this.participation,
    this.validatedCount = 0,
    this.isAnonymous = false,
    this.isVisible = true,
    this.avatarEmoji,
    this.badge,
    this.isCurrentUser = false,
  });

  final String uid;
  final String displayName;
  final int rank;
  final double rankScore;
  final double percentile;
  final String tier;
  final String? countryCode;
  final double? bestScore;
  final double? consistency;
  final double? recency;
  final double? difficulty;
  final double? participation;
  final int validatedCount;
  final bool isAnonymous;
  final bool isVisible;
  final String? avatarEmoji;
  final String? badge;
  final bool isCurrentUser;

  LeaderboardEntry copyWith({
    bool? isCurrentUser,
    int? rank,
    double? percentile,
  }) {
    return LeaderboardEntry(
      uid: uid,
      displayName: displayName,
      rank: rank ?? this.rank,
      rankScore: rankScore,
      percentile: percentile ?? this.percentile,
      tier: tier,
      countryCode: countryCode,
      bestScore: bestScore,
      consistency: consistency,
      recency: recency,
      difficulty: difficulty,
      participation: participation,
      validatedCount: validatedCount,
      isAnonymous: isAnonymous,
      isVisible: isVisible,
      avatarEmoji: avatarEmoji,
      badge: badge,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    displayName,
    rank,
    rankScore,
    percentile,
    tier,
    countryCode,
    bestScore,
    consistency,
    recency,
    difficulty,
    participation,
    validatedCount,
    isAnonymous,
    isVisible,
    avatarEmoji,
    badge,
    isCurrentUser,
  ];
}
