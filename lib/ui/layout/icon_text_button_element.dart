import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class IconTextButtonElement extends StatelessWidget {
  const IconTextButtonElement({
    super.key,
    this.onMacAsText = false,
    required this.icon,
    required this.label,
    this.style,
    this.onPressed,
  });

  final Widget icon;
  final bool onMacAsText;
  final String label;
  final ButtonStyle? style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (SharedWidgets.inIosStyle()) {
      return CupertinoButton.filled(
        disabledColor: CupertinoColors.inactiveGray,
        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
        minSize: 8,
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: icon,
            ),
            Text(
              label,
              style: TextStyle(color: CupertinoColors.white),
            )
          ],
        ),
      );
    }

    return SharedWidgets.inMacosStyle()
        ? onMacAsText
            ? PushButton(
                controlSize: ControlSize.regular,
                color: CupertinoColors.activeBlue.color,
                disabledColor: CupertinoColors.systemGrey,
                mouseCursor: SystemMouseCursors.click,
                onPressed: onPressed,
                child: Text(label),
              )
            : MacosIconButton(
                boxConstraints: const BoxConstraints(
                    minHeight: 30, minWidth: 30, maxWidth: 30, maxHeight: 30),
                backgroundColor: CupertinoColors.activeBlue.color,
                hoverColor: CupertinoColors.activeBlue.darkElevatedColor,
                disabledColor: CupertinoColors.systemGrey,
                padding: EdgeInsets.zero,
                icon: icon,
                //semanticLabel: label,
                onPressed: onPressed,
                mouseCursor: SystemMouseCursors.click,
              )
        : ElevatedButton.icon(
            icon: icon,
            label: Text(label),
            style: style ??
                ElevatedButton.styleFrom(
                    backgroundColor:
                        SharedWidgets.brightness() == Brightness.dark
                            ? Colors.blue.shade800
                            : Colors.blue.shade600),
            onPressed: onPressed,
          );
  }
}
