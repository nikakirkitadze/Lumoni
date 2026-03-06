import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/features/results/domain/entities/improvement_tip.dart';
import 'package:lumoni/features/results/presentation/cubits/results_state.dart';

/// Manages the results display after a completed test session.
class ResultsCubit extends Cubit<ResultsState> {
  ResultsCubit() : super(const ResultsInitial());

  final FirestoreService _firestoreService = getIt<FirestoreService>();

  // ──────────────────────── Load Results ──────────────────────────────────

  /// Loads results for the given [sessionId] from Firestore.
  ///
  /// Falls back to the provided [session] if Firestore fetch fails,
  /// allowing offline results display.
  Future<void> loadResults(String sessionId, {TestSessionModel? session}) async {
    emit(const ResultsLoading());

    try {
      // Try Firestore first, fall back to passed-in session.
      TestSessionModel? loaded;
      try {
        loaded = await _firestoreService.getTestSession(sessionId);
      } catch (e) {
        debugPrint('[ResultsCubit] Firestore fetch failed, using cache: $e');
      }

      final resolvedSession = loaded ?? session;

      if (resolvedSession == null) {
        emit(const ResultsError('Could not load test results. Please try again.'));
        return;
      }

      final isIQ = resolvedSession.testType == TestType.iq;
      final categoryScores = Map<String, double>.from(resolvedSession.categoryScores);

      if (isIQ) {
        final iqScore = (resolvedSession.score ?? AppConstants.iqMean).round();
        final percentile = _calculatePercentile(iqScore.toDouble());
        final classification = AppConstants.iqClassification(iqScore);

        final tips = _generateImprovementTips(categoryScores, isIQ: true);

        emit(ResultsLoaded(
          session: resolvedSession,
          isIQ: true,
          iqScore: iqScore,
          iqPercentile: percentile,
          iqClassification: classification,
          categoryScores: categoryScores,
          improvementTips: tips,
        ));
      } else {
        final eqScore = resolvedSession.score ?? _calculateOverallEQ(categoryScores);
        final classification = AppConstants.eqClassification(eqScore);

        final tips = _generateImprovementTips(categoryScores, isIQ: false);

        emit(ResultsLoaded(
          session: resolvedSession,
          isIQ: false,
          eqScore: eqScore,
          eqClassification: classification,
          categoryScores: categoryScores,
          improvementTips: tips,
        ));
      }
    } catch (e) {
      emit(ResultsError('Failed to process results: ${_friendlyMessage(e)}'));
    }
  }

  // ──────────────────────── Share Results ─────────────────────────────────

  /// Shares results via the system share sheet.
  Future<void> shareResults() async {
    final currentState = state;
    if (currentState is! ResultsLoaded) return;

    try {
      final buffer = StringBuffer();
      buffer.writeln('My Lumoni Intelligence Results');
      buffer.writeln('');

      if (currentState.isIQ) {
        buffer.writeln('IQ Score: ${currentState.iqScore}');
        buffer.writeln('Classification: ${currentState.iqClassification}');
        buffer.writeln('Percentile: Top ${(100 - currentState.iqPercentile).toStringAsFixed(0)}%');
      } else {
        buffer.writeln('EQ Score: ${currentState.eqScore.toStringAsFixed(0)}/100');
        buffer.writeln('Profile: ${currentState.eqClassification}');
      }

      buffer.writeln('');
      buffer.writeln('Category Breakdown:');
      final labels = currentState.isIQ
          ? AppConstants.iqCategoryLabels
          : AppConstants.eqCategoryLabels;

      for (final entry in currentState.categoryScores.entries) {
        final label = labels[entry.key] ?? entry.key;
        buffer.writeln('  $label: ${entry.value.toStringAsFixed(0)}');
      }

      buffer.writeln('');
      buffer.writeln('Tested with Lumoni - Premium Intelligence Platform');

      await Share.share(buffer.toString());
    } catch (e) {
      debugPrint('[ResultsCubit] Share failed: $e');
    }
  }

  // ──────────────────────── Improvement Tips ─────────────────────────────

  /// Generates personalized improvement tips based on category scores.
  List<ImprovementTip> _generateImprovementTips(
    Map<String, double> categoryScores, {
    required bool isIQ,
  }) {
    return ImprovementTip.recommendedTips(
      categoryScores: categoryScores,
      maxTips: 5,
    );
  }

  // ──────────────────────── IQ Percentile ────────────────────────────────

  /// Calculates the percentile rank from an IQ score using the normal
  /// distribution (mean 100, SD 15).
  double _calculatePercentile(double iqScore) {
    final z = (iqScore - AppConstants.iqMean) / AppConstants.iqStandardDeviation;
    return _normalCDF(z) * 100;
  }

  /// Approximation of the cumulative distribution function for the
  /// standard normal distribution.
  double _normalCDF(double z) {
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;

    final sign = z < 0 ? -1 : 1;
    final x = z.abs() / math.sqrt(2);
    final t = 1.0 / (1.0 + p * x);
    final y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * math.exp(-x * x);
    return 0.5 * (1.0 + sign * y);
  }

  // ──────────────────────── EQ Score Calculation ─────────────────────────

  /// Calculates the overall EQ score as a weighted average of category scores.
  double _calculateOverallEQ(Map<String, double> categoryScores) {
    if (categoryScores.isEmpty) return 0;
    final total = categoryScores.values.fold<double>(0, (sum, v) => sum + v);
    return total / categoryScores.length;
  }

  // ──────────────────────── Helpers ──────────────────────────────────────

  String _friendlyMessage(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Network error. Check your connection.';
    }
    if (msg.contains('permission') || msg.contains('denied')) {
      return 'Permission denied. Please sign in again.';
    }
    return 'An unexpected error occurred.';
  }
}
