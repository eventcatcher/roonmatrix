import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:language_code/language_code.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/ping_data.dart';
import 'package:roonmatrix/ui/layout/ripple_ping.dart';

class DeviceInfo extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String ip;
  final Map<String, dynamic> info;
  final bool connected;
  final bool isVirtualDevice;
  final PingData? pingData;
  final double height;
  final VoidCallback onFinishedPing;

  const DeviceInfo({
    super.key,
    required this.translations,
    required this.ip,
    required this.connected,
    required this.isVirtualDevice,
    required this.pingData,
    required this.info,
    required this.height,
    required this.onFinishedPing,
  });

  @override
  State<DeviceInfo> createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  final double widthNameAndIpArea = 140;
  final double fontSizeName = 14.0;
  final double fontSizeIp = 11.0;

  Color rebootIconColor = Colors.red;
  bool roonConnectionError = false;
  String lastRoonErrorLabelPart = '';

  late Timer timer;

  @override
  void initState() {
    roonConnectionError = getRoonConnectionError();
    lastRoonErrorLabelPart = getLastRoonErrorLabelPart();

    timer = Timer.periodic(
      Duration(seconds: 1),
      (timer) => SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          setState(() {
            rebootIconColor = rebootIconColor == Colors.red
                ? Colors.transparent
                : Colors.red;
          });
        }
      }),
    );

    super.initState();
  }

  @override
  void didUpdateWidget(DeviceInfo oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (roonConnectionError != getRoonConnectionError() ||
        lastRoonErrorLabelPart != getLastRoonErrorLabelPart()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            roonConnectionError = getRoonConnectionError();
            lastRoonErrorLabelPart = getLastRoonErrorLabelPart();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  bool getRoonConnectionError() {
    bool roonShow = widget.info[widget.ip]['roon_show'] ?? false;
    bool roonActive = widget.info[widget.ip]['roon_active'] ?? false;
    String lastRoonError = widget.info[widget.ip]?['last_roon_error'] ?? '';

    return roonShow == true && (!roonActive || lastRoonError.isNotEmpty);
  }

  String getLastRoonErrorLabelPart() {
    String lastRoonError = widget.info[widget.ip]?['last_roon_error'] ?? '';

    return lastRoonError.isNotEmpty ? ': $lastRoonError' : '';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: widthNameAndIpArea,
              height: widget.height,
              padding: EdgeInsets.only(right: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message:
                        '${widget.translations['deviceName'] ?? 'Device name'}: ${widget.info[widget.ip]['name']}',
                    waitDuration: Globals.tooltipWaitDuration,
                    child: Text(
                      widget.info[widget.ip]['name'],
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: fontSizeName, height: 1.3),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.ip,
                        softWrap: false,
                        maxLines: 1,
                        style: TextStyle(fontSize: fontSizeIp, height: 1.3),
                      ),
                      SizedBox(
                        child: widget.isVirtualDevice
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Tooltip(
                                  message:
                                      widget
                                          .translations['virtualDeviceBadgeTooltip'] ??
                                      'Virtual device',
                                  waitDuration: Globals.tooltipWaitDuration,
                                  child: Badge(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 3.0,
                                      vertical: 0.0,
                                    ),
                                    label: Text(
                                      'VM',
                                      style: TextStyle(
                                        fontSize: fontSizeIp - 3,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor:
                                        CupertinoColors.activeBlue.color,
                                  ),
                                ),
                              )
                            : SizedBox(),
                      ),
                      if (widget.info[widget.ip]['reboot_python'] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            key: ValueKey('pythonRebootIcon-$rebootIconColor'),
                            Icons.restart_alt,
                            size: 16,
                            color: rebootIconColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 0.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message:
                    widget.translations['deviceConnectionStatusLabel'] ??
                    'Device connection status',
                waitDuration: Globals.tooltipWaitDuration,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Icon(
                    widget.connected ? Icons.wifi : Icons.wifi_off,
                    size: 24.0,
                    color: widget.connected
                        ? Colors.green.shade600
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Tooltip(
                message:
                    (widget.translations['devicePingStatusLabel'] ??
                        'Device response received') +
                    (widget.pingData != null
                        ? ' (${DateFormat.yMd(LanguageCode.code.locale.languageCode).add_jms().format(widget.pingData!.updatedAt)})'
                        : ''),
                waitDuration: Globals.tooltipWaitDuration,
                child: RipplePing(
                  trigger: widget.pingData?.ping ?? false,
                  color: Colors.red.shade800,
                  dotSize: 6,
                  maxRadius: widget.height / 2,
                  onFinished: () => widget.onFinishedPing(),
                ),
              ),
              if (roonConnectionError == true)
                Tooltip(
                  message:
                      (widget.translations['roonErrorTooltip'] ??
                          'Roon error') +
                      lastRoonErrorLabelPart,
                  waitDuration: Globals.tooltipWaitDuration,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: SvgPicture.asset(
                        Globals.roonConnectionErrorSvgAssetPath,
                        allowDrawingOutsideViewBox: false,
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
