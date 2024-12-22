import 'dart:io';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

class IconButtonElement extends StatelessWidget {
  const IconButtonElement({
    super.key,
    required this.showMacStyle,
    required this.icon,
    required this.onPressed,
  });

  final bool showMacStyle;
  final Icon icon;
  final Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return showMacStyle == true && Platform.isMacOS
        ? MacosIconButton(
            //backgroundColor: Colors.blue,
            icon: icon,
            onPressed: onPressed,
          )
        : IconButton(
            color: Colors.blue,
            icon: icon,
            onPressed: onPressed,
          );
  }
}
