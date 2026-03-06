import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// An animated counter that counts from [begin] up (or down) to [end].
///
/// The value is displayed as an integer by default. Use [decimalPlaces] to
/// show fractional values. A [prefix] / [suffix] can be attached (e.g. "IQ: ",
/// "%").
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.end,
    this.begin = 0,
    this.duration = const Duration(milliseconds: 1200),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.decimalPlaces = 0,
    this.animate = true,
  });

  /// Target value.
  final double end;

  /// Starting value. Defaults to 0.
  final double begin;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Text style. Defaults to [AppTypography.statValue].
  final TextStyle? style;

  /// String prepended to the value.
  final String prefix;

  /// String appended to the value.
  final String suffix;

  /// Number of decimal places to display.
  final int decimalPlaces;

  /// Set to `false` to show the final value immediately.
  final bool animate;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _buildAnimation();

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  void _buildAnimation() {
    _animation = Tween<double>(begin: widget.begin, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.end != widget.end || oldWidget.begin != widget.begin) {
      _buildAnimation();
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style =
        widget.style ?? AppTypography.statValue.copyWith(color: AppColors.textPrimary);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final value = widget.decimalPlaces > 0
            ? _animation.value.toStringAsFixed(widget.decimalPlaces)
            : _animation.value.round().toString();

        return Text(
          '${widget.prefix}$value${widget.suffix}',
          style: style,
        );
      },
    );
  }
}
