import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/models/user_model.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/features/home/presentation/cubits/home_state.dart';

/// Repository responsible for fetching and caching home dashboard data.
///
/// Uses [FirestoreService] as the primary data source and
/// [LocalStorageService] for offline caching so the dashboard can render
/// instantly on subsequent launches.
class HomeRepository {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  /// Cache keys.
  static const String _cachedUserKey = 'home_cached_user';
  static const String _cachedSessionsKey = 'home_cached_sessions';
  static const String _cachedWeeklyProgressKey = 'home_cached_weekly_progress';

  HomeRepository({
    required FirestoreService firestoreService,
    required LocalStorageService localStorageService,
  })  : _firestoreService = firestoreService,
        _localStorageService = localStorageService;

  // ────────────────────────── User Data ──────────────────────────────

  /// Fetches the current user's profile from Firestore and caches it.
  /// If the user doesn't exist yet (first sign-in), creates a new document.
  Future<UserModel> getUser(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      if (user != null) {
        // Cache for offline access.
        await _localStorageService.setCacheValue<String>(
          _cachedUserKey,
          jsonEncode(user.toJson()),
        );
        return user;
      }
      // User not found in Firestore — create a new profile from Firebase Auth.
      return await _createNewUser(userId);
    } catch (_) {
      // Fall back to cached data if network fails.
      return _getCachedUser();
    }
  }

  /// Creates a new user document in Firestore from the Firebase Auth user.
  Future<UserModel> _createNewUser(String userId) async {
    // Reload to ensure we have the latest profile data (e.g. after Apple sets name).
    await FirebaseAuth.instance.currentUser?.reload();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Build a meaningful display name.
    String displayName = firebaseUser?.displayName ?? '';
    if (displayName.isEmpty) {
      // Derive from email if available.
      final email = firebaseUser?.email ?? '';
      displayName = email.contains('@') ? email.split('@').first : 'User';
    }

    final newUser = UserModel.newUser(
      id: userId,
      email: firebaseUser?.email ?? '',
      displayName: displayName,
      photoUrl: firebaseUser?.photoURL,
    );
    await _firestoreService.saveUser(newUser);
    // Cache the newly created user.
    await _localStorageService.setCacheValue<String>(
      _cachedUserKey,
      jsonEncode(newUser.toJson()),
    );
    return newUser;
  }

  /// Returns the locally cached user model, if available.
  UserModel _getCachedUser() {
    final raw = _localStorageService.getCacheValue<String>(_cachedUserKey);
    if (raw != null) {
      return UserModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    }
    throw Exception('No cached user data available');
  }

  // ────────────────────── Recent Sessions ────────────────────────────

  /// Fetches the user's most recent completed test sessions.
  Future<List<TestSessionModel>> getRecentSessions(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final sessions = await _firestoreService.getTestHistory(
        userId: userId,
        pageSize: limit,
      );
      // Cache for offline access.
      await _localStorageService.setCacheValue<String>(
        _cachedSessionsKey,
        jsonEncode(sessions.map((s) => s.toJson()).toList()),
      );
      return sessions;
    } catch (_) {
      return _getCachedSessions();
    }
  }

  /// Returns locally cached recent sessions, if available.
  List<TestSessionModel> _getCachedSessions() {
    final raw =
        _localStorageService.getCacheValue<String>(_cachedSessionsKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TestSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ────────────────────── Weekly Progress ────────────────────────────

  /// Calculates the weekly progress from the user's test sessions.
  ///
  /// Returns a [DayProgress] entry for each of the last 7 days. If no
  /// test was taken on a given day the scores are null so the chart can
  /// render a gap.
  Future<List<DayProgress>> getWeeklyProgress(String userId) async {
    try {
      // Fetch recent sessions (last 30 to have enough for a week).
      final sessions = await _firestoreService.getTestHistory(
        userId: userId,
        pageSize: 30,
      );

      // Filter to last 7 days client-side.
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final recentSessions = sessions.where((s) {
        final completed = s.completedAt;
        return completed != null && completed.isAfter(sevenDaysAgo);
      }).toList();

      final progress = _buildWeeklyProgress(recentSessions);

      // Cache for offline.
      await _localStorageService.setCacheValue<String>(
        _cachedWeeklyProgressKey,
        jsonEncode(progress
            .map((p) => {
                  'date': p.date.toIso8601String(),
                  'iqScore': p.iqScore,
                  'eqScore': p.eqScore,
                })
            .toList()),
      );

      return progress;
    } catch (_) {
      return _getCachedWeeklyProgress();
    }
  }

  /// Builds a [List<DayProgress>] for the last 7 days from raw sessions.
  List<DayProgress> _buildWeeklyProgress(List<TestSessionModel> sessions) {
    final now = DateTime.now();
    final List<DayProgress> progress = [];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: i));

      final daySessions = sessions.where((s) {
        final completed = s.completedAt;
        if (completed == null) return false;
        return completed.year == day.year &&
            completed.month == day.month &&
            completed.day == day.day;
      });

      final iqSessions = daySessions
          .where((s) => s.testType == TestType.iq && s.score != null);
      final eqSessions = daySessions
          .where((s) => s.testType == TestType.eq && s.score != null);

      progress.add(DayProgress(
        date: day,
        iqScore: iqSessions.isNotEmpty
            ? iqSessions.map((s) => s.score!).reduce((a, b) => a + b) /
                iqSessions.length
            : null,
        eqScore: eqSessions.isNotEmpty
            ? eqSessions.map((s) => s.score!).reduce((a, b) => a + b) /
                eqSessions.length
            : null,
      ));
    }

    return progress;
  }

  /// Returns locally cached weekly progress, if available.
  List<DayProgress> _getCachedWeeklyProgress() {
    final raw = _localStorageService
        .getCacheValue<String>(_cachedWeeklyProgressKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        return DayProgress(
          date: DateTime.parse(map['date'] as String),
          iqScore: (map['iqScore'] as num?)?.toDouble(),
          eqScore: (map['eqScore'] as num?)?.toDouble(),
        );
      }).toList();
    }
    // Return empty 7-day range as default.
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => DayProgress(
        date: DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: 6 - i)),
      ),
    );
  }

  /// Clears all cached home data.
  Future<void> clearCache() async {
    await _localStorageService.clearCache();
  }
}
