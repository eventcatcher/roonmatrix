import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class IconButtonElement extends StatelessWidget {
  const IconButtonElement({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final Icon icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (SharedWidgets.inIosStyle()) {
      return CupertinoButton.filled(
        padding: EdgeInsets.all(8),
        minSize: 10,
        onPressed: onPressed,
        child: icon,
      );
    }

    return SharedWidgets.inMacosStyle()
        ? MacosIconButton(
            backgroundColor: CupertinoColors.activeBlue.color,
            hoverColor: CupertinoColors.activeBlue.darkElevatedColor,
            disabledColor: CupertinoColors.systemGrey,
            icon: icon,
            //semanticLabel: label,
            onPressed: onPressed,
            mouseCursor: SystemMouseCursors.click,
          )
        : IconButton(
            color: SharedWidgets.brightness() == Brightness.dark
                ? Colors.blue.shade800
                : Colors.blue.shade600,
            icon: icon,
            onPressed: onPressed,
          );
  }
}
