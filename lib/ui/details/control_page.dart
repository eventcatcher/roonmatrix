import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/select_box.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';

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

  String selectedZoneId = '';
  String? controlId;

  late OptionsBloc optionsBloc;

  @override
  void initState() {
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    optionsBloc.getInfo(ip: ip);

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
          const Text('previous'),
        Column(
          children: [
            //const Text('up'),
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
                            if (selectedZoneId.isNotEmpty) {
                              optionsBloc.zoneControl(
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
                            if (selectedZoneId.isNotEmpty) {
                              optionsBloc.zoneControl(
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
                            if (selectedZoneId.isNotEmpty) {
                              optionsBloc.zoneControl(
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
                            if (selectedZoneId.isNotEmpty) {
                              optionsBloc.zoneControl(
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
            const Text('shuffle'),
          ],
        ),
        if (orientation == Orientation.landscape ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
          const Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text('next'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: optionsBloc,
        builder: (context, OptionsState optionsState) {
          if (optionsState is! OptionsStateLoaded) {
            return Container();
          }

          Map<String, dynamic> info = optionsState.info[ip] ?? {};
          Map<String, dynamic> channels = (info['channels'] ?? {});
          Map<String, String> options = {};

          String zoneName = '';
          String value = '';
          String? selectedZoneId;

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

          return OrientationBuilder(
              builder: (BuildContext context, Orientation orientation) {
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: Text('$name : Control'),
                  actions: const [],
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                                  label: 'Zone:',
                                  placeholder: 'Select zone...',
                                  inRow: false,
                                  noVerticalSpace: false,
                                  readOnly: false,
                                  selected: selectedZoneId,
                                  options: options,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      if (options[newValue] != null &&
                                          options[newValue] == 'webserver') {
                                        controlId = newValue ?? '';
                                      } else {
                                        controlId = options[newValue];
                                      }
                                      selectedZoneId = newValue;
                                    });
                                  }),
                              controlButtons(orientation),
                            ],
                          )
                        : Row(
                            // landscape view
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width -
                                    3 * buttonSize -
                                    128 -
                                    (Platform.isIOS ? 24 : 0),
                                child: SelectBox(
                                    aligned: 'horizontal',
                                    label: 'Zone:',
                                    placeholder: 'Select zone...',
                                    inRow: false,
                                    noVerticalSpace: false,
                                    readOnly: false,
                                    selected: selectedZoneId,
                                    options: options,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        if (options[newValue] != null &&
                                            options[newValue] == 'webserver') {
                                          controlId = newValue ?? '';
                                        } else {
                                          controlId = options[newValue];
                                        }
                                        selectedZoneId = newValue;
                                      });
                                    }),
                              ),
                              controlButtons(orientation),
                            ],
                          ),
                  ),
                ),
              ),
            );
          });
        });
  }
}
