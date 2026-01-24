import 'dart:ui';
import 'package:flutter/material.dart';

class GlassBox extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final VoidCallback? onTap;

  const GlassBox({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: width,
          height: height,
          color: Colors.transparent,
          child: Stack(
            children: [
              // Blur Efekti
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(),
              ),
              // Yarı Saydam Gradyan (Işık Yansıması)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1.5),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              // İçerik
              Center(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
