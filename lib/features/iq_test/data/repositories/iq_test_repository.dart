import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/services/ai_question_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/features/iq_test/data/datasources/iq_question_bank.dart';

/// Repository that provides IQ test questions, persists test sessions,
/// and tracks question usage history.
///
/// Primarily sources questions from the local [IQQuestionBank] and falls
/// back to Firestore when the local bank is unavailable or empty.
/// For premium users, can also source AI-generated questions via
/// [AIQuestionService].
class IQTestRepository {
  IQTestRepository({
    LocalStorageService? localStorage,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AIQuestionService? aiService,
  }) : _localStorage = localStorage ?? getIt<LocalStorageService>(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _aiService = aiService;

  final LocalStorageService _localStorage;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AIQuestionService? _aiService;

  /// Cached questions to avoid re-parsing on every call.
  List<IQQuestionModel>? _cachedQuestions;

  // ──────────────────────── Question Loading ────────────────────────────────

  /// Returns the full list of available IQ questions.
  ///
  /// Tries the local question bank first. If empty, falls back to Firestore.
  Future<List<IQQuestionModel>> getQuestions() async {
    // Return cache if available
    if (_cachedQuestions != null && _cachedQuestions!.isNotEmpty) {
      return _cachedQuestions!;
    }

    // Load from local bank
    try {
      final localQuestions = IQQuestionBank.getAllQuestions();
      if (localQuestions.isNotEmpty) {
        _cachedQuestions = localQuestions;
        debugPrint(
          '[IQTestRepository] Loaded ${localQuestions.length} questions from local bank.',
        );
        return localQuestions;
      }
    } catch (e) {
      debugPrint('[IQTestRepository] Local bank error: $e');
    }

    // Fallback to Firestore
    try {
      final snapshot = await _firestore
          .collection(AppConstants.iqQuestionsCollection)
          .get();

      final firestoreQuestions = snapshot.docs
          .map((doc) => IQQuestionModel.fromFirestore(doc))
          .toList();

      if (firestoreQuestions.isNotEmpty) {
        _cachedQuestions = firestoreQuestions;
        debugPrint(
          '[IQTestRepository] Loaded ${firestoreQuestions.length} questions from Firestore.',
        );
        return firestoreQuestions;
      }
    } catch (e) {
      debugPrint('[IQTestRepository] Firestore fallback error: $e');
    }

    return [];
  }

  /// Returns questions filtered by a specific category.
  Future<List<IQQuestionModel>> getQuestionsByCategory(String category) async {
    final all = await getQuestions();
    return all.where((q) => q.category == category).toList();
  }

  /// Returns questions filtered by difficulty level.
  Future<List<IQQuestionModel>> getQuestionsByDifficulty(int difficulty) async {
    final all = await getQuestions();
    return all.where((q) => q.difficulty == difficulty).toList();
  }

  // ──────────────────────── Hybrid (AI + Local) Loading ─────────────────────

  /// Returns a combined pool of AI-generated and local questions.
  ///
  /// For premium users with an available [AIQuestionService], fetches
  /// AI questions across all categories and merges them with the local bank.
  /// The [QuestionRandomizer] handles final selection from this pool.
  ///
  /// Falls back to 100% local questions if AI generation fails or the
  /// user is not premium.
  Future<List<IQQuestionModel>> getHybridQuestions({
    required bool isPremium,
  }) async {
    final aiService = _aiService;

    // Non-premium or no AI service -> existing behavior
    if (!isPremium || aiService == null) {
      return getQuestions();
    }

    final aiTarget =
        (AppConstants.maxIQQuestions * AppConstants.aiQuestionRatio).round();
    final perCategory = (aiTarget / AppConstants.iqCategories.length)
        .ceil(); // ~3 per category

    final recentIds = _localStorage.getRecentQuestionIds();
    final aiQuestions = <IQQuestionModel>[];

    // Generate AI questions across all categories
    for (final category in AppConstants.iqCategories) {
      final generated = await aiService.generateQuestions(
        category: category,
        difficulty:
            3, // mid-level; QuestionRandomizer handles final distribution
        count: perCategory,
        excludeIds: recentIds,
      );
      aiQuestions.addAll(generated);
    }

    if (aiQuestions.isNotEmpty) {
      debugPrint(
        '[IQTestRepository] Hybrid pool: ${aiQuestions.length} AI + local questions.',
      );
    }

    // Always load local questions as well
    final localQuestions = await getQuestions();

    // Combine into a single pool (QuestionRandomizer selects from this)
    return [...aiQuestions, ...localQuestions];
  }

  // ──────────────────────── Session Persistence ─────────────────────────────

  /// Saves a completed test session to Firestore.
  Future<void> saveTestSession(TestSessionModel session) async {
    try {
      final callable = _functions.httpsCallable('submitAssessmentResult');
      await callable.call({
        'sessionId': session.id,
        'testType': session.testType.value,
        'questionIds': session.questionIds,
        'answers': session.answers,
        'startedAt': session.startedAt.toIso8601String(),
        'completedAt': (session.completedAt ?? DateTime.now())
            .toIso8601String(),
      });

      debugPrint(
        '[IQTestRepository] Session ${session.id} submitted for server validation.',
      );
    } catch (e) {
      debugPrint(
        '[IQTestRepository] Validation failed, saving local session fallback: $e',
      );
      await _firestore
          .collection(AppConstants.testSessionsCollection)
          .doc(session.id)
          .set({
            ...session.toFirestore(),
            'validation_status': 'unverified',
            'validated_for_leaderboard': false,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    }
  }

  /// Retrieves the user's IQ test history, newest first.
  Future<List<TestSessionModel>> getTestHistory({
    required String userId,
    int limit = AppConstants.testHistoryPageSize,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.testSessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('testType', isEqualTo: TestType.iq.value)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TestSessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[IQTestRepository] Error fetching test history: $e');
      return [];
    }
  }

  /// Returns the count of completed IQ tests for the given user.
  Future<int> getCompletedTestCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.testSessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('testType', isEqualTo: TestType.iq.value)
          .where('completedAt', isNull: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[IQTestRepository] Error counting tests: $e');
      return 0;
    }
  }

  // ──────────────────────── Question Usage Tracking ─────────────────────────

  /// Returns the list of recently used question IDs.
  List<String> getRecentlyUsedQuestionIds() {
    return _localStorage.getRecentQuestionIds();
  }

  /// Records the given question IDs as recently used.
  ///
  /// Maintains a rolling window of [AppConstants.recentQuestionMemorySize].
  Future<void> trackUsedQuestionIds(List<String> questionIds) async {
    await _localStorage.addRecentQuestionIds(questionIds);
  }

  /// Clears the question usage history (e.g., for testing).
  Future<void> clearQuestionHistory() async {
    await _localStorage.clearRecentQuestionIds();
  }

  /// Clears the question cache, forcing a reload on next access.
  void clearCache() {
    _cachedQuestions = null;
  }
}
