import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class ControlButtons extends StatefulWidget {
  final Orientation orientation;
  final Map<String, dynamic> translations;
  final String ip;
  final String controlId;
  final bool readOnly;

  const ControlButtons({
    super.key,
    required this.orientation,
    required this.translations,
    required this.ip,
    required this.controlId,
    this.readOnly = false,
  });

  @override
  State<ControlButtons> createState() => ControlButtonsState();
}

class ControlButtonsState extends State<ControlButtons> {
  Orientation get orientation => widget.orientation;
  Map<String, dynamic> get translations => widget.translations;
  String get ip => widget.ip;
  String get controlId => widget.controlId;
  bool get readOnly => widget.readOnly;

  final double buttonSize =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux ? 128.0 : 88.0;
  final bool showButtonUp = false;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (orientation == Orientation.landscape ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
          Container(
            margin: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              translations['controlButtonPreviousText'] ?? 'previous',
              style: TextStyle(
                color: SharedWidgets.textColor(context: context),
              ),
            ),
          ),
        Column(
          children: [
            Text(
              showButtonUp == true
                  ? translations['controlButtonUpText'] ?? 'up'
                  : '',
              style: TextStyle(
                color: SharedWidgets.textColor(context: context),
              ),
            ),
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
                            if (!readOnly) {
                              mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId,
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
                            if (!readOnly) {
                              mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId,
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
                            if (!readOnly) {
                              mainBloc.zoneControl(
                                  ip: ip, controlId: controlId, cmd: 'next');
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
                            if (!readOnly) {
                              mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId,
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
            Text(
              translations['controlButtonShuffleText'] ?? 'shuffle',
              style: TextStyle(
                color: SharedWidgets.textColor(context: context),
              ),
            ),
          ],
        ),
        if (orientation == Orientation.landscape ||
            Platform.isMacOS ||
            Platform.isWindows ||
            Platform.isLinux)
          Container(
            margin: const EdgeInsets.only(bottom: 6.0),
            child: Text(
              translations['controlButtonNextText'] ?? 'next',
              style: TextStyle(
                color: SharedWidgets.textColor(context: context),
              ),
            ),
          ),
      ],
    );
  }
}
