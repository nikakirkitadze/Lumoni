import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// The visual variant of an [AppButton].
enum AppButtonVariant {
  /// Gradient fill (primary -> secondary).
  primary,

  /// Solid fill with primary color.
  solid,

  /// Outlined with border only.
  outlined,

  /// Text-only, no background or border.
  text,
}

/// The size of an [AppButton].
enum AppButtonSize {
  small,
  medium,
  large,
}

/// A premium button widget with gradient fill, loading state, haptic feedback,
/// and a subtle scale-down animation on press.
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.large,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.iconAlignment = IconAlignment.start,
    this.gradient,
    this.width,
    this.hapticFeedback = true,
    this.borderRadius,
  });

  /// Button label.
  final String label;

  /// Tap callback. When `null` the button appears disabled.
  final VoidCallback? onPressed;

  /// Visual variant.
  final AppButtonVariant variant;

  /// Size variant.
  final AppButtonSize size;

  /// Shows a circular progress indicator in place of the label.
  final bool isLoading;

  /// When `false` the button appears disabled regardless of [onPressed].
  final bool isEnabled;

  /// Optional leading or trailing icon.
  final IconData? icon;

  /// Where the [icon] is placed relative to the label.
  final IconAlignment iconAlignment;

  /// Custom gradient; used only when [variant] is [AppButtonVariant.primary].
  final Gradient? gradient;

  /// Fixed width. Defaults to `double.infinity` for large buttons.
  final double? width;

  /// Whether to trigger light haptic feedback on tap.
  final bool hapticFeedback;

  /// Custom border radius override.
  final BorderRadius? borderRadius;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;

  bool get _isActive =>
      widget.isEnabled && !widget.isLoading && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0,
      upperBound: 1,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isActive) return;
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  void _handleTap() {
    if (!_isActive) return;
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final height = _resolveHeight();
    final effectiveBorderRadius =
        widget.borderRadius ?? AppSpacing.borderRadiusMd;
    final textStyle = _resolveTextStyle();
    final iconSize = _resolveIconSize();
    final effectiveWidth =
        widget.width ?? (widget.size == AppButtonSize.small ? null : double.infinity);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isActive ? 1.0 : 0.5,
          child: Container(
            width: effectiveWidth,
            height: height,
            decoration: _resolveDecoration(effectiveBorderRadius),
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: iconSize + 4,
                        height: iconSize + 4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _resolveLoadingColor(),
                          ),
                        ),
                      )
                    : _buildContent(textStyle, iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TextStyle textStyle, double iconSize) {
    final label = Text(
      widget.label,
      style: textStyle.copyWith(color: _resolveForegroundColor()),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (widget.icon == null) return label;

    final iconWidget = Icon(
      widget.icon,
      size: iconSize,
      color: _resolveForegroundColor(),
    );

    final spacing = SizedBox(width: AppSpacing.xs);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.iconAlignment == IconAlignment.start
          ? [iconWidget, spacing, label]
          : [label, spacing, iconWidget],
    );
  }

  // ───────────────── Resolvers ───────────────────────────────────

  double _resolveHeight() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 44;
      case AppButtonSize.large:
        return 52;
    }
  }

  TextStyle _resolveTextStyle() {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall;
      case AppButtonSize.medium:
        return AppTypography.button;
      case AppButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  double _resolveIconSize() {
    switch (widget.size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  Color _resolveForegroundColor() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.solid:
        return AppColors.textOnPrimary;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }

  Color _resolveLoadingColor() {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.solid:
        return AppColors.textOnPrimary;
      case AppButtonVariant.outlined:
      case AppButtonVariant.text:
        return AppColors.primary;
    }
  }

  BoxDecoration _resolveDecoration(BorderRadius borderRadius) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          gradient: widget.gradient ?? AppColors.primaryGradient,
          borderRadius: borderRadius,
          boxShadow: _isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
      case AppButtonVariant.solid:
        return BoxDecoration(
          color: AppColors.primary,
          borderRadius: borderRadius,
        );
      case AppButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.6),
            width: 1.5,
          ),
        );
      case AppButtonVariant.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        );
    }
  }
}
