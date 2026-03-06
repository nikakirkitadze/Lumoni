import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/models/iq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/core/services/subscription_service.dart';
import 'package:lumoni/core/utils/iq_score_calculator.dart';
import 'package:lumoni/core/utils/question_randomizer.dart';
import 'package:lumoni/features/iq_test/data/repositories/iq_test_repository.dart';
import 'package:lumoni/features/iq_test/presentation/cubits/iq_test_state.dart';

/// Cubit that manages the complete IQ test lifecycle:
/// loading questions, timing, answer tracking, scoring, and persistence.
class IQTestCubit extends Cubit<IQTestState> {
  IQTestCubit({
    IQTestRepository? repository,
    LocalStorageService? localStorage,
    SubscriptionService? subscriptionService,
  })  : _repository = repository ?? getIt<IQTestRepository>(),
        _localStorage = localStorage ?? getIt<LocalStorageService>(),
        _subscriptionService =
            subscriptionService ?? getIt<SubscriptionService>(),
        super(const IQTestInitial());

  final IQTestRepository _repository;
  final LocalStorageService _localStorage;
  final SubscriptionService _subscriptionService;

  Timer? _timer;
  DateTime? _testStartTime;
  final Map<int, Duration> _questionStartTimes = {};
  final Map<int, int> _timePerQuestion = {};
  int _currentQuestionStartSeconds = 0;

  // ──────────────────────── Public API ──────────────────────────────────────

  /// Starts a new IQ test session.
  ///
  /// Checks subscription status and free test limits before loading questions.
  Future<void> startTest() async {
    emit(const IQTestLoading());

    try {
      // Check if user has reached the free test limit
      final isPremium = _subscriptionService.isPremium;
      if (!isPremium) {
        final testsUsed = _localStorage.getFreeTestsUsed();
        if (testsUsed >= AppConstants.freeTestLimit) {
          emit(const IQTestLimitReached());
          return;
        }
      }

      // Load all available questions (hybrid AI+local for premium users)
      final allQuestions = await _repository.getHybridQuestions(
        isPremium: isPremium,
      );

      if (allQuestions.isEmpty) {
        emit(const IQTestError(
          message: 'No questions available. Please check your connection.',
        ));
        return;
      }

      // Select questions using the randomizer for balanced distribution
      final randomizer = QuestionRandomizer(localStorage: _localStorage);
      final selectedQuestions = randomizer.selectIQQuestions(
        availableQuestions: allQuestions,
        targetCount: AppConstants.maxIQQuestions,
      );

      if (selectedQuestions.length < AppConstants.minQuestionsForValidResult) {
        emit(const IQTestError(
          message:
              'Not enough unique questions available. Please try again later.',
        ));
        return;
      }

      emit(IQTestReady(
        questions: selectedQuestions,
        totalQuestions: selectedQuestions.length,
      ));
    } catch (e) {
      debugPrint('[IQTestCubit] Error starting test: $e');
      emit(IQTestError(message: 'Failed to load questions: ${e.toString()}'));
    }
  }

  /// Begins the timed test after the user confirms readiness.
  void beginTest() {
    final currentState = state;
    if (currentState is! IQTestReady) return;

    _testStartTime = DateTime.now();
    _currentQuestionStartSeconds = AppConstants.testDurationSeconds;

    emit(IQTestInProgress(
      questions: currentState.questions,
      currentIndex: 0,
      answers: const {},
      timeRemaining: AppConstants.testDurationSeconds,
      selectedAnswer: null,
    ));

    _startTimer();
  }

  /// Records the user's selected answer for the current question.
  void selectAnswer(int questionIndex, int answerIndex) {
    final currentState = state;
    if (currentState is! IQTestInProgress) return;

    // Record time spent on this question
    final timeOnQuestion =
        _currentQuestionStartSeconds - currentState.timeRemaining;
    _timePerQuestion[questionIndex] = timeOnQuestion;

    // Update answers map
    final updatedAnswers = Map<int, int>.from(currentState.answers);
    updatedAnswers[questionIndex] = answerIndex;

    // Check correctness
    final question = currentState.questions[questionIndex];
    final isCorrect = question.isCorrect(answerIndex);

    emit(IQTestAnswered(
      questions: currentState.questions,
      currentIndex: currentState.currentIndex,
      answers: updatedAnswers,
      selectedAnswer: answerIndex,
      isCorrect: isCorrect,
      timeRemaining: currentState.timeRemaining,
    ));

    // Auto-advance after a brief delay to show correct/wrong feedback
    Future.delayed(const Duration(milliseconds: 800), () {
      if (state is IQTestAnswered) {
        final answeredState = state as IQTestAnswered;
        if (answeredState.isLastQuestion) {
          // Stay on answered state so user can see feedback and submit
          emit(IQTestInProgress(
            questions: answeredState.questions,
            currentIndex: answeredState.currentIndex,
            answers: answeredState.answers,
            timeRemaining: answeredState.timeRemaining,
            selectedAnswer: answerIndex,
          ));
        } else {
          _moveToQuestion(
            answeredState.questions,
            answeredState.currentIndex + 1,
            answeredState.answers,
            answeredState.timeRemaining,
          );
        }
      }
    });
  }

  /// Advances to the next question.
  void nextQuestion() {
    final currentState = state;
    if (currentState is! IQTestInProgress) return;
    if (currentState.isLastQuestion) return;

    _moveToQuestion(
      currentState.questions,
      currentState.currentIndex + 1,
      currentState.answers,
      currentState.timeRemaining,
    );
  }

