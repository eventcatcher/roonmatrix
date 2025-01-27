import 'dart:io';

import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class HorizontalSlider extends StatefulWidget {
  final String label;
  final double? labelWidth;
  final double min;
  final double max;
  final int divisions;
  final double sliderValue;
  final String valueType;
  final Orientation orientation;

  final Function(double value) onChanged;

  const HorizontalSlider({
    super.key,
    required this.label,
    required this.min,
    required this.max,
    required this.divisions,
    required this.sliderValue,
    required this.valueType,
    this.labelWidth,
    required this.orientation,
    required this.onChanged,
  });

  @override
  State<HorizontalSlider> createState() => _HorizontalSliderState();
}

class _HorizontalSliderState extends State<HorizontalSlider> {
  double sliderValue = 1.0;

  @override
  void initState() {
    sliderValue = widget.sliderValue;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        margin: EdgeInsets.only(
            bottom: (Platform.isIOS || Platform.isAndroid) &&
                    widget.orientation == Orientation.landscape
                ? 4.0
                : 8.0),
        padding: EdgeInsets.symmetric(
            horizontal: 8.0,
            vertical: (Platform.isIOS || Platform.isAndroid) &&
                    widget.orientation == Orientation.landscape
                ? 0.0
                : 8.0),
        decoration: BoxDecoration(
          color: SharedWidgets.brightness() == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade300,
          border: Border.all(
            color: SharedWidgets.brightness() == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade400,
            width: 5.0,
          ),
          borderRadius: BorderRadius.all(
              Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5)),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 0,
            ),
          ],
        ),
        child: MediaQuery.of(context).size.width > 600
            ? Row(
                children: [
                  Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: Text(
                        '${widget.label}: ',
                        style: TextStyle(
                          color: SharedWidgets.textColor(context: context),
                        ),
                      )),
                  Flexible(
                    flex: MediaQuery.of(context).size.width > 1200
                        ? 3
                        : MediaQuery.of(context).size.width > 800
                            ? 2
                            : 1,
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                      child: SizedBox(
                        width: widget.labelWidth ?? 200,
                        child: Slider(
                          value: widget.sliderValue,
                          min: widget.min,
                          max: widget.max,
                          divisions: widget.divisions,
                          thumbColor: Colors.red.shade700,
                          activeColor: Colors.green.shade200,
                          inactiveColor: Colors.grey.shade700,
                          onChanged: (double value) {
                            widget.onChanged(value);
                            setState(() {
                              sliderValue = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                      child: Text(
                        '${widget.valueType == '%' ? (sliderValue / widget.max * 100).round() : sliderValue.floor()} ${widget.valueType}',
                        style: TextStyle(
                          color: SharedWidgets.textColor(context: context),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                          child: SizedBox(
                            width: widget.labelWidth ?? 200,
                            child: Slider(
                              value: widget.sliderValue,
                              min: widget.min,
                              max: widget.max,
                              divisions: widget.divisions,
                              thumbColor: Colors.red.shade700,
                              activeColor: Colors.green.shade200,
                              inactiveColor: Colors.grey.shade700,
                              onChanged: (double value) {
                                widget.onChanged(value);
                                setState(() {
                                  sliderValue = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                          child: Text(
                              '${widget.valueType == '%' ? (sliderValue / widget.max * 100).round() : sliderValue.floor()} ${widget.valueType}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
