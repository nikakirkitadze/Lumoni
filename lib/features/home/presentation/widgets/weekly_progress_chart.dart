import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/features/home/presentation/cubits/home_state.dart';

/// Displays IQ and EQ scores over the last 7 days as two smooth gradient
/// lines inside a frosted glass card.
class WeeklyProgressChart extends StatelessWidget {
  final List<DayProgress> data;

  const WeeklyProgressChart({
    super.key,
    required this.data,
  });

  /// True when there is at least one non-null score across all days.
  bool get _hasData => data.any((d) => d.iqScore != null || d.eqScore != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: AppTypography.heading5,
              ),
              _buildLegend(),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Chart ──────────────────────────────────────────────
          SizedBox(
            height: 200,
            child: _hasData ? _buildChart() : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  // ────────────────────────── Legend ────────────────────────────────

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(AppColors.primary, 'IQ'),
        const SizedBox(width: AppSpacing.sm),
        _legendDot(AppColors.secondary, 'EQ'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.captionSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ────────────────────────── Chart ────────────────────────────────

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withValues(alpha: 0.3),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('E').format(data[index].date).substring(0, 2),
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.textTertiary,
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
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: _computeMinY(),
        maxY: _computeMaxY(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                AppColors.surface.withValues(alpha: 0.95),
            tooltipRoundedRadius: AppSpacing.radiusSm,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIQ = spot.barIndex == 0;
                return LineTooltipItem(
                  '${isIQ ? "IQ" : "EQ"}: ${spot.y.toStringAsFixed(isIQ ? 0 : 1)}',
                  AppTypography.captionSmall.copyWith(
                    color: isIQ ? AppColors.primary : AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          _buildLine(
            spots: _iqSpots(),
            color: AppColors.primary,
            gradientColors: [
              AppColors.primary.withValues(alpha: 0.3),
              AppColors.primary.withValues(alpha: 0.0),
            ],
          ),
          _buildLine(
            spots: _eqSpots(),
            color: AppColors.secondary,
            gradientColors: [
              AppColors.secondary.withValues(alpha: 0.3),
              AppColors.secondary.withValues(alpha: 0.0),
            ],
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  LineChartBarData _buildLine({
    required List<FlSpot> spots,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 1.5,
            strokeColor: AppColors.background,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ────────────────────── Data mapping ─────────────────────────────

  List<FlSpot> _iqSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i].iqScore != null) {
        spots.add(FlSpot(i.toDouble(), data[i].iqScore!));
      }
    }
    return spots;
  }

  List<FlSpot> _eqSpots() {
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      if (data[i].eqScore != null) {
        spots.add(FlSpot(i.toDouble(), data[i].eqScore!));
      }
    }
    return spots;
  }

  double _computeMinY() {
    double min = double.infinity;
    for (final d in data) {
      if (d.iqScore != null && d.iqScore! < min) min = d.iqScore!;
      if (d.eqScore != null && d.eqScore! < min) min = d.eqScore!;
    }
    if (min == double.infinity) return 0;
    return (min - 10).clamp(0, double.infinity);
  }

  double _computeMaxY() {
    double max = double.negativeInfinity;
    for (final d in data) {
      if (d.iqScore != null && d.iqScore! > max) max = d.iqScore!;
      if (d.eqScore != null && d.eqScore! > max) max = d.eqScore!;
    }
    if (max == double.negativeInfinity) return 150;
    return max + 10;
  }

  // ────────────────────── Empty state ──────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: AppColors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No data yet',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Take a test to see your progress here',
            style: AppTypography.caption.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
