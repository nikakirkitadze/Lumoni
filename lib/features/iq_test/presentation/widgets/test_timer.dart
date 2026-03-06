import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// A circular countdown timer with a progress ring, digital time display,
/// and color/animation changes based on remaining time.
class TestTimer extends StatefulWidget {
  const TestTimer({
    super.key,
    required this.timeRemaining,
    required this.totalTime,
    this.size = 64,
  });

  /// Remaining seconds.
  final int timeRemaining;

  /// Total seconds (for computing the progress fraction).
  final int totalTime;

  /// Diameter of the circular timer widget.
  final double size;

  @override
  State<TestTimer> createState() => _TestTimerState();
}

class _TestTimerState extends State<TestTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant TestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCritical && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!_isCritical && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isCritical => widget.timeRemaining < 120;

  bool get _isWarning =>
      widget.timeRemaining < 300 && widget.timeRemaining >= 120;

  Color get _timerColor {
    if (_isCritical) return AppColors.error;
    if (_isWarning) return AppColors.warning;
    return AppColors.textPrimary;
  }

  Color get _ringColor {
    if (_isCritical) return AppColors.error;
    if (_isWarning) return AppColors.warning;
    return AppColors.accent;
  }

  String get _formattedTime {
    final minutes = widget.timeRemaining ~/ 60;
    final seconds = widget.timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalTime > 0
        ? widget.timeRemaining / widget.totalTime
        : 0.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = _isCritical ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _TimerRingPainter(
            progress: progress,
            ringColor: _ringColor,
            trackColor: AppColors.surface,
            strokeWidth: 3.5,
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: AppTypography.buttonSmall.copyWith(
                color: _timerColor,
                fontWeight: FontWeight.w700,
                fontSize: widget.size * 0.22,
              ),
              child: Text(_formattedTime),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  _TimerRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = ringColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect at the tip of the arc
    if (progress > 0.01) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final glowPaint = Paint()
        ..color = ringColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(tipX, tipY), strokeWidth, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor;
}
