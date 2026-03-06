import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';

/// Result of EQ score calculation.
class EQScoreResult {
  /// Overall EQ score (0-100).
  final double overallScore;

  /// Per-category scores (category name -> score 0-100).
  final Map<String, double> categoryScores;

  /// Classification label (e.g. "Strong").
  final String classification;

  /// Per-category classification labels.
  final Map<String, String> categoryClassifications;

  /// Strengths - categories in the top tier.
  final List<String> strengths;

  /// Areas for growth - categories in the bottom tier.
  final List<String> areasForGrowth;

  /// Profile analysis summary.
  final String profileAnalysis;

  /// Total number of questions answered.
  final int questionsAnswered;

  const EQScoreResult({
    required this.overallScore,
    required this.categoryScores,
    required this.classification,
    required this.categoryClassifications,
    required this.strengths,
    required this.areasForGrowth,
    required this.profileAnalysis,
    required this.questionsAnswered,
  });
}

/// Computes EQ scores from Likert-scale responses.
///
/// Each question belongs to an EQ category. Responses are scored (with
/// optional reverse-scoring and weighting), then normalized per-category
/// to a 0-100 scale. The overall EQ score is the weighted average of
/// all category scores.
class EQScoreCalculator {
  /// Calculates the full EQ score result.
  ///
  /// [questions] - the EQ questions presented.
  /// [answers]   - map of questionId -> Likert response (1-5).
  EQScoreResult calculate({
    required List<EQQuestionModel> questions,
    required Map<String, int> answers,
  }) {
    if (questions.isEmpty || answers.isEmpty) {
      return const EQScoreResult(
        overallScore: 0,
        categoryScores: {},
        classification: 'Needs Improvement',
        categoryClassifications: {},
        strengths: [],
        areasForGrowth: [],
        profileAnalysis: 'Not enough data to generate a profile.',
        questionsAnswered: 0,
      );
    }

    // ── 1. Accumulate per-category scores ────────────────────────────

    // earned weighted score per category
    final Map<String, double> categoryEarned = {};
    // maximum possible weighted score per category
    final Map<String, double> categoryMaxPossible = {};
    // count of answered questions per category
    final Map<String, int> categoryCount = {};

    for (final question in questions) {
      final response = answers[question.id];
      if (response == null) continue;

      final effectiveScore = question.effectiveScore(
        response,
        likertMin: AppConstants.likertMin,
        likertMax: AppConstants.likertMax,
      );

      // Maximum achievable effective score for this question:
      // likertMax * weight (since effectiveScore at max Likert = max * weight).
      final maxScore = AppConstants.likertMax.toDouble() * question.weight;

      categoryEarned[question.category] =
          (categoryEarned[question.category] ?? 0) + effectiveScore;
      categoryMaxPossible[question.category] =
          (categoryMaxPossible[question.category] ?? 0) + maxScore;
      categoryCount[question.category] =
          (categoryCount[question.category] ?? 0) + 1;
    }

    // ── 2. Normalize each category to 0-100 ─────────────────────────

    // For Likert 1-5, the minimum earned per question is weight * 1.
    // We normalize so that scoring all 1s = 0 and all 5s = 100.
    final Map<String, double> categoryScores = {};

    for (final category in categoryEarned.keys) {
      final earned = categoryEarned[category]!;
      final maxPossible = categoryMaxPossible[category]!;
      // Minimum possible earned = sum of (likertMin * weight) for each question.
      // Since we accumulated maxPossible = sum of (likertMax * weight),
      // minPossible = sum of (likertMin * weight) = maxPossible * (likertMin / likertMax).
      final minPossible = maxPossible *
          (AppConstants.likertMin.toDouble() / AppConstants.likertMax.toDouble());

      final range = maxPossible - minPossible;
      final normalized = range > 0
          ? ((earned - minPossible) / range * 100).clamp(
              AppConstants.eqMinCategoryScore, AppConstants.eqMaxCategoryScore)
          : 50.0;

      categoryScores[category] = _roundTo(normalized, 1);
    }

    // ── 3. Compute overall EQ score ─────────────────────────────────
    // Weighted average where the weight of each category is proportional
    // to the number of questions answered in it.

    double weightedSum = 0;
    int totalAnswered = 0;

    for (final category in categoryScores.keys) {
      final count = categoryCount[category] ?? 0;
      weightedSum += categoryScores[category]! * count;
      totalAnswered += count;
    }

    final overallScore = totalAnswered > 0
        ? _roundTo(weightedSum / totalAnswered, 1)
        : 0.0;

    // ── 4. Classification ───────────────────────────────────────────

    final classification = AppConstants.eqClassification(overallScore);

    final Map<String, String> categoryClassifications = {};
    for (final entry in categoryScores.entries) {
      categoryClassifications[entry.key] =
          AppConstants.eqClassification(entry.value);
    }

    // ── 5. Identify strengths and growth areas ──────────────────────

    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final strengths = sortedCategories
        .where((e) => e.value >= 60)
        .map((e) => e.key)
        .toList();

    final areasForGrowth = sortedCategories
        .where((e) => e.value < 40)
        .map((e) => e.key)
        .toList();

    // ── 6. Profile analysis ─────────────────────────────────────────

    final profileAnalysis = _generateProfileAnalysis(
      overallScore: overallScore,
      categoryScores: categoryScores,
      strengths: strengths,
      areasForGrowth: areasForGrowth,
    );

    return EQScoreResult(
      overallScore: overallScore,
      categoryScores: categoryScores,
      classification: classification,
      categoryClassifications: categoryClassifications,
      strengths: strengths,
      areasForGrowth: areasForGrowth,
      profileAnalysis: profileAnalysis,
      questionsAnswered: totalAnswered,
    );
  }

