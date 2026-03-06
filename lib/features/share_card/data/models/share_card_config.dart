import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';

// ─────────────────────── Card Type ──────────────────────────────────────────

/// The type of intelligence data shown on the card.
enum ShareCardType {
  iqScore('IQ Score'),
  eqScore('EQ Score'),
  combinedProfile('Combined Profile');

  final String label;
  const ShareCardType(this.label);
}

// ─────────────────────── Aspect Ratio ───────────────────────────────────────

/// Supported aspect ratios for export.
enum ShareCardAspectRatio {
  story(9 / 16, 'Story', Size(1080, 1920)),
  square(1, 'Square', Size(1080, 1080)),
  feed(4 / 5, 'Feed', Size(1080, 1350));

  /// Width / height.
  final double value;

  /// Human-readable label.
  final String label;

  /// Export pixel dimensions.
  final Size exportSize;

  const ShareCardAspectRatio(this.value, this.label, this.exportSize);
}

// ─────────────────────── Card Style ─────────────────────────────────────────

/// Visual styles available for share cards.
///
/// [isFree] indicates styles accessible without a premium subscription.
enum ShareCardStyle {
  classic(
    label: 'Classic',
    isFree: true,
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF1A1145), AppColors.background, Color(0xFF0D1B2A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: AppColors.primary,
    borderColor: Color(0x4D4F46E5), // primary @ 30%
  ),
  minimal(
    label: 'Minimal',
    isFree: true,
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF111827), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    accentColor: AppColors.textSecondary,
    borderColor: AppColors.border,
  ),
  neon(
    label: 'Neon',
    isFree: false,
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF0A0A1A), Color(0xFF0D0D2B), Color(0xFF0A0A1A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFF00FF88),
    borderColor: Color(0x4D00FF88),
  ),
  gradient(
    label: 'Gradient',
    isFree: false,
    backgroundGradient: LinearGradient(
      colors: [AppColors.primary700, AppColors.secondary600, Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Colors.white,
    borderColor: Color(0x33FFFFFF),
  ),
  glass(
    label: 'Glass',
    isFree: false,
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    accentColor: AppColors.accent,
    borderColor: AppColors.glassBorder,
  ),
  royal(
    label: 'Royal',
    isFree: false,
    backgroundGradient: LinearGradient(
      colors: [Color(0xFF1A0A2E), Color(0xFF16213E), Color(0xFF0F3460)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: Color(0xFFFFD700),
    borderColor: Color(0x4DFFD700),
  );

  final String label;
  final bool isFree;
  final LinearGradient backgroundGradient;
  final Color accentColor;
  final Color borderColor;

  const ShareCardStyle({
    required this.label,
    required this.isFree,
    required this.backgroundGradient,
    required this.accentColor,
    required this.borderColor,
  });

  bool get isPremium => !isFree;
}

// ─────────────────────── Card Configuration ─────────────────────────────────

/// Immutable configuration for rendering a share card.
class ShareCardConfig extends Equatable {
  final ShareCardType cardType;
  final ShareCardStyle style;
  final ShareCardAspectRatio aspectRatio;

  /// Whether to show the category breakdown bars.
  final bool showCategoryBreakdown;

  /// Whether to show the percentile label.
  final bool showPercentile;

  /// Whether to show the Lumoni watermark.
  final bool showWatermark;

  const ShareCardConfig({
    required this.cardType,
    this.style = ShareCardStyle.classic,
    this.aspectRatio = ShareCardAspectRatio.story,
    this.showCategoryBreakdown = true,
    this.showPercentile = true,
    this.showWatermark = true,
  });

  ShareCardConfig copyWith({
    ShareCardType? cardType,
    ShareCardStyle? style,
    ShareCardAspectRatio? aspectRatio,
    bool? showCategoryBreakdown,
    bool? showPercentile,
    bool? showWatermark,
  }) {
    return ShareCardConfig(
      cardType: cardType ?? this.cardType,
      style: style ?? this.style,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      showCategoryBreakdown:
          showCategoryBreakdown ?? this.showCategoryBreakdown,
      showPercentile: showPercentile ?? this.showPercentile,
      showWatermark: showWatermark ?? this.showWatermark,
    );
  }

  @override
  List<Object?> get props => [
        cardType,
        style,
        aspectRatio,
        showCategoryBreakdown,
        showPercentile,
        showWatermark,
      ];
}
