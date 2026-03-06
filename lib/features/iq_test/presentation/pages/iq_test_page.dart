import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/app_button.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/iq_test/presentation/cubits/iq_test_cubit.dart';
import 'package:lumoni/features/iq_test/presentation/cubits/iq_test_state.dart';
import 'package:lumoni/features/iq_test/presentation/widgets/answer_option.dart';
import 'package:lumoni/features/iq_test/presentation/widgets/question_card.dart';
import 'package:lumoni/features/iq_test/presentation/widgets/test_progress_bar.dart';
import 'package:lumoni/features/iq_test/presentation/widgets/test_timer.dart';

/// The main IQ test-taking page.
///
/// Manages question display, answer selection, navigation, timer, and
/// submission flow using the [IQTestCubit].
class IQTestPage extends StatelessWidget {
  const IQTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IQTestCubit()..startTest(),
      child: const _IQTestView(),
    );
  }
}

class _IQTestView extends StatelessWidget {
  const _IQTestView();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirmation(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<IQTestCubit, IQTestState>(
          listener: (context, state) {
            if (state is IQTestCompleted) {
              // Navigate to results page
              context.go('/iq-test/results', extra: {
                'result': state.result,
                'session': state.session,
              });
            } else if (state is IQTestLimitReached) {
              // Navigate to paywall
              context.go('/paywall', extra: 'iq_test_limit');
            }
          },
          builder: (context, state) {
            return switch (state) {
              IQTestLoading() => _buildLoading(),
              IQTestReady() => _buildReady(context, state),
              IQTestInProgress() => _buildInProgress(context, state),
              IQTestAnswered() => _buildAnswered(context, state),
              IQTestError() => _buildError(context, state),
              IQTestLimitReached() => _buildLoading(), // transitioning
              IQTestCompleted() => _buildLoading(), // transitioning
              IQTestInitial() => _buildLoading(),
            };
          },
        ),
      ),
    );
  }

  // ──────────────────────── Loading ──────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppSpacing.md),
          Text(
            'Preparing your test...',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Ready ───────────────────────────────────────────

  Widget _buildReady(BuildContext context, IQTestReady state) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_rounded,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Ready to Begin',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.totalQuestions} questions in ${AppConstants.testDurationMinutes} minutes',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Start Test',
              onPressed: () => context.read<IQTestCubit>().beginTest(),
              icon: Icons.play_arrow_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── In Progress ─────────────────────────────────────

  Widget _buildInProgress(BuildContext context, IQTestInProgress state) {
    return SafeArea(
      child: Column(
        children: [
          // Top bar: close, progress, timer
          _TestTopBar(
            currentIndex: state.currentIndex,
            totalQuestions: state.totalQuestions,
            answeredIndices: state.answers.keys.toSet(),
            timeRemaining: state.timeRemaining,
            onClose: () => _showExitConfirmation(context),
          ),

          // Scrollable question + answers area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _QuestionContent(
                key: ValueKey(state.currentIndex),
                state: state,
              ),
            ),
          ),

          // Bottom navigation
          _BottomNavigation(
            isFirstQuestion: state.isFirstQuestion,
            isLastQuestion: state.isLastQuestion,
            hasAnswered: state.answers.containsKey(state.currentIndex),
            onPrevious: () =>
                context.read<IQTestCubit>().previousQuestion(),
            onNext: () => context.read<IQTestCubit>().nextQuestion(),
            onSubmit: () => _showSubmitConfirmation(context, state),
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Answered (feedback) ─────────────────────────────

  Widget _buildAnswered(BuildContext context, IQTestAnswered state) {
    return SafeArea(
      child: Column(
        children: [
          _TestTopBar(
            currentIndex: state.currentIndex,
            totalQuestions: state.totalQuestions,
            answeredIndices: state.answers.keys.toSet(),
            timeRemaining: state.timeRemaining,
            onClose: () => _showExitConfirmation(context),
          ),
          Expanded(
            child: _AnsweredQuestionContent(state: state),
          ),
          _BottomNavigation(
            isFirstQuestion: state.currentIndex == 0,
            isLastQuestion: state.isLastQuestion,
            hasAnswered: true,
            isShowingFeedback: true,
            onPrevious: () {},
            onNext: () {},
            onSubmit: () {},
          ),
        ],
      ),
    );
  }

  // ──────────────────────── Error ───────────────────────────────────────────

  Widget _buildError(BuildContext context, IQTestError state) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Something went wrong',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Try Again',
              onPressed: () => context.read<IQTestCubit>().startTest(),
              icon: Icons.refresh_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Go Back',
              variant: AppButtonVariant.outlined,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Dialogs ─────────────────────────────────────────

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Text(
          'Leave Test?',
          style: AppTypography.heading5.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to leave? All progress will be lost and this will count as an incomplete test.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Continue Test',
              style: AppTypography.button.copyWith(color: AppColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<IQTestCubit>().reset();
              context.pop();
            },
            child: Text(
              'Leave',
              style: AppTypography.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitConfirmation(
      BuildContext context, IQTestInProgress state) {
    final unanswered = state.totalQuestions - state.answeredCount;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusXl,
        ),
        title: Text(
          'Submit Test?',
          style: AppTypography.heading5.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          unanswered > 0
              ? 'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. '
                  'Unanswered questions will be marked as incorrect. Submit anyway?'
              : 'You have answered all questions. Ready to see your results?',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Review Answers',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<IQTestCubit>().submitTest();
            },
            child: Text(
              'Submit',
              style: AppTypography.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

/// Top bar containing the close button, progress bar, and timer.
class _TestTopBar extends StatelessWidget {
  const _TestTopBar({
    required this.currentIndex,
    required this.totalQuestions,
    required this.answeredIndices,
    required this.timeRemaining,
    required this.onClose,
  });

  final int currentIndex;
  final int totalQuestions;
  final Set<int> answeredIndices;
  final int timeRemaining;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textSecondary,
            onPressed: onClose,
            tooltip: 'Leave test',
          ),

          // Progress
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: TestProgressBar(
                currentIndex: currentIndex,
                totalQuestions: totalQuestions,
                answeredIndices: answeredIndices,
              ),
            ),
          ),

          // Timer
          TestTimer(
            timeRemaining: timeRemaining,
            totalTime: AppConstants.testDurationSeconds,
            size: 52,
          ),
        ],
      ),
    );
  }
}

