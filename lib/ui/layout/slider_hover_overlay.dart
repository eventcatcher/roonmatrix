import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hovering/hovering.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class SliderHoverOverlay extends StatefulWidget {
  final Map<String, dynamic> translations;
  final double width;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(double speed) updateValue;

  const SliderHoverOverlay({
    super.key,
    required this.translations,
    required this.width,
    this.min = 0.75,
    this.max = 5,
    this.divisions = 100,
    this.value = 1.0,
    required this.updateValue,
  });

  @override
  State<SliderHoverOverlay> createState() => _SliderHoverOverlayState();
}

class _SliderHoverOverlayState extends State<SliderHoverOverlay> {
  double value = 1.0;

  @override
  void initState() {
    value = widget.value;

    super.initState();
  }

  @override
  void didUpdateWidget(SliderHoverOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    value = widget.value;
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
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    color: Color.fromARGB(200, 33, 33, 33),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 9.0),
                        child: Text(
                          '${widget.translations['speed'] ?? 'speed:'}:',
                          style: TextStyle(
                            color: SharedWidgets.borderColor(context: context),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: widget.width,
                        height: 36.0,
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
      onHover: (PointerEnterEvent event) {
        //
      },
      child: Container(
        width: 120 + widget.width,
        height: 54,
        color: Colors.transparent,
      ));
}
