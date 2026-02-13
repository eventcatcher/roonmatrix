import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/globals.dart';
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
  final Color iconColorLight = Colors.blue.shade900;
  final Color iconColorDark = Colors.blue.shade300;
  final Color enableIconColor = Colors.green;
  final Color disabledIconColorLight = Colors.grey.shade600;
  final Color disabledIconColorDark = Colors.grey.shade300;
  final double controlAreaInCrossMinHeight = 150;

  double getButtonSize({
    required double size,
    required bool inRow,
  }) =>
      size / (inRow ? 9 : 3);

  bool idle = false;
  bool shuffle = false;
  bool repeat = false;
  bool isRadio = false;
  bool inRow = false;

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
      inRow = maxHeight < controlAreaInCrossMinHeight;
      double size =
          inRow ? maxWidth : (maxWidth < maxHeight ? maxWidth : maxHeight);
      double buttonSize = getButtonSize(size: size, inRow: inRow);
      bool textOff = maxHeight < (buttonSize + 8);
      if (textOff) {
        buttonSize = maxHeight - 8;
      }
      double verticalTooltipOffset = buttonSize / 2;
      double width = (inRow ? 9 : 3) * buttonSize;
      double height = (inRow ? 1 : 3) * buttonSize;
      double iconSize = buttonSize * 0.5;

      return SizedBox(
        width: size,
        height: inRow ? buttonSize : size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: width,
                  height: height,
                  decoration: inRow
                      ? BoxDecoration(
                          borderRadius: Globals.borderRadius(),
                          color: Color.fromARGB(30, 70, 70, 70),
                        )
                      : null,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!inRow)
                        Row(
                          children: [
                            SizedBox(width: buttonSize),
                            ControlButton(
                              buttonSize: buttonSize,
                              verticalTooltipOffset: verticalTooltipOffset,
                              tooltipText:
                                  translations['controlButtonRepeatText'] ??
                                      'repeat',
                              icon: Icon(
                                Icons.repeat,
                                size: iconSize,
                                color: repeat
                                    ? enableIconColor
                                    : Globals.brightness() == Brightness.dark
                                        ? disabledIconColorDark
                                        : disabledIconColorLight,
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
                          if (inRow) ...[
                            ControlButton(
                              buttonSize: buttonSize,
                              horizontalMargin: iconSize / 2 + 8,
                              verticalTooltipOffset: verticalTooltipOffset,
                              tooltipText:
                                  translations['controlButtonShuffleText'] ??
                                      'shuffle',
                              icon: Icon(
                                Icons.shuffle,
                                size: iconSize,
                                color: shuffle
                                    ? enableIconColor
                                    : Globals.brightness() == Brightness.dark
                                        ? disabledIconColorDark
                                        : disabledIconColorLight,
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
                            ControlButton(
                              buttonSize: buttonSize,
                              horizontalMargin: iconSize / 2,
                              verticalTooltipOffset: verticalTooltipOffset,
                              tooltipText:
                                  translations['controlButtonRepeatText'] ??
                                      'repeat',
                              icon: Icon(
                                Icons.repeat,
                                size: iconSize,
                                color: repeat
                                    ? enableIconColor
                                    : Globals.brightness() == Brightness.dark
                                        ? disabledIconColorDark
                                        : disabledIconColorLight,
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
                            SizedBox(width: buttonSize),
                          ],
                          ControlButton(
                            buttonSize: buttonSize,
                            horizontalMargin: inRow ? iconSize / 2 : null,
                            verticalTooltipOffset: verticalTooltipOffset,
                            tooltipText:
                                translations['controlButtonPreviousText'] ??
                                    'previous track',
                            icon: Icon(
                              Icons.keyboard_arrow_left,
                              size: iconSize,
                            ),
                            color: Globals.brightness() == Brightness.dark
                                ? iconColorDark
                                : iconColorLight,
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
                            horizontalMargin: inRow ? iconSize / 2 : null,
                            verticalTooltipOffset: verticalTooltipOffset,
                            tooltipText:
                                translations['controlButtonPlaymodeText'] ??
                                    'pause/play',
                            icon: Icon(
                              idle ? Icons.play_arrow : Icons.pause,
                              size: iconSize,
                            ),
                            color: Globals.brightness() == Brightness.dark
                                ? iconColorDark
                                : iconColorLight,
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
                            horizontalMargin: inRow ? iconSize / 2 : null,
                            verticalTooltipOffset: verticalTooltipOffset,
                            tooltipText:
                                translations['controlButtonNextText'] ??
                                    'next track',
                            icon: Icon(
                              Icons.keyboard_arrow_right,
                              size: iconSize,
                            ),
                            color: Globals.brightness() == Brightness.dark
                                ? iconColorDark
                                : iconColorLight,
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
                      if (!inRow)
                        Row(
                          children: [
                            SizedBox(width: buttonSize),
                            ControlButton(
                              buttonSize: buttonSize,
                              verticalTooltipOffset: verticalTooltipOffset,
                              tooltipText:
                                  translations['controlButtonShuffleText'] ??
                                      'shuffle',
                              icon: Icon(
                                Icons.shuffle,
                                size: iconSize,
                                color: shuffle
                                    ? enableIconColor
                                    : Globals.brightness() == Brightness.dark
                                        ? disabledIconColorDark
                                        : disabledIconColorLight,
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
