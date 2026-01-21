import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:hovering/hovering.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SliderHoverOverlay extends StatefulWidget {
  final String label;
  final double width;
  final double height;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(PointerEnterEvent event)? onHover;
  final Function(double value) updateValue;

  const SliderHoverOverlay({
    super.key,
    required this.label,
    required this.width,
    this.height = 36.0,
    this.value = 1.0,
    this.min = 0.75,
    this.max = 5,
    this.divisions = 100,
    this.onHover,
    required this.updateValue,
  });

  @override
  State<SliderHoverOverlay> createState() => _SliderHoverOverlayState();
}

class _SliderHoverOverlayState extends State<SliderHoverOverlay> {
  final Color backgroundColor = Color.fromARGB(200, 33, 33, 33);
  final TextStyle labelStyle = TextStyle(
    color: Colors.white,
  );

  double value = 1.0;
  double labelWidth = 200;

  @override
  void initState() {
    value = widget.value;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        labelWidth = SharedWidgets.measureTextSize(
            context: context, text: widget.label, style: labelStyle);
      }
    });

    super.initState();
  }

  @override
  void didUpdateWidget(SliderHoverOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    value = widget.value;
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        labelWidth = SharedWidgets.measureTextSize(
            context: context, text: widget.label, style: labelStyle);
      }
    });
  }

  @override
  Widget build(BuildContext context) => HoverWidget(
        hoverChild: InkWell(
          onDoubleTap: () => widget.updateValue(1.0),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.ease,
            duration: const Duration(seconds: 1),
            builder: (BuildContext context, double opacity, Widget? child) {
              return Opacity(
                  opacity: opacity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: SharedWidgets.borderRadius(),
                      color: backgroundColor,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 8.0, bottom: 9.0),
                          child: Text(
                            widget.label,
                            style: labelStyle,
                          ),
                        ),
                        SizedBox(
                          width: widget.width,
                          height: widget.height,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 9.0),
                            child: Slider(
                                value: value,
                                min: widget.min,
                                max: widget.max,
                                divisions: widget.divisions,
                                thumbColor: Colors.red.shade700,
                                activeColor: Colors.green.shade200,
                                inactiveColor: Colors.grey.shade700,
                                onChanged: (double value) =>
                                    widget.updateValue(value)),
                          ),
                        ),
                      ],
                    ),
                  ));
            },
          ),
        ),
        onHover: (PointerEnterEvent event) =>
            widget.onHover != null ? widget.onHover!(event) : null,
        child: Container(
          width: labelWidth + widget.width + 10,
          height: widget.height,
          color: Colors.transparent,
        ),
      );
}
