import 'dart:math';
import 'package:flutter/material.dart';

/// TRICKSTER Premium Card - Neon pink-purple illusion theme
class TricksterCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const TricksterCard(
      {Key? key,
      this.icon,
      this.title,
      this.subtitle,
      this.size = 140,
      this.onTap})
      : super(key: key);

  @override
  State<TricksterCard> createState() => _TricksterCardState();
}

class _TricksterCardState extends State<TricksterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(369);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
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
          _rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height));
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
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: [
                          Color(0xFFD946EF),
                          Color(0xFFA855F7),
                          Color(0xFFD946EF)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xFFD946EF).withValues(alpha: 0.8),
                              blurRadius: 35,
                              spreadRadius: 5),
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 20,
                              offset: Offset(0, 10)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(7.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                    gradient: RadialGradient(colors: [
                              Color(0xFF2E1065),
                              Color(0xFF1E1B4B),
                              Color(0xFF000000)
                            ]))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _IllusionPainter(t: t))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _TrickParticlePainter(
                                        particles: _particles, t: t))),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.5 + 3.0 * t, -1.0),
                                    end: Alignment(1.5 + 3.0 * t, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Color(0xFFD946EF).withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.0)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (widget.icon != null)
                                    Icon(widget.icon,
                                        size: widget.size * 0.45,
                                        color: Color(0xFFD946EF),
                                        shadows: [
                                          Shadow(
                                              color: Color(0xFFD946EF),
                                              blurRadius: 30),
                                          Shadow(
                                              color: Color(0xFFA855F7),
                                              blurRadius: 40)
                                        ]),
                                  if (widget.title != null) ...[
                                    SizedBox(height: 8),
                                    Text(widget.title!,
                                        style: TextStyle(
                                            fontSize: widget.size * 0.15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD946EF),
                                            shadows: [
                                              Shadow(
                                                  color: Color(0xFFD946EF),
                                                  blurRadius: 15)
                                            ]),
                                        textAlign: TextAlign.center),
                                  ],
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

class _IllusionPainter extends CustomPainter {
  final double t;
  _IllusionPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Color(0xFFD946EF).withValues(alpha: 0.25);
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 8; i++) {
      final radius = 20.0 + i * 12 + 10 * sin((t + i * 0.3) * 4);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_IllusionPainter oldDelegate) => oldDelegate.t != t;
}

class _TrickParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;
  _TrickParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final angle = (t + i * 0.1) * 3;
      final radius = 20 + (i % 5) * 10;
      final dx = (p.dx + cos(angle) * radius) % size.width;
      final dy = (p.dy + sin(angle) * radius) % size.height;
      final pos = Offset(dx, dy);
      final particleRadius = 0.7 + (i % 3) * 0.6;
      final alpha = (150 + 90 * sin((t + i) * 5)).clamp(80, 240).toInt();
      paint.color = i % 2 == 0
          ? Color.fromARGB(alpha, 217, 70, 239)
          : Color.fromARGB(alpha, 168, 85, 247);
      canvas.drawCircle(pos, particleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_TrickParticlePainter oldDelegate) => oldDelegate.t != t;
}
