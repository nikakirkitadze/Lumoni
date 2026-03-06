import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/features/leaderboard/data/models/leaderboard_entry_model.dart';
import 'package:lumoni/features/leaderboard/data/models/leaderboard_privacy_model.dart';
import 'package:lumoni/features/leaderboard/data/models/leaderboard_snapshot_model.dart';
import 'package:lumoni/features/leaderboard/data/models/leaderboard_user_rank_model.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_filter.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_privacy_settings.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_snapshot.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_tier.dart';
import 'package:lumoni/features/leaderboard/domain/entities/leaderboard_user_rank.dart';
import 'package:lumoni/features/leaderboard/domain/repositories/leaderboard_repository.dart';

class FirestoreLeaderboardRepository implements LeaderboardRepository {
  FirestoreLeaderboardRepository({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
    required AuthService authService,
    required LocalStorageService localStorage,
  }) : _firestore = firestore,
       _functions = functions,
       _authService = authService,
       _localStorage = localStorage;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AuthService _authService;
  final LocalStorageService _localStorage;

  static const String _filterCacheKey = 'leaderboard_cached_filter';
  static const String _snapshotCachePrefix = 'leaderboard_snapshot_cache';

  String get _currentUserId => _authService.currentUser?.uid ?? 'guest';

  @override
  Future<LeaderboardSnapshot?> getLatestSnapshot(
    LeaderboardFilter filter,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.leaderboardSnapshotsCollection)
          .where('metric', isEqualTo: filter.metric.value)
          .where('scope_type', isEqualTo: filter.scopeType.value)
          .where('scope_value', isEqualTo: filter.scopeValue)
          .where('period', isEqualTo: filter.period.value)
          .where('status', isEqualTo: 'ready')
          .orderBy('generated_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return _getCachedSnapshot(filter);
      }

