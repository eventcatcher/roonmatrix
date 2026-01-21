import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/ripple_painter.dart';

class RipplePing extends StatefulWidget {
  final bool trigger;
  final Color color;
  final double dotSize;
  final double maxRadius;
  final VoidCallback onFinished;

  const RipplePing({
    super.key,
    required this.trigger,
    this.color = Colors.greenAccent,
    this.dotSize = 10,
    this.maxRadius = 30,
    required this.onFinished,
  });

  @override
  State<RipplePing> createState() => _RipplePingState();
}

class _RipplePingState extends State<RipplePing>
    with SingleTickerProviderStateMixin {
  final Duration animationDuration = const Duration(milliseconds: 2000);

  bool lastTrigger = false;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: animationDuration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          widget.onFinished();
        }
      });
  }

  @override
  void didUpdateWidget(covariant RipplePing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!lastTrigger && widget.trigger) {
      _controller.forward(from: 0);
    }
    lastTrigger = widget.trigger;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.maxRadius * 2,
      height: widget.maxRadius * 2,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = Curves.easeOutExpo.transform(_controller.value);
          return CustomPaint(
            painter: RipplePainter(
              progress: t,
              color: widget.color,
              dotSize: widget.dotSize,
              maxRadius: widget.maxRadius,
            ),
          );
        },
      ),
    );
  }
}
