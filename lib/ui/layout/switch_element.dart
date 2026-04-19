import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/globals.dart';

class SwitchElement extends StatelessWidget {
  final MaterialTapTargetSize? materialTapTargetSize;
  final Color? activeTrackColor;
  final Color? activeColor;
  final bool value;
  final dynamic Function(bool value) onChanged;

  const SwitchElement({
    super.key,
    this.materialTapTargetSize,
    this.activeTrackColor,
    this.activeColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Globals.inIosStyle()) {
      return CupertinoSwitch(value: value, onChanged: onChanged);
    }

    return Globals.inMacosStyle()
        ? MacosSwitch(value: value, onChanged: onChanged)
        : Switch(
            value: value,
            materialTapTargetSize: materialTapTargetSize,
            activeTrackColor: activeTrackColor,
            activeThumbColor: activeColor,
            onChanged: onChanged,
          );
  }
}