      final model = LeaderboardSnapshotModel.fromDocument(snapshot.docs.first);
      await _cacheSnapshot(filter, model);
      await saveFilter(filter);
      return model;
    } catch (e) {
      debugPrint('[LeaderboardRepo] getLatestSnapshot failed: $e');
      return _getCachedSnapshot(filter);
    }
  }

  @override
  Future<List<LeaderboardEntry>> getLeaderboardPage({
    required String snapshotId,
    required int page,
  }) async {
    try {
      final pageDoc = await _firestore
          .collection(AppConstants.leaderboardSnapshotsCollection)
          .doc(snapshotId)
          .collection('pages')
          .doc('$page')
          .get();

      if (pageDoc.exists && pageDoc.data() != null) {
        final rows =
            (pageDoc.data()!['entries'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(
                  (row) => LeaderboardEntryModel.fromMap(
                    row,
                    currentUserId: _currentUserId,
                  ),
                )
                .toList(growable: false);
        if (rows.isNotEmpty) {
          return rows;
        }
      }

      final startRank = (page * AppConstants.defaultPageSize) + 1;
      final endRank = startRank + AppConstants.defaultPageSize - 1;

      final fallbackRows = await _firestore
          .collection(AppConstants.rankingEntriesCollection)
          .where('snapshot_id', isEqualTo: snapshotId)
          .where('rank', isGreaterThanOrEqualTo: startRank)
          .where('rank', isLessThanOrEqualTo: endRank)
          .orderBy('rank')
          .get();

      return fallbackRows.docs
          .map((doc) {
            final data = doc.data();
            return LeaderboardEntryModel.fromMap(
              data,
              currentUserId: _currentUserId,
            );
          })
          .toList(growable: false);
    } catch (e) {
      debugPrint('[LeaderboardRepo] getLeaderboardPage failed: $e');
      return const <LeaderboardEntry>[];
    }
  }

  @override
  Future<LeaderboardUserRank?> getUserRank({
    required String snapshotId,
    required String userId,
  }) async {
    try {
      final rankDoc = await _firestore
          .collection(AppConstants.rankingEntriesCollection)
          .doc('${snapshotId}_$userId')
          .get();

      if (rankDoc.exists && rankDoc.data() != null) {
        final rankData = rankDoc.data()!;
        final rank = (rankData['rank'] as num?)?.toInt() ?? 0;
        final neighborhood = await _loadNeighborhood(snapshotId, rank);

        final merged = Map<String, dynamic>.from(rankData)
          ..['neighborhood'] = neighborhood
              .map(
                (entry) => {
                  'uid': entry.uid,
                  'display_name': entry.displayName,
                  'rank': entry.rank,
                  'score': entry.rankScore,
                  'percentile': entry.percentile,
                  'tier': entry.tier,
                  'country_code': entry.countryCode,
                  'is_anonymous': entry.isAnonymous,
                  'is_visible': entry.isVisible,
                  'badge': entry.badge,
                },
              )
              .toList(growable: false);

        return LeaderboardUserRankModel.fromMap(
          merged,
          uid: userId,
          currentUserId: _currentUserId,
        );
      }

      return null;
    } catch (e) {
      debugPrint('[LeaderboardRepo] getUserRank failed: $e');
      return null;
    }
  }

  Future<List<LeaderboardEntry>> _loadNeighborhood(
    String snapshotId,
    int rank,
  ) async {
    if (rank <= 0) return const <LeaderboardEntry>[];

    final start = (rank - 5).clamp(1, rank);
    final end = rank + 5;

    final docs = await _firestore
        .collection(AppConstants.rankingEntriesCollection)
        .where('snapshot_id', isEqualTo: snapshotId)
        .where('rank', isGreaterThanOrEqualTo: start)
        .where('rank', isLessThanOrEqualTo: end)
        .orderBy('rank')
        .get();

    return docs.docs
        .map(
          (doc) => LeaderboardEntryModel.fromMap(
            doc.data(),
            currentUserId: _currentUserId,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<LeaderboardPrivacySettings> getPrivacySettings({
    required String userId,
  }) async {
    try {
      final profileDoc = await _firestore
          .collection(AppConstants.leaderboardProfilesCollection)
          .doc(userId)
          .get();

      String fallbackDisplayName = 'Lumoni User';
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      final userData = userDoc.data();
      if (userData != null && userData['displayName'] is String) {
        fallbackDisplayName = userData['displayName'] as String;
      }

      if (!profileDoc.exists || profileDoc.data() == null) {
        return LeaderboardPrivacyModel(
          displayName: fallbackDisplayName,
          countryCode: 'US',
        );
      }

      return LeaderboardPrivacyModel.fromMap(
        profileDoc.data()!,
        fallbackDisplayName: fallbackDisplayName,
      );
    } catch (e) {
      debugPrint('[LeaderboardRepo] getPrivacySettings failed: $e');
      return const LeaderboardPrivacyModel(displayName: 'Lumoni User');
    }
  }

  @override
  Future<void> updatePrivacySettings({
    required String userId,
    required LeaderboardPrivacySettings settings,
  }) async {
    final model = LeaderboardPrivacyModel(
      displayName: settings.displayName,
      publicAlias: settings.publicAlias,
      countryCode: settings.countryCode,
      anonymousMode: settings.anonymousMode,
      hideProfile: settings.hideProfile,
      shareInCountry: settings.shareInCountry,
      visibilityScope: settings.visibilityScope,
    );

    await _firestore
        .collection(AppConstants.leaderboardProfilesCollection)
        .doc(userId)
        .set(model.toMap(), SetOptions(merge: true));
  }

  @override
  Future<List<LeaderboardTier>> getTierCatalog() async {
    return const <LeaderboardTier>[
      LeaderboardTier(
        id: 'legend',
        label: 'Legend',
        minPercentile: 99.0,
        maxPercentile: 100.0,
        colorHex: '0xFFFFD700',
        benefitText: 'Invitational seasonal placements and legend badge.',
      ),
      LeaderboardTier(
        id: 'diamond',
        label: 'Diamond',
        minPercentile: 95.0,
        maxPercentile: 98.9,
        colorHex: '0xFF67E8F9',
        benefitText: 'Diamond frame and top-percentile profile flair.',
      ),
      LeaderboardTier(
        id: 'platinum',
        label: 'Platinum',
        minPercentile: 85.0,
        maxPercentile: 94.9,
        colorHex: '0xFFA5B4FC',
        benefitText: 'Priority placement in local rival highlights.',
      ),
      LeaderboardTier(
        id: 'gold',
        label: 'Gold',
        minPercentile: 70.0,
        maxPercentile: 84.9,
        colorHex: '0xFFFBBF24',
        benefitText: 'Gold badge and faster progression milestones.',
      ),
      LeaderboardTier(
        id: 'silver',
        label: 'Silver',
        minPercentile: 50.0,
        maxPercentile: 69.9,
        colorHex: '0xFFCBD5E1',
        benefitText: 'Steady performer tier with consistency streak rewards.',
      ),
      LeaderboardTier(
        id: 'bronze',
        label: 'Bronze',
        minPercentile: 0.0,
        maxPercentile: 49.9,
        colorHex: '0xFFCD7F32',
        benefitText: 'Entry tier. Complete more validated sessions to climb.',
      ),
    ];
  }

  @override
  Future<void> recomputeUserRank(LeaderboardFilter filter) async {
    final callable = _functions.httpsCallable('recomputeUserRank');
    await callable.call(<String, dynamic>{
      'metric': filter.metric.value,
      'scope_type': filter.scopeType.value,
      'scope_value': filter.scopeValue,
      'period': filter.period.value,
    });
  }

  Future<void> saveFilter(LeaderboardFilter filter) async {
    await _localStorage.setCacheValue<String>(
      _filterCacheKey,
      jsonEncode(filter.toJson()),
    );
  }

  LeaderboardFilter? getCachedFilter() {
    final raw = _localStorage.getCacheValue<String>(_filterCacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      return LeaderboardFilter.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cacheSnapshot(
    LeaderboardFilter filter,
    LeaderboardSnapshot snapshot,
  ) async {
    final cacheKey =
        '${_snapshotCachePrefix}_${filter.metric.value}_${filter.scopeType.value}_${filter.scopeValue}_${filter.period.value}';

    await _localStorage.setCacheValue<String>(
      cacheKey,
      jsonEncode({
        'id': snapshot.id,
        'data': {
          'metric': snapshot.metric.value,
          'scope_type': snapshot.scopeType.value,
          'scope_value': snapshot.scopeValue,
          'period': snapshot.period.value,
          'generated_at': snapshot.generatedAt.toIso8601String(),
          'window_start': snapshot.windowStart.toIso8601String(),
          'window_end': snapshot.windowEnd.toIso8601String(),
          'total_eligible': snapshot.totalEligible,
          'status': snapshot.status,
          'top_highlights': snapshot.highlights
              .map(
                (highlight) => {
                  'uid': highlight.uid,
                  'display_name': highlight.displayName,
                  'rank': highlight.rank,
                  'score': highlight.score,
                  'badge': highlight.badge,
                },
              )
              .toList(growable: false),
        },
      }),
    );
  }

  LeaderboardSnapshot? _getCachedSnapshot(LeaderboardFilter filter) {
    final cacheKey =
        '${_snapshotCachePrefix}_${filter.metric.value}_${filter.scopeType.value}_${filter.scopeValue}_${filter.period.value}';
    final raw = _localStorage.getCacheValue<String>(cacheKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['id'] as String?;
      final payload = (map['data'] as Map?)?.cast<String, dynamic>();
      if (id == null || payload == null) return null;
      return LeaderboardSnapshotModel.fromMap(id, payload);
    } catch (e) {
      debugPrint('[LeaderboardRepo] _getCachedSnapshot parse error: $e');
      return null;
    }
  }
}
