import 'dart:math';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});
  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    for (int i = 0; i < 70; i++) _particles.add(Particle(_rng));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0C29), Color(0xFF302b63), Color(0xFF24243E)],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            for (var p in _particles) p.update();
            return CustomPaint(
                painter: ParticlePainter(_particles), size: Size.infinite);
          },
        ),
      ],
    );
  }
}

class Particle {
  double x = 0, y = 0, speedX = 0, speedY = 0, size = 0, opacity = 0;
  Particle(Random rng) {
    reset(rng, true);
  }
  void reset(Random rng, bool randomY) {
    x = rng.nextDouble();
    y = randomY ? rng.nextDouble() : 1.1;
    speedX = (rng.nextDouble() - 0.5) * 0.0002;
    speedY = -(rng.nextDouble() * 0.0004 + 0.0001);
    size = rng.nextDouble() * 2 + 1;
    opacity = rng.nextDouble() * 0.5 + 0.2;
  }

  void update() {
    x += speedX;
    y += speedY;
    if (y < -0.1) reset(Random(), false);
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  ParticlePainter(this.particles);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      paint.color = Colors.white.withOpacity(p.opacity);
      canvas.drawCircle(
          Offset(p.x * size.width, p.y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
