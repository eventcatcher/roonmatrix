import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hovering/hovering.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/updatable_ticker.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

class ScrollMatrixPage extends StatefulWidget {
  final String device;
  final String name;
  final Map<String, dynamic> translations;
  final Size minDesktopSize;
  final double scrollSpeed;
  final Function(double speed) speedChanged;
  final VoidCallback close;

  const ScrollMatrixPage({
    super.key,
    required this.device,
    required this.name,
    required this.translations,
    required this.minDesktopSize,
    required this.scrollSpeed,
    required this.speedChanged,
    required this.close,
  });

  @override
  State<ScrollMatrixPage> createState() => _ScrollMatrixPageState();
}

class _ScrollMatrixPageState extends State<ScrollMatrixPage> {
  String get device => widget.device;
  String get name => widget.name;
  Map<String, dynamic> get translations => widget.translations;
  Size get minDesktopSize => widget.minDesktopSize;
  Function(double speed) get speedChanged => widget.speedChanged;
  VoidCallback get close => widget.close;

  final double mobileFontSizeSmall = 32.0;
  final double mobileFontSizeMedium = 64.0;
  final double mobileFontSizeBig = 128.0;
  final double sliderTextDesktopMin = 1800;
  final double sliderTextMobileMin = 800;
  final double sliderDesktopMin = 1480;
  final double sliderMobileMin = 550;

  Orientation orientation = Orientation.portrait;
  String displaystr = '';
  String scrollText = '';
  double width = 1280;
  double height = 768;
  double fontSize = 64.0;
  double mobileFontSize = 48.0;
  double sliderTextMin = 800;
  double sliderMin = 550;
  double pixelsPerSecond = 200 + 64.0 / 2.25;
  double sliderValue = 1.0;

  double opacityLevel = 0;

  late MainBloc mainBloc;

  @override
  void initState() {
    width = minDesktopSize.width;
    height = minDesktopSize.height;
    mainBloc = BlocProvider.of<MainBloc>(context);

    sliderValue = widget.scrollSpeed;

    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      sliderTextMin = sliderTextDesktopMin;
      sliderMin = sliderDesktopMin;
      mainBloc.windowResizeToFullWidthAndMinimumHeight(
          minDesktopSize: minDesktopSize);
    } else {
      sliderTextMin = sliderTextMobileMin;
      sliderMin = sliderMobileMin;
    }

