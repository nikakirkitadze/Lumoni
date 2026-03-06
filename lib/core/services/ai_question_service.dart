import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/core/services/local_storage_service.dart';

/// Service that generates IQ questions via AI (Cloud Functions + Gemini)
/// and caches them locally for offline use.
///
/// Returns an empty list on any failure so the caller can fall back
/// to the local question bank without showing an error.
class AIQuestionService {
  AIQuestionService({
    FirebaseFunctions? functions,
    required LocalStorageService localStorage,
  })  : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1'),
        _localStorage = localStorage;

  final FirebaseFunctions _functions;
  final LocalStorageService _localStorage;

  /// Generates AI questions for a specific [category] and [difficulty].
  ///
  /// Tries the local Hive cache first. If the cache has enough unused
  /// questions, returns them immediately without a network call.
  /// Otherwise calls the `generateAIQuestions` Cloud Function.
  ///
  /// Returns an empty list on failure (caller should fall back to local bank).
  Future<List<IQQuestionModel>> generateQuestions({
    required String category,
    required int difficulty,
    required int count,
    List<String> excludeIds = const [],
  }) async {
    try {
      // Try cache first
      final cached = _getCachedQuestions(category, difficulty, excludeIds);
      if (cached.length >= count) {
        debugPrint(
          '[AIQuestionService] Serving $count cached AI questions for $category.',
        );
        return cached.take(count).toList();
      }

      // Call Cloud Function
      final callable = _functions.httpsCallable(
        'generateAIQuestions',
        options: HttpsCallableOptions(
          timeout: Duration(
            seconds: AppConstants.aiGenerationTimeoutSeconds,
          ),
        ),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'category': category,
        'difficulty': difficulty,
        'count': count,
        'excludeIds': excludeIds,
      });

      final data = result.data;
      if (data['success'] != true) {
        debugPrint('[AIQuestionService] Cloud Function returned success=false.');
        return [];
      }

      final rawQuestions = data['questions'] as List<dynamic>? ?? [];
      final questions = <IQQuestionModel>[];

      for (final raw in rawQuestions) {
        try {
          final map = Map<String, dynamic>.from(raw as Map);
          map['isAIGenerated'] = true;
          questions.add(IQQuestionModel.fromJson(map));
        } catch (e) {
          debugPrint('[AIQuestionService] Skipping invalid AI question: $e');
        }
      }

      // Cache for offline use
      if (questions.isNotEmpty) {
        await _cacheQuestions(questions);
      }

      debugPrint(
        '[AIQuestionService] Generated ${questions.length} AI questions for $category.',
      );
      return questions.take(count).toList();
    } catch (e) {
      debugPrint('[AIQuestionService] Generation failed: $e');
      return [];
    }
  }

  /// Returns cached AI questions for [category] and [difficulty]
  /// that are not in the [excludeIds] set.
  List<IQQuestionModel> _getCachedQuestions(
    String category,
    int difficulty,
    List<String> excludeIds,
  ) {
    try {
      final raw = _localStorage.getCacheValue<String>(
        AppConstants.keyAIQuestionCache,
      );
      if (raw == null) return [];

      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final excludeSet = excludeIds.toSet();

      return decoded
          .map((e) => IQQuestionModel.fromJson(e as Map<String, dynamic>))
          .where(
            (q) =>
                q.category == category &&
                q.difficulty == difficulty &&
                !excludeSet.contains(q.id),
          )
          .toList();
    } catch (e) {
      debugPrint('[AIQuestionService] Cache read error: $e');
      return [];
    }
  }

  /// Appends [questions] to the local Hive cache.
  Future<void> _cacheQuestions(List<IQQuestionModel> questions) async {
    try {
      final raw = _localStorage.getCacheValue<String>(
        AppConstants.keyAIQuestionCache,
      );

      List<Map<String, dynamic>> existing = [];
      if (raw != null) {
        existing = (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .toList();
      }

      final existingIds = existing.map((e) => e['id'] as String).toSet();

      for (final q in questions) {
        if (!existingIds.contains(q.id)) {
          existing.add(q.toJson());
        }
      }

      // Keep cache bounded -- retain the most recent 200 AI questions.
      if (existing.length > 200) {
        existing = existing.sublist(existing.length - 200);
      }

      await _localStorage.setCacheValue<String>(
        AppConstants.keyAIQuestionCache,
        jsonEncode(existing),
      );
    } catch (e) {
      debugPrint('[AIQuestionService] Cache write error: $e');
    }
  }
}