/// Displays the question card and answer options for an in-progress question.
class _QuestionContent extends StatelessWidget {
  const _QuestionContent({
    super.key,
    required this.state,
  });

  final IQTestInProgress state;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;
    final cubit = context.read<IQTestCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          QuestionCard(
            question: question,
            questionNumber: state.currentIndex + 1,
            totalQuestions: state.totalQuestions,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Answer options
          ...List.generate(question.answers.length, (index) {
            AnswerOptionState optionState;
            if (state.selectedAnswer == index) {
              optionState = AnswerOptionState.selected;
            } else {
              optionState = AnswerOptionState.idle;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AnswerOption(
                index: index,
                text: question.answers[index],
                optionState: optionState,
                onTap: () => cubit.selectAnswer(state.currentIndex, index),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Displays the question with correct/wrong answer feedback.
class _AnsweredQuestionContent extends StatelessWidget {
  const _AnsweredQuestionContent({required this.state});

  final IQTestAnswered state;

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuestionCard(
            question: question,
            questionNumber: state.currentIndex + 1,
            totalQuestions: state.totalQuestions,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Answer options with correct/wrong highlighting
          ...List.generate(question.answers.length, (index) {
            AnswerOptionState optionState;

            if (index == question.correctAnswerIndex) {
              optionState = AnswerOptionState.correct;
            } else if (index == state.selectedAnswer) {
              optionState = AnswerOptionState.wrong;
            } else {
              optionState = AnswerOptionState.idle;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AnswerOption(
                index: index,
                text: question.answers[index],
                optionState: optionState,
                isEnabled: false,
                onTap: () {},
              ),
            );
          }),

          // Brief explanation
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: (state.isCorrect
                        ? AppColors.success
                        : AppColors.error)
                    .withValues(alpha: 0.08),
                borderRadius: AppSpacing.borderRadiusMd,
                border: Border.all(
                  color: (state.isCorrect
                          ? AppColors.success
                          : AppColors.error)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    state.isCorrect
                        ? Icons.lightbulb_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: state.isCorrect
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom navigation with Previous, Next, and Submit buttons.
class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.isFirstQuestion,
    required this.isLastQuestion,
    required this.hasAnswered,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
    this.isShowingFeedback = false,
  });

  final bool isFirstQuestion;
  final bool isLastQuestion;
  final bool hasAnswered;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;
  final bool isShowingFeedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            if (!isFirstQuestion)
              Expanded(
                child: AppButton(
                  label: 'Previous',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.medium,
                  icon: Icons.arrow_back_rounded,
                  onPressed: isShowingFeedback ? null : onPrevious,
                ),
              )
            else
              const Expanded(child: SizedBox()),

            const SizedBox(width: AppSpacing.sm),

            // Next or Submit button
            Expanded(
              child: isLastQuestion
                  ? AppButton(
                      label: 'Submit',
                      size: AppButtonSize.medium,
                      icon: Icons.check_rounded,
                      gradient: const LinearGradient(
                        colors: [AppColors.success, Color(0xFF059669)],
                      ),
                      onPressed: isShowingFeedback ? null : onSubmit,
                    )
                  : AppButton(
                      label: 'Next',
                      size: AppButtonSize.medium,
                      icon: Icons.arrow_forward_rounded,
                      iconAlignment: IconAlignment.end,
                      onPressed: isShowingFeedback ? null : onNext,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
