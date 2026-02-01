import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/titlebar_info_content.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class MobileSpeedSliderAndFontsizeControls extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String ip;
  final int ledModules;
  final bool verticalOutput;
  final double width;
  final double scrollSpeed;
  final Function(double speed) speedChanged;
  final Function(double size) sizeChanged;

  const MobileSpeedSliderAndFontsizeControls({
    super.key,
    required this.translations,
    required this.ip,
    required this.ledModules,
    required this.verticalOutput,
    required this.width,
    required this.scrollSpeed,
    required this.speedChanged,
    required this.sizeChanged,
  });

  @override
  State<MobileSpeedSliderAndFontsizeControls> createState() =>
      _MobileSpeedSliderAndFontsizeControlsState();
}

class _MobileSpeedSliderAndFontsizeControlsState
    extends State<MobileSpeedSliderAndFontsizeControls> {
  Map<String, dynamic> get translations => widget.translations;
  String get ip => widget.ip;
  int get ledModules => widget.ledModules;
  bool get verticalOutput => widget.verticalOutput;
  double get width => widget.width;
  double get scrollSpeed => widget.scrollSpeed;
  Function(double speed) get speedChanged => widget.speedChanged;
  Function(double size) get sizeChanged => widget.sizeChanged;

  final double sliderMobileMin = 550;
  final double sliderTextMobileMin = 800;
  final double sliderWidthBig = 200.0;
  final double sliderWidthSmall = 120.0;
  final double sliderMinValue = 0.1;
  final double sliderMaxValue = 5.0;
  final int sliderDivisions = 100;

  double mobileFontSizeSmall = Globals.mobileFontSizeSmall;
  double mobileFontSizeMedium = Globals.mobileFontSizeMedium;
  double mobileFontSizeBig = Globals.mobileFontSizeBig;

  double sliderValue = 1.0;
  double fontSize = 1.0;

  late MainBloc mainBloc;

  @override
  void initState() {
    if (verticalOutput == true) {
      double maxFontSize =
          width / ledModules / Globals.verticalTickerWidthFactor;
      mobileFontSizeBig = maxFontSize;
      mobileFontSizeMedium = maxFontSize / 1.5;
      mobileFontSizeSmall = maxFontSize / 2;
      fontSize = mobileFontSizeBig;
    } else {
      fontSize = Globals.mobileFontSizeMedium;
    }
    mainBloc = BlocProvider.of<MainBloc>(context);
    sliderValue = scrollSpeed;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (Globals.isMobileDevice()) ...[
          if (width > sliderTextMobileMin)
            Text(
              '${translations['speed'] ?? 'speed:'}:',
            ),
          InkWell(
            onDoubleTap: () {
              speedChanged(1.0);
              setState(() => sliderValue = 1.0);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: SizedBox(
                width:
                    width > sliderMobileMin ? sliderWidthBig : sliderWidthSmall,
                child: Slider(
                  value: sliderValue,
                  min: sliderMinValue,
                  max: sliderMaxValue,
                  divisions: sliderDivisions,
                  thumbColor: Colors.red.shade700,
                  activeColor: Colors.green.shade200,
                  inactiveColor: Colors.grey.shade700,
                  onChanged: (double value) {
                    speedChanged(value);
                    setState(() => sliderValue = value);
                  },
                ),
              ),
            ),
          ),
          const Text('  |  '),
          IconButton(
            iconSize: 12.0,
            padding: EdgeInsets.zero,
            onPressed: () {
              sizeChanged(mobileFontSizeSmall);
              setState(() => fontSize = mobileFontSizeSmall);
            },
            icon: const Icon(FontAwesomeIcons.font),
          ),
          IconButton(
            iconSize: 16.0,
            padding: EdgeInsets.zero,
            onPressed: () {
              sizeChanged(mobileFontSizeMedium);
              setState(() => fontSize = mobileFontSizeMedium);
            },
            icon: const Icon(FontAwesomeIcons.font),
          ),
          IconButton(
            iconSize: 20.0,
            padding: EdgeInsets.zero,
            onPressed: () {
              sizeChanged(mobileFontSizeBig);
              setState(() => fontSize = mobileFontSizeBig);
            },
            icon: const Icon(FontAwesomeIcons.font),
          ),
        ],
        if (Globals.isDesktopDevice())
          TitlebarInfoContent(
            ip: ip,
            translations: translations,
          ),
        const SizedBox(width: 4.0),
      ],
    );
  }
}
