import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class ControlButtons extends StatefulWidget {
  final Orientation orientation;
  final Map<String, dynamic> translations;
  final double partsToSubtract;
  final String ip;
  final bool? idle;
  final String controlId;
  final bool readOnly;

  const ControlButtons({
    super.key,
    required this.orientation,
    required this.translations,
    this.partsToSubtract = 0,
    this.idle,
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
  double get partsToSubtract => widget.partsToSubtract;
  String get ip => widget.ip;
  String get controlId => widget.controlId;
  bool get readOnly => widget.readOnly;

  double getButtonSize({required double size}) => size / 3;

  final bool showButtonUp = false;
  bool idle = false;

  late MainBloc mainBloc;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    idle = widget.idle ?? false;

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
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: 1 == 1 || showButtonUp == true
                                ? Tooltip(
                                    message:
                                        translations['controlButtonUpText'] ??
                                            'up',
                                    triggerMode: TooltipTriggerMode.manual,
                                    verticalOffset: verticalOffset,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      color: Colors.grey,
                                      hoverColor: Colors.blue,
                                      onPressed: () async {
                                        //
                                      },
                                      icon: Icon(
                                        Icons.keyboard_arrow_up,
                                        size: buttonSize,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: Tooltip(
                              message:
                                  translations['controlButtonPreviousText'] ??
                                      'previous',
                              triggerMode: TooltipTriggerMode.manual,
                              verticalOffset: verticalOffset,
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
                          ),
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: Tooltip(
                              message:
                                  translations['controlButtonPlaymodeText'] ??
                                      'pause/play',
                              triggerMode: TooltipTriggerMode.manual,
                              verticalOffset: verticalOffset,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                hoverColor: Colors.blue,
                                onPressed: () {
                                  if (!readOnly) {
                                    mainBloc.zoneControl(
                                        ip: ip,
                                        controlId: controlId,
                                        cmd: 'playmode');
                                    if (mounted) {
                                      setState(() {
                                        idle = !idle;
                                      });
                                    }
                                  }
                                },
                                icon: Icon(
                                  idle ? Icons.play_arrow : Icons.pause,
                                  size: buttonSize / 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: buttonSize,
                            height: buttonSize,
                            child: Tooltip(
                              message: translations['controlButtonNextText'] ??
                                  'next',
                              triggerMode: TooltipTriggerMode.manual,
                              verticalOffset: verticalOffset,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                hoverColor: Colors.blue,
                                onPressed: () {
                                  if (!readOnly) {
                                    mainBloc.zoneControl(
                                        ip: ip,
                                        controlId: controlId,
                                        cmd: 'next');
                                  }
                                },
                                icon: Icon(
                                  Icons.keyboard_arrow_right,
                                  size: buttonSize,
                                ),
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
                            child: Tooltip(
                              message:
                                  translations['controlButtonShuffleText'] ??
                                      'shuffle',
                              triggerMode: TooltipTriggerMode.manual,
                              verticalOffset: verticalOffset,
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
