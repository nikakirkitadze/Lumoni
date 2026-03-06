import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A scale-down-on-tap animation wrapper.
///
/// When the user presses the child it scales down slightly, giving tactile
/// feedback. On release it springs back. Optionally triggers haptic feedback.
class ScaleTap extends StatefulWidget {
  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeInOut,
    this.haptic = true,
    this.enabled = true,
  });

  /// The widget to wrap.
  final Widget child;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long-press callback.
  final VoidCallback? onLongPress;

  /// How far to scale down (1.0 = no change, 0.9 = 90 %).
  final double scaleDown;

  /// Press animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Whether to trigger haptic feedback on tap.
  final bool haptic;

  /// When `false`, the child renders normally without tap handling.
  final bool enabled;

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: Duration(
        milliseconds: (widget.duration.inMilliseconds * 1.5).round(),
      ),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (!widget.enabled) return;
    if (widget.haptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: _onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
