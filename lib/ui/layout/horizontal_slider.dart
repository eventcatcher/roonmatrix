import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';

class HorizontalSlider extends StatefulWidget {
  final String label;
  final bool? smallHeight;
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
    this.smallHeight = false,
    this.labelWidth,
    required this.min,
    required this.max,
    required this.divisions,
    required this.sliderValue,
    required this.valueType,
    required this.orientation,
    required this.onChanged,
  });

  @override
  State<HorizontalSlider> createState() => _HorizontalSliderState();
}

class _HorizontalSliderState extends State<HorizontalSlider> {
  String get label => widget.label;
  bool get smallHeight => widget.smallHeight!;
  double? get labelWidth => widget.labelWidth;
  double get min => widget.min;
  double get max => widget.max;
  int get divisions => widget.divisions;
  String get valueType => widget.valueType;
  Orientation get orientation => widget.orientation;
  Function(double value) get onChanged => widget.onChanged;

  final double labelWidthx = 150.0;
  final double labelWidthFallback = 200.0;
  final double sliderPercentTextWidth = 124.0;
  final double labelAndSliderInRowMinWidth = 1200;
  final double flex3MinWidth = 1200.0;
  final double flex2MinWidth = 800.0;

  final Color thumbColor = Colors.red.shade700;
  final Color activeColor = Colors.green.shade200;
  final Color inactiveColor = Colors.grey.shade700;

  double sliderValue = 1.0;

  late MainRepository mainRepository;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);

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
                    orientation == Orientation.landscape
                ? 4.0
                : 8.0),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Globals.brightness() == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade300,
          border: Border.all(
            color: Globals.brightness() == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade400,
            width: 5.0,
          ),
          borderRadius: Globals.borderRadius(),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.15),
              spreadRadius: 0,
              blurRadius: 0,
            ),
          ],
        ),
        child: MediaQuery.of(context).size.width > labelAndSliderInRowMinWidth
            ? Row(
                // in row label
                children: [
                  SizedBox(
                      width: labelWidth ?? labelWidthFallback,
                      child: Text(
                        '$label: ',
                        style: TextStyle(
                          color: ColorDefs.textColor(context: context),
                          fontSize: smallHeight ? 12.0 : null,
                        ),
                      )),
                  Flexible(
                    flex: MediaQuery.of(context).size.width > flex3MinWidth
                        ? 3
                        : MediaQuery.of(context).size.width > flex2MinWidth
                            ? 2
                            : 1,
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: 4.0, top: smallHeight ? 1.0 : 4.0),
                      child: SizedBox(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Slider(
                              value: sliderValue,
                              min: min,
                              max: max,
                              divisions: divisions,
                              thumbColor: thumbColor,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                              onChanged: (double value) {
                                onChanged(value);
                                setState(() {
                                  sliderValue = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: sliderPercentTextWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 4.0, top: 4.0, right: 2.0),
                      child: Text(
                        mainRepository.getPercentText(
                          valueType: valueType,
                          sliderValue: sliderValue,
                          max: max,
                        ),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: ColorDefs.textColor(context: context),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                // top label
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: ColorDefs.textColor(context: context),
                      fontSize: smallHeight ? 12.0 : null,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 0.0),
                          child: SizedBox(
                            width: labelWidth ?? labelWidthFallback,
                            child: Slider(
                              value: sliderValue,
                              min: min,
                              max: max,
                              divisions: divisions,
                              padding: smallHeight ? EdgeInsets.all(4.0) : null,
                              thumbColor: thumbColor,
                              activeColor: activeColor,
                              inactiveColor: inactiveColor,
                              onChanged: (double value) {
                                onChanged(value);
                                setState(() {
                                  sliderValue = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: sliderPercentTextWidth,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 4.0),
                          child: Text(
                            mainRepository.getPercentText(
                              valueType: valueType,
                              sliderValue: sliderValue,
                              max: max,
                            ),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: ColorDefs.textColor(context: context),
                            ),
                          ),
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
