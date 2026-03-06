import 'dart:math';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';
import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/core/services/local_storage_service.dart';

/// Handles intelligent question selection for test sessions.
///
/// The algorithm:
/// 1. Excludes recently used questions to avoid repetition.
/// 2. Balances questions across categories.
/// 3. Adapts difficulty based on prior performance (for IQ).
/// 4. Shuffles the final selection for randomness.
class QuestionRandomizer {
  final LocalStorageService _localStorage;
  final Random _random;

  QuestionRandomizer({
    required LocalStorageService localStorage,
    Random? random,
  })  : _localStorage = localStorage,
        _random = random ?? Random();

  // ──────────────────────── IQ Question Selection ──────────────────────

  /// Selects a balanced set of IQ questions for a test session.
  ///
  /// [availableQuestions] - full pool of questions fetched from Firestore.
  /// [targetCount]        - desired number of questions (default 30).
  /// [previousAccuracy]   - accuracy from the user's last test (0.0 - 1.0),
  ///                        used to bias difficulty selection. null for first test.
  ///
  /// Returns a shuffled list of selected questions.
  List<IQQuestionModel> selectIQQuestions({
    required List<IQQuestionModel> availableQuestions,
    int targetCount = AppConstants.maxIQQuestions,
    double? previousAccuracy,
  }) {
    if (availableQuestions.isEmpty) return [];

    // Step 1: Remove recently used questions.
    final recentIds = _localStorage.getRecentQuestionIds().toSet();
    var pool = availableQuestions
        .where((q) => !recentIds.contains(q.id))
        .toList();

    // If filtering leaves too few, include recent ones to fill the gap.
    if (pool.length < targetCount) {
      pool = List.of(availableQuestions);
    }

    // Step 2: Determine target difficulty distribution.
    final difficultyDistribution = _computeDifficultyDistribution(
      previousAccuracy: previousAccuracy,
      targetCount: targetCount,
    );

    // Step 3: Group pool by category.
    final Map<String, List<IQQuestionModel>> byCategory = {};
    for (final q in pool) {
      byCategory.putIfAbsent(q.category, () => []).add(q);
    }

    // Step 4: Select questions balancing categories and difficulty.
    final selected = <IQQuestionModel>[];
    final usedIds = <String>{};

    final categories = byCategory.keys.toList();
    final questionsPerCat =
        AppConstants.questionsPerCategory(targetCount, categories.length);

    for (final category in categories) {
      final categoryPool = byCategory[category]!;
      final catTarget = questionsPerCat.clamp(0, targetCount - selected.length);

      final catSelected = _selectWithDifficultyBias(
        pool: categoryPool,
        targetCount: catTarget,
        difficultyDistribution: difficultyDistribution,
        usedIds: usedIds,
      );

      selected.addAll(catSelected);
      usedIds.addAll(catSelected.map((q) => q.id));
    }

    // Step 5: If still short, fill from remaining pool.
    if (selected.length < targetCount) {
      final remaining = pool
          .where((q) => !usedIds.contains(q.id))
          .toList()
        ..shuffle(_random);

      for (final q in remaining) {
        if (selected.length >= targetCount) break;
        selected.add(q);
        usedIds.add(q.id);
      }
    }

    // Step 6: Shuffle the final list.
    selected.shuffle(_random);

    // Step 7: Trim to exact target count.
    final result = selected.take(targetCount).toList();

    return result;
  }

  /// Selects questions from [pool] biased toward the given difficulty distribution.
  List<IQQuestionModel> _selectWithDifficultyBias({
    required List<IQQuestionModel> pool,
    required int targetCount,
    required Map<int, int> difficultyDistribution,
    required Set<String> usedIds,
  }) {
    final selected = <IQQuestionModel>[];

    // Group pool by difficulty.
    final Map<int, List<IQQuestionModel>> byDifficulty = {};
    for (final q in pool) {
      if (usedIds.contains(q.id)) continue;
      byDifficulty.putIfAbsent(q.difficulty, () => []).add(q);
    }

    // Shuffle each difficulty bucket.
    for (final bucket in byDifficulty.values) {
      bucket.shuffle(_random);
    }

    // Pick according to distribution.
    for (final entry in difficultyDistribution.entries) {
      final difficulty = entry.key;
      var count = entry.value;
      final bucket = byDifficulty[difficulty] ?? [];

      for (final q in bucket) {
        if (count <= 0 || selected.length >= targetCount) break;
        selected.add(q);
        count--;
      }
    }

    // Fill any remaining slots from whatever is available.
    if (selected.length < targetCount) {
      final usedInSelection = selected.map((q) => q.id).toSet();
      final remaining = pool
          .where((q) =>
              !usedIds.contains(q.id) && !usedInSelection.contains(q.id))
          .toList()
        ..shuffle(_random);

      for (final q in remaining) {
        if (selected.length >= targetCount) break;
        selected.add(q);
      }
    }

    return selected;
  }

