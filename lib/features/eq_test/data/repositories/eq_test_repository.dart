import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/features/eq_test/data/datasources/eq_statement_bank.dart';

/// Repository handling EQ test data operations including session persistence,
/// statement retrieval, and test-limit tracking.
class EQTestRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EQTestRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ────────────────────────── User ──────────────────────────────────────

  /// Returns the current authenticated user's ID.
  ///
  /// Throws [StateError] if no user is signed in.
  Future<String> getCurrentUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found. Please sign in first.');
    }
    return user.uid;
  }

  // ────────────────────────── Test Limit ────────────────────────────────

  /// Checks whether the user is allowed to take another EQ test.
  ///
  /// Free users are limited to [AppConstants.freeTestLimit] tests.
  /// Premium users have unlimited access.
  Future<bool> canTakeTest() async {
    try {
      // Check premium status first.
      if (await _isPremiumUser()) return true;

      final box = await Hive.openBox(AppConstants.preferencesBox);
      final usedTests = box.get(AppConstants.keyFreeTestsUsed, defaultValue: 0) as int;
      return usedTests < AppConstants.freeTestLimit;
    } catch (e) {
      debugPrint('[EQTestRepository] canTakeTest error: $e');
      // Default to allowing the test if we cannot check.
      return true;
    }
  }

  /// Increments the count of free tests used.
  Future<void> incrementTestCount() async {
    try {
      final box = await Hive.openBox(AppConstants.preferencesBox);
      final current = box.get(AppConstants.keyFreeTestsUsed, defaultValue: 0) as int;
      await box.put(AppConstants.keyFreeTestsUsed, current + 1);
    } catch (e) {
      debugPrint('[EQTestRepository] incrementTestCount error: $e');
    }
  }

  /// Returns the number of free tests the user has already taken.
  Future<int> getUsedTestCount() async {
    try {
      final box = await Hive.openBox(AppConstants.preferencesBox);
      return box.get(AppConstants.keyFreeTestsUsed, defaultValue: 0) as int;
    } catch (e) {
      debugPrint('[EQTestRepository] getUsedTestCount error: $e');
      return 0;
    }
  }

  // ────────────────────────── Statements ────────────────────────────────

  /// Retrieves all EQ statements from the local bank.
  ///
  /// Returns a complete list of [EQQuestionModel] instances.
  List<EQQuestionModel> getAllStatements() {
    return EQStatementBank.getAllStatements();
  }

  /// Retrieves EQ statements filtered by [category].
  List<EQQuestionModel> getStatementsByCategory(String category) {
    return EQStatementBank.getStatementsByCategory(category);
  }

  // ────────────────────────── Session Persistence ───────────────────────

  /// Saves a completed test session to Firestore.
  Future<void> saveTestSession(TestSessionModel session) async {
    try {
      await _firestore
          .collection(AppConstants.testSessionsCollection)
          .doc(session.id)
          .set(session.toFirestore());

      // Cache the latest EQ score locally.
      if (session.score != null) {
        final box = await Hive.openBox(AppConstants.preferencesBox);
        await box.put(AppConstants.keyCachedEQScore, session.score);
      }

      debugPrint('[EQTestRepository] Session ${session.id} saved successfully.');
    } catch (e) {
      debugPrint('[EQTestRepository] saveTestSession error: $e');
      rethrow;
    }
  }

  /// Retrieves a test session by [sessionId] from Firestore.
  Future<TestSessionModel?> getTestSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.testSessionsCollection)
          .doc(sessionId)
          .get();

      if (!doc.exists || doc.data() == null) return null;

      return TestSessionModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('[EQTestRepository] getTestSession error: $e');
      return null;
    }
  }

  /// Returns a list of all EQ test sessions for the current user,
  /// ordered by most recent first.
  Future<List<TestSessionModel>> getTestHistory({int limit = 20}) async {
    try {
      final userId = await getCurrentUserId();

      final snapshot = await _firestore
          .collection(AppConstants.testSessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('testType', isEqualTo: TestType.eq.value)
          .orderBy('startedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TestSessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[EQTestRepository] getTestHistory error: $e');
      return [];
    }
  }

  /// Returns the most recent completed EQ test session for the current user.
  Future<TestSessionModel?> getLatestSession() async {
    try {
      final history = await getTestHistory(limit: 1);
      return history.isNotEmpty ? history.first : null;
    } catch (e) {
      debugPrint('[EQTestRepository] getLatestSession error: $e');
      return null;
    }
  }

  /// Returns the cached EQ score from local storage, or null if unavailable.
  Future<double?> getCachedEQScore() async {
    try {
      final box = await Hive.openBox(AppConstants.preferencesBox);
      return box.get(AppConstants.keyCachedEQScore) as double?;
    } catch (e) {
      debugPrint('[EQTestRepository] getCachedEQScore error: $e');
      return null;
    }
  }

  // ────────────────────────── Premium Check ─────────────────────────────

  /// Checks whether the current user has a premium subscription.
  ///
  /// This is a simplified check. In production, integrate with RevenueCat
  /// or your subscription service.
  Future<bool> _isPremiumUser() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) return false;

      return doc.data()?['isPremium'] as bool? ?? false;
    } catch (e) {
      debugPrint('[EQTestRepository] _isPremiumUser error: $e');
      return false;
    }
  }

  // ────────────────────────── Cooldown Check ────────────────────────────

  /// Checks whether the test cooldown period has elapsed since the last test.
  Future<bool> isCooldownElapsed() async {
    try {
      final box = await Hive.openBox(AppConstants.preferencesBox);
      final lastTestDateStr = box.get(AppConstants.keyLastTestDate) as String?;

      if (lastTestDateStr == null) return true;

      final lastTestDate = DateTime.tryParse(lastTestDateStr);
      if (lastTestDate == null) return true;

      final cooldownDuration =
          Duration(hours: AppConstants.testCooldownHours);
      return DateTime.now().difference(lastTestDate) >= cooldownDuration;
    } catch (e) {
      debugPrint('[EQTestRepository] isCooldownElapsed error: $e');
      return true;
    }
  }

  /// Records the current time as the last test timestamp.
  Future<void> recordTestTimestamp() async {
    try {
      final box = await Hive.openBox(AppConstants.preferencesBox);
      await box.put(
        AppConstants.keyLastTestDate,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('[EQTestRepository] recordTestTimestamp error: $e');
    }
  }
}
