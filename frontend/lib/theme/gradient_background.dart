import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showGlow;

  const GradientBackground({
    super.key,
    required this.child,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: showGlow
              ? [
                  const Color(0xFF0A0E12),
                  const Color(0xFF0F1815),
                  const Color(0xFF0A0E12),
                ]
              : [
                  const Color(0xFF0A0E12),
                  const Color(0xFF0A0E12),
                ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: child,
    );
  }
}
