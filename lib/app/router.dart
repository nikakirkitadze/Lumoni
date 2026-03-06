import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/app/shell_page.dart';
import 'package:lumoni/design_system/design_system.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:lumoni/features/auth/presentation/cubits/auth_state.dart';
import 'package:lumoni/core/di/injection.dart';
import 'package:lumoni/core/services/auth_service.dart';
import 'package:lumoni/core/services/firebase_service.dart';
import 'package:lumoni/features/auth/presentation/pages/login_page.dart';
import 'package:lumoni/features/auth/presentation/pages/splash_page.dart';
import 'package:lumoni/features/eq_test/data/repositories/eq_test_repository.dart';
import 'package:lumoni/features/eq_test/presentation/cubits/eq_test_cubit.dart';
import 'package:lumoni/features/eq_test/presentation/pages/eq_test_intro_page.dart';
import 'package:lumoni/features/eq_test/presentation/pages/eq_test_page.dart';
import 'package:lumoni/features/home/presentation/cubits/home_cubit.dart';
import 'package:lumoni/features/home/presentation/pages/home_page.dart';
import 'package:lumoni/features/insights/presentation/cubits/insights_cubit.dart';
import 'package:lumoni/features/insights/presentation/pages/insights_page.dart';
import 'package:lumoni/features/iq_test/presentation/cubits/iq_test_cubit.dart';
import 'package:lumoni/features/iq_test/presentation/pages/iq_test_intro_page.dart';
import 'package:lumoni/features/iq_test/presentation/pages/iq_test_page.dart';
import 'package:lumoni/features/onboarding/presentation/cubits/onboarding_cubit.dart';
import 'package:lumoni/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:lumoni/features/paywall/presentation/pages/paywall_page.dart';
import 'package:lumoni/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:lumoni/features/profile/presentation/pages/profile_page.dart';
import 'package:lumoni/features/results/presentation/cubits/results_cubit.dart';
import 'package:lumoni/features/results/presentation/pages/results_page.dart';
import 'package:lumoni/features/share_card/presentation/cubits/share_card_cubit.dart';
import 'package:lumoni/features/share_card/presentation/pages/share_card_builder_page.dart';

// ─── Route paths ───────────────────────────────────────────────────────────

/// Centralized route path constants.
abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String insights = '/insights';
  static const String profile = '/profile';
  static const String iqTestIntro = '/iq-test/intro';
  static const String iqTest = '/iq-test';
  static const String eqTestIntro = '/eq-test/intro';
  static const String eqTest = '/eq-test';
  static const String results = '/results/:sessionId';
  static const String paywall = '/paywall';
  static const String shareCard = '/share-card/:sessionId';
}