  /// Computes the desired number of questions per difficulty level
  /// based on the user's previous accuracy.
  ///
  /// Higher previous accuracy -> more hard questions.
  /// Lower previous accuracy -> more easy questions.
  /// Null (first test) -> balanced distribution centered on medium.
  Map<int, int> _computeDifficultyDistribution({
    required double? previousAccuracy,
    required int targetCount,
  }) {
    // Default balanced weights for difficulties 1-5.
    // Indexed by difficulty level.
    final List<double> weights;

    if (previousAccuracy == null) {
      // First test: normal bell curve centered on medium (3).
      weights = [0.10, 0.20, 0.40, 0.20, 0.10];
    } else if (previousAccuracy >= 0.85) {
      // High performer: shift toward harder.
      weights = [0.05, 0.10, 0.25, 0.35, 0.25];
    } else if (previousAccuracy >= 0.70) {
      // Above average: slightly harder.
      weights = [0.08, 0.15, 0.30, 0.30, 0.17];
    } else if (previousAccuracy >= 0.50) {
      // Average: balanced.
      weights = [0.12, 0.22, 0.35, 0.20, 0.11];
    } else if (previousAccuracy >= 0.30) {
      // Below average: shift toward easier.
      weights = [0.20, 0.30, 0.30, 0.15, 0.05];
    } else {
      // Low performer: mostly easy.
      weights = [0.30, 0.30, 0.25, 0.10, 0.05];
    }

    final distribution = <int, int>{};
    int allocated = 0;

    for (int d = 1; d <= 5; d++) {
      final count = (weights[d - 1] * targetCount).round();
      distribution[d] = count;
      allocated += count;
    }

    // Adjust rounding errors by adding/removing from the middle difficulty.
    final diff = targetCount - allocated;
    distribution[3] = (distribution[3]! + diff).clamp(0, targetCount);

    return distribution;
  }

  // ──────────────────────── EQ Question Selection ──────────────────────

  /// Selects a balanced set of EQ questions for a test session.
  ///
  /// [availableQuestions] - full pool of EQ questions.
  /// [targetCount]        - desired number of questions.
  ///
  /// Returns a shuffled list ensuring even category distribution.
  List<EQQuestionModel> selectEQQuestions({
    required List<EQQuestionModel> availableQuestions,
    int targetCount = AppConstants.maxEQQuestions,
  }) {
    if (availableQuestions.isEmpty) return [];

    // Step 1: Remove recently used questions.
    final recentIds = _localStorage.getRecentQuestionIds().toSet();
    var pool = availableQuestions
        .where((q) => !recentIds.contains(q.id))
        .toList();

    if (pool.length < targetCount) {
      pool = List.of(availableQuestions);
    }

    // Step 2: Group by category.
    final Map<String, List<EQQuestionModel>> byCategory = {};
    for (final q in pool) {
      byCategory.putIfAbsent(q.category, () => []).add(q);
    }

    // Shuffle each category bucket.
    for (final bucket in byCategory.values) {
      bucket.shuffle(_random);
    }

    // Step 3: Round-robin selection across categories.
    final selected = <EQQuestionModel>[];
    final usedIds = <String>{};

    final categories = byCategory.keys.toList()..shuffle(_random);
    final questionsPerCat =
        AppConstants.questionsPerCategory(targetCount, categories.length);

    for (final category in categories) {
      final bucket = byCategory[category]!;
      int taken = 0;

      // Ensure a mix of normal and reversed items when possible.
      final normalItems = bucket.where((q) => !q.isReversed).toList();
      final reversedItems = bucket.where((q) => q.isReversed).toList();

      // Take roughly 70% normal, 30% reversed for scoring reliability.
      final reversedTarget = (questionsPerCat * 0.3).ceil();
      final normalTarget = questionsPerCat - reversedTarget;

      for (final q in normalItems) {
        if (taken >= normalTarget || selected.length >= targetCount) break;
        if (usedIds.contains(q.id)) continue;
        selected.add(q);
        usedIds.add(q.id);
        taken++;
      }

      for (final q in reversedItems) {
        if (taken >= questionsPerCat || selected.length >= targetCount) break;
        if (usedIds.contains(q.id)) continue;
        selected.add(q);
        usedIds.add(q.id);
        taken++;
      }
    }

    // Step 4: Fill remaining slots.
    if (selected.length < targetCount) {
      final remaining = pool
          .where((q) => !usedIds.contains(q.id))
          .toList()
        ..shuffle(_random);

      for (final q in remaining) {
        if (selected.length >= targetCount) break;
        selected.add(q);
        usedIds.add(q.id);
      }
    }

    // Step 5: Shuffle final selection.
    selected.shuffle(_random);

    return selected.take(targetCount).toList();
  }

  // ──────────────────────── Persistence ────────────────────────────────

  /// Records question IDs as recently used to avoid near-future repetition.
  Future<void> recordUsedQuestions(List<String> questionIds) async {
    await _localStorage.addRecentQuestionIds(questionIds);
  }

  /// Clears the recently used question history.
  Future<void> clearHistory() async {
    await _localStorage.clearRecentQuestionIds();
  }
}
