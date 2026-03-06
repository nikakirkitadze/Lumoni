import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/animated_progress_bar.dart';
import 'package:lumoni/design_system/components/app_button.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/eq_test/presentation/cubits/eq_test_cubit.dart';
import 'package:lumoni/features/eq_test/presentation/cubits/eq_test_state.dart';
import 'package:lumoni/features/eq_test/presentation/widgets/eq_statement_card.dart';
import 'package:lumoni/features/eq_test/presentation/widgets/likert_scale.dart';

/// The main EQ assessment page showing one statement at a time with a
/// Likert scale, progress bar, and navigation controls.
class EQTestPage extends StatelessWidget {
  const EQTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<EQTestCubit, EQTestState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          if (state is EQTestLoading) {
            return const _LoadingView();
          }

          if (state is EQTestInProgress) {
            return _TestInProgressView(state: state);
          }

          if (state is EQTestCompleted) {
            return _CompletedView(state: state);
          }

          if (state is EQTestError) {
            return _ErrorView(message: state.message);
          }

          if (state is EQTestLimitReached) {
            return const _LimitReachedView();
          }

          // EQTestInitial - start the test.
          return const _LoadingView();
        },
      ),
    );
  }

  void _handleStateChanges(BuildContext context, EQTestState state) {
    if (state is EQTestCompleted) {
      HapticFeedback.heavyImpact();
    } else if (state is EQTestError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
        ),
      );
    }
  }
}

// ─────────────────────── Loading View ────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Preparing your assessment...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── In Progress View ───────────────────────────────

class _TestInProgressView extends StatelessWidget {
  const _TestInProgressView({required this.state});

  final EQTestInProgress state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EQTestCubit>();

    return SafeArea(
      child: Column(
        children: [
          // ── Header: close button, progress, counter ──
          _TestHeader(state: state),

          // ── Statement card + Likert scale ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Statement card.
                  EQStatementCard(
                    key: ValueKey(state.currentStatement.id),
                    statement: state.currentStatement,
                    statementNumber: state.currentIndex + 1,
                    totalStatements: state.totalStatements,
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Likert scale.
                  LikertScale(
                    selectedValue: state.currentAnswer,
                    onSelected: (value) {
                      cubit.answerStatement(state.currentIndex, value);
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // ── Bottom navigation ──
          _BottomNavigation(state: state),
        ],
      ),
    );
  }
}

// ─────────────────────── Test Header ────────────────────────────────────

class _TestHeader extends StatelessWidget {
  const _TestHeader({required this.state});

  final EQTestInProgress state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Close button.
              _CloseTestButton(onClose: () => _showExitDialog(context)),

              const SizedBox(width: AppSpacing.md),

              // Progress bar.
              Expanded(
                child: AnimatedProgressBar(
                  value: state.progress,
                  height: 6,
                  duration: const Duration(milliseconds: 400),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Answered count.
              Text(
                '${state.answers.length}/${state.totalStatements}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        title: Text(
          'Exit Assessment?',
          style: AppTypography.heading5.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Your progress will be lost. Are you sure you want to leave?',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Continue',
              style: AppTypography.button.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Exit',
              style: AppTypography.button.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true && context.mounted) {
      context.read<EQTestCubit>().reset();
      context.pop();
    }
  }
}

class _CloseTestButton extends StatelessWidget {
  const _CloseTestButton({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onClose();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// ─────────────────────── Bottom Navigation ──────────────────────────────

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({required this.state});

  final EQTestInProgress state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EQTestCubit>();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Previous button.
          if (!state.isFirstStatement)
            Expanded(
              child: AppButton(
                label: 'Previous',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.medium,
                icon: Icons.arrow_back_rounded,
                onPressed: cubit.previousStatement,
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: AppSpacing.md),

          // Next or Submit button.
          Expanded(
            child: state.isLastStatement
                ? AppButton(
                    label: 'Submit',
                    size: AppButtonSize.medium,
                    icon: Icons.check_rounded,
                    iconAlignment: IconAlignment.end,
                    isEnabled: state.allAnswered,
                    onPressed: state.allAnswered
                        ? () => cubit.submitTest()
                        : null,
                  )
                : AppButton(
                    label: 'Next',
                    size: AppButtonSize.medium,
                    icon: Icons.arrow_forward_rounded,
                    iconAlignment: IconAlignment.end,
                    isEnabled: state.isCurrentAnswered,
                    onPressed: state.isCurrentAnswered
                        ? cubit.nextStatement
                        : null,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Completed View ─────────────────────────────────

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.state});

  final EQTestCompleted state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Success icon.
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withValues(alpha: 0.8),
                    AppColors.accent.withValues(alpha: 0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            Text(
              'Assessment Complete!',
              style: AppTypography.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Your emotional intelligence profile is ready.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Overall score display.
            Text(
              state.result.overallScore.toStringAsFixed(0),
              style: AppTypography.scoreHero.copyWith(
                foreground: Paint()
                  ..shader = AppColors.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 120, 60),
                  ),
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              state.result.classification,
              style: AppTypography.heading5.copyWith(
                color: AppColors.accent,
              ),
            ),

            const Spacer(),

            // View results button.
            AppButton(
              label: 'View Detailed Results',
              icon: Icons.insights_rounded,
              onPressed: () {
                // Navigate to results page with the session data.
                context.push(
                  '/results/eq/${state.session.id}',
                  extra: state,
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            AppButton(
              label: 'Back to Home',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                context.read<EQTestCubit>().reset();
                context.go('/home');
              },
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Error View ─────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onPressed: () => context.read<EQTestCubit>().startTest(),
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
}

// ─────────────────────── Limit Reached View ─────────────────────────────

class _LimitReachedView extends StatelessWidget {
  const _LimitReachedView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 40,
                color: AppColors.warning.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Free Tests Used',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Upgrade to Lumoni Premium for unlimited assessments and detailed insights.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            AppButton(
              label: 'Unlock Premium',
              icon: Icons.star_rounded,
              gradient: AppColors.warmGradient,
              onPressed: () => context.push('/paywall'),
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
}
