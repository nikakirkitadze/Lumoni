import 'package:equatable/equatable.dart';

import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/features/results/domain/entities/improvement_tip.dart';

/// Base state for the results feature.
sealed class ResultsState extends Equatable {
  const ResultsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any results have been requested.
class ResultsInitial extends ResultsState {
  const ResultsInitial();
}

/// Results are being loaded from Firestore or local cache.
class ResultsLoading extends ResultsState {
  const ResultsLoading();
}

/// Results loaded and ready for display.
class ResultsLoaded extends ResultsState {
  /// The completed test session containing raw data.
  final TestSessionModel session;

  /// Whether this is an IQ test (true) or EQ test (false).
  final bool isIQ;

  /// Computed IQ score (only meaningful when [isIQ] is true).
  final int iqScore;

  /// IQ percentile rank (0.0 - 100.0).
  final double iqPercentile;

  /// IQ classification label (e.g. "Above Average").
  final String iqClassification;

  /// Overall EQ score (0 - 100, only meaningful when [isIQ] is false).
  final double eqScore;

  /// EQ profile label (e.g. "Strong", "Exceptional").
  final String eqClassification;

  /// Category-level scores for breakdown display.
  final Map<String, double> categoryScores;

  /// Personalized improvement tips based on weak categories.
  final List<ImprovementTip> improvementTips;

  const ResultsLoaded({
    required this.session,
    required this.isIQ,
    this.iqScore = 0,
    this.iqPercentile = 0,
    this.iqClassification = '',
    this.eqScore = 0,
    this.eqClassification = '',
    this.categoryScores = const {},
    this.improvementTips = const [],
  });

  @override
  List<Object?> get props => [
        session,
        isIQ,
        iqScore,
        iqPercentile,
        iqClassification,
        eqScore,
        eqClassification,
        categoryScores,
        improvementTips,
      ];
}

/// An error occurred while loading results.
class ResultsError extends ResultsState {
  final String message;

  const ResultsError(this.message);

  @override
  List<Object?> get props => [message];
}
