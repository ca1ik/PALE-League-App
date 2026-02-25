import 'dart:math';
import 'package:flutter/material.dart';

/// RAMADAN Premium Card
/// - Purple-gold gradient with crescent moon and star motifs
/// - Mystical particle effects
/// - Animated glow and shimmer
class RamadanCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const RamadanCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<RamadanCard> createState() => _RamadanCardState();
}

class _RamadanCardState extends State<RamadanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(123);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
    final count = (size.width * size.height / 3500).clamp(15, 50).toInt();
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
                    // Outer border with purple-gold gradient
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: SweepGradient(
                          colors: [
                            const Color(0xFF8B00FF),
                            const Color(0xFFFFD700),
                            const Color(0xFF00CED1),
                            const Color(0xFF8B00FF),
                          ],
                          stops: const [0.0, 0.33, 0.66, 1.0],
                          startAngle: t * 2 * pi,
                          endAngle: t * 2 * pi + pi,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF8B00FF).withValues(alpha: 0.6),
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
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
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1A0033),
                                    Color(0xFF2E001F),
                                    Color(0xFF1A0033),
                                  ],
                                ),
                              ),
                            ),

                            // Crescent moon and star pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CrescentStarPainter(t: t),
                              ),
                            ),

                            // Mystical particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _MysticalParticlePainter(
                                  particles: _particles,
                                  t: t,
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
                                      Colors.purple.withValues(alpha: 0.15),
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
                                          color: const Color(0xFF8B00FF)
                                              .withValues(alpha: 0.8),
                                          blurRadius: 12,
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
                                            color: const Color(0xFF8B00FF),
                                            blurRadius: 8,
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
                                        color: Colors.white70,
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

class _CrescentStarPainter extends CustomPainter {
  final double t;

  _CrescentStarPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3);

    // Crescent moon
    final moonCenter = Offset(size.width * 0.3, size.height * 0.25);
    final moonRadius = size.width * 0.12;

    canvas.drawCircle(moonCenter, moonRadius, paint);

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF1A0033);
    canvas.drawCircle(
      moonCenter + Offset(moonRadius * 0.4, 0),
      moonRadius * 0.9,
      paint,
    );

    // Star
    paint.color =
        const Color(0xFFFFD700).withValues(alpha: 0.4 + 0.3 * sin(t * 4));
    paint.style = PaintingStyle.fill;

    final starCenter = Offset(size.width * 0.7, size.height * 0.25);
    final starPath = Path();
    for (var i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = starCenter.dx + cos(angle) * size.width * 0.08;
      final y = starCenter.dy + sin(angle) * size.width * 0.08;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, paint);
  }

  @override
  bool shouldRepaint(_CrescentStarPainter oldDelegate) => oldDelegate.t != t;
}

class _MysticalParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _MysticalParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final dx = (p.dx + 5 * sin((t + i * 0.1) * 2)) % size.width;
      final dy = (p.dy + 4 * cos((t + i * 0.15) * 1.5)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.8 + (i % 3) * 0.6;
      final alpha = (120 + 100 * sin((t + i) * 3)).clamp(60, 220).toInt();

      // Purple and teal particles
      if (i % 3 == 0) {
        paint.color = Color.fromARGB(alpha, 139, 0, 255);
      } else if (i % 3 == 1) {
        paint.color = Color.fromARGB(alpha, 0, 206, 209);
      } else {
        paint.color = Color.fromARGB(alpha, 255, 215, 0);
      }

      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_MysticalParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
