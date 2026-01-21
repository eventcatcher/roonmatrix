import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/control_button.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class ControlButtons extends StatefulWidget {
  final Orientation orientation;
  final Map<String, dynamic> translations;
  final double partsToSubtract;
  final String ip;
  final bool? idle;
  final bool? shuffle;
  final bool? repeat;
  final bool? isRadio;
  final String controlId;
  final bool readOnly;

  const ControlButtons({
    super.key,
    required this.orientation,
    required this.translations,
    this.partsToSubtract = 0,
    required this.ip,
    this.idle,
    this.shuffle,
    this.repeat,
    this.isRadio,
    required this.controlId,
    this.readOnly = false,
  });

  @override
  State<ControlButtons> createState() => ControlButtonsState();
}

class ControlButtonsState extends State<ControlButtons> {
  Orientation get orientation => widget.orientation;
  Map<String, dynamic> get translations => widget.translations;
  double get partsToSubtract => widget.partsToSubtract;
  String get ip => widget.ip;
  String get controlId => widget.controlId;
  bool get readOnly => widget.readOnly;

  final bool showButtonUp = false;
  final Color iconColor = Colors.blue.shade900;
  final Color enableIconColor = Colors.green;
  final Color disabledIconColor = Colors.grey;

  double getButtonSize({required double size}) => size / 3;

  bool idle = false;
  bool shuffle = false;
  bool repeat = false;
  bool isRadio = false;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    idle = widget.idle ?? false;
    shuffle = widget.shuffle ?? false;
    repeat = widget.repeat ?? false;
    isRadio = widget.isRadio ?? false;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double maxWidth = constraints.maxWidth;
      double maxHeight = constraints.maxHeight == double.infinity
          ? MediaQuery.of(context).size.height - partsToSubtract
          : constraints.maxHeight;
      double size = maxWidth < maxHeight ? maxWidth : maxHeight;
      double buttonSize = getButtonSize(size: size);
      double verticalOffset = 60.0;

      return SizedBox(
        width: size,
        height: size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                SizedBox(
                  width: 3 * buttonSize,
                  height: 3 * buttonSize,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          SizedBox(width: buttonSize),
                          ControlButton(
                            buttonSize: buttonSize,
                            verticalOffset: verticalOffset,
                            tooltipText:
                                translations['controlButtonRepeatText'] ??
                                    'repeat',
                            icon: Icon(
                              Icons.repeat,
                              size: buttonSize * 0.5,
                              color:
                                  repeat ? enableIconColor : disabledIconColor,
                            ),
                            readOnly: isRadio,
                            onPressed: () {
                              if (!readOnly) {
                                mainBloc.zoneControl(
                                    ip: ip,
                                    controlId: controlId,
                                    cmd: 'repeatmode',
                                    enable: !repeat);
                                if (mounted) {
                                  setState(() {
                                    repeat = !repeat;
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          ControlButton(
                            buttonSize: buttonSize,
                            verticalOffset: verticalOffset,
                            tooltipText:
                                translations['controlButtonPreviousText'] ??
                                    'previous track',
                            icon: Icon(
                              Icons.keyboard_arrow_left,
                              size: buttonSize,
                            ),
                            color: iconColor,
                            readOnly: isRadio || idle,
                            onPressed: () {
                              if (!readOnly) {
                                mainBloc.zoneControl(
                                    ip: ip,
                                    controlId: controlId,
                                    cmd: 'previous');
                              }
                            },
                          ),
                          ControlButton(
                            buttonSize: buttonSize,
                            verticalOffset: verticalOffset,
                            tooltipText:
                                translations['controlButtonPlaymodeText'] ??
                                    'pause/play',
                            icon: Icon(
                              idle ? Icons.play_arrow : Icons.pause,
                              size: buttonSize / 2,
                            ),
                            color: iconColor,
                            readOnly: false,
                            onPressed: () {
                              if (!readOnly) {
                                mainBloc.zoneControl(
                                  ip: ip,
                                  controlId: controlId,
                                  cmd: 'playmode',
                                  enable: idle,
                                );
                                if (mounted) {
                                  setState(() {
                                    idle = !idle;
                                  });
                                }
                              }
                            },
                          ),
                          ControlButton(
                            buttonSize: buttonSize,
                            verticalOffset: verticalOffset,
                            tooltipText:
                                translations['controlButtonNextText'] ??
                                    'next track',
                            icon: Icon(
                              Icons.keyboard_arrow_right,
                              size: buttonSize,
                            ),
                            color: iconColor,
                            readOnly: isRadio || idle,
                            onPressed: () {
                              if (!readOnly) {
                                if (mounted) {
                                  setState(() {
                                    idle = false;
                                  });
                                }
                                mainBloc.zoneControl(
                                    ip: ip, controlId: controlId, cmd: 'next');
                              }
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: buttonSize),
                          ControlButton(
                            buttonSize: buttonSize,
                            verticalOffset: verticalOffset,
                            tooltipText:
                                translations['controlButtonShuffleText'] ??
                                    'shuffle',
                            icon: Icon(
                              Icons.shuffle,
                              size: buttonSize * 0.5,
                              color:
                                  shuffle ? enableIconColor : disabledIconColor,
                            ),
                            readOnly: isRadio,
                            onPressed: () {
                              if (!readOnly) {
                                mainBloc.zoneControl(
                                    ip: ip,
                                    controlId: controlId,
                                    cmd: 'shufflemode',
                                    enable: !shuffle);
                                if (mounted) {
                                  setState(() {
                                    shuffle = !shuffle;
                                  });
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
