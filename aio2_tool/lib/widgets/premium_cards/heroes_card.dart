import 'dart:math';
import 'package:flutter/material.dart';

/// HEROES Premium Card
/// - Red-orange fire theme
/// - Flame burst particles
/// - Intense heat glow effects
class HeroesCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const HeroesCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<HeroesCard> createState() => _HeroesCardState();
}

class _HeroesCardState extends State<HeroesCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(654);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
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
    final count = (size.width * size.height / 2500).clamp(30, 80).toInt();
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
                    // Outer fire border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFFF0000),
                            const Color(0xFFFF4500),
                            const Color(0xFFFFD700),
                            const Color(0xFFFF0000),
                          ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                          transform: GradientRotation(t * 2 * pi),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF0000).withValues(alpha: 0.8),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
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
                            // Dark red gradient background
                            Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  colors: [
                                    Color(0xFF330000),
                                    Color(0xFF1a0000),
                                    Color(0xFF000000),
                                  ],
                                ),
                              ),
                            ),

                            // Flame pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _FlamePainter(t: t),
                              ),
                            ),

                            // Fire particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _FireParticlePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),

                            // Heat wave distortion effect
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      const Color(0xFFFF4500).withValues(
                                        alpha: 0.15 * (0.5 + 0.5 * sin(t * 5)),
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
                                      const Color(0xFFFFD700)
                                          .withValues(alpha: 0.25),
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
                                      color: const Color(0xFFFFD700),
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFF0000)
                                              .withValues(alpha: 0.9),
                                          blurRadius: 25,
                                        ),
                                        Shadow(
                                          color: const Color(0xFFFF4500)
                                              .withValues(alpha: 0.8),
                                          blurRadius: 35,
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
                                            color: const Color(0xFFFF0000),
                                            blurRadius: 15,
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
                                        color: const Color(0xFFFFB380),
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
                              right: size.width * 0.6,
                              bottom: size.height * 0.6,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.2),
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

class _FlamePainter extends CustomPainter {
  final double t;

  _FlamePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.screen;

    // Draw flame shapes from bottom
    for (var i = 0; i < 5; i++) {
      final xOffset = (size.width / 6) * i;
      final flameHeight = size.height * 0.4 * (0.7 + 0.3 * sin((t + i) * 4));

      final path = Path();
      path.moveTo(xOffset, size.height);

      // Create flame shape
      path.quadraticBezierTo(
        xOffset + 10,
        size.height - flameHeight * 0.5,
        xOffset + 20 + 10 * sin((t + i) * 6),
        size.height - flameHeight,
      );
      path.quadraticBezierTo(
        xOffset + 30,
        size.height - flameHeight * 0.5,
        xOffset + 40,
        size.height,
      );
      path.close();

      // Gradient from red to yellow
      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF0000).withValues(alpha: 0.3),
          const Color(0xFFFF4500).withValues(alpha: 0.2),
          const Color(0xFFFFD700).withValues(alpha: 0.1),
        ],
      ).createShader(
          Rect.fromLTWH(xOffset, size.height - flameHeight, 40, flameHeight));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => oldDelegate.t != t;
}

class _FireParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _FireParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Rising motion with flicker
      final dx = (p.dx + 3 * sin((t + i * 0.2) * 4)) % size.width;
      final dy = (p.dy - (t * 60 + i * 3)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.6 + (i % 5) * 0.5;
      final alpha = (160 + 80 * sin((t + i) * 5)).clamp(80, 240).toInt();

      // Red, orange, and yellow particles
      if (i % 3 == 0) {
        paint.color = Color.fromARGB(alpha, 255, 0, 0);
      } else if (i % 3 == 1) {
        paint.color = Color.fromARGB(alpha, 255, 69, 0);
      } else {
        paint.color = Color.fromARGB(alpha, 255, 215, 0);
      }

      canvas.drawCircle(pos, radius, paint);

      // Add glow
      paint.color = paint.color.withValues(alpha: alpha * 0.3 / 255);
      canvas.drawCircle(pos, radius * 3, paint);

      // Add trail
      if (i % 4 == 0) {
        paint.color = paint.color.withValues(alpha: alpha * 0.15 / 255);
        canvas.drawCircle(Offset(pos.dx, pos.dy + 5), radius * 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FireParticlePainter oldDelegate) => oldDelegate.t != t;
}
