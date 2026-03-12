import 'package:flutter/material.dart';

class RipplePainter extends CustomPainter {
  final double progress;
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

    final double fadeProgress = Curves.easeOut.transform(1 - progress);
    final double offset = maxRadius * 0.35;
    final Offset center = Offset(
      size.width / 2 - offset,
      (maxRadius + size.height) / 2 - offset - 1,
    );

    // ripple-circle
    final Paint ripplePaint = Paint()
      ..color = color.withValues(alpha: (1 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(
      center,
      maxRadius * progress,
      ripplePaint,
    );

    // dot (Ease-Out Fade)
    final Paint dotPaint = Paint()
      ..color = color.withValues(alpha: fadeProgress)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    canvas.drawCircle(center, dotSize, dotPaint);
  }

  @override
  bool shouldRepaint(covariant RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
