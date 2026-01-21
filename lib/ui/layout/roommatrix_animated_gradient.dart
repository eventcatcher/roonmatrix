import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget to display animated gradient.
class RoonmatrixAnimatedGradient extends StatefulWidget {
  final Widget? child;
  final List<Color> colors;

  const RoonmatrixAnimatedGradient({
    super.key,
    this.child,
    this.colors = const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
  });

  @override
  RoonmatrixAnimatedGradientState createState() =>
      RoonmatrixAnimatedGradientState();
}

class RoonmatrixAnimatedGradientState
    extends State<RoonmatrixAnimatedGradient> {
  List<Color> get colors => widget.colors;

  List<Alignment> alignmentList = [
    Alignment.bottomLeft,
    Alignment.bottomRight,
    Alignment.topRight,
    Alignment.topLeft
  ];

  int index = 0;
  Color bottomColor = Colors.transparent;
  Color topColor = Colors.transparent;
  Alignment begin = Alignment.bottomLeft;
  Alignment end = Alignment.topRight;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        setState(
          () {
            topColor = colors.first;
            bottomColor = colors.last;
          },
        );
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 2),
      onEnd: () {
        setState(
          () {
            index = index + 1;
            // animate the color
            bottomColor = colors[index % colors.length];
            topColor = colors[(index + 1) % colors.length];

            // animate the alignment
            begin = alignmentList[index % alignmentList.length];
            end = alignmentList[(index + 2) % alignmentList.length];
          },
        );
      },
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: begin, end: end, colors: [bottomColor, topColor]),
      ),
      child: widget.child,
    );
  }
}
