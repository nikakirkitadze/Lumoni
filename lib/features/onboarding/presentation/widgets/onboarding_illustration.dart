import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';

/// Renders a custom-painted illustration for a given onboarding [pageIndex].
///
/// - Page 0: Abstract brain pattern with connected dots and lines
/// - Page 1: Bar chart / assessment visualization
/// - Page 2: Upward growth / rocket pattern
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.pageIndex,
    this.animationValue = 1.0,
  });

  final int pageIndex;

  /// A 0-1 animation value that drives subtle drawing effects.
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OnboardingPainter(
        pageIndex: pageIndex,
        animationValue: animationValue,
      ),
      size: Size.infinite,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPainter extends CustomPainter {
  _OnboardingPainter({
    required this.pageIndex,
    required this.animationValue,
  });

  final int pageIndex;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    switch (pageIndex) {
      case 0:
        _paintBrainNetwork(canvas, size);
        break;
      case 1:
        _paintAssessmentChart(canvas, size);
        break;
      case 2:
        _paintGrowthRocket(canvas, size);
        break;
    }
  }

  // ─────────────── Page 0: Brain Network ──────────────────────────────────

  void _paintBrainNetwork(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.38;

    // Outer glow circle
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.25 * animationValue),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3));
    canvas.drawCircle(center, radius * 1.3, glowPaint);

    // Generate node positions in a brain-like symmetrical pattern
    final random = math.Random(42);
    final nodes = <Offset>[];

    // Central cluster
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final r = radius * (0.2 + random.nextDouble() * 0.15);
      nodes.add(center + Offset(math.cos(angle) * r, math.sin(angle) * r));
    }

    // Middle ring
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * 2 * math.pi + 0.15;
      final r = radius * (0.45 + random.nextDouble() * 0.15);
      nodes.add(center + Offset(math.cos(angle) * r, math.sin(angle) * r));
    }

    // Outer ring
    for (var i = 0; i < 16; i++) {
      final angle = (i / 16) * 2 * math.pi;
      final r = radius * (0.75 + random.nextDouble() * 0.2);
      nodes.add(center + Offset(math.cos(angle) * r, math.sin(angle) * r));
    }

    // Draw connections between nearby nodes
    final linePaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < radius * 0.55) {
          final opacity = ((1.0 - dist / (radius * 0.55)) * 0.4 * animationValue)
              .clamp(0.0, 1.0);
          linePaint.color = AppColors.primary.withValues(alpha: opacity);
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw nodes with gradient dots
    for (var i = 0; i < nodes.length; i++) {
      final isInner = i < 8;
      final isMid = i >= 8 && i < 20;
      final nodeRadius = isInner ? 5.0 : (isMid ? 3.5 : 2.5);

      final Color color;
      if (isInner) {
        color = AppColors.accent;
      } else if (isMid) {
        color = AppColors.primary400;
      } else {
        color = AppColors.primary300;
      }

      final dotPaint = Paint()
        ..color = color.withValues(alpha: animationValue)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(nodes[i], nodeRadius * animationValue, dotPaint);

      // Solid center
      final solidPaint = Paint()..color = color.withValues(alpha: animationValue);
      canvas.drawCircle(nodes[i], nodeRadius * 0.6 * animationValue, solidPaint);
    }

    // Central brain icon highlight
    final centerGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.3 * animationValue),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.25));
    canvas.drawCircle(center, radius * 0.25, centerGlow);
  }

  // ─────────────── Page 1: Assessment Chart ──────────────────────────────

  void _paintAssessmentChart(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final chartWidth = size.width * 0.7;
    final chartHeight = size.height * 0.5;
    final baseX = center.dx - chartWidth / 2;
    final baseY = center.dy + chartHeight * 0.3;

    // Background glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.secondary.withValues(alpha: 0.15 * animationValue),
          AppColors.secondary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.45));
    canvas.drawCircle(center, size.shortestSide * 0.45, glowPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3 * animationValue)
      ..strokeWidth = 0.8;

    for (var i = 0; i <= 4; i++) {
      final y = baseY - (i / 4) * chartHeight;
      canvas.drawLine(
        Offset(baseX, y),
        Offset(baseX + chartWidth, y),
        gridPaint,
      );
    }

    // Bar data (5 bars representing IQ/EQ categories)
    final barHeights = [0.65, 0.82, 0.55, 0.9, 0.72];
    final barColors = [
      AppColors.primary,
      AppColors.primary400,
      AppColors.secondary,
      AppColors.accent,
      AppColors.primary300,
    ];

    final barCount = barHeights.length;
    final barGap = chartWidth * 0.06;
    final totalGaps = barGap * (barCount + 1);
    final barWidth = (chartWidth - totalGaps) / barCount;

    for (var i = 0; i < barCount; i++) {
      final x = baseX + barGap + i * (barWidth + barGap);
      final height = chartHeight * barHeights[i] * animationValue;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, baseY - height, barWidth, height),
        const Radius.circular(6),
      );

      // Bar gradient fill
      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            barColors[i],
            barColors[i].withValues(alpha: 0.6),
          ],
        ).createShader(barRect.outerRect);
      canvas.drawRRect(barRect, barPaint);

      // Bar glow
      final barGlowPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            barColors[i].withValues(alpha: 0.0),
            barColors[i].withValues(alpha: 0.2 * animationValue),
          ],
        ).createShader(barRect.outerRect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(barRect, barGlowPaint);

      // Small dot indicator on top
      final dotCenter = Offset(x + barWidth / 2, baseY - height - 8);
      final dotPaint = Paint()
        ..color = barColors[i].withValues(alpha: animationValue);
      canvas.drawCircle(dotCenter, 3, dotPaint);
    }

    // Trend line overlay
    final trendPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.6 * animationValue)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trendPath = Path();
    for (var i = 0; i < barCount; i++) {
      final x = baseX + barGap + i * (barWidth + barGap) + barWidth / 2;
      final y = baseY - chartHeight * barHeights[i] * animationValue - 16;
      if (i == 0) {
        trendPath.moveTo(x, y);
      } else {
        trendPath.lineTo(x, y);
      }
    }
    canvas.drawPath(trendPath, trendPaint);
  }

  // ─────────────── Page 2: Growth / Rocket ──────────────────────────────

  void _paintGrowthRocket(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.shortestSide * 0.01;

    // Background radial glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.2 * animationValue),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: unit * 42));
    canvas.drawCircle(center, unit * 42, glowPaint);

    // Rising arrow / rocket trail
    final trailPath = Path();
    final trailStartY = center.dy + unit * 30;
    final trailEndY = center.dy - unit * 30 * animationValue;

    // Curved upward path
    trailPath.moveTo(center.dx, trailStartY);
    trailPath.quadraticBezierTo(
      center.dx - unit * 8,
      center.dy + unit * 5,
      center.dx,
      trailEndY,
    );

    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.0),
          AppColors.primary.withValues(alpha: 0.5 * animationValue),
          AppColors.accent.withValues(alpha: 0.8 * animationValue),
        ],
      ).createShader(Rect.fromLTWH(
        center.dx - unit * 10,
        trailEndY,
        unit * 20,
        trailStartY - trailEndY,
      ))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(trailPath, trailPaint);

    // Exhaust particles along the trail
    final particleRandom = math.Random(99);
    for (var i = 0; i < 20; i++) {
      final t = i / 20.0;
      final py = trailStartY + (trailEndY - trailStartY) * t;
      final spread = unit * (8 - 6 * t);
      final px = center.dx + (particleRandom.nextDouble() - 0.5) * spread;
      final particleSize = unit * (0.5 + particleRandom.nextDouble() * 1.2) * (1 - t);

      final particlePaint = Paint()
        ..color = Color.lerp(
          AppColors.primary,
          AppColors.accent,
          t,
        )!
            .withValues(alpha: (0.6 * (1 - t) * animationValue).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), particleSize, particlePaint);
    }

    // Rocket tip (diamond / chevron shape)
    final tipCenter = Offset(center.dx, trailEndY - unit * 2);
    final rocketPath = Path()
      ..moveTo(tipCenter.dx, tipCenter.dy - unit * 8)
      ..lineTo(tipCenter.dx + unit * 4, tipCenter.dy + unit * 2)
      ..lineTo(tipCenter.dx + unit * 2, tipCenter.dy + unit * 5)
      ..lineTo(tipCenter.dx, tipCenter.dy + unit * 3)
      ..lineTo(tipCenter.dx - unit * 2, tipCenter.dy + unit * 5)
      ..lineTo(tipCenter.dx - unit * 4, tipCenter.dy + unit * 2)
      ..close();

    final rocketPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: animationValue),
          AppColors.primary.withValues(alpha: 0.8 * animationValue),
        ],
      ).createShader(Rect.fromCenter(
        center: tipCenter,
        width: unit * 8,
        height: unit * 13,
      ));
    canvas.drawPath(rocketPath, rocketPaint);

    // Glow around the rocket tip
    final tipGlow = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.3 * animationValue)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(tipCenter, unit * 6, tipGlow);

    // Stars / sparkles around
    _drawSparkles(canvas, size, center, unit);

    // Orbital rings suggesting growth
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (var i = 0; i < 3; i++) {
      final ringRadius = unit * (18 + i * 10);
      ringPaint.color = AppColors.primary.withValues(
        alpha: (0.15 - i * 0.04) * animationValue,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * 0.3);

      final ringRect = Rect.fromCenter(
        center: Offset.zero,
        width: ringRadius * 2,
        height: ringRadius * 1.2,
      );
      canvas.drawOval(ringRect, ringPaint);
      canvas.restore();
    }
  }

  void _drawSparkles(Canvas canvas, Size size, Offset center, double unit) {
    final sparklePositions = [
      Offset(center.dx - unit * 25, center.dy - unit * 20),
      Offset(center.dx + unit * 22, center.dy - unit * 18),
      Offset(center.dx + unit * 30, center.dy + unit * 5),
      Offset(center.dx - unit * 28, center.dy + unit * 10),
      Offset(center.dx + unit * 10, center.dy - unit * 30),
      Offset(center.dx - unit * 15, center.dy - unit * 28),
    ];

    for (var i = 0; i < sparklePositions.length; i++) {
      final sparkleSize = unit * (1.5 + (i % 3) * 0.8);
      final alpha = (0.4 + (i % 3) * 0.15) * animationValue;
      final color = i.isEven ? AppColors.accent : AppColors.primary300;

      _drawFourPointStar(
        canvas,
        sparklePositions[i],
        sparkleSize,
        color.withValues(alpha: alpha.clamp(0.0, 1.0)),
      );
    }
  }

  void _drawFourPointStar(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size * 0.3, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size * 0.3, center.dy)
      ..close()
      ..moveTo(center.dx - size, center.dy)
      ..lineTo(center.dx, center.dy + size * 0.3)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy - size * 0.3)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _OnboardingPainter oldDelegate) =>
      oldDelegate.pageIndex != pageIndex ||
      oldDelegate.animationValue != animationValue;
}
