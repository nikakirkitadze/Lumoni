import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/local_storage_service.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Animated splash screen shown on cold start.
///
/// Displays the Lumoni brand, then auto-navigates after a short delay:
/// - First-time launch -> onboarding
/// - Authenticated user -> home
/// - Otherwise -> login
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final AnimationController _subtitleController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _subtitleFade;

  @override
  void initState() {
    super.initState();

    // Logo fade-in
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Logo scale
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );

    // Subtitle fade
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _subtitleFade = CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    );

    // Start animation sequence
    _fadeController.forward();
    _scaleController.forward();

    // Subtitle appears with a slight delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _subtitleController.forward();
    });

    // Navigate after splash duration
    Future.delayed(AppConstants.splashDuration, _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    try {
      final storage = getIt<LocalStorageService>();
      final authService = getIt<AuthService>();

      final onboardingCompleted = storage.getOnboardingCompleted();

      if (!onboardingCompleted) {
        if (mounted) context.go('/onboarding');
        return;
      }

      final currentUser = authService.currentUser;
      if (currentUser != null) {
        if (mounted) context.go('/home');
      } else {
        if (mounted) context.go('/login');
      }
    } catch (_) {
      // Fallback: always allow the user to proceed to login on error
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle background gradient
          _SplashBackground(size: size),

          // Centered logo content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decorative glow behind the logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                                colors: [Colors.white, Colors.white70],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'L',
                            style: AppTypography.heading1.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Brand name with gradient
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        'Lumoni',
                        style: AppTypography.display.copyWith(
                          fontSize: 44,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: Text(
                        'Premium Intelligence Platform',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom loading indicator
          Positioned(
            bottom: MediaQuery.paddingOf(context).bottom + 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleFade,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top gradient
        Positioned(
          top: -size.height * 0.15,
          left: -size.width * 0.1,
          child: Container(
            width: size.width * 0.8,
            height: size.width * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        // Bottom gradient
        Positioned(
          bottom: -size.height * 0.1,
          right: -size.width * 0.1,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.06),
                  AppColors.secondary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
