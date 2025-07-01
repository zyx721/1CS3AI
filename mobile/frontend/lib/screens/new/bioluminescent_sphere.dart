// lib/widgets/bioluminescent_sphere.dart
import 'package:flutter/material.dart';
import 'dart:math'; // For sin and cos

class BioluminescentSphere extends StatefulWidget {
  final double animationValue; // Represents 'loudness' for displacement
  final Color primaryColor;    // Base color of the sphere
  final Color accentColor1;    // First accent color
  final Color accentColor2;    // Second accent color

  const BioluminescentSphere({
    Key? key,
    required this.animationValue,
    required this.primaryColor,
    required this.accentColor1,
    required this.accentColor2,
  }) : super(key: key);

  @override
  _BioluminescentSphereState createState() => _BioluminescentSphereState();
}

class _BioluminescentSphereState extends State<BioluminescentSphere> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Drives the 'time' uniform

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Long duration for continuous background animation
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: SpherePainter(
            animationValue: widget.animationValue,
            time: _controller.value * 2 * 10, // Scale time for visual effect
            primaryColor: widget.primaryColor,
            accentColor1: widget.accentColor1,
            accentColor2: widget.accentColor2,
          ),
          child: Container(), // Empty container as the custom painter draws directly
        );
      },
    );
  }
}

class SpherePainter extends CustomPainter {
  final double animationValue; // Corresponds to u_loudness
  final double time;           // Corresponds to u_time
  final Color primaryColor;
  final Color accentColor1;
  final Color accentColor2;

  SpherePainter({
    required this.animationValue,
    required this.time,
    required this.primaryColor,
    required this.accentColor1,
    required this.accentColor2,
  });

  // A simplified 2D noise approximation (not true Perlin noise)
  double _noise(double x, double y, double t) {
    return (
        0.5 * (
            sin(x * 5 + t) * 0.5 +
            cos(y * 5 + t) * 0.5
        ) +
        0.5 * (
            cos(x * 10 + t * 0.5) * 0.3 +
            sin(y * 10 + t * 0.5) * 0.3
        )
    ) * 0.5; // Scale down for subtle effect
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.shortestSide * 0.35; // Approx. sphere radius, scales with screen size

    final paint = Paint();

    canvas.save();
    canvas.translate(center.dx, center.dy);

    const int segments = 360; // For drawing the sphere contour
    final path = Path();

    for (int i = 0; i <= segments; i++) {
      final angle = 2 * pi * (i / segments);
      final x = baseRadius * cos(angle);
      final y = baseRadius * sin(angle);

      // Apply the simulated 'noise' and 'loudness' for displacement
      final noise = _noise(x / baseRadius, y / baseRadius, time);
      final displacement = animationValue * 1.5; // Matches u_loudness * 1.5 from shader
      final finalRadius = baseRadius + (noise + displacement) * (baseRadius * 0.2); // Controls displacement magnitude

      final deformedX = finalRadius * cos(angle);
      final deformedY = finalRadius * sin(angle);

      if (i == 0) {
        path.moveTo(deformedX, deformedY);
      } else {
        path.lineTo(deformedX, deformedY);
      }
    }
    path.close();

    // Create a radial gradient for the 'bioluminescent' effect and color mixing
    paint.shader = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: [
        primaryColor,
        accentColor1,
        accentColor2,
      ].map((color) {
        // Brighten colors slightly based on animationValue (loudness)
        final factor = (animationValue * 0.5 + 0.5).clamp(0.0, 1.0);
        return Color.lerp(color, Colors.white.withOpacity(0.8), factor)!;
      }).toList(),
      stops: const [0.0, 0.6, 1.0],
      transform: GradientRotation(time * 0.05), // Subtle rotation of the gradient
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: baseRadius * 1.2));

    // Simulate the blur filter from chat.html
    paint.maskFilter = MaskFilter.blur(BlurStyle.outer, baseRadius * 0.05);
    
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SpherePainter oldDelegate) {
    // Only repaint if critical properties change
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.time != time ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor1 != accentColor1 ||
           oldDelegate.accentColor2 != accentColor2;
  }
}