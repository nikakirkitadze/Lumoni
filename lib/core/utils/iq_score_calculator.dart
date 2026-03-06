import 'dart:math' as math;

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/iq_question_model.dart';

/// Result of IQ score calculation.
class IQScoreResult {
  /// Raw number of correct answers.
  final int rawCorrect;

  /// Total questions attempted.
  final int totalQuestions;

  /// Raw proportion correct (0.0 - 1.0).
  final double rawProportion;

  /// Difficulty-weighted score before normalization.
  final double weightedScore;

  /// Time bonus/penalty factor applied.
  final double timeFactor;

  /// Final normalized IQ score (mean 100, SD 15).
  final int iqScore;

  /// Percentile rank (0.0 - 100.0).
  final double percentile;

  /// Classification label (e.g. "Above Average").
  final String classification;

  /// Per-category scores (category name -> normalized score 0-100).
  final Map<String, double> categoryScores;

  const IQScoreResult({
    required this.rawCorrect,
    required this.totalQuestions,
    required this.rawProportion,
    required this.weightedScore,
    required this.timeFactor,
    required this.iqScore,
    required this.percentile,
    required this.classification,
    required this.categoryScores,
  });
}

/// Computes IQ scores from raw test answers using proper statistical
/// normalization (z-score mapping to IQ scale with mean 100, SD 15).
class IQScoreCalculator {
  /// Calculates the full IQ score result.
  ///
  /// [questions] - the questions presented in the test.
  /// [answers]   - map of questionId -> selected answer index.
  /// [timeSpentSeconds] - total seconds spent on the test.
  IQScoreResult calculate({
    required List<IQQuestionModel> questions,
    required Map<String, int> answers,
    required int timeSpentSeconds,
  }) {
    if (questions.isEmpty) {
      return const IQScoreResult(
        rawCorrect: 0,
        totalQuestions: 0,
        rawProportion: 0,
        weightedScore: 0,
        timeFactor: 1.0,
        iqScore: 100,
        percentile: 50,
        classification: 'Average',
        categoryScores: {},
      );
    }

    // ── 1. Count correct answers and compute weighted score ──────────

    int rawCorrect = 0;
    double totalWeight = 0;
    double earnedWeight = 0;

    // Per-category accumulators.
    final Map<String, double> categoryEarned = {};
    final Map<String, double> categoryTotal = {};

    for (final question in questions) {
      final selectedIndex = answers[question.id];
      if (selectedIndex == null) continue; // unanswered

      // Difficulty weight: higher difficulty questions contribute more.
      // Weight = 1 + (difficulty - 1) * 0.5, so difficulty 1 => 1.0, 5 => 3.0.
      final weight = 1.0 + (question.difficulty - 1) * 0.5;
      totalWeight += weight;

      categoryTotal[question.category] =
          (categoryTotal[question.category] ?? 0) + weight;

      if (question.isCorrect(selectedIndex)) {
        rawCorrect++;
        earnedWeight += weight;
        categoryEarned[question.category] =
            (categoryEarned[question.category] ?? 0) + weight;
      }
    }

    final answeredCount = answers.length;
    final rawProportion =
        answeredCount > 0 ? rawCorrect / answeredCount : 0.0;
    final weightedProportion =
        totalWeight > 0 ? earnedWeight / totalWeight : 0.0;

    // ── 2. Compute time factor ──────────────────────────────────────

    final timeFactor =
        _computeTimeFactor(timeSpentSeconds, answeredCount);

    // ── 3. Apply time factor to weighted proportion ─────────────────

    final adjustedProportion =
        (weightedProportion * timeFactor).clamp(0.0, 1.0);

    // ── 4. Map to IQ scale using inverse normal CDF (probit) ────────
    //
    // We treat the adjusted proportion as a percentile rank among
    // test-takers and map it to a z-score. To avoid edge effects we
    // clamp the proportion to [0.001, 0.999] before the probit transform.

    final clampedP = adjustedProportion.clamp(0.001, 0.999);
    final zScore = _probit(clampedP);
    final rawIQ =
        AppConstants.iqMean + zScore * AppConstants.iqStandardDeviation;
    final iqScore =
        rawIQ.round().clamp(AppConstants.iqScoreFloor, AppConstants.iqScoreCeiling);

    // ── 5. Percentile from the IQ score ─────────────────────────────

    final percentile = _iqToPercentile(iqScore.toDouble());

    // ── 6. Category scores ──────────────────────────────────────────

    final Map<String, double> categoryScores = {};
    for (final category in categoryTotal.keys) {
      final catTotal = categoryTotal[category]!;
      final catEarned = categoryEarned[category] ?? 0;
      // Normalize each category to 0-100 scale.
      categoryScores[category] =
          catTotal > 0 ? (catEarned / catTotal * 100).roundToDouble() : 0;
    }

    // ── 7. Build result ─────────────────────────────────────────────

    return IQScoreResult(
      rawCorrect: rawCorrect,
      totalQuestions: questions.length,
      rawProportion: rawProportion,
      weightedScore: weightedProportion,
      timeFactor: timeFactor,
      iqScore: iqScore,
      percentile: percentile,
      classification: AppConstants.iqClassification(iqScore),
      categoryScores: categoryScores,
    );
  }

