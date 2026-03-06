import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';
import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/models/user_model.dart';

/// Exception thrown by [FirestoreService] operations.
class FirestoreException implements Exception {
  final String message;
  final Object? originalError;

  const FirestoreException(this.message, {this.originalError});

  @override
  String toString() => 'FirestoreException: $message';
}

/// Service providing Firestore CRUD operations and domain-specific queries.
class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ──────────────────────── Generic CRUD ───────────────────────────────

  /// Creates or overwrites a document at [collection]/[docId].
  Future<void> setDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    bool merge = false,
  }) async {
    try {
      await _firestore
          .collection(collection)
          .doc(docId)
          .set(data, SetOptions(merge: merge));
    } catch (e) {
      throw FirestoreException(
        'Failed to set document $collection/$docId',
        originalError: e,
      );
    }
  }

  /// Reads a single document from [collection]/[docId].
  /// Returns null if the document does not exist.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      final doc = await _firestore.collection(collection).doc(docId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      throw FirestoreException(
        'Failed to get document $collection/$docId',
        originalError: e,
      );
    }
  }

  /// Updates specific fields of a document at [collection]/[docId].
  Future<void> updateDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      throw FirestoreException(
        'Failed to update document $collection/$docId',
        originalError: e,
      );
    }
  }

  /// Deletes a document at [collection]/[docId].
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      throw FirestoreException(
        'Failed to delete document $collection/$docId',
        originalError: e,
      );
    }
  }

  /// Adds a document with an auto-generated ID to [collection].
  /// Returns the new document ID.
  Future<String> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add(data);
      return docRef.id;
    } catch (e) {
      throw FirestoreException(
        'Failed to add document to $collection',
        originalError: e,
      );
    }
  }

  // ──────────────────────── User Operations ────────────────────────────

  /// Retrieves the user document for [userId].
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException('Failed to get user $userId', originalError: e);
    }
  }

  /// Creates or updates the user document.
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.id)
          .set(user.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException(
        'Failed to save user ${user.id}',
        originalError: e,
      );
    }
  }

  /// Listens to real-time updates for a user document.
  Stream<UserModel?> userStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ──────────────────────── IQ Questions ───────────────────────────────

  /// Fetches IQ questions filtered by optional criteria.
  ///
  /// - [category] filters by IQ category.
  /// - [difficulty] filters by difficulty level (1-5).
  /// - [excludeIds] removes questions the user has recently seen.
  /// - [limit] caps the number of returned questions.
  Future<List<IQQuestionModel>> getIQQuestions({
    String? category,
    int? difficulty,
    List<String> excludeIds = const [],
    int limit = 30,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(AppConstants.iqQuestionsCollection);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty);
      }

      // Firestore does not support a native `NOT IN` filter for large lists,
      // so we fetch more than needed and filter client-side.
      final fetchLimit =
          excludeIds.isEmpty ? limit : limit + excludeIds.length;
      query = query.limit(fetchLimit);

      final snapshot = await query.get();

      final questions = snapshot.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .take(limit)
          .map((doc) => IQQuestionModel.fromFirestore(doc))
          .toList();

      return questions;
    } catch (e) {
      throw FirestoreException(
        'Failed to fetch IQ questions',
        originalError: e,
      );
    }
  }

  /// Fetches a single IQ question by ID.
  Future<IQQuestionModel?> getIQQuestion(String questionId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.iqQuestionsCollection)
          .doc(questionId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return IQQuestionModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        'Failed to fetch IQ question $questionId',
        originalError: e,
      );
    }
  }

  // ──────────────────────── EQ Questions ───────────────────────────────

  /// Fetches EQ questions, optionally filtered by [category].
  Future<List<EQQuestionModel>> getEQQuestions({
    String? category,
    List<String> excludeIds = const [],
    int limit = 40,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(AppConstants.eqQuestionsCollection);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }

      final fetchLimit =
          excludeIds.isEmpty ? limit : limit + excludeIds.length;
      query = query.limit(fetchLimit);

      final snapshot = await query.get();

      final questions = snapshot.docs
          .where((doc) => !excludeIds.contains(doc.id))
          .take(limit)
          .map((doc) => EQQuestionModel.fromFirestore(doc))
          .toList();

      return questions;
    } catch (e) {
      throw FirestoreException(
        'Failed to fetch EQ questions',
        originalError: e,
      );
    }
  }

  // ──────────────────────── Test Sessions ──────────────────────────────

  /// Persists a test session (create or update).
  Future<void> saveTestSession(TestSessionModel session) async {
    try {
      await _firestore
          .collection(AppConstants.testSessionsCollection)
          .doc(session.id)
          .set(session.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw FirestoreException(
        'Failed to save test session ${session.id}',
        originalError: e,
      );
    }
  }

  /// Retrieves a single test session by ID.
  Future<TestSessionModel?> getTestSession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.testSessionsCollection)
          .doc(sessionId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return TestSessionModel.fromFirestore(doc);
    } catch (e) {
      throw FirestoreException(
        'Failed to get test session $sessionId',
        originalError: e,
      );
    }
  }

  /// Fetches the test history for a given [userId], ordered by most recent.
  ///
  /// Supports pagination via [lastDocument] and [pageSize].
  /// Optionally filter by [testType].
  Future<List<TestSessionModel>> getTestHistory({
    required String userId,
    TestType? testType,
    int pageSize = AppConstants.testHistoryPageSize,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.testSessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startedAt', descending: true)
          .limit(pageSize);

      if (testType != null) {
        query = query.where('testType', isEqualTo: testType.value);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => TestSessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw FirestoreException(
        'Failed to fetch test history for $userId',
        originalError: e,
      );
    }
  }

  /// Fetches all completed test sessions for a user (for results / insights).
  Future<List<TestSessionModel>> getUserResults({
    required String userId,
    TestType? testType,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.testSessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('completedAt', isNull: false)
          .orderBy('completedAt', descending: true);

      if (testType != null) {
        query = query.where('testType', isEqualTo: testType.value);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => TestSessionModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw FirestoreException(
        'Failed to fetch results for $userId',
        originalError: e,
      );
    }
  }

  /// Returns the count of completed tests for [userId].
  Future<int> getCompletedTestCount({
    required String userId,
    TestType? testType,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(AppConstants.testSessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('completedAt', isNull: false);

      if (testType != null) {
        query = query.where('testType', isEqualTo: testType.value);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[FirestoreService] Error counting tests: $e');
      return 0;
    }
  }

  // ──────────────────────── Batch Operations ───────────────────────────

  /// Runs a batched write. The [actions] callback receives a [WriteBatch]
  /// that the caller populates; [runBatch] commits it atomically.
  Future<void> runBatch(
    void Function(WriteBatch batch) actions,
  ) async {
    try {
      final batch = _firestore.batch();
      actions(batch);
      await batch.commit();
    } catch (e) {
      throw FirestoreException('Batch write failed', originalError: e);
    }
  }

  /// Provides direct access to a Firestore [CollectionReference] for
  /// advanced queries not covered by the convenience methods above.
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _firestore.collection(path);
}
