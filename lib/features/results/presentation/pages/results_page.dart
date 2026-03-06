import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/app_button.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/components/score_chart.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/results/presentation/cubits/results_cubit.dart';
import 'package:lumoni/features/results/presentation/cubits/results_state.dart';
import 'package:lumoni/features/results/presentation/widgets/category_breakdown.dart';
import 'package:lumoni/features/results/presentation/widgets/improvement_card.dart';
import 'package:lumoni/features/results/presentation/widgets/score_reveal_animation.dart';

/// Full-screen results page with a multi-phase animated reveal sequence.
///
/// Phase 1: "Calculating your score..." with pulsing animation (2s).
/// Phase 2: Animated score reveal with counting number.
/// Phase 3: Category breakdown with staggered bars.
/// Phase 4: Radar chart and improvement tips.
class ResultsPage extends StatefulWidget {
  const ResultsPage({
    super.key,
    required this.sessionId,
  });

  /// The test session ID to load results for.
  final String sessionId;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with TickerProviderStateMixin {
  // ── Phase controllers ────────────────────────────────────────────────

  /// Current reveal phase (0 = calculating, 1-4 = reveal phases).
  int _currentPhase = 0;

  late final AnimationController _calculatingController;
  late final Animation<double> _calculatingPulse;
  late final Animation<double> _calculatingDots;

  late final AnimationController _phase2Controller;
  late final Animation<double> _phase2Fade;

  late final AnimationController _phase3Controller;
  late final Animation<double> _phase3Fade;

  late final AnimationController _phase4Controller;
  late final Animation<double> _phase4Fade;

  late final AnimationController _bgParticleController;

  @override
  void initState() {
    super.initState();

    // Calculating phase animation (pulsing dots).
    _calculatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _calculatingPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _calculatingController, curve: Curves.easeInOut),
    );
    _calculatingDots = Tween<double>(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _calculatingController, curve: Curves.linear),
    );

    // Phase 2: Score reveal fade-in.
    _phase2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _phase2Fade = CurvedAnimation(
      parent: _phase2Controller,
      curve: Curves.easeOut,
    );

    // Phase 3: Category breakdown fade-in.
    _phase3Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _phase3Fade = CurvedAnimation(
      parent: _phase3Controller,
      curve: Curves.easeOut,
    );

    // Phase 4: Charts + tips + buttons.
    _phase4Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _phase4Fade = CurvedAnimation(
      parent: _phase4Controller,
      curve: Curves.easeOut,
    );

    // Background subtle animation.
    _bgParticleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _calculatingController.dispose();
    _phase2Controller.dispose();
    _phase3Controller.dispose();
    _phase4Controller.dispose();
    _bgParticleController.dispose();
    super.dispose();
  }

  /// Kicks off the reveal sequence once results are loaded.
  Future<void> _startRevealSequence() async {
    // Phase 0: Show calculating animation for 2 seconds.
    setState(() => _currentPhase = 0);
    _calculatingController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Phase 1 -> 2: Fade out calculating, reveal score.
    _calculatingController.stop();
    setState(() => _currentPhase = 2);
    _phase2Controller.forward();

    // Wait for score count-up to finish.
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Phase 3: Category breakdown.
    setState(() => _currentPhase = 3);
    _phase3Controller.forward();

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Phase 4: Radar chart, tips, and action buttons.
    setState(() => _currentPhase = 4);
    _phase4Controller.forward();
  }

  bool _sequenceStarted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<ResultsCubit, ResultsState>(
        listener: (context, state) {
          if (state is ResultsLoaded && !_sequenceStarted) {
            _sequenceStarted = true;
            _startRevealSequence();
          }
        },
        builder: (context, state) {
          if (state is ResultsLoading || state is ResultsInitial) {
            return _buildCalculatingPhase();
          }

          if (state is ResultsError) {
            return _buildErrorState(state.message);
          }

          if (state is ResultsLoaded) {
            return _buildResultsContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ──────────────────────── Phase 0: Calculating ──────────────────────

  Widget _buildCalculatingPhase() {
    return Stack(
      children: [
        _buildBackgroundDecoration(),
        Center(
          child: AnimatedBuilder(
            animation: _calculatingPulse,
            builder: (context, _) {
              return Opacity(
                opacity: _calculatingPulse.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing brain icon.
                    Transform.scale(
                      scale: 0.8 + _calculatingPulse.value * 0.2,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.4 * _calculatingPulse.value),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedBuilder(
                      animation: _calculatingDots,
                      builder: (context, _) {
                        final dots = '.' * (_calculatingDots.value.floor() + 1);
                        return Text(
                          'Calculating your score$dots',
                          style: AppTypography.heading4.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Analyzing your responses',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────── Main Results Content ─────────────────────

  Widget _buildResultsContent(ResultsLoaded state) {
    return Stack(
      children: [
        _buildBackgroundDecoration(),

        // Scrollable content.
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top safe area padding.
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + AppSpacing.md),
            ),

            // Close button.
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: Align(
                  alignment: Alignment.topRight,
                  child: _currentPhase >= 4
                      ? FadeTransition(
                          opacity: _phase4Fade,
                          child: GestureDetector(
                            onTap: () => context.go('/home'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(height: 40),
                ),
              ),
            ),

            // Phase 2: Score reveal.
            if (_currentPhase >= 2)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _phase2Fade,
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.isIQ
                            ? 'Your IQ Score'
                            : 'Your EQ Score',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: ScoreRevealAnimation(
                          score: state.isIQ
                              ? state.iqScore
                              : state.eqScore.round(),
                          label: state.isIQ
                              ? state.iqClassification
                              : state.eqClassification,
                          subtitle: state.isIQ
                              ? 'Top ${(100 - state.iqPercentile).toStringAsFixed(0)}%'
                              : null,
                          isIQ: state.isIQ,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),

            // Phase 3: Category breakdown.
            if (_currentPhase >= 3)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _phase3Fade,
                  child: Padding(
                    padding: AppSpacing.paddingHorizontalXl,
                    child: GlassCard(
                      child: CategoryBreakdown(
                        categoryScores: state.categoryScores,
                        isIQ: state.isIQ,
                      ),
                    ),
                  ),
                ),
              ),

            // Phase 4: Radar chart.
            if (_currentPhase >= 4) ...[
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _phase4Fade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: GlassCard(
                      child: Column(
                        children: [
                          Text(
                            'Score Profile',
                            style: AppTypography.heading5,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Center(
                            child: ScoreChart(
                              data: _buildChartData(state),
                              size: 200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Time spent.
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _phase4Fade,
                  child: Padding(
                    padding: AppSpacing.paddingHorizontalXl,
                    child: GlassCard(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: AppSpacing.borderRadiusMd,
                            ),
                            child: const Icon(
                              Icons.timer_rounded,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Spent',
                                style: AppTypography.bodySmall,
                              ),
                              Text(
                                _formatDuration(state.session.duration),
                                style: AppTypography.heading5.copyWith(
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Questions',
                                style: AppTypography.bodySmall,
                              ),
                              Text(
                                '${state.session.answeredCount}/${state.session.totalQuestions}',
                                style: AppTypography.heading5,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Improvement tips.
              if (state.improvementTips.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _phase4Fade,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        top: AppSpacing.lg,
                      ),
                      child: Text(
                        'Improvement Tips',
                        style: AppTypography.heading4,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _phase4Fade,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.xl,
                        right: AppSpacing.xl,
                        top: AppSpacing.sm,
                        bottom: AppSpacing.xs,
                      ),
                      child: Text(
                        'Based on your results, here are some personalized recommendations:',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.paddingHorizontalXl,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FadeTransition(
                          opacity: _phase4Fade,
                          child: ImprovementCard(
                            tip: state.improvementTips[index],
                            index: index,
                          ),
                        );
                      },
                      childCount: state.improvementTips.length,
                    ),
                  ),
                ),
              ],

              // Action buttons.
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _phase4Fade,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      children: [
                        // Share button.
                        AppButton(
                          label: 'Share Results',
                          icon: Icons.share_rounded,
                          variant: AppButtonVariant.primary,
                          onPressed: () {
                            context.read<ResultsCubit>().shareResults();
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Back to home button.
                        AppButton(
                          label: 'Back to Home',
                          variant: AppButtonVariant.outlined,
                          icon: Icons.home_rounded,
                          onPressed: () => context.go('/home'),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom safe area.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ──────────────────────── Error State ──────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingAllXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong',
              style: AppTypography.heading4,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Back to Home',
              variant: AppButtonVariant.outlined,
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Background ────────────────────────────────

  Widget _buildBackgroundDecoration() {
    return AnimatedBuilder(
      animation: _bgParticleController,
      builder: (context, _) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BackgroundPainter(
            progress: _bgParticleController.value,
          ),
        );
      },
    );
  }

  // ──────────────────────── Helpers ──────────────────────────────────

  List<ScoreChartData> _buildChartData(ResultsLoaded state) {
    final labels = state.isIQ
        ? AppConstants.iqCategoryLabels
        : AppConstants.eqCategoryLabels;

    return state.categoryScores.entries.map((entry) {
      return ScoreChartData(
        label: labels[entry.key] ?? entry.key,
        value: entry.value,
        maxValue: 100,
      );
    }).toList();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}

/// Paints subtle animated shapes on the background for a premium feel.
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle gradient orbs that slowly move.
    final paint1 = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final paint2 = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final paint3 = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.03)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Slowly drifting orbs.
    final offset1 = Offset(
      size.width * 0.3 + math.sin(progress * 2 * math.pi) * 40,
      size.height * 0.2 + math.cos(progress * 2 * math.pi) * 30,
    );
    final offset2 = Offset(
      size.width * 0.7 + math.cos(progress * 2 * math.pi + 1) * 50,
      size.height * 0.5 + math.sin(progress * 2 * math.pi + 1) * 40,
    );
    final offset3 = Offset(
      size.width * 0.5 + math.sin(progress * 2 * math.pi + 2) * 30,
      size.height * 0.8 + math.cos(progress * 2 * math.pi + 2) * 35,
    );

    canvas.drawCircle(offset1, 120, paint1);
    canvas.drawCircle(offset2, 150, paint2);
    canvas.drawCircle(offset3, 100, paint3);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
