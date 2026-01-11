import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final double progress; // 0 -> 1
  final Color color;
  final double dotSize;
  final double maxRadius;

  RipplePainter({
    required this.progress,
    required this.color,
    required this.dotSize,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    // Ease-Out für den Fade
    final fadeProgress = Curves.easeOut.transform(1 - progress);

    // Punkt-Position
    final offset = maxRadius * 0.35;
    final center = Offset(
      size.width / 2 - offset,
      size.height / 2 - offset,
    );

    // Ripple-Kreis (leicht transparent, linear ok)
    final ripplePaint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      center,
      maxRadius * progress,
      ripplePaint,
    );

    // Punkt (Ease-Out Fade)
    final dotPaint = Paint()
      ..color = color.withValues(alpha: fadeProgress)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawCircle(center, dotSize, dotPaint);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
