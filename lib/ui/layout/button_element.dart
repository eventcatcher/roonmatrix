import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class ButtonElement extends StatelessWidget {
  const ButtonElement({
    super.key,
    required this.showMacStyle,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final bool showMacStyle;
  final String label;
  final Icon? icon;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return showMacStyle == true && Platform.isMacOS
        ? PushButton(
            controlSize: ControlSize.regular,
            onPressed: onPressed,
            child: Text(label),
          )
        : ElevatedButton.icon(
            icon: icon != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: icon,
                  )
                : const SizedBox(),
            label: Text(label),
            onPressed: onPressed,
          );
  }
}