/// The global GoRouter configuration for the Lumoni app.
///
/// Includes redirect logic for authentication, shell routes for the bottom
/// navigation bar, and custom page transitions.
final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: false,
  routes: [
    // ── Splash ────────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.splash,
      pageBuilder: (context, state) => _fadeTransitionPage(
        key: state.pageKey,
        child: const SplashPage(),
      ),
    ),

    // ── Onboarding ────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.onboarding,
      pageBuilder: (context, state) => _fadeTransitionPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => OnboardingCubit(),
          child: const OnboardingPage(),
        ),
      ),
    ),

    // ── Login ─────────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.login,
      pageBuilder: (context, state) => _fadeTransitionPage(
        key: state.pageKey,
        child: const LoginPage(),
      ),
    ),

    // ── Shell Route (Bottom Navigation) ───────────────────────────────
    ShellRoute(
      builder: (context, state, child) => ShellPage(child: child),
      routes: [
        GoRoute(
          path: RoutePaths.home,
          pageBuilder: (context, state) => _fadeTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) {
                String? userId;
                if (FirebaseService.instance.isInitialized) {
                  try {
                    userId = getIt<AuthService>().currentUser?.uid;
                  } catch (_) {}
                }
                return HomeCubit(userId: userId ?? 'guest')..loadDashboard();
              },
              child: const HomePage(),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.insights,
          pageBuilder: (context, state) => _fadeTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => InsightsCubit()..loadInsights(),
              child: const InsightsPage(),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.profile,
          pageBuilder: (context, state) => _fadeTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => ProfileCubit()..loadProfile(),
              child: const ProfilePage(),
            ),
          ),
        ),
      ],
    ),

    // ── IQ Test ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.iqTestIntro,
      pageBuilder: (context, state) => _slideTransitionPage(
        key: state.pageKey,
        child: const IQTestIntroPage(),
      ),
    ),
    GoRoute(
      path: RoutePaths.iqTest,
      pageBuilder: (context, state) => _slideTransitionPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => IQTestCubit()..startTest(),
          child: const IQTestPage(),
        ),
      ),
    ),

    // ── EQ Test ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.eqTestIntro,
      pageBuilder: (context, state) => _slideTransitionPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => EQTestCubit(repository: EQTestRepository()),
          child: const EQTestIntroPage(),
        ),
      ),
    ),
    GoRoute(
      path: RoutePaths.eqTest,
      pageBuilder: (context, state) => _slideTransitionPage(
        key: state.pageKey,
        child: BlocProvider(
          create: (_) => EQTestCubit(repository: EQTestRepository())..startTest(),
          child: const EQTestPage(),
        ),
      ),
    ),

    // ── Results ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.results,
      pageBuilder: (context, state) {
        final sessionId = state.pathParameters['sessionId'] ?? '';
        return _slideTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => ResultsCubit()..loadResults(sessionId),
            child: ResultsPage(sessionId: sessionId),
          ),
        );
      },
    ),

    // ── Share Card ──────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.shareCard,
      pageBuilder: (context, state) {
        final sessionId = state.pathParameters['sessionId'] ?? '';
        return _slideTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => ShareCardCubit()..loadSession(sessionId),
            child: const ShareCardBuilderPage(),
          ),
        );
      },
    ),

    // ── Paywall ───────────────────────────────────────────────────────
    GoRoute(
      path: RoutePaths.paywall,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PaywallPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
      ),
    ),
  ],

  // ── Error page ────────────────────────────────────────────────────
  errorBuilder: (context, state) => _ErrorPage(error: state.error),

  // ── Redirect Logic ────────────────────────────────────────────────
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    final currentPath = state.uri.path;

    // Public routes that do not require authentication.
    const publicRoutes = [
      RoutePaths.splash,
      RoutePaths.onboarding,
      RoutePaths.login,
    ];

    final isPublicRoute = publicRoutes.contains(currentPath);

    // If the auth state is still initial or loading, stay on splash.
    if (authState is AuthInitial || authState is AuthLoading) {
      return isPublicRoute ? null : RoutePaths.splash;
    }

    // Guest mode: allow access to most routes except certain premium ones.
    if (authState is AuthGuest) {
      if (currentPath == RoutePaths.splash ||
          currentPath == RoutePaths.login) {
        return RoutePaths.home;
      }
      return null;
    }

    // Authenticated user on a public route: redirect to home.
    if (authState is AuthAuthenticated) {
      if (currentPath == RoutePaths.splash ||
          currentPath == RoutePaths.login) {
        return RoutePaths.home;
      }
      return null;
    }

    // Unauthenticated user trying to access a protected route.
    if (authState is AuthUnauthenticated) {
      if (!isPublicRoute) {
        return RoutePaths.login;
      }
      return null;
    }

    // AuthError: redirect to login.
    if (authState is AuthError && !isPublicRoute) {
      return RoutePaths.login;
    }

    return null;
  },
);

// ─── Page transition helpers ─────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
  );
}

CustomTransitionPage<void> _slideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.5),
          ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}

/// Error page shown for unknown routes.
class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Page not found',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(
              onPressed: () => context.go(RoutePaths.home),
              child: Text(
                'Go Home',
                style: AppTypography.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
