import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';

/// Lumoni typography system built on the Inter typeface.
///
/// Falls back to Google Fonts when the bundled asset is unavailable.
abstract final class AppTypography {
  // ──────────────────── Base font family ──────────────────────────────

  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.5,
    double letterSpacing = 0,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ──────────────────── Display ───────────────────────────────────────

  /// 48 px / ExtraBold — hero headlines.
  static TextStyle get display => _base(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -1.5,
      );

  // ──────────────────── Headings ──────────────────────────────────────

  /// 32 px / Bold.
  static TextStyle get heading1 => _base(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.8,
      );

  /// 28 px / Bold.
  static TextStyle get heading2 => _base(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.6,
      );

  /// 24 px / SemiBold.
  static TextStyle get heading3 => _base(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.4,
      );

  /// 20 px / SemiBold.
  static TextStyle get heading4 => _base(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        letterSpacing: -0.2,
      );

  /// 18 px / SemiBold.
  static TextStyle get heading5 => _base(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  /// 16 px / SemiBold.
  static TextStyle get heading6 => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      );

  // ──────────────────── Body ──────────────────────────────────────────

  /// 16 px / Regular — default body.
  static TextStyle get bodyLarge => _base(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// 14 px / Regular.
  static TextStyle get body => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  /// 14 px / Medium.
  static TextStyle get bodyMedium => _base(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
      );

  /// 13 px / Regular — slightly smaller body text.
  static TextStyle get bodySmall => _base(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  // ──────────────────── Caption / Overline ─────────────────────────────

  /// 12 px / Regular.
  static TextStyle get caption => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.textSecondary,
      );

  /// 11 px / Medium — small labels.
  static TextStyle get captionSmall => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  /// 11 px / SemiBold / uppercase — overline.
  static TextStyle get overline => _base(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      );

  // ──────────────────── Button / Label ─────────────────────────────────

  /// 16 px / SemiBold — primary button.
  static TextStyle get buttonLarge => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
      );

  /// 14 px / SemiBold — default button.
  static TextStyle get button => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
      );

  /// 12 px / SemiBold — small button.
  static TextStyle get buttonSmall => _base(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.3,
      );

  /// 14 px / Medium — input labels.
  static TextStyle get label => _base(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  /// 12 px / Medium — small labels / badges.
  static TextStyle get labelSmall => _base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
      );

  // ──────────────────── Numeric ───────────────────────────────────────

  /// 56 px / ExtraBold — large score display.
  static TextStyle get scoreHero => _base(
        fontSize: 56,
        fontWeight: FontWeight.w800,
        height: 1.0,
        letterSpacing: -2,
      );

  /// 36 px / Bold — medium numeric display.
  static TextStyle get scoreLarge => _base(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1,
      );

  /// 24 px / Bold — stat values.
  static TextStyle get statValue => _base(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
      );

  // ──────────────────── Flutter TextTheme mapping ─────────────────────

  /// Returns a [TextTheme] suitable for [ThemeData].
  static TextTheme get textTheme => TextTheme(
        displayLarge: display,
        displayMedium: heading1,
        displaySmall: heading2,
        headlineLarge: heading3,
        headlineMedium: heading4,
        headlineSmall: heading5,
        titleLarge: heading4,
        titleMedium: heading6,
        titleSmall: bodyMedium,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: bodySmall,
        labelLarge: button,
        labelMedium: label,
        labelSmall: labelSmall,
      );
}
