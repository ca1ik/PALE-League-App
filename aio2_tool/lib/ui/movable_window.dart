import 'package:flutter/material.dart';

class MovableWindow extends StatefulWidget {
  final Widget child;
  final double initialX;
  final double initialY;

  const MovableWindow({
    super.key,
    required this.child,
    this.initialX = 50,
    this.initialY = 50,
  });

  @override
  State<MovableWindow> createState() => _MovableWindowState();
}

class _MovableWindowState extends State<MovableWindow> {
  late double x;
  late double y;

  @override
  void initState() {
    super.initState();
    x = widget.initialX;
    y = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
        },
        child: widget.child,
      ),
    );
  }
}
