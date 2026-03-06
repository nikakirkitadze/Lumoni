import 'package:flutter/material.dart';

/// Spacing constants used throughout Lumoni.
///
/// Based on a 4-point scale to ensure visual consistency.
abstract final class AppSpacing {
  /// 4 px
  static const double xxs = 4;

  /// 8 px
  static const double xs = 8;

  /// 12 px
  static const double sm = 12;

  /// 16 px
  static const double md = 16;

  /// 20 px
  static const double lg = 20;

  /// 24 px
  static const double xl = 24;

  /// 32 px
  static const double xxl = 32;

  /// 40 px
  static const double xxxl = 40;

  /// 48 px
  static const double huge = 48;

  /// 64 px
  static const double massive = 64;

  // ───────────────────── EdgeInsets helpers ────────────────────────────

  static const EdgeInsets paddingAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets paddingAllXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingAllXxl = EdgeInsets.all(xxl);

  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets paddingHorizontalXl =
      EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets paddingVerticalXs =
      EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets paddingVerticalSm =
      EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets paddingVerticalMd =
      EdgeInsets.symmetric(vertical: md);

  /// Standard screen-level horizontal padding.
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: xl, vertical: md);

  // ───────────────────── Border radius ────────────────────────────────

  /// 8 px
  static const double radiusSm = 8;

  /// 12 px
  static const double radiusMd = 12;

  /// 16 px
  static const double radiusLg = 16;

  /// 20 px
  static const double radiusXl = 20;

  /// 24 px
  static const double radiusXxl = 24;

  /// Fully rounded (pill).
  static const double radiusFull = 999;

  static const BorderRadius borderRadiusSm =
      BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd =
      BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg =
      BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusXxl =
      BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius borderRadiusFull =
      BorderRadius.all(Radius.circular(radiusFull));
}
