import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:lumoni/core/models/test_session_model.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/features/home/domain/entities/daily_insight.dart';
import 'package:lumoni/features/home/presentation/cubits/home_cubit.dart';
import 'package:lumoni/features/home/presentation/cubits/home_state.dart';
import 'package:lumoni/features/home/presentation/widgets/greeting_header.dart';
import 'package:lumoni/features/home/presentation/widgets/premium_banner.dart';
import 'package:lumoni/features/home/presentation/widgets/recent_score_card.dart';
import 'package:lumoni/features/home/presentation/widgets/test_action_card.dart';
import 'package:lumoni/features/home/presentation/widgets/weekly_progress_chart.dart';

/// The main dashboard page of the Lumoni app.
///
/// Displays a greeting header, IQ/EQ test action cards, daily insight,
/// recent scores, weekly progress chart, and an optional premium upsell
/// banner. Each section fades and slides in with a staggered entrance
/// animation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Staggered entrance animations -- one per dashboard section.
  static const int _sectionCount = 6;
  static const Duration _sectionDelay = Duration(milliseconds: 80);
  static const Duration _sectionDuration = Duration(milliseconds: 500);

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();

    _controllers = List.generate(
      _sectionCount,
      (i) => AnimationController(vsync: this, duration: _sectionDuration),
    );

    _fadeAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(c))
        .toList();

    _slideAnimations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .map((c) =>
            Tween<Offset>(begin: const Offset(0, 24), end: Offset.zero)
                .animate(c))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Triggers the staggered entrance animation for all sections.
  void _playEntrance() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(_sectionDelay * i, () {
        if (mounted) _controllers[i].forward(from: 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<HomeCubit, HomeState>(
        listener: (context, state) {
          if (state is HomeLoaded) {
            _playEntrance();
          }
        },
        builder: (context, state) {
          return switch (state) {
            HomeInitial() => _buildShimmerLoading(),
            HomeLoading() => _buildShimmerLoading(),
            HomeError(:final message) => _buildError(context, message),
            HomeLoaded() => _buildLoaded(context, state),
          };
        },
      ),
    );
  }

  // ─────────────────────── Loaded State ──────────────────────────────

  Widget _buildLoaded(BuildContext context, HomeLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<HomeCubit>().refreshData(),
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Safe area top padding.
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.top + AppSpacing.xs,
            ),
          ),

          // ── 0: Greeting Header ────────────────────────────────
          SliverToBoxAdapter(
            child: _animatedSection(
              index: 0,
              child: GreetingHeader(
                displayName: state.user.displayName,
                photoUrl: state.user.photoUrl,
                isPremium: state.user.isPremium,
                onAvatarTap: () => context.push('/profile'),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.lg),
          ),

          // ── 1: Test Action Cards ──────────────────────────────
          SliverToBoxAdapter(
            child: _animatedSection(
              index: 1,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: TestActionCard(
                          type: TestCardType.iq,
                          onTap: () => context.push('/iq-test/intro'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 180,
                        child: TestActionCard(
                          type: TestCardType.eq,
                          onTap: () => context.push('/eq-test/intro'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),

          // ── 2: Daily Insight ──────────────────────────────────
          SliverToBoxAdapter(
            child: _animatedSection(
              index: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: _buildDailyInsight(state.dailyInsight),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),

          // ── 3: Recent Scores ──────────────────────────────────
          SliverToBoxAdapter(
            child: _animatedSection(
              index: 3,
              child: _buildRecentScoresSection(state.recentSessions),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),

          // ── 4: Weekly Progress Chart ──────────────────────────
          SliverToBoxAdapter(
            child: _animatedSection(
              index: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: WeeklyProgressChart(data: state.weeklyProgress),
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl),
          ),

          // ── 5: Premium Banner (conditional) ───────────────────
          if (!state.user.isPremium)
            SliverToBoxAdapter(
              child: _animatedSection(
                index: 5,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: PremiumBanner(
                    onUpgrade: () => context.push('/paywall'),
                  ),
                ),
              ),
            ),

          // Bottom padding so content doesn't sit behind nav bar.
          SliverToBoxAdapter(
            child: SizedBox(
              height:
                  MediaQuery.of(context).padding.bottom + AppSpacing.huge,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Animated section wrapper ─────────────────────

  Widget _animatedSection({required int index, required Widget child}) {
    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimations[index].value,
          child: Transform.translate(
            offset: _slideAnimations[index].value,
            child: child,
          ),
        );
      },
    );
  }

  // ─────────────────── Daily Insight Card ───────────────────────────

  Widget _buildDailyInsight(DailyInsight insight) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ─────────────────────────────────────────────
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              insight.icon,
              color: AppColors.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // ── Text content ─────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        'Daily Insight',
                        style: AppTypography.captionSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      insight.category,
                      style: AppTypography.captionSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  insight.title,
                  style: AppTypography.heading6.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  insight.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── Recent Scores Section ────────────────────────

  Widget _buildRecentScoresSection(List<TestSessionModel> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Scores', style: AppTypography.heading5),
              if (sessions.isNotEmpty)
                GestureDetector(
                  onTap: () => context.push('/results'),
                  child: Text(
                    'See all',
                    style: AppTypography.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: _buildEmptyScoresPlaceholder(),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: sessions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return RecentScoreCard(
                  session: sessions[index],
                  onTap: () =>
                      context.push('/results/${sessions[index].id}'),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyScoresPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No tests yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Complete your first test to see scores here',
            style: AppTypography.caption.copyWith(
              color: AppColors.textDisabled,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─────────────────── Error State ──────────────────────────────────

  Widget _buildError(BuildContext context, String message) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Something went wrong',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () =>
                      context.read<HomeCubit>().loadDashboard(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: AppTypography.button.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── Shimmer Loading ──────────────────────────────

  Widget _buildShimmerLoading() {
    return SafeArea(
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header shimmer.
              Row(
                children: [
                  _shimmerCircle(48),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _shimmerBox(80, 12),
                      const SizedBox(height: AppSpacing.xs),
                      _shimmerBox(140, 18),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Action cards shimmer.
              Row(
                children: [
                  Expanded(child: _shimmerBox(double.infinity, 180)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _shimmerBox(double.infinity, 180)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Daily insight shimmer.
              _shimmerBox(double.infinity, 120),
              const SizedBox(height: AppSpacing.xl),

              // Recent scores section shimmer.
              _shimmerBox(120, 20),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 180,
                child: Row(
                  children: [
                    _shimmerBox(160, 180),
                    const SizedBox(width: AppSpacing.sm),
                    _shimmerBox(160, 180),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Chart shimmer.
              _shimmerBox(double.infinity, 260),
              const SizedBox(height: AppSpacing.xl),

              // Banner shimmer.
              _shimmerBox(double.infinity, 180),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    );
  }

  Widget _shimmerCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
    );
  }
}
