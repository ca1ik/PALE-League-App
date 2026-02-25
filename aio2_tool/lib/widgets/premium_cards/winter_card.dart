import 'dart:math';
import 'package:flutter/material.dart';

/// WINTER Premium Card
/// - Green-ice blue glacial theme
/// - Snowflake and ice crystal particles
/// - Frosty shimmer effects
class WinterCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const WinterCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<WinterCard> createState() => _WinterCardState();
}

class _WinterCardState extends State<WinterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(321);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
    final count = (size.width * size.height / 2800).clamp(25, 70).toInt();
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
                    // Outer frosty border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF00FF7F),
                            const Color(0xFF50C878),
                            const Color(0xFFE0FFFF),
                            const Color(0xFF00FF7F),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00FF7F).withValues(alpha: 0.6),
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
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
                            // Icy gradient background
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF001a1a),
                                    Color(0xFF003333),
                                    Color(0xFF004d4d),
                                  ],
                                ),
                              ),
                            ),

                            // Ice crystal pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _IceCrystalPainter(t: t),
                              ),
                            ),

                            // Snowflake particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _SnowflakeParticlePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),

                            // Frost overlay
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.topLeft,
                                    radius: 1.2,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.12),
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
                                      const Color(0xFFE0FFFF)
                                          .withValues(alpha: 0.2),
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
                                      color: const Color(0xFF00FF7F),
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF00FF7F)
                                              .withValues(alpha: 0.9),
                                          blurRadius: 18,
                                        ),
                                        Shadow(
                                          color: const Color(0xFFE0FFFF)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 28,
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
                                            color: const Color(0xFF00FF7F),
                                            blurRadius: 10,
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
                                        color: const Color(0xFFB3FFE6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),

                            // Glossy ice overlay
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
                                      Colors.white.withValues(alpha: 0.3),
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

class _IceCrystalPainter extends CustomPainter {
  final double t;

  _IceCrystalPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00FF7F).withValues(alpha: 0.2);

    // Draw ice crystal patterns
    final center = Offset(size.width * 0.7, size.height * 0.3);
    final radius = size.width * 0.15;

    for (var i = 0; i < 6; i++) {
      final angle = (i * pi / 3) + (t * 0.5);
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      canvas.drawLine(center, Offset(x, y), paint);

      // Add branches
      final branchAngle1 = angle + pi / 6;
      final branchAngle2 = angle - pi / 6;
      final branchLength = radius * 0.4;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + cos(branchAngle1) * branchLength,
            y + sin(branchAngle1) * branchLength),
        paint,
      );
      canvas.drawLine(
        Offset(x, y),
        Offset(x + cos(branchAngle2) * branchLength,
            y + sin(branchAngle2) * branchLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_IceCrystalPainter oldDelegate) => oldDelegate.t != t;
}

class _SnowflakeParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _SnowflakeParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Gentle falling motion
      final dx = (p.dx + 2 * sin((t + i * 0.3) * 2)) % size.width;
      final dy = (p.dy + (t * 30 + i * 2)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.8 + (i % 4) * 0.6;
      final alpha = (150 + 70 * sin((t + i) * 2.5)).clamp(100, 220).toInt();

      // Green, ice blue, and white particles
      if (i % 3 == 0) {
        paint.color = Color.fromARGB(alpha, 0, 255, 127);
      } else if (i % 3 == 1) {
        paint.color = Color.fromARGB(alpha, 224, 255, 255);
      } else {
        paint.color = Color.fromARGB(alpha, 80, 200, 120);
      }

      canvas.drawCircle(pos, radius, paint);

      // Draw simple snowflake shape
      if (i % 5 == 0) {
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 0.5;
        for (var j = 0; j < 6; j++) {
          final angle = j * pi / 3;
          final x = pos.dx + cos(angle) * radius * 2;
          final y = pos.dy + sin(angle) * radius * 2;
          canvas.drawLine(pos, Offset(x, y), paint);
        }
        paint.style = PaintingStyle.fill;
      }
    }
  }

  @override
  bool shouldRepaint(_SnowflakeParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
