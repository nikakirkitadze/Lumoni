import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/spacing.dart';

/// A premium glassmorphism card with blur, gradient overlay, and subtle border.
///
/// Uses [BackdropFilter] with [ImageFilter.blur] to achieve the frosted-glass
/// effect. Works best when placed over content with color variation (images,
/// gradients, etc.).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurX = 24,
    this.blurY = 24,
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1,
    this.gradient,
    this.width,
    this.height,
    this.onTap,
  });

  /// Content to display inside the card.
  final Widget child;

  /// Inner padding. Defaults to 16 px all around.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Border radius. Defaults to 16 px.
  final BorderRadius? borderRadius;

  /// Horizontal blur sigma.
  final double blurX;

  /// Vertical blur sigma.
  final double blurY;

  /// Background fill color. Defaults to [AppColors.glassFill].
  final Color? fillColor;

  /// Border color. Defaults to [AppColors.glassBorder].
  final Color? borderColor;

  /// Border width.
  final double borderWidth;

  /// Optional gradient overlay drawn on top of the fill.
  final Gradient? gradient;

  /// Fixed width (optional).
  final double? width;

  /// Fixed height (optional).
  final double? height;

  /// Tap callback. When provided, the card is wrapped in a gesture detector.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = borderRadius ?? AppSpacing.borderRadiusLg;
    final effectivePadding = padding ?? AppSpacing.paddingAllMd;

    Widget card = ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fillColor ?? AppColors.glassFill,
            borderRadius: effectiveBorderRadius,
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: borderWidth,
            ),
            gradient: gradient ?? AppColors.glassGradient,
          ),
          padding: effectivePadding,
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return card;
  }
}
