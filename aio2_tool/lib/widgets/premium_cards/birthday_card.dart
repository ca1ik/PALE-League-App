import 'dart:math';
import 'package:flutter/material.dart';

/// BIRTHDAY Premium Card - Colorful celebration theme with balloons and confetti
class BirthdayCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final double size;
  final VoidCallback? onTap;

  const BirthdayCard(
      {Key? key,
      this.icon,
      this.title,
      this.subtitle,
      this.size = 140,
      this.onTap})
      : super(key: key);

  @override
  State<BirthdayCard> createState() => _BirthdayCardState();
}

class _BirthdayCardState extends State<BirthdayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(2025);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
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
    final count = (size.width * size.height / 2400).clamp(35, 90).toInt();
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
                          Color(0xFFFBBF24),
                          Color(0xFFEC4899),
                          Color(0xFF8B5CF6),
                          Color(0xFF3B82F6),
                          Color(0xFFFBBF24)
                        ], transform: GradientRotation(t * 2 * pi)),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0xFFFBBF24).withValues(alpha: 0.7),
                              blurRadius: 30,
                              spreadRadius: 4),
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
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
                              Color(0xFF1F2937),
                              Color(0xFF111827),
                              Color(0xFF000000)
                            ]))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _BalloonPainter(t: t))),
                            Positioned.fill(
                                child: CustomPaint(
                                    painter: _ConfettiParticlePainter(
                                        particles: _particles, t: t))),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.7,
                                    colors: [
                                      Colors.white.withValues(
                                          alpha:
                                              0.08 * (0.5 + 0.5 * sin(t * 4))),
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
                                        color: Color(0xFFFBBF24),
                                        shadows: [
                                          Shadow(
                                              color: Color(0xFFFBBF24),
                                              blurRadius: 25),
                                          Shadow(
                                              color: Color(0xFFEC4899),
                                              blurRadius: 35)
                                        ]),
                                  if (widget.title != null) ...[
                                    SizedBox(height: 8),
                                    Text(widget.title!,
                                        style: TextStyle(
                                            fontSize: widget.size * 0.15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFFBBF24),
                                            shadows: [
                                              Shadow(
                                                  color: Color(0xFFFBBF24),
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

class _BalloonPainter extends CustomPainter {
  final double t;
  _BalloonPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      Color(0xFFFBBF24),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6)
    ];
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.2 + i * 0.2);
      final y = size.height * 0.7 + 15 * sin((t + i * 0.5) * 3);
      paint.color = colors[i].withValues(alpha: 0.3);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 20, height: 28), paint);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.0;
      paint.color = colors[i].withValues(alpha: 0.5);
      canvas.drawLine(Offset(x, y + 14), Offset(x, y + 30), paint);
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(_BalloonPainter oldDelegate) => oldDelegate.t != t;
}

class _ConfettiParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;
  _ConfettiParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final colors = [
      Color(0xFFFBBF24),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFF10B981)
    ];
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      final dx = (p.dx + 4 * sin((t + i * 0.15) * 3)) % size.width;
      final dy = (p.dy + (t * 50 + i * 2)) % size.height;
      final pos = Offset(dx, dy);
      final rectSize = 2.0 + (i % 3);
      final alpha = (160 + 70 * sin((t + i) * 4)).clamp(100, 230).toInt();
      paint.color = colors[i % colors.length].withValues(alpha: alpha / 255);
      canvas.drawRect(
          Rect.fromCenter(center: pos, width: rectSize, height: rectSize * 1.5),
          paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiParticlePainter oldDelegate) =>
      oldDelegate.t != t;
}
