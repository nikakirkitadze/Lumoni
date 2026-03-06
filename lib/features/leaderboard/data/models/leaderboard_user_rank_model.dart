import 'package:lumoni/features/leaderboard/data/models/leaderboard_entry_model.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_user_rank.dart';

class LeaderboardUserRankModel extends LeaderboardUserRank {
  const LeaderboardUserRankModel({
    required super.uid,
    required super.rank,
    required super.rankScore,
    required super.percentile,
    required super.tier,
    required super.totalEligible,
    required super.validatedCount,
    required super.isVisible,
    required super.isEligible,
    super.unrankedReason,
    super.neighborhood,
  });

  factory LeaderboardUserRankModel.fromMap(
    Map<String, dynamic> map, {
    required String uid,
    required String currentUserId,
  }) {
    final rawNeighborhood =
        (map['neighborhood'] as List<dynamic>? ?? const <dynamic>[]);

    return LeaderboardUserRankModel(
      uid: uid,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      rankScore:
          (map['score'] as num?)?.toDouble() ??
          (map['rank_score'] as num?)?.toDouble() ??
          0,
      percentile: (map['percentile'] as num?)?.toDouble() ?? 0,
      tier: (map['tier'] ?? 'Unranked') as String,
      totalEligible: (map['total_eligible'] as num?)?.toInt() ?? 0,
      validatedCount: (map['validated_count'] as num?)?.toInt() ?? 0,
      isVisible: (map['is_visible'] as bool?) ?? true,
      isEligible: (map['is_eligible'] as bool?) ?? true,
      unrankedReason: map['unranked_reason'] as String?,
      neighborhood: rawNeighborhood
          .whereType<Map<String, dynamic>>()
          .map(
            (row) => LeaderboardEntryModel.fromMap(
              row,
              currentUserId: currentUserId,
            ),
          )
          .toList(growable: false),
    );
  }
}
