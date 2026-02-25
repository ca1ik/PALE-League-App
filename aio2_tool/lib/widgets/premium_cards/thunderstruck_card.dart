import 'dart:math';
import 'package:flutter/material.dart';

/// THUNDERSTRUCK Premium Card
/// - Electric purple-yellow lightning theme
/// - Thunder bolt particles and shock waves
/// - Intense electrical glow
class ThunderstruckCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const ThunderstruckCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<ThunderstruckCard> createState() => _ThunderstruckCardState();
}

class _ThunderstruckCardState extends State<ThunderstruckCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(999);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
    final count = (size.width * size.height / 2200).clamp(35, 90).toInt();
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
                    // Outer electric border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF8B5CF6),
                            const Color(0xFFFFD700),
                            const Color(0xFF6366F1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.8),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                            blurRadius: 25,
                            spreadRadius: 3,
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
                            // Dark purple gradient
                            Container(
                              decoration: const BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  colors: [
                                    Color(0xFF1E1B4B),
                                    Color(0xFF0F0A1E),
                                    Color(0xFF000000),
                                  ],
                                ),
                              ),
                            ),

                            // Lightning bolts
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _LightningPainter(t: t),
                              ),
                            ),

                            // Electric particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ElectricParticlePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),

                            // Shock wave pulse
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.5 + 0.5 * sin(t * 6),
                                    colors: [
                                      const Color(0xFFFFD700).withValues(
                                        alpha: 0.2 * (0.5 + 0.5 * sin(t * 6)),
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
                                          .withValues(alpha: 0.3),
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
                                          color: const Color(0xFFFFD700),
                                          blurRadius: 30,
                                        ),
                                        Shadow(
                                          color: const Color(0xFF8B5CF6),
                                          blurRadius: 40,
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
                                        color: const Color(0xFFFFD700),
                                        shadows: [
                                          Shadow(
                                            color: const Color(0xFFFFD700),
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
                                        color: const Color(0xFFFDE68A),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
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

class _LightningPainter extends CustomPainter {
  final double t;

  _LightningPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color =
          const Color(0xFFFFD700).withValues(alpha: 0.7 + 0.3 * sin(t * 8));

    // Draw zigzag lightning bolts
    for (var i = 0; i < 3; i++) {
      if ((t * 3 + i) % 1.0 < 0.3) {
        final path = Path();
        final startX = size.width * (0.2 + i * 0.3);
        final startY = 0.0;

        path.moveTo(startX, startY);

        var currentX = startX;
        var currentY = startY;

        for (var j = 0; j < 6; j++) {
          currentX += (Random(i * 100 + j).nextDouble() - 0.5) * 30;
          currentY += size.height / 6;
          path.lineTo(currentX, currentY);
        }

        canvas.drawPath(path, paint);

        // Add glow
        paint.strokeWidth = 5.0;
        paint.color = const Color(0xFFFFD700).withValues(alpha: 0.3);
        canvas.drawPath(path, paint);
        paint.strokeWidth = 2.5;
        paint.color = const Color(0xFFFFD700).withValues(alpha: 0.7);
      }
    }
  }

  @override
  bool shouldRepaint(_LightningPainter oldDelegate) => oldDelegate.t != t;
}

class _ElectricParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _ElectricParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Erratic electric movement
      final dx = (p.dx + 8 * sin((t + i * 0.1) * 10)) % size.width;
      final dy = (p.dy + 6 * cos((t + i * 0.15) * 8)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.5 + (i % 4) * 0.6;
      final alpha = (180 + 70 * sin((t + i) * 12)).clamp(100, 250).toInt();

      // Yellow and purple electric particles
      if (i % 2 == 0) {
        paint.color = Color.fromARGB(alpha, 255, 215, 0);
      } else {
        paint.color = Color.fromARGB(alpha, 139, 92, 246);
      }

      canvas.drawCircle(pos, radius, paint);

      // Electric glow
      paint.color = paint.color.withValues(alpha: alpha * 0.25 / 255);
      canvas.drawCircle(pos, radius * 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ElectricParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
