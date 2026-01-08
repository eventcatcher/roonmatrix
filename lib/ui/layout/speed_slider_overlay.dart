import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hovering/hovering.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class SpeedSliderOverlay extends StatefulWidget {
  final Map<String, dynamic> translations;
  final double width;
  final double scrollSpeed;
  final Function(double speed) speedChanged;

  const SpeedSliderOverlay({
    super.key,
    required this.translations,
    required this.width,
    required this.scrollSpeed,
    required this.speedChanged,
  });

  @override
  State<SpeedSliderOverlay> createState() => _SpeedSliderOverlayState();
}

class _SpeedSliderOverlayState extends State<SpeedSliderOverlay> {
  Map<String, dynamic> get translations => widget.translations;
  double get width => widget.width;
  Function(double speed) get speedChanged => widget.speedChanged;

  final double sliderDesktopMin = 1480;

  double sliderValue = 1.0;
  String macosVersion = '';

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    sliderValue = widget.scrollSpeed;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return HoverWidget(
      hoverChild: InkWell(
        onDoubleTap: () {
          speedChanged(1.0);
          setState(() => sliderValue = 1.0);
        },
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
                    color: Color.fromARGB(80, 33, 33, 33),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          '${translations['speed'] ?? 'speed:'}:',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width > sliderDesktopMin ? 200 : 120,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Slider(
                            value: sliderValue,
                            min: 0.1,
                            max: 5,
                            divisions: 100,
                            thumbColor: Colors.red.shade700,
                            activeColor: Colors.green.shade200,
                            inactiveColor: Colors.grey.shade700,
                            onChanged: (double value) {
                              speedChanged(value);
                              setState(() {
                                sliderValue = value;
                              });
                            },
                          ),
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
        width: 324,
        height: 54,
        color: Colors.transparent,
      ),
    );
  }
}
