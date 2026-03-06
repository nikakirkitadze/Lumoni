import 'package:equatable/equatable.dart';

import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';

/// Result data returned by the IQ score calculator.
class IQResult extends Equatable {
  /// The computed IQ score (typically 55-145).
  final int iqScore;

  /// Percentile rank (0.0-100.0).
  final double percentile;

  /// Per-category scores (e.g. {"pattern": 85.0, "logical": 92.0}).
  final Map<String, double> categoryScores;

  /// Overall accuracy as a fraction (0.0-1.0).
  final double accuracy;

  const IQResult({
    required this.iqScore,
    required this.percentile,
    required this.categoryScores,
    required this.accuracy,
  });

  @override
  List<Object?> get props => [iqScore, percentile, categoryScores, accuracy];
}

/// Base state for the IQ test feature.
sealed class IQTestState extends Equatable {
  const IQTestState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action.
class IQTestInitial extends IQTestState {
  const IQTestInitial();
}

/// Loading questions or processing results.
class IQTestLoading extends IQTestState {
  const IQTestLoading();
}

/// Questions loaded, ready to begin the test.
class IQTestReady extends IQTestState {
  final List<IQQuestionModel> questions;
  final int totalQuestions;

  const IQTestReady({
    required this.questions,
    required this.totalQuestions,
  });

  @override
  List<Object?> get props => [questions, totalQuestions];
}

/// User is actively taking the test.
class IQTestInProgress extends IQTestState {
  final List<IQQuestionModel> questions;
  final int currentIndex;
  final Map<int, int> answers;
  final int timeRemaining;
  final int? selectedAnswer;

  const IQTestInProgress({
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.timeRemaining,
    this.selectedAnswer,
  });

  int get totalQuestions => questions.length;

  IQQuestionModel get currentQuestion => questions[currentIndex];

  double get progress => (currentIndex + 1) / totalQuestions;

  bool get isFirstQuestion => currentIndex == 0;

  bool get isLastQuestion => currentIndex == totalQuestions - 1;

  int get answeredCount => answers.length;

  String get formattedTime {
    final minutes = timeRemaining ~/ 60;
    final seconds = timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isTimeCritical => timeRemaining < 120;

  bool get isTimeWarning => timeRemaining < 300 && !isTimeCritical;

  IQTestInProgress copyWith({
    List<IQQuestionModel>? questions,
    int? currentIndex,
    Map<int, int>? answers,
    int? timeRemaining,
    int? Function()? selectedAnswer,
  }) {
    return IQTestInProgress(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      selectedAnswer:
          selectedAnswer != null ? selectedAnswer() : this.selectedAnswer,
    );
  }

  @override
  List<Object?> get props => [
        questions,
        currentIndex,
        answers,
        timeRemaining,
        selectedAnswer,
      ];
}

/// Briefly shown after the user selects an answer, indicating correct/wrong.
class IQTestAnswered extends IQTestState {
  final List<IQQuestionModel> questions;
  final int currentIndex;
  final Map<int, int> answers;
  final int selectedAnswer;
  final bool isCorrect;
  final int timeRemaining;

  const IQTestAnswered({
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeRemaining,
  });

  int get totalQuestions => questions.length;

  IQQuestionModel get currentQuestion => questions[currentIndex];

  bool get isLastQuestion => currentIndex == totalQuestions - 1;

  @override
  List<Object?> get props => [
        questions,
        currentIndex,
        answers,
        selectedAnswer,
        isCorrect,
        timeRemaining,
      ];
}

/// Test completed successfully with computed results.
class IQTestCompleted extends IQTestState {
  final IQResult result;
  final TestSessionModel session;

  const IQTestCompleted({
    required this.result,
    required this.session,
  });

  @override
  List<Object?> get props => [result, session];
}

/// An error occurred during the test flow.
class IQTestError extends IQTestState {
  final String message;

  const IQTestError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Free user has reached their test limit.
class IQTestLimitReached extends IQTestState {
  const IQTestLimitReached();
}
