import 'package:flutter/material.dart';

/// A reusable animation wrapper that fades and slides its [child] into view.
///
/// The animation triggers automatically when the widget is first inserted
/// into the tree. Use [delay] to stagger multiple items.
class FadeSlideTransition extends StatefulWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.offset = const Offset(0, 24),
    this.animate = true,
  });

  /// The widget to animate.
  final Widget child;

  /// Total animation duration.
  final Duration duration;

  /// Delay before the animation starts. Useful for staggering.
  final Duration delay;

  /// Animation curve.
  final Curve curve;

  /// The starting offset (in logical pixels) from which the child slides in.
  /// Defaults to 24 px from the bottom.
  final Offset offset;

  /// When `false`, the child is rendered immediately without animation.
  final bool animate;

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);

    if (widget.animate) {
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        Future.delayed(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
