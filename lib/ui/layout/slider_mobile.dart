import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';

class SliderMobile extends StatefulWidget {
  final double min;
  final double max;
  final int divisions;
  final double value;
  final Function(double value) updateValue;

  const SliderMobile({
    super.key,
    this.min = 0.25,
    this.max = 5,
    this.divisions = 100,
    this.value = 1.0,
    required this.updateValue,
  });

  @override
  State<SliderMobile> createState() => _SliderMobileState();
}

class _SliderMobileState extends State<SliderMobile> {
  final double height = 38.0;

  double value = 1.0;

  late SettingsBloc settingsBloc;

  @override
  void initState() {
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    value = widget.value;

    super.initState();
  }

  @override
  void didUpdateWidget(SliderMobile oldWidget) {
    super.didUpdateWidget(oldWidget);

    value = widget.value;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.only(top: 2.0),
        height: height,
        child: Slider(
          value: value,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          thumbColor: Colors.red.shade700,
          activeColor: Colors.green.shade200,
          inactiveColor: Colors.grey.shade700,
          onChanged: (double value) => widget.updateValue(value),
        ),
      );
}
