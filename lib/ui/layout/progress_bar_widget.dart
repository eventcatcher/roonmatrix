import 'dart:async';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

class ProgressBarWidget extends StatefulWidget {
  final String ip;
  final String? controlId;
  final double coverPadding;
  final Brightness? brightness;

  const ProgressBarWidget({
    super.key,
    required this.ip,
    this.controlId,
    required this.coverPadding,
    this.brightness,
  });

  @override
  State<ProgressBarWidget> createState() => ProgressBarWidgetState();
}

class ProgressBarWidgetState extends State<ProgressBarWidget> {
  String get ip => widget.ip;
  double get coverPadding => widget.coverPadding;
  Brightness? get brightness => widget.brightness;

  final int toleranceInSeconds = 5;

  Map<String, dynamic> info = {};
  Widget progressBarWidget = SizedBox();
  int lastProgressPosition = 0;
  int progressBarPosition = 0;
  String lastProgressId = '';
  int total = 0;
  bool isRadio = false;
  bool idle = false;

  Timer? progressBarTimer;
  String? controlId;
  Map<String, dynamic>? selectedZone;
  double? coverWidth;

  late MainBloc mainBloc;
  late StreamSubscription mainBlocSubscription;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);
    initSubscription();

    super.initState();
  }

  void initSubscription() {
    info = mainBloc.state.info[ip] ?? {};

    if (info != {} && info['control_id'] != null) {
      String? controlIdUpdated = widget.controlId ?? info['control_id'];

      Map<String, dynamic> data = mainBloc.getZoneDataForControlId(
        info: info,
        controlId: controlIdUpdated,
        isRadio: isRadio,
      );

      setProgressBarArea(zoneData: data['zone']);
    }

    mainBlocSubscription = mainBloc.stream.listen((MainState mainState) {
      if (mainState is MainStateLoaded) {
        info = mainState.info[ip] ?? {};

        if (info != {} && info['control_id'] != null) {
          String? controlIdUpdated = widget.controlId ?? info['control_id'];

          Map<String, dynamic> data = mainBloc.getZoneDataForControlId(
            info: info,
            controlId: controlIdUpdated,
            isRadio: isRadio,
          );

          if (data['zone'] != null) {
            if (selectedZone != data['zone'] || controlIdUpdated != controlId) {
              SchedulerBinding.instance.addPostFrameCallback((_) async {
                if (mounted) {
                  setState(() {
                    Map<String, dynamic>? zone = data['zone'];
                    if (controlIdUpdated != controlId) {
                      lastProgressPosition = 0;
                      progressBarPosition = 0;
                      controlId = controlIdUpdated;
                    }

                    if (zone != null && selectedZone != zone) {
                      selectedZone = zone;
                    }

                    if (controlId != null) {
                      if ((info['playmode'] as Map<String, dynamic>)
                          .containsKey(controlId)) {
                        idle = info['playmode'][controlId] != 'play';
                      }

                      isRadio = data['isRadio'];
                      if (selectedZone?['zone'] == 'Apple Music') {
                        isRadio =
                            false; // fix for AppleMusic because the delay is too big (every stream with position:0 will be disabling the prev/next button for isRadio == true, but the next infodata update will be loaded 10-15sec later)
                      }
                      total =
                          data['zone'] != null && data['zone']['total'] != null
                          ? int.parse(data['zone']['total'].toString())
                          : 0;
                    }
                  });
                }
              });
            }
            setProgressBarArea(zoneData: data['zone']);
          }
        }
      }
    });
  }

  void setProgressBarArea({required Map<String, dynamic>? zoneData}) {
    if (zoneData != null && zoneData.isNotEmpty) {
      String id = zoneData['id'] ?? zoneData['hash'] ?? '';
      int actualProgressPosition = zoneData['position'] != null
          ? int.parse(zoneData['position'].toString())
          : 0;
      int total = isRadio == true ? actualProgressPosition : this.total;
      if ((actualProgressPosition != lastProgressPosition &&
              (actualProgressPosition - progressBarPosition).abs() >
                  toleranceInSeconds) ||
          lastProgressPosition == 0 ||
          lastProgressId != id) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              progressBarPosition = actualProgressPosition;
              lastProgressPosition = actualProgressPosition;
              lastProgressId = id;
              if (kDebugMode) {
                debugPrint(
                  'setProgressBarArea (update) => id: $id, progress: $progressBarPosition, total: $total, isRadio: $isRadio',
                );
              }
              progressBarWidget = total == 0
                  ? SizedBox()
                  : getProgressBar(
                      progress: actualProgressPosition,
                      total: total,
                    );

              if (progressBarTimer != null && progressBarTimer!.isActive) {
                progressBarTimer!.cancel();
                if (kDebugMode) {
                  debugPrint('setProgressBarArea => cancel timer');
                }
              }

              progressBarTimer = Timer.periodic(Duration(seconds: 1), (
                Timer timer,
              ) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      if ((isRadio == true || progressBarPosition < total) &&
                          !idle) {
                        progressBarPosition += 1;
                        if (isRadio == true) {
                          total = progressBarPosition;
                        }
                      }
                      if (kDebugMode) {
                        debugPrint(
                          'setProgressBarArea (timer) => id: $id, position: $progressBarPosition, total: $total, isRadio: $isRadio',
                        );
                      }
                      progressBarWidget = total == 0
                          ? SizedBox()
                          : getProgressBar(
                              progress: progressBarPosition,
                              total: total,
                            );
                    });
                  }
                });
              });
            });
          }
        });
      }
    }
  }

  Widget getProgressBar({required int progress, required int total}) {
    return Container(
      margin: EdgeInsets.only(top: coverPadding),
      constraints: coverWidth != null
          ? BoxConstraints(minWidth: coverWidth!, maxWidth: coverWidth!)
          : null,

      decoration:
          Globals.brightness() == Brightness.dark ||
              brightness == Brightness.dark
          ? ColorDefs.areaDecorationFilledDarkStyle(
              withAnimatedBackground: false,
            )
          : ColorDefs.areaDecorationFilledLightStyle(
              withAnimatedBackground: false,
            ),
      child: Padding(
        padding: EdgeInsets.only(
          left: coverPadding,
          right: coverPadding,
          top: 24.0,
          bottom: 8.0,
        ),
        child: ProgressBar(
          progress: Duration(seconds: progress),
          total: Duration(seconds: total),
          progressBarColor: Colors.red,
          baseBarColor: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.24)
              : ColorDefs.textColor(context: context).withValues(alpha: 0.24),
          thumbColor: Colors.green,
          barHeight: 3.0,
          thumbRadius: 5.0,
          timeLabelTextStyle: TextStyle(
            fontSize: 12.0,
            color: brightness == Brightness.dark
                ? Colors.white
                : ColorDefs.textColor(context: context),
          ),
          onSeek: (duration) {
            //_player.seek(duration);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Globals.coverSwitchDefaultFadeAnimationDuration * 0.6,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 1),
            end: Offset(0, 0),
          ).animate(animation),
          child: child,
        );
      },
      child: progressBarWidget,
    );
  }

  @override
  Future<void> dispose() async {
    mainBlocSubscription.cancel();

    super.dispose();
  }
}
