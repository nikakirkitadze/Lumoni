import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/glass_card.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/features/insights/presentation/cubits/insights_state.dart';

/// Line chart showing IQ scores over time using fl_chart.
///
/// Features: gradient line, dot markers, dashed average line, tooltips,
/// and a glass card background.
class IQTimelineChart extends StatelessWidget {
  const IQTimelineChart({
    super.key,
    required this.dataPoints,
    required this.averageScore,
  });

  /// IQ score data points ordered chronologically.
  final List<ScoreDataPoint> dataPoints;

  /// The average IQ score (shown as a dashed reference line).
  final double averageScore;

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'Complete an IQ test to see your progress',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'IQ Progress',
                style: AppTypography.heading5,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Avg: ${averageScore.round()}',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          SizedBox(
            height: 220,
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    // Map data points to FlSpot coordinates.
    final spots = <FlSpot>[];
    for (int i = 0; i < dataPoints.length; i++) {
      spots.add(FlSpot(i.toDouble(), dataPoints[i].score));
    }

    // Determine Y-axis range.
    final minScore = dataPoints
        .fold<double>(150, (min, p) => p.score < min ? p.score : min);
    final maxScore = dataPoints
        .fold<double>(70, (max, p) => p.score > max ? p.score : max);

    final yMin = ((minScore - 10) / 10).floorToDouble() * 10;
    final yMax = ((maxScore + 10) / 10).ceilToDouble() * 10;

    return LineChartData(
      minX: 0,
      maxX: (dataPoints.length - 1).toDouble().clamp(1, double.infinity),
      minY: yMin.clamp(55, 130),
      maxY: yMax.clamp(80, 155),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppColors.border.withValues(alpha: 0.2),
            strokeWidth: 0.8,
          );
        },
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35,
            interval: 10,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: _bottomInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= dataPoints.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('MMM d').format(dataPoints[index].date),
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 9,
                  ),
                ),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.surface,
          tooltipBorder: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              final point = dataPoints[index];
              return LineTooltipItem(
                'IQ: ${point.score.round()}\n',
                AppTypography.bodyMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: DateFormat('MMM d, yyyy').format(point.date),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          // Average score dashed line.
          HorizontalLine(
            y: averageScore,
            color: AppColors.accent.withValues(alpha: 0.4),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.accent.withValues(alpha: 0.6),
                fontSize: 9,
              ),
              labelResolver: (_) => 'avg',
            ),
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.background,
                strokeWidth: 2.5,
                strokeColor: AppColors.primary,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.accent.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  double _bottomInterval() {
    if (dataPoints.length <= 5) return 1;
    if (dataPoints.length <= 10) return 2;
    return (dataPoints.length / 5).ceilToDouble();
  }
}
