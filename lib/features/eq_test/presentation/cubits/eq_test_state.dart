import 'package:equatable/equatable.dart';

import 'package:lumoni/core/models/eq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/utils/eq_score_calculator.dart';

/// Base state for the EQ test feature.
sealed class EQTestState extends Equatable {
  const EQTestState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state before any action is taken.
class EQTestInitial extends EQTestState {
  const EQTestInitial();
}

/// Loading state while statements are being fetched or scores calculated.
class EQTestLoading extends EQTestState {
  const EQTestLoading();
}

/// The user is actively taking the EQ assessment.
class EQTestInProgress extends EQTestState {
  /// All statements for this session.
  final List<EQQuestionModel> statements;

  /// Zero-based index of the currently displayed statement.
  final int currentIndex;

  /// Map of statement index -> Likert value (1-5).
  final Map<int, int> answers;

  /// Total number of statements in the session.
  final int totalStatements;

  const EQTestInProgress({
    required this.statements,
    required this.currentIndex,
    required this.answers,
    required this.totalStatements,
  });

  /// Progress fraction from 0.0 to 1.0 based on answered statements.
  double get progress =>
      totalStatements > 0 ? answers.length / totalStatements : 0.0;

  /// Whether the current statement has been answered.
  bool get isCurrentAnswered => answers.containsKey(currentIndex);

  /// Whether the user is on the last statement.
  bool get isLastStatement => currentIndex == totalStatements - 1;

  /// Whether the user is on the first statement.
  bool get isFirstStatement => currentIndex == 0;

  /// The currently displayed statement model.
  EQQuestionModel get currentStatement => statements[currentIndex];

  /// The Likert value selected for the current statement, or null if unanswered.
  int? get currentAnswer => answers[currentIndex];

  /// Whether all statements have been answered.
  bool get allAnswered => answers.length == totalStatements;

  /// Creates a copy with updated fields.
  EQTestInProgress copyWith({
    List<EQQuestionModel>? statements,
    int? currentIndex,
    Map<int, int>? answers,
    int? totalStatements,
  }) {
    return EQTestInProgress(
      statements: statements ?? this.statements,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      totalStatements: totalStatements ?? this.totalStatements,
    );
  }

  @override
  List<Object?> get props => [
        statements,
        currentIndex,
        answers,
        totalStatements,
      ];
}

/// The assessment has been completed and results are available.
class EQTestCompleted extends EQTestState {
  /// The computed EQ result with overall score and category breakdowns.
  final EQScoreResult result;

  /// The persisted test session.
  final TestSessionModel session;

  const EQTestCompleted({
    required this.result,
    required this.session,
  });

  @override
  List<Object?> get props => [result, session];
}

/// An error occurred during the test flow.
class EQTestError extends EQTestState {
  /// Human-readable error message.
  final String message;

  const EQTestError(this.message);

  @override
  List<Object?> get props => [message];
}

/// The user has reached their free test limit and must upgrade.
class EQTestLimitReached extends EQTestState {
  const EQTestLimitReached();
}
