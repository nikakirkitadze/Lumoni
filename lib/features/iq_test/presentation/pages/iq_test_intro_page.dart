import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lumoni/core/constants/app_constants.dart';
import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/components/app_button.dart';
import 'package:lumoni/design_system/spacing.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Pre-test intro page showing test information, instructions, and
/// an animated brain illustration.
class IQTestIntroPage extends StatefulWidget {
  const IQTestIntroPage({super.key});

  @override
  State<IQTestIntroPage> createState() => _IQTestIntroPageState();
}

class _IQTestIntroPageState extends State<IQTestIntroPage>
    with TickerProviderStateMixin {
  late AnimationController _brainController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _brainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _brainController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.md),

                // Back button row
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Animated brain illustration
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: AnimatedBuilder(
                    animation: _brainController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _BrainIllustrationPainter(
                          animationValue: _brainController.value,
                        ),
                        size: Size.infinite,
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Title
                Text(
                  'IQ Assessment',
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Measure your cognitive abilities across\nfive key dimensions',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Test info cards
                _InfoRow(
                  icon: Icons.quiz_rounded,
                  label: '${AppConstants.maxIQQuestions} Questions',
                  subtitle: 'Adaptive difficulty',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: Icons.timer_rounded,
                  label: '${AppConstants.testDurationMinutes} Minutes',
                  subtitle: 'Timed assessment',
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  icon: Icons.insights_rounded,
                  label: 'Detailed Results',
                  subtitle: 'Score, percentile & breakdown',
                ),
                const SizedBox(height: AppSpacing.xl),

                // Category badges
                Text(
                  'CATEGORIES TESTED',
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.center,
                  children: const [
                    _CategoryBadge(
                      icon: Icons.grid_view_rounded,
                      label: 'Pattern',
                      color: AppColors.primary,
                    ),
                    _CategoryBadge(
                      icon: Icons.psychology_rounded,
                      label: 'Logic',
                      color: AppColors.secondary,
                    ),
                    _CategoryBadge(
                      icon: Icons.calculate_rounded,
                      label: 'Math',
                      color: AppColors.accent,
                    ),
                    _CategoryBadge(
                      icon: Icons.text_fields_rounded,
                      label: 'Verbal',
                      color: AppColors.success,
                    ),
                    _CategoryBadge(
                      icon: Icons.view_in_ar_rounded,
                      label: 'Spatial',
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Tips / instructions
                Container(
                  width: double.infinity,
                  padding: AppSpacing.paddingAllMd,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Tips for Best Results',
                            style: AppTypography.heading6.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _TipItem(text: 'Find a quiet place without distractions'),
                      _TipItem(text: 'Read each question carefully before answering'),
                      _TipItem(text: 'Don\'t spend too long on one question'),
                      _TipItem(text: 'Trust your first instinct on difficult questions'),
                      _TipItem(text: 'Answer every question - guessing beats skipping'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Begin test button
                AppButton(
                  label: 'Begin Test',
                  onPressed: () => context.push('/iq-test'),
                  icon: Icons.play_arrow_rounded,
                  gradient: AppColors.primaryGradient,
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Your results are private and encrypted',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.heading6.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppSpacing.borderRadiusFull,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Brain illustration painter
// ═══════════════════════════════════════════════════════════════════════════════

class _BrainIllustrationPainter extends CustomPainter {
  _BrainIllustrationPainter({required this.animationValue});

  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.4;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.4));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Brain outline (two hemispheres)
    _drawBrainHemispheres(canvas, center, radius);

    // Neural network nodes and connections
    _drawNeuralNetwork(canvas, center, radius);

    // Central pulsing glow
    final pulseRadius = radius * 0.2 * (0.8 + 0.2 * math.sin(animationValue * 2 * math.pi));
    final pulseGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.35),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: pulseRadius));
    canvas.drawCircle(center, pulseRadius, pulseGlow);

    // Rotating sparkle particles
    _drawOrbitingParticles(canvas, center, radius);
  }

  void _drawBrainHemispheres(Canvas canvas, Offset center, double radius) {
    final brainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.primary.withValues(alpha: 0.3);

    // Left hemisphere
    final leftPath = Path();
    leftPath.moveTo(center.dx, center.dy - radius * 0.6);
    leftPath.cubicTo(
      center.dx - radius * 0.8, center.dy - radius * 0.7,
      center.dx - radius * 0.9, center.dy + radius * 0.1,
      center.dx - radius * 0.3, center.dy + radius * 0.55,
    );
    leftPath.cubicTo(
      center.dx - radius * 0.1, center.dy + radius * 0.65,
      center.dx - radius * 0.05, center.dy + radius * 0.5,
      center.dx, center.dy + radius * 0.45,
    );
    canvas.drawPath(leftPath, brainPaint);

    // Right hemisphere (mirrored)
    final rightPath = Path();
    rightPath.moveTo(center.dx, center.dy - radius * 0.6);
    rightPath.cubicTo(
      center.dx + radius * 0.8, center.dy - radius * 0.7,
      center.dx + radius * 0.9, center.dy + radius * 0.1,
      center.dx + radius * 0.3, center.dy + radius * 0.55,
    );
    rightPath.cubicTo(
      center.dx + radius * 0.1, center.dy + radius * 0.65,
      center.dx + radius * 0.05, center.dy + radius * 0.5,
      center.dx, center.dy + radius * 0.45,
    );
    canvas.drawPath(rightPath, brainPaint);

    // Sulcus lines (wrinkle details)
    final sulcusPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.primary.withValues(alpha: 0.15);

    // Left hemisphere wrinkles
    for (var i = 0; i < 3; i++) {
      final yOffset = -radius * 0.3 + i * radius * 0.25;
      final path = Path()
        ..moveTo(center.dx - radius * 0.15, center.dy + yOffset)
        ..quadraticBezierTo(
          center.dx - radius * 0.45,
          center.dy + yOffset + radius * 0.1,
          center.dx - radius * 0.6,
          center.dy + yOffset - radius * 0.05,
        );
      canvas.drawPath(path, sulcusPaint);
    }

    // Right hemisphere wrinkles
    for (var i = 0; i < 3; i++) {
      final yOffset = -radius * 0.3 + i * radius * 0.25;
      final path = Path()
        ..moveTo(center.dx + radius * 0.15, center.dy + yOffset)
        ..quadraticBezierTo(
          center.dx + radius * 0.45,
          center.dy + yOffset + radius * 0.1,
          center.dx + radius * 0.6,
          center.dy + yOffset - radius * 0.05,
        );
      canvas.drawPath(path, sulcusPaint);
    }
  }

  void _drawNeuralNetwork(Canvas canvas, Offset center, double radius) {
    final rng = math.Random(42);
    final nodes = <Offset>[];

    // Generate nodes in a brain-like distribution
    for (var i = 0; i < 24; i++) {
      final angle = (i / 24) * 2 * math.pi;
      final r = radius * (0.15 + rng.nextDouble() * 0.55);
      nodes.add(center + Offset(math.cos(angle) * r, math.sin(angle) * r));
    }

    // Connections
    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < radius * 0.5) {
          final alpha = (1.0 - dist / (radius * 0.5)) * 0.25;
          // Animate connection visibility
          final phase = (animationValue + i * 0.04) % 1.0;
          final pulse = (math.sin(phase * 2 * math.pi) + 1) / 2;
          linePaint.color = AppColors.primary.withValues(
            alpha: (alpha * (0.5 + 0.5 * pulse)).clamp(0.0, 1.0),
          );
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Nodes
    for (var i = 0; i < nodes.length; i++) {
      final isCenter = (nodes[i] - center).distance < radius * 0.25;
      final nodeSize = isCenter ? 3.5 : 2.0;
      final color = isCenter ? AppColors.accent : AppColors.primary400;

      final phase = (animationValue + i * 0.05) % 1.0;
      final pulse = (math.sin(phase * 2 * math.pi) + 1) / 2;

      final dotPaint = Paint()
        ..color = color.withValues(alpha: (0.5 + 0.5 * pulse).clamp(0.0, 1.0));
      canvas.drawCircle(nodes[i], nodeSize, dotPaint);

      // Glow for center nodes
      if (isCenter) {
        final glowPaint = Paint()
          ..color = color.withValues(alpha: (0.2 * pulse).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(nodes[i], nodeSize * 2, glowPaint);
      }
    }
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, double radius) {
    for (var i = 0; i < 6; i++) {
      final orbitRadius = radius * (0.7 + i * 0.08);
      final speed = 1.0 + i * 0.3;
      final angle = animationValue * speed * 2 * math.pi + (i * math.pi / 3);

      final px = center.dx + orbitRadius * math.cos(angle);
      final py = center.dy + orbitRadius * math.sin(angle) * 0.6;

      final color = i.isEven ? AppColors.accent : AppColors.primary300;
      final particleSize = 1.5 + (i % 3) * 0.5;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), particleSize, paint);

      // Solid core
      final solidPaint = Paint()..color = color;
      canvas.drawCircle(Offset(px, py), particleSize * 0.5, solidPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrainIllustrationPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
