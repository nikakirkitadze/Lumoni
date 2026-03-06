import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/features/onboarding/presentation/cubits/onboarding_cubit.dart';
import 'package:lumoni/features/onboarding/presentation/widgets/onboarding_illustration.dart';

/// Three-screen onboarding flow for first-time users.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _illustrationAnimController;
  late final Animation<double> _illustrationAnimation;

  static const _pages = [
    _OnboardingContent(
      title: 'Discover Your\nIntelligence',
      description:
          'Understand your cognitive abilities with beautifully crafted assessments powered by proven psychological science.',
      pageIndex: 0,
    ),
    _OnboardingContent(
      title: 'Measure\nIQ & EQ',
      description:
          'Take scientifically-designed tests that evaluate both your intellectual and emotional intelligence with precision.',
      pageIndex: 1,
    ),
    _OnboardingContent(
      title: 'Unlock Your\nPotential',
      description:
          'Receive personalized insights and track your growth over time with detailed analytics and actionable recommendations.',
      pageIndex: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _illustrationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _illustrationAnimation = CurvedAnimation(
      parent: _illustrationAnimController,
      curve: Curves.easeOutCubic,
    );
    _illustrationAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    context.read<OnboardingCubit>().goToPage(page);
    _illustrationAnimController.reset();
    _illustrationAnimController.forward();
  }

  Future<void> _onGetStarted() async {
    await context.read<OnboardingCubit>().completeOnboarding();
    if (mounted) context.go('/login');
  }

  void _onSkip() async {
    await context.read<OnboardingCubit>().completeOnboarding();
    if (mounted) context.go('/login');
  }

  void _onNext() {
    final cubit = context.read<OnboardingCubit>();
    if (cubit.state.isLastPage) {
      _onGetStarted();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // Background decorative gradients
              _BackgroundDecoration(currentPage: state.currentPage),

              // PageView content
              Column(
                children: [
                  // Skip button area
                  SizedBox(
                    height: padding.top + 16,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!state.isLastPage)
                          GestureDetector(
                            onTap: _onSkip,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Text(
                                'Skip',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Page content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _PageContent(
                          content: _pages[index],
                          animationValue: _illustrationAnimation,
                          screenSize: size,
                        );
                      },
                    ),
                  ),

                  // Bottom controls
                  _BottomControls(
                    pageController: _pageController,
                    currentPage: state.currentPage,
                    isLastPage: state.isLastPage,
                    onNext: _onNext,
                    onGetStarted: _onGetStarted,
                  ),

                  SizedBox(height: padding.bottom + AppSpacing.lg),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal data class for onboarding content
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingContent {
  const _OnboardingContent({
    required this.title,
    required this.description,
    required this.pageIndex,
  });

  final String title;
  final String description;
  final int pageIndex;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page content widget
// ─────────────────────────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.content,
    required this.animationValue,
    required this.screenSize,
  });

  final _OnboardingContent content;
  final Animation<double> animationValue;
  final Size screenSize;

  @override
  Widget build(BuildContext context) {
    final illustrationHeight = screenSize.height * 0.38;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Illustration area
          SizedBox(
            height: illustrationHeight,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: animationValue,
              builder: (context, child) {
                return OnboardingIllustration(
                  pageIndex: content.pageIndex,
                  animationValue: animationValue.value,
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.xxxl),

          // Title
          AnimatedBuilder(
            animation: animationValue,
            builder: (context, _) {
              return Opacity(
                opacity: animationValue.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - animationValue.value)),
                  child: Text(
                    content.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.15,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          AnimatedBuilder(
            animation: animationValue,
            builder: (context, _) {
              final delayed =
                  ((animationValue.value - 0.2) / 0.8).clamp(0.0, 1.0);
              return Opacity(
                opacity: delayed,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - delayed)),
                  child: Text(
                    content.description,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              );
            },
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom controls with page indicator and button
// ─────────────────────────────────────────────────────────────────────────────

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.pageController,
    required this.currentPage,
    required this.isLastPage,
    required this.onNext,
    required this.onGetStarted,
  });

  final PageController pageController;
  final int currentPage;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator
          SmoothPageIndicator(
            controller: pageController,
            count: OnboardingState.totalPages,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.primary,
              dotColor: AppColors.border,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 3,
              spacing: 6,
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Action button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: isLastPage
                ? _GradientButton(
                    key: const ValueKey('getStarted'),
                    label: 'Get Started',
                    onTap: onGetStarted,
                  )
                : _GradientButton(
                    key: const ValueKey('next'),
                    label: 'Continue',
                    onTap: onNext,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient action button
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatefulWidget {
  const _GradientButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressController.reverse(),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: AppSpacing.borderRadiusMd,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTypography.buttonLarge.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background decoration with animated gradient circles
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Different gradient positions per page for visual variety
    final configs = [
      // Page 0
      [
        _GlowConfig(
          Alignment(-0.6, -0.4),
          size.width * 0.6,
          AppColors.primary.withValues(alpha: 0.12),
        ),
        _GlowConfig(
          Alignment(0.7, -0.2),
          size.width * 0.4,
          AppColors.accent.withValues(alpha: 0.08),
        ),
      ],
      // Page 1
      [
        _GlowConfig(
          Alignment(0.5, -0.5),
          size.width * 0.55,
          AppColors.secondary.withValues(alpha: 0.1),
        ),
        _GlowConfig(
          Alignment(-0.6, 0.0),
          size.width * 0.45,
          AppColors.primary.withValues(alpha: 0.08),
        ),
      ],
      // Page 2
      [
        _GlowConfig(
          Alignment(0.0, -0.6),
          size.width * 0.5,
          AppColors.accent.withValues(alpha: 0.1),
        ),
        _GlowConfig(
          Alignment(-0.5, -0.3),
          size.width * 0.5,
          AppColors.primary.withValues(alpha: 0.08),
        ),
      ],
    ];

    final glows = configs[currentPage.clamp(0, 2)];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: SizedBox(
        key: ValueKey(currentPage),
        width: size.width,
        height: size.height,
        child: Stack(
          children: glows.map((glow) {
            return Align(
              alignment: glow.alignment,
              child: Container(
                width: glow.radius,
                height: glow.radius,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [glow.color, glow.color.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GlowConfig {
  const _GlowConfig(this.alignment, this.radius, this.color);
  final Alignment alignment;
  final double radius;
  final Color color;
}