  /// Returns to the previous question.
  void previousQuestion() {
    final currentState = state;
    if (currentState is! IQTestInProgress) return;
    if (currentState.isFirstQuestion) return;

    final previousIndex = currentState.currentIndex - 1;
    final previousAnswer = currentState.answers[previousIndex];

    emit(currentState.copyWith(
      currentIndex: previousIndex,
      selectedAnswer: () => previousAnswer,
    ));

    _currentQuestionStartSeconds = currentState.timeRemaining;
  }

  /// Submits the test, calculates the score, and persists results.
  Future<void> submitTest() async {
    IQTestInProgress? progressState;

    if (state is IQTestInProgress) {
      progressState = state as IQTestInProgress;
    } else if (state is IQTestAnswered) {
      final answered = state as IQTestAnswered;
      progressState = IQTestInProgress(
        questions: answered.questions,
        currentIndex: answered.currentIndex,
        answers: answered.answers,
        timeRemaining: answered.timeRemaining,
        selectedAnswer: answered.selectedAnswer,
      );
    }

    if (progressState == null) return;

    _stopTimer();
    emit(const IQTestLoading());

    try {
      final totalTimeSpent =
          AppConstants.testDurationSeconds - progressState.timeRemaining;

      // Convert index-based answers to question-ID-based answers
      final idBasedAnswers = <String, int>{};
      for (final entry in progressState.answers.entries) {
        final questionId = progressState.questions[entry.key].id;
        idBasedAnswers[questionId] = entry.value;
      }

      // Calculate IQ score
      final calculator = IQScoreCalculator();
      final result = calculator.calculate(
        questions: progressState.questions,
        answers: idBasedAnswers,
        timeSpentSeconds: totalTimeSpent,
      );

      // Build session model
      final sessionId = const Uuid().v4();
      final userId = getIt<AuthService>().currentUser?.uid;
      if (userId == null) {
        emit(const IQTestError(
          message: 'You must be signed in to save results.',
        ));
        return;
      }

      final session = TestSessionModel(
        id: sessionId,
        userId: userId,
        testType: TestType.iq,
        startedAt: _testStartTime ?? DateTime.now(),
        completedAt: DateTime.now(),
        score: result.iqScore.toDouble(),
        categoryScores: result.categoryScores,
        questionIds: progressState.questions.map((q) => q.id).toList(),
        answers: idBasedAnswers,
        timeSpentSeconds: totalTimeSpent,
      );

      // Persist results
      await _repository.saveTestSession(session);

      // Track used question IDs for future avoidance
      await _repository.trackUsedQuestionIds(
        progressState.questions.map((q) => q.id).toList(),
      );

      // Update free test counter
      final isPremium = _subscriptionService.isPremium;
      if (!isPremium) {
        await _localStorage.incrementFreeTestsUsed();
      }

      // Cache the latest IQ score
      await _localStorage.setCachedIQScore(result.iqScore);

      // Update last test date
      await _localStorage.setLastTestDate(DateTime.now());

      // Convert IQScoreResult to IQResult (state model).
      final iqResult = IQResult(
        iqScore: result.iqScore,
        percentile: result.percentile,
        categoryScores: result.categoryScores,
        accuracy: result.rawProportion,
      );

      emit(IQTestCompleted(result: iqResult, session: session));
    } catch (e) {
      debugPrint('[IQTestCubit] Error submitting test: $e');
      emit(IQTestError(message: 'Failed to save results: ${e.toString()}'));
    }
  }

  /// Resets the cubit to the initial state.
  void reset() {
    _stopTimer();
    _questionStartTimes.clear();
    _timePerQuestion.clear();
    _testStartTime = null;
    emit(const IQTestInitial());
  }

  // ──────────────────────── Timer Logic ─────────────────────────────────────

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), _onTimerTick);
  }

  void _onTimerTick(Timer timer) {
    final currentState = state;

    if (currentState is IQTestInProgress) {
      final newTimeRemaining = currentState.timeRemaining - 1;

      if (newTimeRemaining <= 0) {
        // Time's up - auto-submit
        _stopTimer();
        submitTest();
        return;
      }

      emit(currentState.copyWith(timeRemaining: newTimeRemaining));
    } else if (currentState is IQTestAnswered) {
      // Timer continues during the answered feedback state
      final newTimeRemaining = currentState.timeRemaining - 1;

      if (newTimeRemaining <= 0) {
        _stopTimer();
        // Emit an in-progress state so submitTest can use it
        emit(IQTestInProgress(
          questions: currentState.questions,
          currentIndex: currentState.currentIndex,
          answers: currentState.answers,
          timeRemaining: 0,
          selectedAnswer: currentState.selectedAnswer,
        ));
        submitTest();
        return;
      }
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ──────────────────────── Helpers ─────────────────────────────────────────

  void _moveToQuestion(
    List<IQQuestionModel> questions,
    int newIndex,
    Map<int, int> answers,
    int timeRemaining,
  ) {
    _currentQuestionStartSeconds = timeRemaining;

    final existingAnswer = answers[newIndex];

    emit(IQTestInProgress(
      questions: questions,
      currentIndex: newIndex,
      answers: answers,
      timeRemaining: timeRemaining,
      selectedAnswer: existingAnswer,
    ));
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}
