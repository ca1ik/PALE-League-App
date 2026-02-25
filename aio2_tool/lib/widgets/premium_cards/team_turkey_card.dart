import 'dart:math';
import 'package:flutter/material.dart';

/// TEAM TURKEY Premium Card - Red-white Turkish flag theme
class TeamTurkeyCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const TeamTurkeyCard(
      {Key? key,
      this.icon,
      this.title,
      this.subtitle,
      this.size = 140,
      this.onTap})
      : super(key: key);

  @override
  State<TeamTurkeyCard> createState() => _TeamTurkeyCardState();
}

class _TeamTurkeyCardState extends State<TeamTurkeyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(1923);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 7))
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
    final count = (size.width * size.height / 3000).clamp(20, 60).toInt();
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
                          Color(0xFFDC2626),
                          Color(0xFFFFFFFF),
                          Color(0xFFDC2626)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xFFDC2626).withValues(alpha: 0.8),
                              blurRadius: 32,
                              spreadRadius: 4),
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 18,
                              offset: Offset(0, 9)),
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
                                    gradient: LinearGradient(colors: [
                              Color(0xFF7F1D1D),
                              Color(0xFF450A0A),
                              Color(0xFF1A0000)
                            ]))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _CrescentStarTurkeyPainter(t: t))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _TurkeyParticlePainter(
                                        particles: _particles, t: t))),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.5 + 3.0 * t, -1.0),
                                    end: Alignment(1.5 + 3.0 * t, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Colors.white.withValues(alpha: 0.15),
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
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                              color: Color(0xFFDC2626),
                                              blurRadius: 25),
                                          Shadow(
                                              color: Colors.white,
                                              blurRadius: 35)
                                        ]),
                                  if (widget.title != null) ...[
                                    SizedBox(height: 8),
                                    Text(widget.title!,
                                        style: TextStyle(
                                            fontSize: widget.size * 0.15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                  color: Color(0xFFDC2626),
                                                  blurRadius: 12)
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

class _CrescentStarTurkeyPainter extends CustomPainter {
  final double t;
  _CrescentStarTurkeyPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.15 + 0.1 * sin(t * 4));
    final center = Offset(size.width * 0.5, size.height * 0.3);
    final moonRadius = size.width * 0.12;
    canvas.drawCircle(center, moonRadius, paint);
    paint.color = Color(0xFF7F1D1D);
    canvas.drawCircle(
        center + Offset(moonRadius * 0.5, 0), moonRadius * 0.85, paint);
    paint.color = Colors.white.withValues(alpha: 0.2);
    final starCenter = Offset(size.width * 0.65, size.height * 0.3);
    final starPath = Path();
    for (var i = 0; i < 5; i++) {
      final angle = (i * 4 * pi / 5) - pi / 2;
      final x = starCenter.dx + cos(angle) * size.width * 0.08;
      final y = starCenter.dy + sin(angle) * size.width * 0.08;
      if (i == 0)
        starPath.moveTo(x, y);
      else
        starPath.lineTo(x, y);
    }
    starPath.close();
    canvas.drawPath(starPath, paint);
  }

  @override
  bool shouldRepaint(_CrescentStarTurkeyPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _TurkeyParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;
  _TurkeyParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final dx = (p.dx + 3 * sin((t + i * 0.2) * 2)) % size.width;
      final dy = (p.dy + 2.5 * cos((t + i * 0.15) * 1.8)) % size.height;
      final pos = Offset(dx, dy);
      final radius = 0.8 + (i % 3) * 0.6;
      final alpha = (140 + 80 * sin((t + i) * 2.5)).clamp(80, 220).toInt();
      paint.color = i % 2 == 0
          ? Color.fromARGB(alpha, 220, 38, 38)
          : Color.fromARGB(alpha, 255, 255, 255);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_TurkeyParticlePainter oldDelegate) => oldDelegate.t != t;
}
