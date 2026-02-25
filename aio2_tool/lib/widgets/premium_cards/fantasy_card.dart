import 'dart:math';
import 'package:flutter/material.dart';

/// FANTASY Premium Card
/// - Magenta-purple mystical aura
/// - Magical particle swirls
/// - Enchanted glow effects
class FantasyCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const FantasyCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<FantasyCard> createState() => _FantasyCardState();
}

class _FantasyCardState extends State<FantasyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(789);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particles = [];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ensureParticles(Size size) {
    if (_particles.isNotEmpty) return;
    final count = (size.width * size.height / 3200).clamp(18, 55).toInt();
    for (var i = 0; i < count; i++) {
      _particles.add(Offset(
        _rnd.nextDouble() * size.width,
        _rnd.nextDouble() * size.height,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _ensureParticles(size);

            return AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final t = _ctrl.value;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer magical border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFFF00FF),
                            const Color(0xFF8B00FF),
                            const Color(0xFFFF69B4),
                            const Color(0xFFFF00FF),
                          ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                          transform: GradientRotation(t * 2 * pi),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF00FF).withValues(alpha: 0.7),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),

                    // Inner card
                    Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            // Dark purple gradient background
                            Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  colors: [
                                    Color(0xFF2D0A3D),
                                    Color(0xFF1A0033),
                                    Color(0xFF0D001A),
                                  ],
                                ),
                              ),
                            ),

                            // Mystical swirl pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MysticalSwirlPainter(t: t),
                              ),
                            ),

                            // Magical particles with trails
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MagicalParticlePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),

                            // Pulsing aura
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      const Color(0xFFFF00FF).withValues(
                                        alpha: 0.15 * (0.5 + 0.5 * sin(t * 3)),
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Animated shimmer
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.5 + 3.0 * t, -1.0),
                                    end: Alignment(1.5 + 3.0 * t, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      const Color(0xFFFF69B4)
                                          .withValues(alpha: 0.18),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Content
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.icon != null)
                                    Icon(
                                      widget.icon,
                                      size: widget.size * 0.45,
                                      color: const Color(0xFFFF69B4),
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFF00FF)
                                              .withValues(alpha: 0.9),
                                          blurRadius: 20,
                                        ),
                                        Shadow(
                                          color: const Color(0xFF8B00FF)
                                              .withValues(alpha: 0.7),
                                          blurRadius: 30,
                                        ),
                                      ],
                                    ),
                                  if (widget.title != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.title!,
                                      style: TextStyle(
                                        fontSize: widget.size * 0.15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFF00FF),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  if (widget.subtitle != null)
                                    Text(
                                      widget.subtitle!,
                                      style: TextStyle(
                                        fontSize: widget.size * 0.1,
                                        color: const Color(0xFFFFB3E6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),

                            // Glossy overlay
                            Positioned(
                              top: 0,
                              left: 0,
                              right: size.width * 0.65,
                              bottom: size.height * 0.65,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MysticalSwirlPainter extends CustomPainter {
  final double t;

  _MysticalSwirlPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFF00FF).withValues(alpha: 0.25);

    final center = Offset(size.width / 2, size.height / 2);

    // Draw spiral swirls
    for (var i = 0; i < 3; i++) {
      final path = Path();
      final startAngle = (t * 2 * pi) + (i * 2 * pi / 3);

      for (var j = 0; j < 50; j++) {
        final angle = startAngle + (j * 0.2);
        final radius = (j * 2.0);
        final x = center.dx + cos(angle) * radius;
        final y = center.dy + sin(angle) * radius;

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MysticalSwirlPainter oldDelegate) => oldDelegate.t != t;
}

class _MagicalParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _MagicalParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Circular motion
      final angle = (t + i * 0.1) * 2;
      final radius = 15 + (i % 5) * 8;
      final dx = (p.dx + cos(angle) * radius) % size.width;
      final dy = (p.dy + sin(angle) * radius) % size.height;
      final pos = Offset(dx, dy);

      final particleRadius = 0.7 + (i % 3) * 0.5;
      final alpha = (130 + 90 * sin((t + i) * 3.5)).clamp(70, 220).toInt();

      // Magenta, purple, and pink particles
      if (i % 3 == 0) {
        paint.color = Color.fromARGB(alpha, 255, 0, 255);
      } else if (i % 3 == 1) {
        paint.color = Color.fromARGB(alpha, 139, 0, 255);
      } else {
        paint.color = Color.fromARGB(alpha, 255, 105, 180);
      }

      canvas.drawCircle(pos, particleRadius, paint);

      // Add glow
      paint.color = paint.color.withValues(alpha: alpha * 0.2 / 255);
      canvas.drawCircle(pos, particleRadius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_MagicalParticlePainter oldDelegate) => oldDelegate.t != t;
}
