import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/ripple_ping.dart';

class DeviceInfo extends StatefulWidget {
  final Map<String, dynamic> translations;
  final String ip;
  final Map<String, dynamic> info;
  final bool connected;
  final bool ping;
  final double height;
  final VoidCallback onFinishedPing;

  const DeviceInfo({
    super.key,
    required this.translations,
    required this.ip,
    required this.connected,
    required this.ping,
    required this.info,
    required this.height,
    required this.onFinishedPing,
  });

  @override
  State<DeviceInfo> createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  final double widthNameAndIpArea = 150;
  final double fontSizeName = 14.0;
  final double fontSizeIp = 11.0;

  Color rebootIconColor = Colors.red;

  late Timer timer;

  @override
  void initState() {
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
  void dispose() {
    super.dispose();
    timer.cancel();
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
            SizedBox(
              width: widthNameAndIpArea,
              height: widget.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.info[widget.ip]['name'],
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(fontSize: fontSizeName, height: 1.3),
                  ),
                  Row(
                    children: [
                      Text(
                        widget.ip,
                        softWrap: false,
                        maxLines: 1,
                        style: TextStyle(fontSize: fontSizeIp, height: 1.3),
                      ),
                      if (widget.info[widget.ip]['reboot_python'] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            key: ValueKey('pythonRebootIcon-$rebootIconColor'),
                            Icons.restart_alt,
                            size: 18,
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
              SizedBox(width: 16.0),
              Tooltip(
                message:
                    widget.translations['devicePingStatusLabel'] ??
                    'Device response received',
                waitDuration: Globals.tooltipWaitDuration,
                child: RipplePing(
                  trigger: widget.ping,
                  color: Colors.red.shade800,
                  dotSize: 6,
                  maxRadius: widget.height / 2,
                  onFinished: () => widget.onFinishedPing(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
