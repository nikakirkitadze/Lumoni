import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for quick access to common
/// theme, layout, and scaffold properties.
extension BuildContextExtensions on BuildContext {
  // ──────────────────────── Theme ──────────────────────────────────────

  /// Shortcut to [Theme.of(context)].
  ThemeData get theme => Theme.of(this);

  /// Shortcut to [Theme.of(context).colorScheme].
  ColorScheme get colorScheme => theme.colorScheme;

  /// Shortcut to [Theme.of(context).textTheme].
  TextTheme get textTheme => theme.textTheme;

  /// Whether the current theme brightness is dark.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  // ──────────────────────── Media Query ────────────────────────────────

  /// Shortcut to [MediaQuery.of(context)].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Screen size.
  Size get screenSize => mediaQuery.size;

  /// Screen width.
  double get screenWidth => screenSize.width;

  /// Screen height.
  double get screenHeight => screenSize.height;

  /// Top padding (status bar / notch).
  double get topPadding => mediaQuery.padding.top;

  /// Bottom padding (home indicator / nav bar).
  double get bottomPadding => mediaQuery.padding.bottom;

  /// View insets (keyboard, etc.).
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Whether the keyboard is currently visible.
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Device pixel ratio.
  double get devicePixelRatio => mediaQuery.devicePixelRatio;

  /// Text scale factor.
  double get textScaleFactor => mediaQuery.textScaler.scale(1.0);

  // ──────────────────────── Responsive Breakpoints ─────────────────────

  /// True on phones (width < 600).
  bool get isPhone => screenWidth < 600;

  /// True on tablets (600 <= width < 1024).
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  /// True on desktops (width >= 1024).
  bool get isDesktop => screenWidth >= 1024;

  // ──────────────────────── Scaffold / Overlay ─────────────────────────

  /// Shows a [SnackBar] using the nearest [ScaffoldMessenger].
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: behavior,
        margin: behavior == SnackBarBehavior.floating
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : null,
        shape: behavior == SnackBarBehavior.floating
            ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            : null,
      ),
    );
  }

  /// Shows an error snack bar with an error color.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    return showSnackBar(
      message,
      duration: duration,
      backgroundColor: colorScheme.error,
    );
  }

  /// Shows a success snack bar.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    return showSnackBar(
      message,
      duration: duration,
      backgroundColor: const Color(0xFF10B981), // AppColors.success
    );
  }

  /// Clears all current snack bars.
  void clearSnackBars() {
    ScaffoldMessenger.of(this).clearSnackBars();
  }

  // ──────────────────────── Focus ──────────────────────────────────────

  /// Unfocuses the current focus node (dismisses keyboard).
  void unfocus() {
    FocusScope.of(this).unfocus();
  }

  // ──────────────────────── Navigation helpers ─────────────────────────

  /// Shortcut to [Navigator.of(context)].
  NavigatorState get navigator => Navigator.of(this);
}
