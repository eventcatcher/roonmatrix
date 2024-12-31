import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:text_scroll/text_scroll.dart';

class ScrollMatrixPage extends StatefulWidget {
  final int index;
  final String name;
  final Map<String, dynamic> translations;
  final Size minDesktopSize;
  final VoidCallback close;

  const ScrollMatrixPage({
    super.key,
    required this.index,
    required this.name,
    required this.translations,
    required this.minDesktopSize,
    required this.close,
  });

  @override
  State<ScrollMatrixPage> createState() => _ScrollMatrixPageState();
}

class _ScrollMatrixPageState extends State<ScrollMatrixPage> {
  int get index => widget.index;
  String get name => widget.name;
  Map<String, dynamic> get translations => widget.translations;
  Size get minDesktopSize => widget.minDesktopSize;
  VoidCallback get close => widget.close;

  final double mobileFontSizeSmall = 32.0;
  final double mobileFontSizeMedium = 64.0;
  final double mobileFontSizeBig = 128.0;
  final double sliderTextDesktopMin = 1800;
  final double sliderTextMobileMin = 800;
  final double sliderDesktopMin = 1480;
  final double sliderMobileMin = 550;

  String displaystr = '';
  double width = 1280;
  double height = 768;
  double fontSize = 64.0;
  double mobileFontSize = 48.0;
  double sliderTextMin = 800;
  double sliderMin = 550;
  double pixelsPerSecond = 200 + 64.0 / 2.25;
  double sliderValue = 1.0;

  late MainBloc mainBloc;

  @override
  void initState() {
    width = minDesktopSize.width;
    height = minDesktopSize.height;
    mainBloc = BlocProvider.of<MainBloc>(context);

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

  getMaskedString(String str) {
    int strTimePos = str.indexOf('Uhrzeit');
    if (strTimePos == -1) {
      return str;
    }

    String strMasked =
        '${str.substring(0, strTimePos + 9)}hh:mm:ss${str.substring(strTimePos + 17)}';
    return strMasked;
  }

  updateSizes(String caller) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    fontSize = Platform.isMacOS || Platform.isWindows || Platform.isLinux
        ? height - 60 - height / 6
        : mobileFontSize;
    pixelsPerSecond = 200 + fontSize / 2.25;
    // if (kDebugMode) {
    //   print(
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
                    setState(() {
                      sliderValue = value;
                    });
                  },
                ),
              ),
            ),
          ),
          if (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
            BlocBuilder(
                bloc: mainBloc,
                builder: (context, MainState mainState) {
                  String zoneName = '';
                  dynamic info = mainState.info[mainState.devices[index]];
                  if (info['control_id'] != null) {
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
                      'IP: ${mainState.devices[index]}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ');
                }),
          if (SharedWidgets.inIosStyle() ||
              Platform.isAndroid ||
              Platform.isFuchsia) ...[
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
          const SizedBox(width: 4.0),
        ],
      );

  Widget body() => SizedBox(
        width: double.infinity,
        child: RoonmatrixAnimatedGradient(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              BlocBuilder(
                  bloc: mainBloc,
                  builder: (context, MainState mainState) {
                    if (mainState is MainStateLoaded) {
                      String displaystrNew = mainState
                          .info[mainState.devices[index]]['displaystr'];

                      String displaystrNewMasked =
                          getMaskedString(displaystrNew);
                      String displaystrMasked = getMaskedString(displaystr);

                      if (displaystrNewMasked != displaystrMasked) {
                        SchedulerBinding.instance
                            .addPostFrameCallback((_) async {
                          if (mounted) {
                            setState(() {
                              displaystr = displaystrNew;
                            });
                          }
                        });
                      }
                    }

                    return const SizedBox(height: 0.0);
                  }),
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  OrientationBuilder(
                      builder: (BuildContext context, Orientation orientation) {
                    updateSizes('OrientationBuilder');

                    // if (kDebugMode) {
                    //   print('height: $height, fontSize: $fontSize');
                    // }

                    return NotificationListener<SizeChangedLayoutNotification>(
                      onNotification: (notification) {
                        updateSizes('NotificationListener');
                        build(context);
                        return false;
                      },
                      child: SizeChangedLayoutNotifier(
                        child: SizedBox(
                          key: ValueKey(
                              'TextScrollWrapper${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                          height: fontSize * 1.15,
                          child: TextScroll(
                            '${replaceCodes(displaystr)}    ////    ',
                            key: ValueKey(
                                'TextScroll${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height-$fontSize'),
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: fontSize,
                              color: SharedWidgets.textColor(context: context),
                            ),
                            mode: TextScrollMode.endless,
                            velocity: Velocity(
                                pixelsPerSecond:
                                    Offset(pixelsPerSecond * sliderValue, 0)),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
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
            child: body(),
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
                  if (width > sliderTextMin)
                    CustomToolbarItem(
                      inToolbarBuilder: (context) => Padding(
                        padding: const EdgeInsets.only(
                            left: 8.0, right: 8.0, bottom: 8.0),
                        child: Text(
                          '${translations['speed'] ?? 'speed:'}:',
                          style: TextStyle(
                            color: SharedWidgets.textColor(context: context),
                          ),
                        ),
                      ),
                      inOverflowedBuilder: (context) =>
                          Container(color: Colors.grey, width: 30, height: 1),
                    ),
                  CustomToolbarItem(
                    inToolbarBuilder: (context) => Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 0.0),
                      child: InkWell(
                        onDoubleTap: () {
                          setState(() {
                            sliderValue = 1.0;
                          });
                        },
                        child: SizedBox(
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
                                setState(() {
                                  sliderValue = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    inOverflowedBuilder: (context) =>
                        Container(color: Colors.grey, width: 30, height: 1),
                  ),
                  const ToolBarSpacer(),
                  CustomToolbarItem(
                    inToolbarBuilder: (context) => Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, bottom: 8.0),
                      child: BlocBuilder(
                          bloc: mainBloc,
                          builder: (context, MainState mainState) {
                            String zoneName = '';
                            dynamic info =
                                mainState.info[mainState.devices[index]];
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
                              'IP: ${mainState.devices[index]}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ',
                              style: TextStyle(
                                color:
                                    SharedWidgets.textColor(context: context),
                              ),
                            );
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
                        child: body(),
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
            body: body(),
          );
  }
}
