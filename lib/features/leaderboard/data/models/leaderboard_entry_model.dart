import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.uid,
    required super.displayName,
    required super.rank,
    required super.rankScore,
    required super.percentile,
    required super.tier,
    super.countryCode,
    super.bestScore,
    super.consistency,
    super.recency,
    super.difficulty,
    super.participation,
    super.validatedCount,
    super.isAnonymous,
    super.isVisible,
    super.avatarEmoji,
    super.badge,
    super.isCurrentUser,
  });

  factory LeaderboardEntryModel.fromMap(
    Map<String, dynamic> map, {
    required String currentUserId,
  }) {
    double? asDouble(Object? value) => (value as num?)?.toDouble();

    final uid = (map['uid'] ?? map['user_id'] ?? '') as String;
    return LeaderboardEntryModel(
      uid: uid,
      displayName:
          (map['display_name'] ?? map['displayName'] ?? 'Unknown') as String,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      rankScore: asDouble(map['score']) ?? asDouble(map['rank_score']) ?? 0,
      percentile: (map['percentile'] as num?)?.toDouble() ?? 0,
      tier: (map['tier'] ?? 'Unranked') as String,
      countryCode: map['country_code'] as String?,
      bestScore: (map['best_score'] as num?)?.toDouble(),
      consistency: (map['consistency'] as num?)?.toDouble(),
      recency: (map['recency'] as num?)?.toDouble(),
      difficulty: (map['difficulty'] as num?)?.toDouble(),
      participation: (map['participation'] as num?)?.toDouble(),
      validatedCount: (map['validated_count'] as num?)?.toInt() ?? 0,
      isAnonymous: (map['is_anonymous'] as bool?) ?? false,
      isVisible: (map['is_visible'] as bool?) ?? true,
      avatarEmoji: map['avatar_emoji'] as String?,
      badge: map['badge'] as String?,
      isCurrentUser: uid == currentUserId,
    );
  }

  factory LeaderboardEntryModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String currentUserId,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return LeaderboardEntryModel.fromMap(data, currentUserId: currentUserId);
  }
}
