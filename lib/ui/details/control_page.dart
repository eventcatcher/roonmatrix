import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/details/message_writer.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class ControlPage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const ControlPage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<ControlPage> createState() => ControlPageState();
}

class ControlPageState extends State<ControlPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  final double buttonSize =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux ? 128.0 : 88.0;
  final bool showButtonUp = false;

  Map<String, dynamic> translations = {};
  String title = '';
  bool translationsLoaded = false;
  String? selectedZoneId;
  String? controlId;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : Control';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);

    super.initState();
  }

  Widget controlButtons(Orientation orientation) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (orientation == Orientation.landscape ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
          Container(
            margin: const EdgeInsets.only(bottom: 6.0),
            child:
                Text(translations['controlButtonPreviousText'] ?? 'previous'),
          ),
        Column(
          children: [
            Text(showButtonUp == true
                ? translations['controlButtonUpText'] ?? 'up'
                : ''),
            SizedBox(
              width: 3 * buttonSize,
              height: 3 * buttonSize,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(width: buttonSize),
                      SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          color: Colors.grey,
                          hoverColor: Colors.blue,
                          onPressed: () {
                            //
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_up,
                            size: buttonSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          hoverColor: Colors.blue,
                          onPressed: () {
                            if (selectedZoneId != null &&
                                selectedZoneId!.isNotEmpty) {
                              mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId!,
                                  cmd: 'previous');
                            }
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_left,
                            size: buttonSize,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          hoverColor: Colors.blue,
                          onPressed: () {
                            if (selectedZoneId != null &&
                                selectedZoneId!.isNotEmpty) {
                              mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId!,
                                  cmd: 'playmode');
                            }
                          },
                          icon: const Icon(
                            Icons.circle,
                            size: 32,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          hoverColor: Colors.blue,
                          onPressed: () {
                            if (selectedZoneId != null &&
                                selectedZoneId!.isNotEmpty) {
                              mainBloc.zoneControl(
                                  ip: ip, controlId: controlId!, cmd: 'next');
                            }
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_right,
                            size: buttonSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(width: buttonSize),
                      SizedBox(
                        width: buttonSize,
                        height: buttonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          hoverColor: Colors.blue,
                          onPressed: () {
                            if (selectedZoneId != null &&
                                selectedZoneId!.isNotEmpty) {
                              mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId!,
                                  cmd: 'shufflemode');
                            }
                          },
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: buttonSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(translations['controlButtonShuffleText'] ?? 'shuffle'),
          ],
        ),
        if (orientation == Orientation.landscape ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
          Container(
            margin: const EdgeInsets.only(bottom: 6.0),
            child: Text(translations['controlButtonNextText'] ?? 'next'),
          ),
      ],
    );
  }

  Map<String, String> generateOptionsAndPreselect(Map<String, dynamic> info) {
    Map<String, dynamic> channels = (info['channels'] ?? {});
    Map<String, String> options = {};

    String zoneName = '';
    String value = '';

    if (info['control_id'] != null) {
      if (controlId == null && info['control_id'] != null) {
        controlId = info['control_id'];
        if (kDebugMode) {
          print('controlId preset: $controlId');
        }
      }

      if (controlId != null) {
        if (channels[controlId] == 'webserver') {
          selectedZoneId = controlId;
        } else {
          selectedZoneId = channels[controlId]!;
        }
      }
    }
    if (info['channels'] != null) {
      for (String key in channels.keys) {
        if (channels[key] == 'webserver') {
          zoneName = key;
          value = channels[key];
        } else {
          zoneName = channels[key]!;
          value = key;
        }
        options.putIfAbsent(zoneName, () => value);
      }
    }

    return options;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
            title =
                '$name : ${translations['controlPageHeaderText'] ?? 'Control'}';
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
            return Scaffold(
                appBar: AppBar(
                  title: Text(title),
                ),
                body: const SizedBox());
          }

          return BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return const SizedBox();
                }

                Map<String, dynamic> info = mainState.info[ip] ?? {};
                Map<String, String> options = generateOptionsAndPreselect(info);

                return OrientationBuilder(
                    builder: (BuildContext context, Orientation orientation) {
                  return DefaultTabController(
                    length: 2,
                    child: Scaffold(
                      appBar: AppBar(
                        title: Text(title),
                        actions: const [],
                      ),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                          child: orientation == Orientation.portrait ||
                                  Platform.isMacOS ||
                                  Platform.isWindows ||
                                  Platform.isLinux
                              ? Column(
                                  // portrait view
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    SelectBox(
                                        aligned: 'horizontal',
                                        label:
                                            '${translations['zoneSelectionLabel'] ?? 'Zone'}:',
                                        placeholder:
                                            '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
                                        inRow: false,
                                        noVerticalSpace: false,
                                        readOnly: false,
                                        selected: selectedZoneId,
                                        options: options,
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            if (options[newValue] != null &&
                                                options[newValue] ==
                                                    'webserver') {
                                              controlId = newValue ?? '';
                                            } else {
                                              controlId = options[newValue];
                                            }
                                            selectedZoneId = newValue;
                                          });
                                        }),
                                    controlButtons(orientation),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: MessageWriter(
                                        name: name,
                                        ip: ip,
                                        translations: translations,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  // landscape view
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      fit: FlexFit.loose,
                                      child: Column(
                                        children: [
                                          SelectBox(
                                              aligned: 'horizontal',
                                              label:
                                                  '${translations['zoneSelectionLabel'] ?? 'Zone'}:',
                                              placeholder:
                                                  '${translations['zoneSelectionPlaceholder'] ?? 'Select zone'}...',
                                              inRow: false,
                                              noVerticalSpace: false,
                                              readOnly: false,
                                              selected: selectedZoneId,
                                              options: options,
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  if (options[newValue] !=
                                                          null &&
                                                      options[newValue] ==
                                                          'webserver') {
                                                    controlId = newValue ?? '';
                                                  } else {
                                                    controlId =
                                                        options[newValue];
                                                  }
                                                  selectedZoneId = newValue;
                                                });
                                              }),
                                          const SizedBox(height: 184.0),
                                          MessageWriter(
                                            name: name,
                                            ip: ip,
                                            translations: translations,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200 + 3 * buttonSize,
                                      child: controlButtons(orientation),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                });
              });
        });
  }
}
