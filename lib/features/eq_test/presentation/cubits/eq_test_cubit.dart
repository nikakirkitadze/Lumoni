import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/models/eq_question_model.dart';
import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/core/utils/eq_score_calculator.dart';
import 'package:lumoni/features/eq_test/data/datasources/eq_statement_bank.dart';
import 'package:lumoni/features/eq_test/data/repositories/eq_test_repository.dart';
import 'package:lumoni/features/eq_test/presentation/cubits/eq_test_state.dart';

/// Cubit managing the full EQ assessment lifecycle.
///
/// Flow: [startTest] -> [answerStatement] -> [nextStatement] / [previousStatement]
/// -> [submitTest].
///
/// EQ tests are untimed - there is no countdown timer.
class EQTestCubit extends Cubit<EQTestState> {
  final EQTestRepository _repository;

  /// Timestamp recorded when the test begins, used to compute elapsed time.
  DateTime? _startTime;

  EQTestCubit({
    required EQTestRepository repository,
  })  : _repository = repository,
        super(const EQTestInitial());

  // ────────────────────────── Start Test ────────────────────────────────

  /// Loads EQ statements from the local bank, randomizes their order, and
  /// transitions to [EQTestInProgress].
  ///
  /// Selects [AppConstants.maxEQQuestions] statements, balanced across the
  /// five EQ categories.
  Future<void> startTest() async {
    emit(const EQTestLoading());

    try {
      // Check if the user has remaining free tests.
      final canTakeTest = await _repository.canTakeTest();
      if (!canTakeTest) {
        emit(const EQTestLimitReached());
        return;
      }

      // Load all statements from the local bank.
      final allStatements = EQStatementBank.getAllStatements();

      // Select a balanced subset across all categories.
      final selected = _selectBalancedStatements(
        allStatements,
        AppConstants.maxEQQuestions,
      );

      // Randomize order to reduce ordering bias.
      selected.shuffle();

      _startTime = DateTime.now();

      emit(EQTestInProgress(
        statements: selected,
        currentIndex: 0,
        answers: const {},
        totalStatements: selected.length,
      ));
    } catch (e) {
      debugPrint('[EQTestCubit] startTest error: $e');
      emit(EQTestError('Failed to start EQ assessment: $e'));
    }
  }

  // ────────────────────────── Answer Statement ─────────────────────────

  /// Records a Likert-scale response for the statement at [index].
  ///
  /// [likertValue] must be between [AppConstants.likertMin] (1) and
  /// [AppConstants.likertMax] (5).
  void answerStatement(int index, int likertValue) {
    final currentState = state;
    if (currentState is! EQTestInProgress) return;

    assert(
      likertValue >= AppConstants.likertMin &&
          likertValue <= AppConstants.likertMax,
      'Likert value must be between ${AppConstants.likertMin} and ${AppConstants.likertMax}',
    );

    final updatedAnswers = Map<int, int>.from(currentState.answers);
    updatedAnswers[index] = likertValue;

    emit(currentState.copyWith(answers: updatedAnswers));
  }

  // ────────────────────────── Navigation ────────────────────────────────

  /// Advances to the next statement if one exists.
  void nextStatement() {
    final currentState = state;
    if (currentState is! EQTestInProgress) return;

    if (currentState.currentIndex < currentState.totalStatements - 1) {
      emit(currentState.copyWith(
        currentIndex: currentState.currentIndex + 1,
      ));
    }
  }

  /// Goes back to the previous statement if one exists.
  void previousStatement() {
    final currentState = state;
    if (currentState is! EQTestInProgress) return;

    if (currentState.currentIndex > 0) {
      emit(currentState.copyWith(
        currentIndex: currentState.currentIndex - 1,
      ));
    }
  }

  /// Jumps directly to a specific statement by [index].
  void goToStatement(int index) {
    final currentState = state;
    if (currentState is! EQTestInProgress) return;

    if (index >= 0 && index < currentState.totalStatements) {
      emit(currentState.copyWith(currentIndex: index));
    }
  }

  // ────────────────────────── Submit Test ───────────────────────────────

  /// Calculates EQ scores from all answers, persists the session, and
  /// transitions to [EQTestCompleted].
  ///
  /// Requires all statements to be answered before submission.
  Future<void> submitTest() async {
    final currentState = state;
    if (currentState is! EQTestInProgress) return;

    if (!currentState.allAnswered) {
      emit(const EQTestError(
        'Please answer all statements before submitting.',
      ));
      // Restore the in-progress state so the user can continue.
      emit(currentState);
      return;
    }

    emit(const EQTestLoading());

    try {
      // Convert index-based answers to question-ID-based answers for the
      // calculator, which expects Map<String, int> (questionId -> likertValue).
      final idBasedAnswers = <String, int>{};
      for (final entry in currentState.answers.entries) {
        final questionId = currentState.statements[entry.key].id;
        idBasedAnswers[questionId] = entry.value;
      }

      // Calculate EQ scores.
      final calculator = EQScoreCalculator();
      final result = calculator.calculate(
        questions: currentState.statements,
        answers: idBasedAnswers,
      );

      // Compute elapsed time.
      final endTime = DateTime.now();
      final elapsedSeconds =
          endTime.difference(_startTime ?? endTime).inSeconds;

      // Build session model.
      final session = TestSessionModel(
        id: const Uuid().v4(),
        userId: await _repository.getCurrentUserId(),
        testType: TestType.eq,
        startedAt: _startTime ?? endTime,
        completedAt: endTime,
        score: result.overallScore,
        categoryScores: result.categoryScores,
        questionIds:
            currentState.statements.map((s) => s.id).toList(),
        answers: idBasedAnswers,
        timeSpentSeconds: elapsedSeconds,
      );

      // Persist session.
      await _repository.saveTestSession(session);

      // Increment free test counter.
      await _repository.incrementTestCount();

      emit(EQTestCompleted(result: result, session: session));
    } catch (e) {
      debugPrint('[EQTestCubit] submitTest error: $e');
      emit(EQTestError('Failed to submit EQ assessment: $e'));
    }
  }

  // ────────────────────────── Reset ────────────────────────────────────

  /// Resets the cubit to the initial state.
  void reset() {
    _startTime = null;
    emit(const EQTestInitial());
  }

  // ────────────────────────── Helpers ───────────────────────────────────

  /// Selects a balanced set of statements across all EQ categories.
  ///
  /// Each category gets an equal share of [total] statements. If a category
  /// has fewer items than its quota, all items from that category are included
  /// and the remaining quota is redistributed.
  List<EQQuestionModel> _selectBalancedStatements(
    List<EQQuestionModel> all,
    int total,
  ) {
    final byCategory = <String, List<EQQuestionModel>>{};
    for (final s in all) {
      byCategory.putIfAbsent(s.category, () => []).add(s);
    }

    // Shuffle within each category for variety.
    for (final list in byCategory.values) {
      list.shuffle();
    }

    final categories = AppConstants.eqCategories;
    final perCategory = total ~/ categories.length;
    final remainder = total % categories.length;

    final selected = <EQQuestionModel>[];

    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final available = byCategory[category] ?? [];
      final quota = perCategory + (i < remainder ? 1 : 0);
      final count = quota.clamp(0, available.length);
      selected.addAll(available.take(count));
    }

    return selected;
  }
}
