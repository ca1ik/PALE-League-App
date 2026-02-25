import 'dart:math';

import 'package:flutter/material.dart';

/// A decorative "golden" card inspired by the provided design.
///
/// - Gold outer border and inner white/marble tone.
/// - Slow shimmer animation across the card.
/// - Subtle animated gold speckles.
class GoldenCard extends StatefulWidget {
  final double width;
  final double height;
  final Widget? child;

  const GoldenCard({
    Key? key,
    this.width = 360,
    this.height = 640,
    this.child,
  }) : super(key: key);

  @override
  State<GoldenCard> createState() => _GoldenCardState();
}

class _GoldenCardState extends State<GoldenCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(42);

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
    // initial empty; will be generated in build when size is known
    _particles = [];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _ensureParticles(Size size) {
    if (_particles.isNotEmpty) return;
    final count = (size.width * size.height / 20000).clamp(18, 120).toInt();
    for (var i = 0; i < count; i++) {
      _particles.add(Offset(
        _rnd.nextDouble() * size.width,
        _rnd.nextDouble() * size.height,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: LayoutBuilder(builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _ensureParticles(size);

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            // shimmer position cycles 0..1
            final t = _ctrl.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer gold border
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: SweepGradient(
                      colors: [
                        Colors.amber.shade700,
                        Colors.amber.shade300,
                        Colors.amber.shade800,
                        Colors.amber.shade600,
                      ],
                      stops: const [0.0, 0.35, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                ),

                // Inner white card with marble-like gradient and gold streak
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Marble base
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey.shade100,
                                Colors.grey.shade200,
                              ],
                              stops: const [0.0, 0.6, 1.0],
                            ),
                          ),
                        ),

                        // soft cracks / veins (subtle)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _VeinPainter(opacity: 0.08),
                          ),
                        ),

                        // gold streak (diagonal decorative band)
                        Positioned.fill(
                          child: Transform.rotate(
                            angle: -0.25,
                            origin: Offset(-size.width * 0.1, 0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                widthFactor: 1.2,
                                heightFactor: 0.28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade300,
                                        Colors.amber.shade700,
                                        Colors.brown.shade700,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // slow shimmer overlay using animated gradient
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(-1.5 + 3.0 * t, -1.0),
                                  end: Alignment(1.5 + 3.0 * t, 1.0),
                                  colors: [
                                    Colors.white.withOpacity(0.00),
                                    Colors.white.withOpacity(0.05),
                                    Colors.white.withOpacity(0.00),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                                backgroundBlendMode: BlendMode.srcOver,
                              ),
                            ),
                          ),
                        ),

                        // animated gold speckles
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SpecklePainter(
                              particles: _particles,
                              t: t,
                            ),
                          ),
                        ),

                        if (widget.child != null)
                          Positioned.fill(child: widget.child!),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }
}

class _SpecklePainter extends CustomPainter {
  final List<Offset> particles;
  final double t;

  _SpecklePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      // subtle drifting effect
      final dx =
          (p.dx + 8 * (i % 3 == 0 ? sin((t + i) * 2) : cos((t + i) * 1.5))) %
              size.width;
      final dy = (p.dy + 6 * sin((t + i) * 1.3)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.6 + (i % 5) * 0.6;
      final alpha = (120 + 80 * sin((t + i) * 3)).clamp(40, 200).toInt();
      paint.color = Color.fromARGB(alpha, 255, 215, 80);
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpecklePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _VeinPainter extends CustomPainter {
  final double opacity;
  _VeinPainter({this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.withOpacity(opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // draw a few soft curved veins
    path.moveTo(size.width * 0.1, size.height * 0.25);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.22,
        size.width * 0.5, size.height * 0.28);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.34,
        size.width * 0.9, size.height * 0.30);

    path.moveTo(size.width * 0.2, size.height * 0.6);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.58,
        size.width * 0.6, size.height * 0.64);
    path.quadraticBezierTo(size.width * 0.8, size.height * 0.70,
        size.width * 0.95, size.height * 0.68);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VeinPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
