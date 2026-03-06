import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/firestore_service.dart';
import 'package:lumoni/features/insights/presentation/cubits/insights_state.dart';
import 'package:lumoni/features/results/domain/entities/improvement_tip.dart';

/// Manages the insights/analytics dashboard by analyzing all test history.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit() : super(const InsightsInitial());

  final FirestoreService _firestoreService = getIt<FirestoreService>();
  final AuthService _authService = getIt<AuthService>();

  // ──────────────────────── Load Insights ─────────────────────────────

  /// Loads and analyzes all test history for the current user.
  Future<void> loadInsights() async {
    emit(const InsightsLoading());

    try {
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        emit(const InsightsError('Please sign in to view your insights.'));
        return;
      }

      // Fetch all completed IQ and EQ sessions.
      final iqSessions = await _firestoreService.getUserResults(
        userId: userId,
        testType: TestType.iq,
      );

      final eqSessions = await _firestoreService.getUserResults(
        userId: userId,
        testType: TestType.eq,
      );

      // Build IQ score timeline.
      final iqHistory = iqSessions
          .where((s) => s.score != null && s.completedAt != null)
          .map((s) => ScoreDataPoint(
                date: s.completedAt!,
                score: s.score!,
                sessionId: s.id,
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Build EQ score timeline.
      final eqHistory = eqSessions
          .where((s) => s.score != null && s.completedAt != null)
          .map((s) => ScoreDataPoint(
                date: s.completedAt!,
                score: s.score!,
                sessionId: s.id,
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Compute average scores.
      final averageIQ = iqHistory.isEmpty
          ? 0.0
          : iqHistory.fold<double>(0, (sum, p) => sum + p.score) /
              iqHistory.length;

      final averageEQ = eqHistory.isEmpty
          ? 0.0
          : eqHistory.fold<double>(0, (sum, p) => sum + p.score) /
              eqHistory.length;

      // Latest category scores.
      final latestIQCategoryScores = iqSessions.isNotEmpty
          ? Map<String, double>.from(iqSessions.first.categoryScores)
          : <String, double>{};

      final latestEQCategoryScores = eqSessions.isNotEmpty
          ? Map<String, double>.from(eqSessions.first.categoryScores)
          : <String, double>{};

      // Aggregate all category scores across sessions for analysis.
      final allCategoryScores = <String, List<double>>{};
      for (final session in [...iqSessions, ...eqSessions]) {
        for (final entry in session.categoryScores.entries) {
          allCategoryScores.putIfAbsent(entry.key, () => []).add(entry.value);
        }
      }

      // Calculate average per category.
      final categoryAverages = <String, double>{};
      for (final entry in allCategoryScores.entries) {
        categoryAverages[entry.key] =
            entry.value.fold<double>(0, (sum, v) => sum + v) /
                entry.value.length;
      }

      // Determine strengths (top 2) and weaknesses (bottom 2).
      final sortedCategories = categoryAverages.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final strengths = <CategoryInsight>[];
      final weaknesses = <CategoryInsight>[];

      for (int i = 0; i < sortedCategories.length && i < 2; i++) {
        final entry = sortedCategories[i];
        strengths.add(_buildCategoryInsight(
          entry.key,
          entry.value,
          allCategoryScores[entry.key] ?? [],
          isStrength: true,
        ));
      }

      for (int i = sortedCategories.length - 1;
          i >= 0 && weaknesses.length < 2;
          i--) {
        final entry = sortedCategories[i];
        // Avoid duplicating categories already in strengths.
        if (strengths.any((s) => s.category == entry.key)) continue;
        weaknesses.add(_buildCategoryInsight(
          entry.key,
          entry.value,
          allCategoryScores[entry.key] ?? [],
          isStrength: false,
        ));
      }

      // Compute overall trend from recent scores.
      final overallTrend = _computeOverallTrend(iqHistory, eqHistory);

      // Generate recommendations based on weak categories.
      final weakCategoryScores = <String, double>{};
      for (final w in weaknesses) {
        weakCategoryScores[w.category] = w.averageScore;
      }
      final recommendations = ImprovementTip.recommendedTips(
        categoryScores:
            weakCategoryScores.isNotEmpty ? weakCategoryScores : categoryAverages,
        maxTips: 5,
      );

      emit(InsightsLoaded(
        iqHistory: iqHistory,
        eqHistory: eqHistory,
        strengths: strengths,
        weaknesses: weaknesses,
        recommendations: recommendations,
        overallTrend: overallTrend,
        latestIQCategoryScores: latestIQCategoryScores,
        latestEQCategoryScores: latestEQCategoryScores,
        averageIQ: averageIQ,
        averageEQ: averageEQ,
        totalTests: iqSessions.length + eqSessions.length,
      ));
    } catch (e) {
      debugPrint('[InsightsCubit] Error loading insights: $e');
      emit(InsightsError('Failed to load insights: ${_friendlyMessage(e)}'));
    }
  }

  // ──────────────────────── Category Insight Builder ──────────────────

  CategoryInsight _buildCategoryInsight(
    String category,
    double averageScore,
    List<double> scores, {
    required bool isStrength,
  }) {
    final label = AppConstants.iqCategoryLabels[category] ??
        AppConstants.eqCategoryLabels[category] ??
        category;

    // Calculate trend from the scores list.
    double trend = 0;
    if (scores.length >= 2) {
      final recent = scores.sublist((scores.length / 2).floor());
      final earlier = scores.sublist(0, (scores.length / 2).floor());
      final recentAvg =
          recent.fold<double>(0, (s, v) => s + v) / recent.length;
      final earlierAvg =
          earlier.fold<double>(0, (s, v) => s + v) / earlier.length;
      trend = recentAvg - earlierAvg;
    }

    final insightText = isStrength
        ? _strengthInsight(category, averageScore, trend)
        : _weaknessInsight(category, averageScore, trend);

    return CategoryInsight(
      category: category,
      label: label,
      averageScore: averageScore,
      trend: trend,
      insightText: insightText,
    );
  }

  String _strengthInsight(String category, double score, double trend) {
    final trendWord = trend > 2
        ? 'and still improving'
        : trend < -2
            ? 'but showing slight decline recently'
            : 'with consistent performance';

    if (score >= 85) {
      return 'Exceptional performance in this area, $trendWord. Keep pushing your limits with advanced exercises.';
    }
    if (score >= 70) {
      return 'Strong performance here, $trendWord. You have a natural aptitude that you can develop further.';
    }
    return 'This is your relative strength, $trendWord. Regular practice will help you maintain and grow.';
  }

  String _weaknessInsight(String category, double score, double trend) {
    final trendWord = trend > 2
        ? 'The good news: you are showing improvement'
        : trend < -2
            ? 'This area needs more attention as performance is declining'
            : 'Focused practice can make a significant difference';

    if (score < 40) {
      return 'This is your biggest opportunity for growth. $trendWord. Start with beginner-level exercises.';
    }
    if (score < 60) {
      return 'There is room for improvement here. $trendWord. Consistent daily practice will yield results.';
    }
    return 'Not far from being a strength. $trendWord. A little extra focus can push this into top-tier territory.';
  }

  // ──────────────────────── Trend Computation ────────────────────────

  PerformanceTrend _computeOverallTrend(
    List<ScoreDataPoint> iqHistory,
    List<ScoreDataPoint> eqHistory,
  ) {
    final allScores = [...iqHistory, ...eqHistory]
      ..sort((a, b) => a.date.compareTo(b.date));

    if (allScores.length < 2) return PerformanceTrend.stable;

    // Compare average of the first half vs second half of all scores.
    final midpoint = allScores.length ~/ 2;
    final firstHalf = allScores.sublist(0, midpoint);
    final secondHalf = allScores.sublist(midpoint);

    final firstAvg =
        firstHalf.fold<double>(0, (s, p) => s + p.score) / firstHalf.length;
    final secondAvg =
        secondHalf.fold<double>(0, (s, p) => s + p.score) / secondHalf.length;

    final diff = secondAvg - firstAvg;

    if (diff > 3) return PerformanceTrend.improving;
    if (diff < -3) return PerformanceTrend.declining;
    return PerformanceTrend.stable;
  }

  // ──────────────────────── Helpers ──────────────────────────────────

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
