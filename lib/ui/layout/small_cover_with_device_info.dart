import 'package:flutter/material.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class DeviceInfo extends StatelessWidget {
  final String ip;
  final Map<String, dynamic> info;

  const DeviceInfo({
    super.key,
    required this.ip,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              info[ip]['name'],
              softWrap: false,
              maxLines: 1,
              style: SharedWidgets.isDesktopDevice()
                  ? const TextStyle(fontSize: 16.0)
                  : const TextStyle(fontSize: 14.0),
            ),
            Text(
              ip,
              softWrap: false,
              maxLines: 1,
              style: SharedWidgets.isDesktopDevice()
                  ? const TextStyle(fontSize: 13.0)
                  : const TextStyle(fontSize: 11.0),
            )
          ],
        ),
      ],
    );
  }
}
