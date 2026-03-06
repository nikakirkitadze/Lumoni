import 'package:flutter/material.dart';

/// A fade page route transition.
///
/// ```dart
/// Navigator.of(context).push(FadePageRoute(page: const MyPage()));
/// ```
class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required this.page,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 250),
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (_, _, _) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
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
        );

  /// The destination page widget.
  final Widget page;
}

/// A slide page route transition that enters from the right.
///
/// ```dart
/// Navigator.of(context).push(SlidePageRoute(page: const MyPage()));
/// ```
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.right,
    Duration duration = const Duration(milliseconds: 350),
    Duration reverseDuration = const Duration(milliseconds: 300),
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (_, _, _) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final begin = _offsetForDirection(direction);
            final tween = Tween<Offset>(begin: begin, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0, 0.5),
                ),
                child: child,
              ),
            );
          },
        );

  /// The destination page widget.
  final Widget page;

  /// Slide direction.
  final SlideDirection direction;

  static Offset _offsetForDirection(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.right:
        return const Offset(1, 0);
      case SlideDirection.left:
        return const Offset(-1, 0);
      case SlideDirection.up:
        return const Offset(0, 1);
      case SlideDirection.down:
        return const Offset(0, -1);
    }
  }
}

/// Direction from which a [SlidePageRoute] enters.
enum SlideDirection {
  right,
  left,
  up,
  down,
}

/// A combined fade + slide up transition, ideal for modal-style pages.
class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  FadeSlidePageRoute({
    required this.page,
    Duration duration = const Duration(milliseconds: 400),
    Duration reverseDuration = const Duration(milliseconds: 300),
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (_, _, _) => page,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );

  /// The destination page widget.
  final Widget page;
}