  /// Computes the time bonus/penalty factor.
  ///
  /// Returns a multiplier centered around 1.0:
  /// - Fast answering (below bonus threshold) -> up to 1 + maxBonusFraction
  /// - Slow answering (above penalty threshold) -> down to 1 - maxPenaltyFraction
  /// - In between -> 1.0
  double _computeTimeFactor(int timeSpentSeconds, int questionCount) {
    if (questionCount == 0) return 1.0;

    final avgTimePerQuestion = timeSpentSeconds / questionCount;

    if (avgTimePerQuestion < AppConstants.timeBonusThresholdSeconds) {
      // Bonus: linearly interpolate from 1.0 at threshold to
      // (1 + maxBonus) at 0 seconds.
      final bonusFraction = 1.0 -
          (avgTimePerQuestion / AppConstants.timeBonusThresholdSeconds);
      return 1.0 + bonusFraction * AppConstants.maxTimeBonusFraction;
    }

    if (avgTimePerQuestion > AppConstants.timePenaltyThresholdSeconds) {
      // Penalty: linearly interpolate from 1.0 at threshold to
      // (1 - maxPenalty) at 2x the threshold.
      final excessRatio = (avgTimePerQuestion -
              AppConstants.timePenaltyThresholdSeconds) /
          AppConstants.timePenaltyThresholdSeconds;
      final penaltyFraction = excessRatio.clamp(0.0, 1.0);
      return 1.0 - penaltyFraction * AppConstants.maxTimePenaltyFraction;
    }

    return 1.0;
  }

  /// Approximation of the inverse standard normal CDF (probit function)
  /// using the Beasley-Springer-Moro algorithm.
  ///
  /// Input [p] must be in (0, 1). Returns the z-score such that
  /// Phi(z) = p, where Phi is the standard normal CDF.
  double _probit(double p) {
    // Rational approximation coefficients for the central region.
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];

    const pLow = 0.02425;
    const pHigh = 1.0 - pLow;

    double q, r;

    if (p < pLow) {
      // Rational approximation for lower region.
      q = math.sqrt(-2.0 * math.log(p));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) *
                  q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1.0);
    } else if (p <= pHigh) {
      // Rational approximation for central region.
      q = p - 0.5;
      r = q * q;
      return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) *
                  r +
              a[5]) *
          q /
          (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r +
              1.0);
    } else {
      // Rational approximation for upper region.
      q = math.sqrt(-2.0 * math.log(1.0 - p));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) *
                  q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1.0);
    }
  }

  /// Converts an IQ score to a percentile using the standard normal CDF.
  double _iqToPercentile(double iq) {
    final z = (iq - AppConstants.iqMean) / AppConstants.iqStandardDeviation;
    final cdf = _normalCDF(z);
    return (cdf * 100).clamp(0.1, 99.9);
  }

  /// Standard normal cumulative distribution function approximation
  /// using Abramowitz & Stegun formula 26.2.17.
  double _normalCDF(double z) {
    if (z < -8.0) return 0.0;
    if (z > 8.0) return 1.0;

    double sum = 0.0;
    double term = z;
    for (int i = 3; sum + term != sum; i += 2) {
      sum += term;
      term = term * z * z / i;
    }

    return 0.5 + sum * _standardNormalPDF(z);
  }

  /// Standard normal probability density function.
  double _standardNormalPDF(double z) {
    return math.exp(-0.5 * z * z) / math.sqrt(2.0 * math.pi);
  }
}
