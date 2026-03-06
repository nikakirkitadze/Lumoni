import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/app_button.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/components/score_chart.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/insights/presentation/cubits/insights_cubit.dart';
import 'package:lumoni/features/insights/presentation/cubits/insights_state.dart';
import 'package:lumoni/features/insights/presentation/widgets/eq_profile_chart.dart';
import 'package:lumoni/features/insights/presentation/widgets/iq_timeline_chart.dart';
import 'package:lumoni/features/insights/presentation/widgets/premium_lock_overlay.dart';
import 'package:lumoni/features/insights/presentation/widgets/strength_weakness_card.dart';
import 'package:lumoni/features/results/presentation/widgets/improvement_card.dart';

/// Analytics dashboard page displaying the user's intelligence profile
/// with charts, strengths, weaknesses, and personalized recommendations.
///
/// Some sections are gated behind premium for free users.
class InsightsPage extends StatefulWidget {
  const InsightsPage({
    super.key,
    this.isPremium = false,
  });

  /// Whether the current user has premium access.
  final bool isPremium;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<InsightsCubit, InsightsState>(
        listener: (context, state) {
          if (state is InsightsLoaded) {
            _fadeController.forward();
          }
        },
        builder: (context, state) {
          if (state is InsightsLoading || state is InsightsInitial) {
            return _buildLoadingState();
          }

          if (state is InsightsError) {
            return _buildErrorState(state.message);
          }

          if (state is InsightsLoaded) {
            return _buildInsightsContent(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ──────────────────────── Loading State ─────────────────────────────

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Analyzing your intelligence data...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
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
              'Unable to load insights',
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
              label: 'Try Again',
              variant: AppButtonVariant.outlined,
              onPressed: () {
                context.read<InsightsCubit>().loadInsights();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── Insights Content ─────────────────────────

  Widget _buildInsightsContent(InsightsLoaded state) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header.
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppSpacing.md,
                left: AppSpacing.xl,
                right: AppSpacing.xl,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Intelligence Profile',
                    style: AppTypography.heading2,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      _TrendBadge(trend: state.overallTrend),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${state.totalTests} tests completed',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Quick stats row.
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingHorizontalXl,
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Avg IQ',
                      value: state.averageIQ > 0
                          ? state.averageIQ.round().toString()
                          : '--',
                      icon: Icons.psychology_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      title: 'Avg EQ',
                      value: state.averageEQ > 0
                          ? state.averageEQ.round().toString()
                          : '--',
                      icon: Icons.favorite_rounded,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      title: 'Tests',
                      value: '${state.totalTests}',
                      icon: Icons.assignment_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // IQ Progress Timeline (free users see this).
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingHorizontalXl,
              child: IQTimelineChart(
                dataPoints: state.iqHistory,
                averageScore: state.averageIQ,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // EQ Profile Radar Chart (premium gated).
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.paddingHorizontalXl,
              child: PremiumLockOverlay(
                isLocked: !widget.isPremium,
                title: 'EQ Profile Analysis',
                subtitle: 'Unlock your full emotional intelligence profile',
                child: EQProfileChart(
                  categoryScores: state.latestEQCategoryScores,
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // Strengths section.
          if (state.strengths.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AppColors.success,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Your Strengths',
                      style: AppTypography.heading5,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverPadding(
              padding: AppSpacing.paddingHorizontalXl,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return StrengthWeaknessCard(
                      insight: state.strengths[index],
                      isStrength: true,
                    );
                  },
                  childCount: state.strengths.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],

          // Weaknesses section (premium gated).
          if (state.weaknesses.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.warning,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Areas to Improve',
                      style: AppTypography.heading5,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: PremiumLockOverlay(
                  isLocked: !widget.isPremium,
                  title: 'Weakness Analysis',
                  subtitle: 'Get detailed insights on where to improve',
                  child: Column(
                    children: state.weaknesses
                        .map((w) => StrengthWeaknessCard(
                              insight: w,
                              isStrength: false,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],

          // IQ Category Radar (premium for full detail).
          if (state.latestIQCategoryScores.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: PremiumLockOverlay(
                  isLocked: !widget.isPremium,
                  title: 'IQ Category Profile',
                  subtitle: 'See your cognitive strengths in detail',
                  child: GlassCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                gradient: AppColors.accentGradient,
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                              child: const Icon(
                                Icons.radar_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Cognitive Profile',
                              style: AppTypography.heading5,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: ScoreChart(
                            data: state.latestIQCategoryScores.entries
                                .map((e) => ScoreChartData(
                                      label: AppConstants
                                              .iqCategoryLabels[e.key] ??
                                          e.key,
                                      value: e.value,
                                      maxValue: 100,
                                    ))
                                .toList(),
                            size: 200,
                            fillColor: AppColors.accent.withValues(alpha: 0.2),
                            strokeColor: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          ],

          // Recommended exercises.
          if (state.recommendations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Recommended Exercises',
                      style: AppTypography.heading5,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xs)),
            SliverToBoxAdapter(
              child: Padding(
                padding: AppSpacing.paddingHorizontalXl,
                child: Text(
                  'Personalized activities based on your performance',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
            SliverPadding(
              padding: AppSpacing.paddingHorizontalXl,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return PremiumLockOverlay(
                      isLocked: !widget.isPremium && index > 0,
                      title: 'More Recommendations',
                      subtitle: 'Unlock all personalized exercises',
                      child: ImprovementCard(
                        tip: state.recommendations[index],
                        index: index,
                      ),
                    );
                  },
                  childCount: state.recommendations.length,
                ),
              ),
            ),
          ],

          // Bottom spacing.
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + AppSpacing.huge,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge showing the overall performance trend.
class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend});

  final PerformanceTrend trend;

  @override
  Widget build(BuildContext context) {
    final color = switch (trend) {
      PerformanceTrend.improving => AppColors.success,
      PerformanceTrend.stable => AppColors.accent,
      PerformanceTrend.declining => AppColors.warning,
    };

    final icon = switch (trend) {
      PerformanceTrend.improving => Icons.trending_up_rounded,
      PerformanceTrend.stable => Icons.trending_flat_rounded,
      PerformanceTrend.declining => Icons.trending_down_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            trend.label,
            style: AppTypography.captionSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small stat card for the quick-stats row.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.statValue.copyWith(
              color: color,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.captionSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
