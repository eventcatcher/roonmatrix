import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/expandable_menu.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/zone_start_button.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';

class ZoneStartButtons extends StatefulWidget {
  final Map<String, dynamic> translations;
  final double deviceWidth;
  final Orientation orientation;
  final Map<String, dynamic>? info;

  const ZoneStartButtons({
    super.key,
    required this.translations,
    required this.deviceWidth,
    required this.orientation,
    required this.info,
  });

  @override
  State<ZoneStartButtons> createState() => ZoneStartButtonsState();
}

class ZoneStartButtonsState extends State<ZoneStartButtons> {
  Map<String, dynamic> get translations => widget.translations;
  Orientation get orientation => widget.orientation;

  final GlobalKey keyZoneNotRunningButtonsKey = GlobalKey();
  final double notRunningButtonsExpandableMenuWidthStandardAddon = 42;

  final double expandableSize = 38.0;
  final double buttonsWidthDefault = 200.0;
  final int animationSpeed = 400;

  List<Widget> buttons = [];
  double? zoneNotRunningButtonsWidth;

  late MainBloc mainBloc;
  late double deviceWidth;
  late Map<String, dynamic>? info;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    deviceWidth = widget.deviceWidth;
    info = widget.info;
    buttons = getZonesNotRunningStartButtons();

    super.initState();
  }

  @override
  void didUpdateWidget(ZoneStartButtons oldWidget) {
    super.didUpdateWidget(oldWidget);

    deviceWidth = widget.deviceWidth;
    info = widget.info;
    buttons = getZonesNotRunningStartButtons();
  }

  List<Widget> getZonesNotRunningStartButtons() {
    List<Widget> buttons = [];

    if (info != null &&
        info != {} &&
        info!.keys.isNotEmpty &&
        (info![info!.keys.first] as Map<String, dynamic>)
            .containsKey('channels')) {
      Map<String, dynamic> channels = info![info!.keys.first]['channels'];
      Map<String, dynamic> webPlayouts =
          info![info!.keys.first]['web_playouts'];

      for (String serverName in webPlayouts.keys) {
        List<dynamic> zones = webPlayouts[serverName];
        for (dynamic zone in zones) {
          if (zone != null &&
              zone['status'] == 'not running' &&
              zone['zone'] != 'SpotifyConnect') {
            String zoneName = '$serverName-${zone['zone']}';

            String? controlId =
                channels.keys.firstWhereOrNull((el) => el == zoneName);

            if (controlId != null) {
              buttons.add(ZoneStartButton(
                label: zoneName,
                onPressed: () {
                  mainBloc.zoneControl(
                    ip: info!.keys.first,
                    controlId: controlId,
                    cmd: 'playmode',
                    enable: true,
                  );
                },
              ));
            }
          }
        }
      }
    }

    updateZoneNotRunningButtonsWidth(length: buttons.length);

    return buttons;
  }

  void updateZoneNotRunningButtonsWidth({required int length, int retry = 0}) {
    double width = 0;
    double addOn = orientation == Orientation.portrait
        ? notRunningButtonsExpandableMenuWidthStandardAddon
        : Platform.isAndroid
            ? notRunningButtonsExpandableMenuWidthStandardAddon
            : -46;

    if (length > 0) {
      if (keyZoneNotRunningButtonsKey.currentContext != null) {
        RenderBox? box;
        BuildContext? itemContext = keyZoneNotRunningButtonsKey.currentContext;
        if (mounted && itemContext != null) {
          RenderObject? renderObject = itemContext.findRenderObject();
          if (renderObject is RenderBox && renderObject.attached) {
            box = renderObject;
            width = box.size.width + 94 + (length - 1) * 2;
          }
        }

        if (zoneNotRunningButtonsWidth == null && width == 0) {
          width = deviceWidth + addOn;
        }

        if (width > 0) {
          if (width > deviceWidth + addOn) {
            width = deviceWidth + addOn;
          }

          if (width != zoneNotRunningButtonsWidth) {
            SchedulerBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                setState(() {
                  zoneNotRunningButtonsWidth = width;
                });
              }
            });
          }
        }
      } else {
        if (retry < 10) {
          Future<void>.delayed(Duration(milliseconds: 500)).then((value) =>
              updateZoneNotRunningButtonsWidth(
                  length: length, retry: retry += 1));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (buttons.isEmpty) {
      return SizedBox();
    }
    return SharedWidgets.isMobileDevice()
        ? SizedBox(
            width: zoneNotRunningButtonsWidth ?? buttonsWidthDefault,
            height: expandableSize,
            child: ExpandableMenu(
              key: ValueKey(
                  'ExpandableMenuZoneButtons-$zoneNotRunningButtonsWidth'), // zone button menu in cover area
              width: expandableSize,
              height: expandableSize,
              animationSpeed: animationSpeed,
              backgroundColor:
                  SharedWidgets.buttonRowBackgroundColor(context: context),
              items: [
                Wrap(
                  direction: Axis.horizontal,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      key: keyZoneNotRunningButtonsKey,
                      children: [
                        SizedBox(
                            height: 30.0,
                            child: Center(
                                child: Text(
                                    '${translations['startZone'] ?? 'start'}: '))),
                        ...buttons,
                        Text(
                          '$zoneNotRunningButtonsWidth-${orientation.name}',
                          style: TextStyle(
                            fontSize:
                                0, // update value here to refresh widget (without the width is not actualized)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8.0),
              Text(translations['startZone'] ?? 'start',
                  style: TextStyle(
                      color: SharedWidgets.textColor(context: context))),
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Row(
                    children: buttons,
                  ),
                ),
              ),
            ],
          );
  }
}
