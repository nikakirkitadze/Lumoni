import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Radar/pentagon chart showing the 5 EQ categories with gradient fill,
/// score labels at each vertex, and a glass card background.
class EQProfileChart extends StatefulWidget {
  const EQProfileChart({
    super.key,
    required this.categoryScores,
    this.size = 220,
    this.duration = const Duration(milliseconds: 1200),
  });

  /// Map of EQ category key to score (0-100).
  final Map<String, double> categoryScores;

  /// Chart diameter.
  final double size;

  /// Animation duration.
  final Duration duration;

  @override
  State<EQProfileChart> createState() => _EQProfileChartState();
}

class _EQProfileChartState extends State<EQProfileChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant EQProfileChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryScores != widget.categoryScores) {
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
    if (widget.categoryScores.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Complete an EQ test to see your profile',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    // Ensure categories are in canonical order.
    final orderedEntries = <MapEntry<String, double>>[];
    for (final cat in AppConstants.eqCategories) {
      if (widget.categoryScores.containsKey(cat)) {
        orderedEntries.add(MapEntry(cat, widget.categoryScores[cat]!));
      }
    }

    // If there are categories not in the canonical list, append them.
    for (final entry in widget.categoryScores.entries) {
      if (!AppConstants.eqCategories.contains(entry.key)) {
        orderedEntries.add(entry);
      }
    }

    final labelPadding = 50.0;
    final totalSize = widget.size + labelPadding * 2;

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'EQ Profile',
                style: AppTypography.heading5,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: totalSize,
            height: totalSize,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(totalSize, totalSize),
                  painter: _EQRadarPainter(
                    entries: orderedEntries,
                    progress: _animation.value,
                    labelPadding: labelPadding,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EQRadarPainter extends CustomPainter {
  _EQRadarPainter({
    required this.entries,
    required this.progress,
    required this.labelPadding,
  });

  final List<MapEntry<String, double>> entries;
  final double progress;
  final double labelPadding;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - labelPadding;
    final sides = entries.length;
    if (sides < 3) return;

    final angleStep = (2 * math.pi) / sides;
    const startAngle = -math.pi / 2;
    const gridRings = 4;

    // ── Grid rings ──
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int ring = 1; ring <= gridRings; ring++) {
      final ringRadius = radius * (ring / gridRings);
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
      ..color = AppColors.border.withValues(alpha: 0.15)
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
      final normalizedValue =
          (entries[index].value / 100).clamp(0.0, 1.0) * progress;
      final point = Offset(
        center.dx + radius * normalizedValue * math.cos(angle),
        center.dy + radius * normalizedValue * math.sin(angle),
      );
      dotPositions.add(point);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();

    // Gradient fill.
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.secondary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.15),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke.
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.secondary, AppColors.primary],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, strokePaint);

    // ── Dots at vertices ──
    final dotOutline = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    final dotFill = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;

    for (int i = 0; i < sides; i++) {
      canvas.drawCircle(dotPositions[i], 5, dotOutline);
      canvas.drawCircle(dotPositions[i], 3, dotFill);
    }

    // ── Labels and scores ──
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + angleStep * i;
      final labelDistance = radius + 24;
      final labelOffset = Offset(
        center.dx + labelDistance * math.cos(angle),
        center.dy + labelDistance * math.sin(angle),
      );

      final categoryKey = entries[i].key;
      final label =
          AppConstants.eqCategoryLabels[categoryKey] ?? categoryKey;
      final score = (entries[i].value * progress).round();

      // Category label.
      final labelSpan = TextSpan(
        text: label,
        style: AppTypography.captionSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      // Score value.
      final scoreSpan = TextSpan(
        text: '$score',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
      final scorePainter = TextPainter(
        text: scoreSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      // Position label and score together.
      final totalHeight = labelPainter.height + scorePainter.height + 2;
      final labelPos = Offset(
        labelOffset.dx - labelPainter.width / 2,
        labelOffset.dy - totalHeight / 2,
      );
      final scorePos = Offset(
        labelOffset.dx - scorePainter.width / 2,
        labelOffset.dy - totalHeight / 2 + labelPainter.height + 2,
      );

      labelPainter.paint(canvas, labelPos);
      scorePainter.paint(canvas, scorePos);
    }
  }

  @override
  bool shouldRepaint(covariant _EQRadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.entries != entries;
  }
}
