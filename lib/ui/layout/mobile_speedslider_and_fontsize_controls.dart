import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/titlebar_info_content.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class MobileSpeedSliderAndFontsizeControls extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String ip;
  final double width;
  final double scrollSpeed;
  final Function(double speed) speedChanged;
  final Function(double size) sizeChanged;

  const MobileSpeedSliderAndFontsizeControls({
    super.key,
    required this.translations,
    required this.ip,
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
  double get width => widget.width;
  Function(double speed) get speedChanged => widget.speedChanged;
  Function(double size) get sizeChanged => widget.sizeChanged;

  final double sliderMobileMin = 550;
  final double sliderTextMobileMin = 800;
  final double mobileFontSizeSmall = 32.0;
  final double mobileFontSizeMedium = 64.0;
  final double mobileFontSizeBig = 128.0;

  double sliderValue = 1.0;
  double fontSize = 48.0;
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (SharedWidgets.isMobileDevice()) ...[
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
                width: width > sliderMobileMin ? 200 : 120,
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
        if (SharedWidgets.isDesktopDevice())
          TitlebarInfoContent(
            ip: ip,
            translations: translations,
          ),
        const SizedBox(width: 4.0),
      ],
    );
  }
}
