import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder, BlocProvider;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/control_buttons.dart';
import 'package:roonmatrix/ui/layout/roommatrix_animated_gradient.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart'
    show MainState, MainStateLoaded;

class CoverPage extends StatefulWidget {
  final String name;
  final String ip;
  final String? controlId;
  final Map<String, dynamic> translations;

  const CoverPage({
    super.key,
    required this.name,
    required this.ip,
    this.controlId,
    required this.translations,
  });

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Map<String, dynamic> get translations => widget.translations;

  final double fontSize =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux ? 20.0 : 16.0;

  Map<String, dynamic> info = {};
  Map<String, dynamic> channels = {};
  Map<String, String> options = {};
  Map<String, dynamic> webPlayoutsRaw = {};
  Map<String, dynamic> roonPlayoutsRaw = {};
  Map<String, dynamic>? selectedZone;

  String? selectedZoneId;
  String? controlId;
  bool idle = false;
  bool shuffle = false;
  bool repeat = false;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);

    super.initState();
  }

  Map<String, String> generateOptionsAndPreselect() {
    Map<String, String> options = {};

    if (info == {}) {
      return {};
    }

    Map<String, dynamic> channels = info['channels'];

    if (info['control_id'] != null) {
      if (controlId == null && info['control_id'] != null) {
        controlId = info['control_id'];
      }

      if (controlId != null && channels.containsKey(controlId)) {
        if (channels[controlId] == 'webserver') {
          selectedZoneId = controlId;
        } else {
          selectedZoneId = channels[controlId]!;
        }
      }
    }

    Map<String, String> roonOptions = {};
    for (String key in channels.keys) {
      if (channels[key] != 'webserver') {
        String zoneName = channels[key]!;
        if ((info['roon_playouts'] as Map).containsKey(zoneName)) {
          roonOptions.putIfAbsent(zoneName, () => key);
        }
      }
    }
    options.addAll(Map.fromEntries(
        roonOptions.entries.toList()..sort((a, b) => a.key.compareTo(b.key))));

    Map<String, String> webOptions = {};
    for (String key in channels.keys) {
      if (channels[key] == 'webserver') {
        List<String> controlIdParts = key.split('-');
        String serverName = controlIdParts[0];
        String zoneName = controlIdParts[1];
        if (info['web_playouts'][serverName] != null) {
          List<dynamic> zones = info['web_playouts'][serverName];
          Map<String, dynamic>? zone = zones.firstWhereOrNull(
              (dynamic el) => (el['zone'] as String) == zoneName);
          if (zone != null) {
            webOptions.putIfAbsent(key, () => channels[key]);
          }
        }
      }
    }
    options.addAll(Map.fromEntries(
        webOptions.entries.toList()..sort((a, b) => a.key.compareTo(b.key))));

    return options;
  }

  Map<String, dynamic>? getZoneDataForControlId(String? controlId) {
    Map<String, dynamic>? zone;

    if (info == {}) {
      return {};
    }

    Map<String, dynamic> channels = info['channels'];

    if (controlId != null &&
        controlId.isNotEmpty &&
        channels.keys.contains(controlId)) {
      if (channels[controlId] == 'webserver') {
        List<String> controlIdParts = controlId.split('-');
        String serverName = controlIdParts[0];
        String zoneName = controlIdParts[1];
        if (info['web_playouts'][serverName] != null) {
          List<dynamic> zones = info['web_playouts'][serverName];
          zone = zones.firstWhereOrNull(
              (dynamic el) => (el['zone'] as String) == zoneName);
          if (zone != null) {
            zone['server'] = serverName;
          }
        }
      } else {
        String zoneName = channels[controlId];
        if (info['roon_playouts'][zoneName] != null) {
          zone = info['roon_playouts'][zoneName];
          if (zone != null) {
            zone['zone'] = zoneName;
            zone['server'] = 'roon';
          }
        }
      }
    }

    return zone;
  }

  Widget getTextArea() {
    if (selectedZone == null ||
        selectedZone!.isEmpty ||
        selectedZone!['cover'] == null) {
      return Row(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 104.0),
            child: Text(
              '${translations['inactive'] ?? 'inactive zone'}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: Colors.black,
              ),
            ),
          ),
        ],
      );
    }

    if (selectedZone != null &&
        selectedZone!.isNotEmpty &&
        selectedZone!['artist'] != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
        child: Table(
          columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
          children: [
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${translations['coverZoneHeader'] ?? 'Zone'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  selectedZone!['zone'] != null
                      ? '${selectedZone!['zone']}${idle ? ' (${translations['paused'] ?? 'paused'})' : ''}'
                      : '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ]),
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${translations['coverArtistHeader'] ?? 'Artist'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  selectedZone!['artist'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ]),
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${translations['coverAlbumHeader'] ?? 'Album'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  selectedZone!['album'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ]),
            TableRow(children: [
              TableCell(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${translations['coverTrackHeader'] ?? 'Track'}: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              TableCell(
                child: Text(
                  selectedZone!['track'],
                  softWrap: true,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    color: Colors.black,
                  ),
                ),
              ),
            ]),
          ],
        ),
      );
    }

    return SizedBox();
  }

  Widget getSelectBoxArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: SelectBox(
          key: ValueKey('ZoneSelectBox$selectedZoneId'),
          translations: translations,
          aligned: 'horizontal',
          label: '${translations['zoneSelectionLabel'] ?? 'Zone'}:',
          placeholder:
              '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
          inRow: false,
          noVerticalSpace: false,
          readOnly: false,
          selected: selectedZoneId,
          options: options,
          onChanged: (String? newValue) {
            if (newValue != null) {
              String? selectedControlId;
              if (options[newValue] != null &&
                  options[newValue] == 'webserver') {
                selectedControlId = newValue;
              } else {
                selectedControlId = options[newValue];
              }

              if (selectedControlId != null) {
                mainBloc.zoneControl(
                    ip: ip, controlId: selectedControlId, cmd: 'switch');

                Map<String, dynamic>? zone =
                    getZoneDataForControlId(selectedControlId);
                if (zone != null) {
                  setState(() {
                    controlId = selectedControlId;
                    selectedZone = zone;
                    selectedZoneId = newValue;
                  });
                }
              }
            }
          }),
    );
  }

  Widget body() => SizedBox(
        child: Column(
          children: [
            BlocBuilder(
                bloc: mainBloc,
                builder: (context, MainState mainState) {
                  if (mainState is MainStateLoaded) {
                    info = mainState.info[ip] ?? {};

                    channels = (info['channels'] ?? {});
                    if (widget.controlId == null) {
                      Map<String, String> optionsUpdated =
                          generateOptionsAndPreselect();

                      if (options.keys.join(',') !=
                              optionsUpdated.keys.join(',') ||
                          options.values.join(',') !=
                              optionsUpdated.values.join(',')) {
                        SchedulerBinding.instance
                            .addPostFrameCallback((_) async {
                          if (mounted) {
                            setState(() {
                              options = optionsUpdated;
                            });
                          }
                        });
                      }
                    }

                    if (info != {} && info['control_id'] != null) {
                      String? controlIdUpdated =
                          widget.controlId ?? info['control_id'];

                      if (info['web_playouts_raw'] != webPlayoutsRaw ||
                          info['roon_playouts_raw'] != roonPlayoutsRaw ||
                          controlId == null ||
                          controlIdUpdated != controlId) {
                        Map<String, dynamic>? zone =
                            getZoneDataForControlId(controlIdUpdated);
                        if (zone != null) {
                          selectedZone = zone;
                        }

                        SchedulerBinding.instance
                            .addPostFrameCallback((_) async {
                          if (mounted) {
                            setState(() {
                              webPlayoutsRaw = info['web_playouts_raw'];
                              roonPlayoutsRaw = info['roon_playouts_raw'];
                              if (controlIdUpdated != controlId) {
                                controlId = controlIdUpdated;
                              }
                              if (zone != null) {
                                selectedZone = zone;
                                selectedZoneId = zone['server'] == 'roon'
                                    ? zone['zone']
                                    : '${zone['server']}-${zone['zone']}';
                              }
                            });
                          }
                        });

                        if (controlIdUpdated != null) {
                          if ((info['shufflemode'] as Map<String, dynamic>)
                              .containsKey(controlIdUpdated)) {
                            shuffle = info['shufflemode'][controlIdUpdated] ==
                                'shuffle';
                          }
                          if ((info['repeatmode'] as Map<String, dynamic>)
                              .containsKey(controlIdUpdated)) {
                            repeat = info['repeatmode'][controlIdUpdated] ==
                                'repeat';
                          }
                          if ((info['playmode'] as Map<String, dynamic>)
                              .containsKey(controlIdUpdated)) {
                            idle = info['playmode'][controlIdUpdated] != 'play';
                          }
                        }
                      }
                    }
                  }

                  return const SizedBox(height: 0.0);
                }),
            Expanded(
              child: RoonmatrixAnimatedGradient(
                child: OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  bool portraitMode = (SharedWidgets.isMobileDevice() &&
                          orientation == Orientation.portrait) ||
                      (SharedWidgets.isDesktopDevice() &&
                          MediaQuery.of(context).size.height > 800);
                  bool dektopMode = !portraitMode;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (portraitMode == true && widget.controlId == null)
                        getSelectBoxArea(),
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: NotificationListener<
                                  SizeChangedLayoutNotification>(
                                onNotification: (notification) {
                                  build(context);
                                  return false;
                                },
                                child: SizeChangedLayoutNotifier(
                                  child: Container(
                                    padding: EdgeInsets.all(24.0),
                                    child: AnimatedSwitcher(
                                      duration: Duration(milliseconds: 2000),
                                      // transitionBuilder: (Widget child,
                                      //     Animation<double> animation) {
                                      //   return ScaleTransition(
                                      //       scale: animation, child: child);
                                      // },
                                      child: selectedZone != null &&
                                              selectedZone!['cover'] != null &&
                                              (selectedZone!['cover'] as String)
                                                  .isNotEmpty
                                          ? Image.network(
                                              selectedZone!['cover'],
                                              key: ValueKey(
                                                  'BigCover${selectedZone!['cover']}'),
                                              fit: BoxFit.contain,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : SvgPicture.asset(
                                              'assets/svg/8-8-led-matrix-display-unit.svg',
                                              allowDrawingOutsideViewBox: false,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (dektopMode == true)
                              Flexible(
                                fit: FlexFit.tight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (widget.controlId == null)
                                      getSelectBoxArea(),
                                    Expanded(
                                      child: ControlButtons(
                                        key: ValueKey(
                                            'ControButtonsDesktop-$idle-$shuffle-$repeat'),
                                        orientation: orientation,
                                        translations: translations,
                                        partsToSubtract: 275,
                                        ip: ip,
                                        controlId:
                                            controlId ?? widget.controlId ?? '',
                                        idle: idle,
                                        shuffle: shuffle,
                                        repeat: repeat,
                                        readOnly: selectedZoneId == null ||
                                            selectedZoneId!.isEmpty,
                                      ),
                                    ),
                                    getTextArea(),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                      if (portraitMode == true)
                        Row(
                          children: [
                            Expanded(child: getTextArea()),
                            ControlButtons(
                              key: ValueKey(
                                  'ControButtonsPortrait-$idle-$shuffle-$repeat'),
                              orientation: orientation,
                              translations: translations,
                              partsToSubtract:
                                  MediaQuery.of(context).size.height - 150,
                              ip: ip,
                              controlId: controlId ?? widget.controlId ?? '',
                              idle: idle,
                              shuffle: shuffle,
                              repeat: repeat,
                              readOnly: selectedZoneId == null ||
                                  selectedZoneId!.isEmpty,
                            ),
                          ],
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (SharedWidgets.inIosStyle()) {
      return Material(
        child: CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            brightness: SharedWidgets.brightness(),
            middle: Text(
              '$name : ${translations['coverPageHeaderText'] ?? 'Zone / Cover'}',
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
            ),
            body: body(),
          );
  }
}
