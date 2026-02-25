import 'dart:math';
import 'package:flutter/material.dart';

/// FUTURE STARS Premium Card
/// - Cyan-blue neon hologram effect
/// - Digital glitch particles
/// - Futuristic animated borders
class FutureStarsCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const FutureStarsCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.size = 140,
    this.onTap,
  }) : super(key: key);

  @override
  State<FutureStarsCard> createState() => _FutureStarsCardState();
}

class _FutureStarsCardState extends State<FutureStarsCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(456);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
                    // Outer neon border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF00FFFF),
                            const Color(0xFF0080FF),
                            const Color(0xFF00FFFF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00FFFF).withValues(alpha: 0.7),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 18,
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
                            // Dark blue gradient background
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF001a33),
                                    Color(0xFF003366),
                                    Color(0xFF001a33),
                                  ],
                                ),
                              ),
                            ),

                            // Digital grid pattern
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DigitalGridPainter(t: t),
                              ),
                            ),

                            // Hologram particles
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _HologramParticlePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),

                            // Scanning line effect
                            Positioned(
                              left: 0,
                              right: 0,
                              top: (t * size.height) % size.height,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF00FFFF)
                                          .withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00FFFF)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ],
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
                                      const Color(0xFF00FFFF)
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
                                      color: const Color(0xFF00FFFF),
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF00FFFF)
                                              .withValues(alpha: 0.9),
                                          blurRadius: 15,
                                        ),
                                        Shadow(
                                          color: const Color(0xFF0080FF)
                                              .withValues(alpha: 0.6),
                                          blurRadius: 25,
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
                                            color: const Color(0xFF00FFFF),
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
                                        color: const Color(0xFF80D4FF),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),

                            // Corner accents
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CornerAccentsPainter(t: t),
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

class _DigitalGridPainter extends CustomPainter {
  final double t;

  _DigitalGridPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.15);

    // Vertical lines
    for (var i = 0; i < 8; i++) {
      final x = (size.width / 8) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (var i = 0; i < 8; i++) {
      final y = (size.height / 8) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DigitalGridPainter oldDelegate) => false;
}

class _HologramParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _HologramParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];

      // Fast vertical movement for digital effect
      final dx = (p.dx + 3 * sin((t + i * 0.2) * 3)) % size.width;
      final dy = (p.dy - (t * 80 + i * 5)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.5 + (i % 4) * 0.4;
      final alpha = (140 + 80 * sin((t + i) * 4)).clamp(80, 220).toInt();

      // Cyan and blue particles
      if (i % 2 == 0) {
        paint.color = Color.fromARGB(alpha, 0, 255, 255);
      } else {
        paint.color = Color.fromARGB(alpha, 0, 128, 255);
      }

      canvas.drawCircle(pos, radius, paint);

      // Add small trail
      paint.color = paint.color.withValues(alpha: alpha * 0.3 / 255);
      canvas.drawCircle(Offset(pos.dx, pos.dy + 3), radius * 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(_HologramParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _CornerAccentsPainter extends CustomPainter {
  final double t;

  _CornerAccentsPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..color =
          const Color(0xFF00FFFF).withValues(alpha: 0.6 + 0.3 * sin(t * 4));

    final cornerSize = size.width * 0.15;

    // Top-left
    canvas.drawLine(Offset(0, cornerSize), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(cornerSize, 0), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerSize), paint);

    // Bottom-left
    canvas.drawLine(
        Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerSize, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerSize, size.height),
        Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height - cornerSize),
        Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_CornerAccentsPainter oldDelegate) => oldDelegate.t != t;
}
