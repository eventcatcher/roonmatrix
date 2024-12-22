import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class SwitchElement extends StatelessWidget {
  const SwitchElement({
    super.key,
    required this.showMacStyle,
    this.materialTapTargetSize,
    this.activeTrackColor,
    this.activeColor,
    required this.value,
    required this.onChanged,
  });

  final bool showMacStyle;
  final MaterialTapTargetSize? materialTapTargetSize;
  final Color? activeTrackColor;
  final Color? activeColor;
  final bool value;
  final dynamic Function(bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return showMacStyle == true && Platform.isMacOS
        ? MacosSwitch(
            value: value,
            onChanged: onChanged,
          )
        : Switch(
            value: value,
            materialTapTargetSize: materialTapTargetSize,
            activeTrackColor: activeTrackColor,
            activeColor: activeColor,
            onChanged: onChanged,
          );
  }
}
