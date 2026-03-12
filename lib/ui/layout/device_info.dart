import 'package:flutter/material.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/ripple_ping.dart';

class DeviceInfo extends StatelessWidget {
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

  final double widthNameAndIpArea = 150;
  final double fontSizeName = 14.0;
  final double fontSizeIp = 11.0;

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
              height: height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info[ip]['name'],
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(fontSize: fontSizeName, height: 1.3),
                  ),
                  Text(
                    ip,
                    softWrap: false,
                    maxLines: 1,
                    style: TextStyle(fontSize: fontSizeIp, height: 1.3),
                  )
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
                message: translations['deviceConnectionStatusLabel'] ??
                    'Device connection status',
                waitDuration: Globals.tooltipWaitDuration,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3.0),
                  child: Icon(
                    connected ? Icons.wifi : Icons.wifi_off,
                    size: 24.0,
                    color: connected
                        ? Colors.green.shade600
                        : Colors.grey.shade500,
                  ),
                ),
              ),
              SizedBox(width: 16.0),
              Tooltip(
                message: translations['devicePingStatusLabel'] ??
                    'Device response received',
                waitDuration: Globals.tooltipWaitDuration,
                child: RipplePing(
                  trigger: ping,
                  color: Colors.red.shade800,
                  dotSize: 6,
                  maxRadius: height / 2,
                  onFinished: () => onFinishedPing(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
