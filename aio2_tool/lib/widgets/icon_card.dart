import 'dart:math';

import 'package:flutter/material.dart';

/// A premium icon card with glossy golden border and sparkling edge effects.
///
/// - Golden animated border with shimmer
/// - White marble-like base or custom background image
/// - Animated gold speckles
/// - Edge shine effects
/// - Perfect for card types and new card displays
class IconCard extends StatefulWidget {
  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;
  final LinearGradient? customGradient;
  final String? backgroundImagePath;

  const IconCard({
    Key? key,
    this.icon,
    this.title,
    this.subtitle,
    this.iconColor = Colors.amberAccent,
    this.size = 140,
    this.onTap,
    this.customGradient,
    this.backgroundImagePath,
  }) : super(key: key);

  @override
  State<IconCard> createState() => _IconCardState();
}

class _IconCardState extends State<IconCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<Offset> _particles;
  final Random _rnd = Random(42);

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
    final count = (size.width * size.height / 4000).clamp(12, 45).toInt();
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
        child: LayoutBuilder(builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          _ensureParticles(size);

          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = _ctrl.value;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // OUTER GOLDEN BORDER with gradient and glow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: SweepGradient(
                        colors: [
                          Colors.amber.shade600,
                          Colors.amber.shade300,
                          Colors.amber.shade700,
                          Colors.amber.shade500,
                          Colors.amber.shade600,
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        startAngle: t * 2 * pi,
                        endAngle: t * 2 * pi + pi,
                      ),
                      boxShadow: [
                        // Glow around the border
                        BoxShadow(
                          color: Colors.amber.shade400.withOpacity(0.6),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                        // Darker shadow for depth
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                  ),

                  // INNER CARD with marble texture
                  Padding(
                    padding: const EdgeInsets.all(7.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Background - Image or Marble
                          if (widget.backgroundImagePath != null)
                            // Animated background image with pulsing overlay
                            Positioned.fill(
                              child: Stack(
                                children: [
                                  Image.asset(
                                    widget.backgroundImagePath!,
                                    fit: BoxFit.cover,
                                  ),
                                  // Pulsing glow overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.amber.withOpacity(0.3 *
                                              (0.5 + 0.5 * sin((t + 1) * 3))),
                                          Colors.amber.withOpacity(0.1),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // Marble base gradient (default)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey.shade50,
                                    Colors.grey.shade200,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),

                          // Subtle veins for marble effect (only if no background image)
                          if (widget.backgroundImagePath == null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _VeinPainter(opacity: 0.06),
                              ),
                            ),

                          // Diagonal gold streak (top)
                          Positioned.fill(
                            child: Transform.rotate(
                              angle: -0.3,
                              origin: Offset(-size.width * 0.15, 0),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: FractionallySizedBox(
                                  widthFactor: 1.3,
                                  heightFactor: 0.32,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.shade200,
                                          Colors.amber.shade600,
                                          Colors.brown.shade700,
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Animated shimmer overlay
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment(-1.5 + 3.0 * t, -1.0),
                                    end: Alignment(1.5 + 3.0 * t, 1.0),
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white.withOpacity(0.08),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  backgroundBlendMode: BlendMode.srcOver,
                                ),
                              ),
                            ),
                          ),

                          // Animated gold speckles
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _SpecklePainter(
                                  particles: _particles,
                                  t: t,
                                ),
                              ),
                            ),
                          ),

                          // Icon content in center
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.icon != null)
                                  Icon(
                                    widget.icon,
                                    size: widget.size * 0.45,
                                    color: widget.iconColor,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
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
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (widget.subtitle != null)
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      fontSize: widget.size * 0.1,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                              ],
                            ),
                          ),

                          // Glossy overlay (top-left to bottom-right)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: size.width * 0.7,
                            bottom: size.height * 0.7,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Shine effect on edges (animated)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _EdgeShinePainter(t: t),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Border shine effects
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _BorderShinePainter(t: t),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
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
      final dx =
          (p.dx + 6 * (i % 3 == 0 ? sin((t + i) * 2) : cos((t + i) * 1.5))) %
              size.width;
      final dy = (p.dy + 5 * sin((t + i) * 1.3)) % size.height;
      final pos = Offset(dx, dy);

      final radius = 0.5 + (i % 4) * 0.5;
      final alpha = (100 + 70 * sin((t + i) * 3)).clamp(40, 170).toInt();
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
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.35, size.height * 0.25,
        size.width * 0.65, size.height * 0.35);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.42,
        size.width * 0.95, size.height * 0.38);

    path.moveTo(size.width * 0.15, size.height * 0.65);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.62,
        size.width * 0.88, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VeinPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

class _EdgeShinePainter extends CustomPainter {
  final double t;
  _EdgeShinePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Animated edge shine - moves around the border
    final alpha = (150 * (0.5 + 0.5 * sin(t * 6))).toInt().clamp(0, 200);
    paint.color = Colors.white.withOpacity(alpha / 255);

    final path = Path();
    final radius = 16.0;
    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius));
    path.addRRect(rect);

    // Draw shimmer along the path
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgeShinePainter oldDelegate) =>
      oldDelegate.t != t;
}

class _BorderShinePainter extends CustomPainter {
  final double t;
  _BorderShinePainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Animated glint effects at corners
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.screen;

    final corners = [
      Offset(size.width * 0.15, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.15),
      Offset(size.width * 0.15, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.85),
    ];

    for (var i = 0; i < corners.length; i++) {
      final glintAlpha =
          (120 * (0.4 + 0.6 * sin((t + i * 0.25) * 8))).toInt().clamp(0, 150);
      paint.color = Colors.amber.shade200.withOpacity(glintAlpha / 255);
      canvas.drawCircle(corners[i], 8 + 3 * sin((t + i) * 3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BorderShinePainter oldDelegate) =>
      oldDelegate.t != t;
}
