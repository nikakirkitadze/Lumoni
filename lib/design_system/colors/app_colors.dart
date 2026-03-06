import 'package:flutter/material.dart';

/// Lumoni color system.
///
/// All colors follow a premium dark-mode palette built around deep indigo,
/// violet, and cyan accents on a dark navy canvas.
abstract final class AppColors {
  // ───────────────────────── Brand primaries ──────────────────────────

  /// Deep indigo primary.
  static const Color primary = Color(0xFF4F46E5);

  static const Color primary50 = Color(0xFFEEF2FF);
  static const Color primary100 = Color(0xFFE0E7FF);
  static const Color primary200 = Color(0xFFC7D2FE);
  static const Color primary300 = Color(0xFFA5B4FC);
  static const Color primary400 = Color(0xFF818CF8);
  static const Color primary500 = Color(0xFF6366F1);
  static const Color primary600 = Color(0xFF4F46E5);
  static const Color primary700 = Color(0xFF4338CA);
  static const Color primary800 = Color(0xFF3730A3);
  static const Color primary900 = Color(0xFF312E81);

  /// Violet secondary.
  static const Color secondary = Color(0xFF7C3AED);

  static const Color secondary50 = Color(0xFFF5F3FF);
  static const Color secondary100 = Color(0xFFEDE9FE);
  static const Color secondary200 = Color(0xFFDDD6FE);
  static const Color secondary300 = Color(0xFFC4B5FD);
  static const Color secondary400 = Color(0xFFA78BFA);
  static const Color secondary500 = Color(0xFF8B5CF6);
  static const Color secondary600 = Color(0xFF7C3AED);
  static const Color secondary700 = Color(0xFF6D28D9);
  static const Color secondary800 = Color(0xFF5B21B6);
  static const Color secondary900 = Color(0xFF4C1D95);

  /// Cyan accent.
  static const Color accent = Color(0xFF22D3EE);

  static const Color accent50 = Color(0xFFECFEFF);
  static const Color accent100 = Color(0xFFCFFAFE);
  static const Color accent200 = Color(0xFFA5F3FC);
  static const Color accent300 = Color(0xFF67E8F9);
  static const Color accent400 = Color(0xFF22D3EE);
  static const Color accent500 = Color(0xFF06B6D4);
  static const Color accent600 = Color(0xFF0891B2);
  static const Color accent700 = Color(0xFF0E7490);
  static const Color accent800 = Color(0xFF155E75);
  static const Color accent900 = Color(0xFF164E63);

  // ─────────────────────── Background / Surface ───────────────────────

  /// Dark navy background.
  static const Color background = Color(0xFF0F172A);

  /// Slightly lighter surface.
  static const Color surface = Color(0xFF1E293B);

  /// Elevated surface (cards, sheets).
  static const Color surfaceElevated = Color(0xFF283548);

  /// Subtle border/divider on dark surfaces.
  static const Color border = Color(0xFF334155);

  /// Glass card fill (white at 6 % opacity).
  static const Color glassFill = Color(0x0FFFFFFF);

  /// Glass card border (white at 12 % opacity).
  static const Color glassBorder = Color(0x1FFFFFFF);

  // ──────────────────────────── Text ──────────────────────────────────

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF0F172A);

  // ───────────────────────── Semantic colors ──────────────────────────

  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);

  // ─────────────────────── Misc / overlay ─────────────────────────────

  static const Color scrim = Color(0xB30F172A); // 70 % opacity
  static const Color shimmerBase = Color(0xFF1E293B);
  static const Color shimmerHighlight = Color(0xFF334155);

  // ──────────────────────── Gradients ─────────────────────────────────

  /// Primary brand gradient (indigo -> violet).
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Accent gradient (primary -> cyan).
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Warm gradient (violet -> pink).
  static const LinearGradient warmGradient = LinearGradient(
    colors: [secondary, Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Surface subtle gradient used as a background overlay.
  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Glass overlay gradient (used inside glass cards).
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card glow gradient (radial) for premium effect.
  static const RadialGradient cardGlow = RadialGradient(
    colors: [Color(0x224F46E5), Color(0x004F46E5)],
    radius: 0.85,
  );

  /// Progress bar fill gradient (indigo -> cyan).
  static const LinearGradient progressGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // ────────────────────── Helpers ─────────────────────────────────────

  /// Returns [color] with the given [opacity] (0.0 - 1.0).
  static Color withOpacity(Color color, double opacity) =>
      color.withValues(alpha: opacity);
}
