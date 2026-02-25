import 'dart:math';
import 'package:flutter/material.dart';

/// DREAMCHASERS Premium Card - Blue-purple galaxy theme
class DreamchasersCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const DreamchasersCard(
      {Key? key,
      this.icon,
      this.title,
      this.subtitle,
      this.size = 140,
      this.onTap})
      : super(key: key);

  @override
  State<DreamchasersCard> createState() => _DreamchasersCardState();
}

class _DreamchasersCardState extends State<DreamchasersCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(888);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 11))
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
    final count = (size.width * size.height / 2600).clamp(30, 80).toInt();
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
                        gradient: SweepGradient(colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                          Color(0xFF3B82F6),
                          Color(0xFF6366F1)
                        ], transform: GradientRotation(t * 2 * pi)),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xFF6366F1).withValues(alpha: 0.8),
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
                              Color(0xFF1E1B4B),
                              Color(0xFF0F172A),
                              Color(0xFF000000)
                            ]))),
                            Positioned.fill(
                                child:
                                    CustomPaint(painter: _GalaxyPainter(t: t))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _StarParticlePainter(
                                        particles: _particles, t: t))),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.6 + 0.3 * sin(t * 2),
                                    colors: [
                                      Color(0xFF6366F1).withValues(
                                          alpha:
                                              0.15 * (0.5 + 0.5 * sin(t * 3))),
                                      Colors.transparent
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
                                        color: Color(0xFF818CF8),
                                        shadows: [
                                          Shadow(
                                              color: Color(0xFF6366F1),
                                              blurRadius: 30),
                                          Shadow(
                                              color: Color(0xFF8B5CF6),
                                              blurRadius: 40)
                                        ]),
                                  if (widget.title != null) ...[
                                    SizedBox(height: 8),
                                    Text(widget.title!,
                                        style: TextStyle(
                                            fontSize: widget.size * 0.15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF818CF8),
                                            shadows: [
                                              Shadow(
                                                  color: Color(0xFF6366F1),
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

class _GalaxyPainter extends CustomPainter {
  final double t;
  _GalaxyPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 5; i++) {
      final angle = (t * 2 * pi) + (i * 2 * pi / 5);
      final radius = 30.0 + i * 15;
      paint.color = Color(0xFF6366F1).withValues(alpha: 0.1 - i * 0.015);
      for (var j = 0; j < 20; j++) {
        final a = angle + (j * 0.3);
        final r = radius + j * 2;
        final x = center.dx + cos(a) * r;
        final y = center.dy + sin(a) * r;
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GalaxyPainter oldDelegate) => oldDelegate.t != t;
}

class _StarParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;
  _StarParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final dx = (p.dx + 2 * sin((t + i * 0.1) * 1.5)) % size.width;
      final dy = (p.dy + 1.5 * cos((t + i * 0.12) * 1.3)) % size.height;
      final pos = Offset(dx, dy);
      final radius = 0.6 + (i % 4) * 0.5;
      final alpha = (150 + 80 * sin((t + i) * 2.5)).clamp(90, 230).toInt();
      paint.color = i % 3 == 0
          ? Color.fromARGB(alpha, 99, 102, 241)
          : (i % 3 == 1
              ? Color.fromARGB(alpha, 139, 92, 246)
              : Color.fromARGB(alpha, 59, 130, 246));
      canvas.drawCircle(pos, radius, paint);
      if (i % 6 == 0) {
        paint.color = Colors.white.withValues(alpha: alpha * 0.4 / 255);
        canvas.drawCircle(pos, radius * 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_StarParticlePainter oldDelegate) => oldDelegate.t != t;
}
