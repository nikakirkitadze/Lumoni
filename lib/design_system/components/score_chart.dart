import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// A data point for the radar chart.
class ScoreChartData {
  const ScoreChartData({
    required this.label,
    required this.value,
    this.maxValue = 100,
  });

  /// Category label (e.g. "Logic", "Memory").
  final String label;

  /// Score value.
  final double value;

  /// Maximum possible value for normalization.
  final double maxValue;

  /// Normalized value between 0 and 1.
  double get normalized => (value / maxValue).clamp(0.0, 1.0);
}

/// A radar/spider chart that displays category scores with animation.
///
/// Renders a polygon for each data ring using [CustomPainter]. The scores
/// animate from 0 to their target values on first build.
class ScoreChart extends StatefulWidget {
  const ScoreChart({
    super.key,
    required this.data,
    this.size = 220,
    this.rings = 4,
    this.fillColor,
    this.strokeColor,
    this.gridColor,
    this.labelStyle,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOutCubic,
    this.showLabels = true,
  }) : assert(data.length >= 3, 'At least 3 data points are required');

  /// Score data for each axis.
  final List<ScoreChartData> data;

  /// Widget size (width = height).
  final double size;

  /// Number of concentric grid rings.
  final int rings;

  /// Fill color with opacity. Defaults to primary at 20 %.
  final Color? fillColor;

  /// Stroke color. Defaults to primary.
  final Color? strokeColor;

  /// Grid line color.
  final Color? gridColor;

  /// Label text style override.
  final TextStyle? labelStyle;

  /// Animation duration.
  final Duration duration;

  /// Animation curve.
  final Curve curve;

  /// Whether to show axis labels.
  final bool showLabels;

  @override
  State<ScoreChart> createState() => _ScoreChartState();
}

class _ScoreChartState extends State<ScoreChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ScoreChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
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
    // The outer box is sized to accommodate labels around the chart.
    final labelPadding = widget.showLabels ? 40.0 : 0.0;
    final totalSize = widget.size + labelPadding * 2;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            size: Size(totalSize, totalSize),
            painter: _ScoreChartPainter(
              data: widget.data,
              progress: _animation.value,
              rings: widget.rings,
              fillColor: widget.fillColor ??
                  AppColors.primary.withValues(alpha: 0.2),
              strokeColor: widget.strokeColor ?? AppColors.primary,
              gridColor: widget.gridColor ??
                  AppColors.border.withValues(alpha: 0.4),
              labelStyle: widget.labelStyle ?? AppTypography.captionSmall,
              showLabels: widget.showLabels,
              labelPadding: labelPadding,
            ),
          );
        },
      ),
    );
  }
}

class _ScoreChartPainter extends CustomPainter {
  _ScoreChartPainter({
    required this.data,
    required this.progress,
    required this.rings,
    required this.fillColor,
    required this.strokeColor,
    required this.gridColor,
    required this.labelStyle,
    required this.showLabels,
    required this.labelPadding,
  });

  final List<ScoreChartData> data;
  final double progress;
  final int rings;
  final Color fillColor;
  final Color strokeColor;
  final Color gridColor;
  final TextStyle labelStyle;
  final bool showLabels;
  final double labelPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - labelPadding;
    final sides = data.length;
    final angleStep = (2 * math.pi) / sides;
    // Start from the top (-pi/2).
    const startAngle = -math.pi / 2;

    // ── Grid rings ──
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int ring = 1; ring <= rings; ring++) {
      final ringRadius = radius * (ring / rings);
      final path = Path();
      for (int i = 0; i <= sides; i++) {
        final angle = startAngle + angleStep * (i % sides);
        final point = Offset(
          center.dx + ringRadius * math.cos(angle),
          center.dy + ringRadius * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // ── Axis lines ──
    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final endpoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, endpoint, axisPaint);
    }

    // ── Data polygon ──
    final dataPath = Path();
    final dotPositions = <Offset>[];

    for (int i = 0; i <= sides; i++) {
      final index = i % sides;
      final angle = startAngle + angleStep * index;
      final value = data[index].normalized * progress;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );
      dotPositions.add(point);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    // Fill.
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke.
    final strokePaintLine = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, strokePaintLine);

    // Dots on each vertex.
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    final dotOutline = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;

    for (int i = 0; i < sides; i++) {
      canvas.drawCircle(dotPositions[i], 4, dotOutline);
      canvas.drawCircle(dotPositions[i], 2.5, dotPaint);
    }

    // ── Labels ──
    if (showLabels) {
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + angleStep * i;
        final labelOffset = Offset(
          center.dx + (radius + 18) * math.cos(angle),
          center.dy + (radius + 18) * math.sin(angle),
        );

        final textSpan = TextSpan(text: data[i].label, style: labelStyle);
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout();

        // Center the label around its anchor point.
        final offset = Offset(
          labelOffset.dx - textPainter.width / 2,
          labelOffset.dy - textPainter.height / 2,
        );
        textPainter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.data != data;
  }
}
