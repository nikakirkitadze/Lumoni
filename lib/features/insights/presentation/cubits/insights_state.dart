import 'package:equatable/equatable.dart';

import 'package:lumoni/features/results/domain/entities/improvement_tip.dart';

/// A single data point in the score timeline.
class ScoreDataPoint extends Equatable {
  /// The date the test was completed.
  final DateTime date;

  /// The score achieved.
  final double score;

  /// The session ID for reference.
  final String sessionId;

  const ScoreDataPoint({
    required this.date,
    required this.score,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [date, score, sessionId];
}

/// Describes a category's performance as a strength or weakness.
class CategoryInsight extends Equatable {
  /// The category key (e.g. 'pattern', 'empathy').
  final String category;

  /// The display label for the category.
  final String label;

  /// The average score across all sessions.
  final double averageScore;

  /// The trend direction: positive means improving, negative means declining.
  final double trend;

  /// A brief insight message about performance in this category.
  final String insightText;

  const CategoryInsight({
    required this.category,
    required this.label,
    required this.averageScore,
    required this.trend,
    required this.insightText,
  });

  /// Whether the trend is improving.
  bool get isImproving => trend > 0;

  /// Whether the trend is declining.
  bool get isDeclining => trend < 0;

  @override
  List<Object?> get props => [category, label, averageScore, trend, insightText];
}

/// The overall performance trend direction.
enum PerformanceTrend {
  improving,
  stable,
  declining;

  String get label {
    switch (this) {
      case PerformanceTrend.improving:
        return 'Improving';
      case PerformanceTrend.stable:
        return 'Stable';
      case PerformanceTrend.declining:
        return 'Needs Attention';
    }
  }
}

/// Base state for the insights feature.
sealed class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before insights have been loaded.
class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

/// Insights data is being loaded and analyzed.
class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

/// Insights loaded and ready for display.
class InsightsLoaded extends InsightsState {
  /// IQ score history as a timeline of data points.
  final List<ScoreDataPoint> iqHistory;

  /// EQ score history as a timeline of data points.
  final List<ScoreDataPoint> eqHistory;

  /// Top-performing categories (strengths).
  final List<CategoryInsight> strengths;

  /// Lowest-performing categories (weaknesses).
  final List<CategoryInsight> weaknesses;

  /// Personalized recommendations based on weak areas.
  final List<ImprovementTip> recommendations;

  /// Overall performance trend across recent tests.
  final PerformanceTrend overallTrend;

  /// The most recent IQ category scores (for radar chart).
  final Map<String, double> latestIQCategoryScores;

  /// The most recent EQ category scores (for radar chart).
  final Map<String, double> latestEQCategoryScores;

  /// Average IQ score across all tests.
  final double averageIQ;

  /// Average EQ score across all tests.
  final double averageEQ;

  /// Total number of tests completed.
  final int totalTests;

  const InsightsLoaded({
    required this.iqHistory,
    required this.eqHistory,
    required this.strengths,
    required this.weaknesses,
    required this.recommendations,
    required this.overallTrend,
    this.latestIQCategoryScores = const {},
    this.latestEQCategoryScores = const {},
    this.averageIQ = 0,
    this.averageEQ = 0,
    this.totalTests = 0,
  });

  @override
  List<Object?> get props => [
        iqHistory,
        eqHistory,
        strengths,
        weaknesses,
        recommendations,
        overallTrend,
        latestIQCategoryScores,
        latestEQCategoryScores,
        averageIQ,
        averageEQ,
        totalTests,
      ];
}

/// An error occurred while loading insights.
class InsightsError extends InsightsState {
  final String message;

  const InsightsError(this.message);

  @override
  List<Object?> get props => [message];
}
