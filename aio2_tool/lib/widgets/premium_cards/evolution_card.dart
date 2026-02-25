import 'dart:math';
import 'package:flutter/material.dart';

/// EVOLUTION Premium Card - Green-turquoise transformation theme
class EvolutionCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const EvolutionCard(
      {Key? key,
      this.icon,
      this.title,
      this.subtitle,
      this.size = 140,
      this.onTap})
      : super(key: key);

  @override
  State<EvolutionCard> createState() => _EvolutionCardState();
}

class _EvolutionCardState extends State<EvolutionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(777);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
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
    final count = (size.width * size.height / 3200).clamp(18, 55).toInt();
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
                          Color(0xFF10B981),
                          Color(0xFF14B8A6),
                          Color(0xFF10B981)
                        ]),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xFF10B981).withValues(alpha: 0.7),
                              blurRadius: 30,
                              spreadRadius: 4),
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 15,
                              offset: Offset(0, 8)),
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
                              Color(0xFF064E3B),
                              Color(0xFF022C22),
                              Color(0xFF000000)
                            ]))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _DNAHelixPainter(t: t))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _EvolutionParticlePainter(
                                        particles: _particles, t: t))),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.5 + 3.0 * t, -1.0),
                                    end: Alignment(1.5 + 3.0 * t, 1.0),
                                    colors: [
                                      Colors.white.withValues(alpha: 0.0),
                                      Color(0xFF10B981).withValues(alpha: 0.2),
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
                                        color: Color(0xFF10B981),
                                        shadows: [
                                          Shadow(
                                              color: Color(0xFF10B981),
                                              blurRadius: 25)
                                        ]),
                                  if (widget.title != null) ...[
                                    SizedBox(height: 8),
                                    Text(widget.title!,
                                        style: TextStyle(
                                            fontSize: widget.size * 0.15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10B981),
                                            shadows: [
                                              Shadow(
                                                  color: Color(0xFF10B981),
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

class _DNAHelixPainter extends CustomPainter {
  final double t;
  _DNAHelixPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Color(0xFF10B981).withValues(alpha: 0.3);
    for (var i = 0; i < 20; i++) {
      final y = (size.height / 20) * i;
      final x1 = size.width * 0.3 + 20 * sin((t * 2 + i * 0.3) * pi);
      final x2 = size.width * 0.7 - 20 * sin((t * 2 + i * 0.3) * pi);
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DNAHelixPainter oldDelegate) => oldDelegate.t != t;
}

class _EvolutionParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;
  _EvolutionParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final dx = (p.dx + 4 * sin((t + i * 0.2) * 2)) % size.width;
      final dy = (p.dy + 3 * cos((t + i * 0.15) * 1.8)) % size.height;
      final pos = Offset(dx, dy);
      final radius = 0.7 + (i % 3) * 0.5;
      final alpha = (130 + 90 * sin((t + i) * 3)).clamp(70, 220).toInt();
      paint.color = i % 2 == 0
          ? Color.fromARGB(alpha, 16, 185, 129)
          : Color.fromARGB(alpha, 20, 184, 166);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_EvolutionParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
