import 'package:flutter/material.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';

class SliderExpandable extends StatefulWidget {
  final double width;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(double value) updateValue;

  const SliderExpandable({
    super.key,
    required this.width,
    this.value = 1.0,
    this.min = 0.25,
    this.max = 5,
    this.divisions = 100,
    required this.updateValue,
  });

  @override
  State<SliderExpandable> createState() => _SliderExpandableState();
}

class _SliderExpandableState extends State<SliderExpandable> {
  final double size = 38.0;
  final int animationSpeed = 400;

  double value = 1.0;

  @override
  void initState() {
    value = widget.value;

    super.initState();
  }

  @override
  void didUpdateWidget(SliderExpandable oldWidget) {
    super.didUpdateWidget(oldWidget);

    value = widget.value;
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned(
            top: 4.0,
            right: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                    width: widget.width,
                    height: size,
                    child: ExpandableMenu(
                      key: ValueKey('SliderExpandable'),
                      width: size,
                      height: size,
                      animationSpeed: animationSpeed,
                      backgroundColor:
                          ColorDefs.buttonRowBackgroundColor(context: context),
                      items: [
                        SizedBox(
                          width: widget.width - 84.0,
                          child: Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Slider(
                              value: value,
                              min: widget.min,
                              max: widget.max,
                              divisions: widget.divisions,
                              thumbColor: Colors.red.shade700,
                              activeColor: Colors.green.shade200,
                              inactiveColor: Colors.grey.shade700,
                              onChanged: (double value) =>
                                  widget.updateValue(value),
                            ),
                          ),
                        )
                      ],
                    )),
              ],
            ),
          ),
        ],
      );
}
