import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:lumoni/design_system/colors/app_colors.dart';
import 'package:lumoni/design_system/typography/app_typography.dart';

/// Animated score reveal widget with a glowing circular container,
/// counting number, and sparkle/confetti particle effects.
class ScoreRevealAnimation extends StatefulWidget {
  const ScoreRevealAnimation({
    super.key,
    required this.score,
    required this.label,
    this.subtitle,
    this.isIQ = true,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  /// The final score to reveal (e.g. 127 for IQ, 85 for EQ).
  final int score;

  /// Classification label shown below the score.
  final String label;

  /// Optional subtitle (e.g. "Top 4%").
  final String? subtitle;

  /// Whether this is an IQ score (affects gradient colors).
  final bool isIQ;

  /// Duration of the count-up animation.
  final Duration duration;

  /// Callback when the reveal animation completes.
  final VoidCallback? onComplete;

  @override
  State<ScoreRevealAnimation> createState() => _ScoreRevealAnimationState();
}

class _ScoreRevealAnimationState extends State<ScoreRevealAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _countController;
  late final AnimationController _glowController;
  late final AnimationController _labelController;
  late final AnimationController _particleController;

  late final Animation<double> _countAnimation;
  late final Animation<double> _glowAnimation;
  late final Animation<double> _labelAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Count-up animation.
    _countController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _countAnimation = Tween<double>(begin: 0, end: widget.score.toDouble())
        .animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.easeOutCubic,
    ));

    // Scale animation for the circle.
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _countController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // Glow pulsing animation.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Label fade-in animation (delayed until count is mostly done).
    _labelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _labelAnimation = CurvedAnimation(
      parent: _labelController,
      curve: Curves.easeOut,
    );

    // Particle animation.
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    // Start the glow pulse loop.
    _glowController.repeat(reverse: true);

    // Start count and particles simultaneously.
    _countController.forward();
    _particleController.forward();

    // Show label after 70% of count animation.
    await Future.delayed(
      Duration(milliseconds: (widget.duration.inMilliseconds * 0.7).round()),
    );

    if (mounted) {
      _labelController.forward();
    }

    // Wait for count to finish, then notify.
    await _countController.forward().orCancel.catchError((_) {});
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _countController.dispose();
    _glowController.dispose();
    _labelController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isIQ ? AppColors.primary : AppColors.secondary;
    final secondaryColor = widget.isIQ ? AppColors.accent : AppColors.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _countAnimation,
        _glowAnimation,
        _labelAnimation,
        _scaleAnimation,
        _particleController,
      ]),
      builder: (context, _) {
        final currentScore = _countAnimation.value.round();
        final glowIntensity = _glowAnimation.value;
        final labelOpacity = _labelAnimation.value;
        final scale = _scaleAnimation.value;

        return SizedBox(
          width: 280,
          height: 320,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sparkle particles.
              if (_particleController.isAnimating || _particleController.isCompleted)
                CustomPaint(
                  size: const Size(280, 320),
                  painter: _SparkleParticlePainter(
                    progress: _particleController.value,
                    color: primaryColor,
                    secondaryColor: secondaryColor,
                  ),
                ),

              // Outer glow.
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3 * glowIntensity),
                        blurRadius: 40 * glowIntensity,
                        spreadRadius: 10 * glowIntensity,
                      ),
                      BoxShadow(
                        color: secondaryColor.withValues(alpha: 0.2 * glowIntensity),
                        blurRadius: 60 * glowIntensity,
                        spreadRadius: 20 * glowIntensity,
                      ),
                    ],
                  ),
                ),
              ),

              // Gradient border ring.
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        primaryColor,
                        secondaryColor,
                        primaryColor.withValues(alpha: 0.6),
                        secondaryColor,
                        primaryColor,
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),

              // Score number.
              Transform.scale(
                scale: scale,
                child: Text(
                  '$currentScore',
                  style: AppTypography.scoreHero.copyWith(
                    fontSize: 64,
                    foreground: Paint()
                      ..shader = LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(
                        const Rect.fromLTWH(0, 0, 100, 80),
                      ),
                  ),
                ),
              ),

              // Classification label.
              Positioned(
                bottom: 40,
                child: Opacity(
                  opacity: labelOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withValues(alpha: 0.2),
                              secondaryColor.withValues(alpha: 0.2),
                            ],
                          ),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          widget.label,
                          style: AppTypography.heading5.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter that renders simple sparkle/confetti particles
/// emanating from the center of the score reveal.
class _SparkleParticlePainter extends CustomPainter {
  _SparkleParticlePainter({
    required this.progress,
    required this.color,
    required this.secondaryColor,
  });

  final double progress;
  final Color color;
  final Color secondaryColor;

  static final List<_Particle> _particles = _generateParticles(30);

  static List<_Particle> _generateParticles(int count) {
    final rng = math.Random(42);
    return List.generate(count, (i) {
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 60 + rng.nextDouble() * 100;
      final size = 2 + rng.nextDouble() * 4;
      final delay = rng.nextDouble() * 0.4;
      final isSecondary = rng.nextBool();
      return _Particle(
        angle: angle,
        speed: speed,
        size: size,
        delay: delay,
        isSecondary: isSecondary,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in _particles) {
      final adjustedProgress =
          ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);

      if (adjustedProgress <= 0) continue;

      final distance = particle.speed * adjustedProgress;
      final opacity = (1 - adjustedProgress).clamp(0.0, 1.0);

      final dx = center.dx + math.cos(particle.angle) * distance;
      final dy = center.dy + math.sin(particle.angle) * distance;

      final paint = Paint()
        ..color = (particle.isSecondary ? secondaryColor : color)
            .withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      // Draw a small diamond/star shape.
      final particleSize = particle.size * (1 - adjustedProgress * 0.5);
      final path = Path()
        ..moveTo(dx, dy - particleSize)
        ..lineTo(dx + particleSize * 0.6, dy)
        ..lineTo(dx, dy + particleSize)
        ..lineTo(dx - particleSize * 0.6, dy)
        ..close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkleParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final double delay;
  final bool isSecondary;

  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.isSecondary,
  });
}
