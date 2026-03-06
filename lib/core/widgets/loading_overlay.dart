import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';

/// Full-screen semi-transparent loading overlay with a centered spinner.
///
/// Usage:
/// ```dart
/// Stack(
///   children: [
///     MainContent(),
///     if (isLoading) const LoadingOverlay(),
///   ],
/// )
/// ```
///
/// Or use the static [show] / [hide] methods for route-based overlays.
class LoadingOverlay extends StatelessWidget {
  /// Optional message displayed beneath the spinner.
  final String? message;

  /// Background color of the overlay.
  final Color barrierColor;

  /// Whether the overlay absorbs taps (prevents interaction behind it).
  final bool absorbing;

  const LoadingOverlay({
    super.key,
    this.message,
    this.barrierColor = const Color(0xB30F172A), // AppColors.scrim
    this.absorbing = true,
  });

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: absorbing,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: barrierColor,
          alignment: Alignment.center,
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 20),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ──────────────────────── Static Overlay API ─────────────────────────

  static OverlayEntry? _overlayEntry;

  /// Shows a loading overlay on top of the current route.
  static void show(
    BuildContext context, {
    String? message,
  }) {
    hide(); // Remove any existing overlay first.

    _overlayEntry = OverlayEntry(
      builder: (_) => LoadingOverlay(message: message),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hides the loading overlay previously shown with [show].
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
