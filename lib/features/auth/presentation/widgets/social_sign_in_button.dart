import 'package:flutter/material.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';
import 'package:lumoni/design_system/spacing.dart';

/// The social provider this button represents.
enum SocialProvider { apple, google }

/// A premium-styled social sign-in button with icon, label, and loading state.
class SocialSignInButton extends StatefulWidget {
  const SocialSignInButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  State<SocialSignInButton> createState() => _SocialSignInButtonState();
}

class _SocialSignInButtonState extends State<SocialSignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  bool get _isApple => widget.provider == SocialProvider.apple;

  String get _label =>
      _isApple ? 'Continue with Apple' : 'Continue with Google';

  Color get _backgroundColor =>
      _isApple ? Colors.white : AppColors.surface;

  Color get _foregroundColor =>
      _isApple ? Colors.black : AppColors.textPrimary;

  Color get _borderColor =>
      _isApple ? Colors.white.withValues(alpha: 0.1) : AppColors.border;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          if (!widget.isLoading) widget.onPressed?.call();
        },
        onTapCancel: () => _pressController.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(_foregroundColor),
                    ),
                  ),
                ] else ...[
                  _ProviderIcon(provider: widget.provider),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    _label,
                    style: AppTypography.button.copyWith(
                      color: _foregroundColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Renders the provider icon using vector drawing for crisp display.
class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.provider});

  final SocialProvider provider;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: provider == SocialProvider.apple
            ? _AppleIconPainter()
            : _GoogleIconPainter(),
      ),
    );
  }
}

// ─────────────────── Apple Icon Painter ──────────────────────────────────────

class _AppleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Simplified Apple logo shape
    path.moveTo(w * 0.75, h * 0.15);
    path.cubicTo(w * 0.7, h * 0.05, w * 0.6, h * 0.0, w * 0.52, h * 0.0);
    path.cubicTo(w * 0.51, h * 0.08, w * 0.54, h * 0.16, w * 0.6, h * 0.22);
    path.cubicTo(w * 0.65, h * 0.28, w * 0.73, h * 0.18, w * 0.75, h * 0.15);
    path.close();

    path.moveTo(w * 0.78, h * 0.3);
    path.cubicTo(w * 0.65, h * 0.3, w * 0.58, h * 0.38, w * 0.5, h * 0.38);
    path.cubicTo(w * 0.42, h * 0.38, w * 0.32, h * 0.3, w * 0.22, h * 0.3);
    path.cubicTo(w * 0.08, h * 0.31, w * 0.0, h * 0.46, w * 0.0, h * 0.62);
    path.cubicTo(w * 0.0, h * 0.82, w * 0.15, h * 1.0, w * 0.32, h * 1.0);
    path.cubicTo(w * 0.4, h * 1.0, w * 0.44, h * 0.95, w * 0.5, h * 0.95);
    path.cubicTo(w * 0.56, h * 0.95, w * 0.6, h * 1.0, w * 0.68, h * 1.0);
    path.cubicTo(w * 0.85, h * 1.0, w * 1.0, h * 0.82, w * 1.0, h * 0.62);
    path.cubicTo(w * 1.0, h * 0.46, w * 0.92, h * 0.31, w * 0.78, h * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────── Google Icon Painter ─────────────────────────────────────

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w * 0.42;

    // Blue arc (top-right)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.8,
      1.6,
      false,
      bluePaint,
    );

    // Green arc (bottom-right)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.8,
      1.3,
      false,
      greenPaint,
    );

    // Yellow arc (bottom-left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.1,
      1.3,
      false,
      yellowPaint,
    );

    // Red arc (top-left)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.4,
      1.3,
      false,
      redPaint,
    );

    // Horizontal bar (the "G" crossbar)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.42, h * 0.2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
