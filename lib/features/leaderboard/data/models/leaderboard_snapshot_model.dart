import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_enums.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_snapshot.dart';

class LeaderboardSnapshotModel extends LeaderboardSnapshot {
  const LeaderboardSnapshotModel({
    required super.id,
    required super.metric,
    required super.scopeType,
    required super.scopeValue,
    required super.period,
    required super.generatedAt,
    required super.windowStart,
    required super.windowEnd,
    required super.totalEligible,
    required super.status,
    super.highlights,
  });

  factory LeaderboardSnapshotModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? const <String, dynamic>{};
    return LeaderboardSnapshotModel.fromMap(doc.id, map);
  }

  factory LeaderboardSnapshotModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    final rawHighlights =
        (map['top_highlights'] as List<dynamic>? ?? const <dynamic>[]);

    return LeaderboardSnapshotModel(
      id: id,
      metric: LeaderboardMetric.fromValue(map['metric'] as String?),
      scopeType: LeaderboardScopeType.fromValue(map['scope_type'] as String?),
      scopeValue: (map['scope_value'] ?? 'all') as String,
      period: LeaderboardPeriod.fromValue(map['period'] as String?),
      generatedAt: _toDateTime(map['generated_at']) ?? DateTime.now(),
      windowStart: _toDateTime(map['window_start']) ?? DateTime.now(),
      windowEnd: _toDateTime(map['window_end']) ?? DateTime.now(),
      totalEligible: (map['total_eligible'] as num?)?.toInt() ?? 0,
      status: (map['status'] ?? 'processing') as String,
      highlights: rawHighlights
          .whereType<Map<String, dynamic>>()
          .map(LeaderboardHighlightModel.fromMap)
          .toList(growable: false),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class LeaderboardHighlightModel extends LeaderboardHighlight {
  const LeaderboardHighlightModel({
    required super.uid,
    required super.displayName,
    required super.rank,
    required super.score,
    super.badge,
  });

  factory LeaderboardHighlightModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardHighlightModel(
      uid: (map['uid'] ?? '') as String,
      displayName: (map['display_name'] ?? 'Unknown') as String,
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0,
      badge: map['badge'] as String?,
    );
  }
}
