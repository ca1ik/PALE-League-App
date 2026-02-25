import 'dart:math';
import 'package:flutter/material.dart';

/// TOTY (Team of the Year) Premium Card
/// - Gold-black premium theme
/// - Trophy particles and champion glow
/// - Prestigious shimmer effects
class TOTYCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const TOTYCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<TOTYCard> createState() => _TOTYCardState();
}

class _TOTYCardState extends State<TOTYCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(2024);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
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
    final count = (size.width * size.height / 3000).clamp(20, 60).toInt();
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
                    // Outer gold border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFA500),
                            const Color(0xFFFFD700),
                            const Color(0xFFDAA520),
                            const Color(0xFFFFD700),
                          ],
                          transform: GradientRotation(t * 2 * pi),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.9),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
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
                            // Black gradient background
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF1A1A1A),
                                    Color(0xFF000000),
                                    Color(0xFF0A0A0A),
                                  ],
                                ),
                              ),
                            ),

                            // Trophy pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _TrophyPatternPainter(t: t),
                              ),
                            ),

                            // Champion particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _ChampionParticlePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),

                            // Radial gold glow
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      const Color(0xFFFFD700).withValues(
                                        alpha: 0.15 * (0.6 + 0.4 * sin(t * 2)),
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
                                          color: const Color(0xFFFFD700),
                                          blurRadius: 35,
                                        ),
                                        Shadow(
                                          color: const Color(0xFFFFA500),
                                          blurRadius: 45,
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
                                            blurRadius: 18,
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
                                        color: const Color(0xFFDAA520),
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
                              right: size.width * 0.55,
                              bottom: size.height * 0.55,
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

class _TrophyPatternPainter extends CustomPainter {
  final double t;

  _TrophyPatternPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.2);

    // Draw trophy silhouettes
    final center = Offset(size.width / 2, size.height * 0.3);
    final trophyWidth = size.width * 0.15;
    final trophyHeight = size.height * 0.25;

    final path = Path();
    path.moveTo(center.dx - trophyWidth / 2, center.dy);
    path.lineTo(center.dx - trophyWidth / 3, center.dy - trophyHeight * 0.6);
    path.lineTo(center.dx + trophyWidth / 3, center.dy - trophyHeight * 0.6);
    path.lineTo(center.dx + trophyWidth / 2, center.dy);
    path.lineTo(center.dx + trophyWidth / 4, center.dy + trophyHeight * 0.2);
    path.lineTo(center.dx - trophyWidth / 4, center.dy + trophyHeight * 0.2);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrophyPatternPainter oldDelegate) => false;
}

class _ChampionParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _ChampionParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Slow floating motion
      final dx = (p.dx + 3 * sin((t + i * 0.2) * 1.5)) % size.width;
      final dy = (p.dy + 2 * cos((t + i * 0.15) * 1.2)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.9 + (i % 3) * 0.7;
      final alpha = (140 + 80 * sin((t + i) * 2)).clamp(80, 220).toInt();

      // Gold and orange particles
      if (i % 2 == 0) {
        paint.color = Color.fromARGB(alpha, 255, 215, 0);
      } else {
        paint.color = Color.fromARGB(alpha, 255, 165, 0);
      }

      canvas.drawCircle(pos, radius, paint);

      // Glow
      paint.color = paint.color.withValues(alpha: alpha * 0.3 / 255);
      canvas.drawCircle(pos, radius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_ChampionParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
