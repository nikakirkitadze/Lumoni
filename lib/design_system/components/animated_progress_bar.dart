import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// An animated progress bar with gradient fill and optional percentage label.
///
/// The bar animates from 0 to [value] on first build and whenever [value]
/// changes.
class AnimatedProgressBar extends StatefulWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.trackColor,
    this.borderRadius,
    this.showLabel = false,
    this.labelStyle,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
  }) : assert(value >= 0 && value <= 1, 'value must be between 0.0 and 1.0');

  /// Current progress value between 0.0 and 1.0.
  final double value;

  /// Height of the bar.
  final double height;

  /// Fill gradient. Defaults to [AppColors.progressGradient].
  final Gradient? gradient;

  /// Track (background) color. Defaults to [AppColors.surface].
  final Color? trackColor;

  /// Border radius. Defaults to fully rounded.
  final BorderRadius? borderRadius;

  /// Whether to display the percentage label to the right of the bar.
  final bool showLabel;

  /// Label text style override.
  final TextStyle? labelStyle;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _animation = Tween<double>(begin: _previousValue, end: widget.value)
          .animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
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
    final effectiveBorderRadius =
        widget.borderRadius ?? AppSpacing.borderRadiusFull;
    final effectiveTrackColor = widget.trackColor ?? AppColors.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final animatedValue = _animation.value;
        final percentage = (animatedValue * 100).round();

        Widget bar = Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: effectiveTrackColor,
            borderRadius: effectiveBorderRadius,
          ),
          child: ClipRRect(
            borderRadius: effectiveBorderRadius,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: animatedValue.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: widget.gradient ?? AppColors.progressGradient,
                    borderRadius: effectiveBorderRadius,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        if (!widget.showLabel) return bar;

        return Row(
          children: [
            Expanded(child: bar),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 40,
              child: Text(
                '$percentage%',
                style: widget.labelStyle ??
                    AppTypography.captionSmall
                        .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        );
      },
    );
  }
}