    super.initState();
  }

  updateSizes(String caller) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    fontSize = Platform.isMacOS || Platform.isWindows || Platform.isLinux
        ? height - 60 - height / 6
        : mobileFontSize;
    pixelsPerSecond = 200 + fontSize / 2.25;
    // if (kDebugMode) {
    //   debugPrint(
    //       'ScrollMatrixPage => updateSizes, caller: $caller, width: $width, height: $height, fontSize: $fontSize');
    // }
  }

  String replaceCodes(String str) {
    if (str.length > 1 && str.startsWith('[') && str.endsWith(']')) {
      str = jsonDecode(str.replaceAll("'", '"')).join(' ');
      str = str.replaceAll('< ', ', ');
      str = str.replaceAll(' >', ': ');
    }

    return str;
  }

  controls() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (SharedWidgets.isMobileDevice()) ...[
            if (width > sliderTextMin)
              Text('${translations['speed'] ?? 'speed:'}:'),
            InkWell(
              onDoubleTap: () {
                setState(() {
                  sliderValue = 1.0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: SizedBox(
                  width: width > sliderMin ? 200 : 120,
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
            ),
            const Text('  |  '),
            IconButton(
              iconSize: 12.0,
              padding: EdgeInsets.zero,
              onPressed: () =>
                  setState(() => mobileFontSize = mobileFontSizeSmall),
              icon: const Icon(FontAwesomeIcons.font),
            ),
            IconButton(
              iconSize: 16.0,
              padding: EdgeInsets.zero,
              onPressed: () =>
                  setState(() => mobileFontSize = mobileFontSizeMedium),
              icon: const Icon(FontAwesomeIcons.font),
            ),
            IconButton(
              iconSize: 20.0,
              padding: EdgeInsets.zero,
              onPressed: () =>
                  setState(() => mobileFontSize = mobileFontSizeBig),
              icon: const Icon(FontAwesomeIcons.font),
            ),
          ],
          if (SharedWidgets.isDesktopDevice())
            BlocBuilder(
                bloc: mainBloc,
                builder: (context, MainState mainState) {
                  String zoneName = '';
                  dynamic info = mainState.info.containsKey(device)
                      ? mainState.info[device]
                      : null;
                  if (info != null && info['control_id'] != null) {
                    String controlId = info['control_id'];
                    if (info['channels'] != null &&
                        info['channels'][controlId] != null) {
                      if (info['channels'][controlId] == 'webserver') {
                        zoneName = controlId;
                      } else {
                        zoneName = info['channels'][controlId];
                      }
                    }
                  }

                  return Text(
                      'IP: $device  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ');
                }),
          const SizedBox(width: 4.0),
        ],
      );

  Widget speedSliderOverlay() => HoverWidget(
      hoverChild: InkWell(
        onDoubleTap: () {
          setState(() {
            sliderValue = 1.0;
          });
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
                            color: SharedWidgets.borderColor(context: context),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width > sliderMin ? 200 : 120,
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
      ));

  Widget body() => SizedBox(
        width: double.infinity,
        child: RoonmatrixAnimatedGradient(
          child: BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return SizedBox();
                }

                if (mainState.devices.isNotEmpty &&
                    mainState.info.containsKey(device)) {
                  String displaystrNew =
                      mainState.info[device]['app_displaystr'];

                  if (displaystrNew != displaystr) {
                    scrollText = replaceCodes(displaystrNew);
                    if (kDebugMode) {
                      debugPrint('xxxx new scrollText: $scrollText');
                    }
                  }
                }

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation o) {
                  if (o != orientation) {
                    orientation = o;
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        setState(() {
                          orientation = o;
                        });
                      }
                    });
                  }

                  return NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (notification) {
                      updateSizes('NotificationListener');
                      build(context);
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        height: height - 52,
                        child: UpdatableTicker(
                          key: ValueKey(
                              'UpdatableTickerMatrixPage${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                          updatableText: scrollText,
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize: fontSize / 1.2,
                            color: Colors.black,
                          ),
                          pixelsPerSecond: pixelsPerSecond * sliderValue,
                          forceUpdate: false,
                          center: true,
                          separator: '    ////    ',
                        ),
                      ),
                    ),
                  );
                });
              }),
        ),
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (SharedWidgets.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: SharedWidgets.brightness(),
            middle: SharedWidgets.inIosStyle() ? null : Text(name),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              child: CupertinoNavigationBarBackButton(),
              onPressed: () => Navigator.pop(context),
            ),
            trailing: SizedBox(
              width: SharedWidgets.inIosStyle()
                  ? MediaQuery.of(context).size.width - 100
                  : 900.0,
              child: controls(),
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                body(),
                if (SharedWidgets.isDesktopDevice())
                  Positioned(
                    bottom: -10,
                    right: 0,
                    child: speedSliderOverlay(),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return SharedWidgets.inMacosStyle()
        ? Material(
            child: MacosScaffold(
              toolBar: ToolBar(
                title: Text(name),
                titleWidth: 540.0,
                actions: [
                  CustomToolbarItem(
                    inToolbarBuilder: (context) => Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 0.0),
                      child: BlocBuilder(
                          bloc: mainBloc,
                          builder: (context, MainState mainState) {
                            String zoneName = '';
                            if (mainState.devices.isNotEmpty &&
                                mainState.info.containsKey(device)) {
                              dynamic info = mainState.info[device];
                              if (info['control_id'] != null) {
                                String controlId = info['control_id'];
                                if (info['channels'] != null &&
                                    info['channels'][controlId] != null) {
                                  if (info['channels'][controlId] ==
                                      'webserver') {
                                    zoneName = controlId;
                                  } else {
                                    zoneName = info['channels'][controlId];
                                  }
                                }
                              }

                              return Text(
                                'IP: $device  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ',
                                style: TextStyle(
                                  color:
                                      SharedWidgets.textColor(context: context),
                                ),
                              );
                            }

                            return Text('');
                          }),
                    ),
                    inOverflowedBuilder: (context) =>
                        Container(color: Colors.grey, width: 30, height: 1),
                  ),
                  const ToolBarSpacer(),
                ],
              ),
              children: [
                ContentArea(
                  builder: ((context, scrollController) {
                    return Material(
                      child: MacosWindow(
                        child: Stack(
                          children: [
                            body(),
                            Positioned(
                              bottom: -10,
                              right: 0,
                              child: speedSliderOverlay(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(name),
              actions: [controls()],
            ),
            body: Stack(
              children: [
                body(),
                if (SharedWidgets.isDesktopDevice())
                  Positioned(
                    bottom: -10,
                    right: 0,
                    child: speedSliderOverlay(),
                  ),
              ],
            ),
          );
  }
}