  /// Generates a descriptive profile analysis string.
  String _generateProfileAnalysis({
    required double overallScore,
    required Map<String, double> categoryScores,
    required List<String> strengths,
    required List<String> areasForGrowth,
  }) {
    final buffer = StringBuffer();

    // Overall assessment.
    if (overallScore >= 80) {
      buffer.write(
        'You demonstrate exceptional emotional intelligence across '
        'multiple dimensions. ',
      );
    } else if (overallScore >= 60) {
      buffer.write(
        'You show strong emotional intelligence with a solid foundation '
        'in understanding and managing emotions. ',
      );
    } else if (overallScore >= 40) {
      buffer.write(
        'Your emotional intelligence is developing well, with clear '
        'potential for growth in several areas. ',
      );
    } else if (overallScore >= 20) {
      buffer.write(
        'Your emotional intelligence is emerging. Focused effort on '
        'specific areas can lead to meaningful improvement. ',
      );
    } else {
      buffer.write(
        'There are significant opportunities to develop your emotional '
        'intelligence skills. ',
      );
    }

    // Strengths.
    if (strengths.isNotEmpty) {
      final strengthLabels = strengths
          .map((s) => AppConstants.eqCategoryLabels[s] ?? s)
          .toList();
      if (strengthLabels.length == 1) {
        buffer.write(
          'Your strongest area is ${strengthLabels.first}. ',
        );
      } else {
        final joined = strengthLabels.sublist(0, strengthLabels.length - 1).join(', ');
        buffer.write(
          'Your strongest areas are $joined and ${strengthLabels.last}. ',
        );
      }
    }

    // Growth areas.
    if (areasForGrowth.isNotEmpty) {
      final growthLabels = areasForGrowth
          .map((s) => AppConstants.eqCategoryLabels[s] ?? s)
          .toList();
      if (growthLabels.length == 1) {
        buffer.write(
          'Consider focusing on developing ${growthLabels.first} '
          'to further enhance your emotional capabilities.',
        );
      } else {
        final joined = growthLabels.sublist(0, growthLabels.length - 1).join(', ');
        buffer.write(
          'Consider focusing on developing $joined and '
          '${growthLabels.last} to further enhance your emotional capabilities.',
        );
      }
    }

    // Balance analysis.
    if (categoryScores.length >= 2) {
      final values = categoryScores.values.toList();
      final maxScore = values.reduce((a, b) => a > b ? a : b);
      final minScore = values.reduce((a, b) => a < b ? a : b);
      final spread = maxScore - minScore;

      if (spread <= 15) {
        buffer.write(
          ' Your profile is well-balanced across all EQ dimensions.',
        );
      } else if (spread >= 40) {
        buffer.write(
          ' There is notable variation across your EQ dimensions, '
          'suggesting focused development in lower-scoring areas would '
          'be particularly beneficial.',
        );
      }
    }

    return buffer.toString().trim();
  }

  /// Rounds [value] to [places] decimal places.
  double _roundTo(double value, int places) {
    final mod = _pow10(places);
    return (value * mod).roundToDouble() / mod;
  }

  double _pow10(int n) {
    double result = 1.0;
    for (int i = 0; i < n; i++) {
      result *= 10.0;
    }
    return result;
  }
}
