import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/globals.dart';

class IconTextButtonElement extends StatelessWidget {
  final bool onMacAsText;
  final bool secondaryStyle;
  final Widget icon;
  final String label;
  final ButtonStyle? style;
  final VoidCallback? onPressed;

  const IconTextButtonElement({
    super.key,
    this.onMacAsText = false,
    this.secondaryStyle = false,
    required this.icon,
    required this.label,
    this.style,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (Globals.inIosStyle()) {
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

    return Globals.inMacosStyle()
        ? onMacAsText
            ? PushButton(
                controlSize: ControlSize.regular,
                secondary: secondaryStyle,
                color: secondaryStyle == true
                    ? CupertinoColors.activeOrange.color
                    : CupertinoColors.activeBlue.color,
                disabledColor: CupertinoColors.systemGrey,
                mouseCursor: SystemMouseCursors.click,
                onPressed: onPressed,
                child: Text(
                  label,
                  style: secondaryStyle == true
                      ? TextStyle(color: CupertinoColors.black)
                      : TextStyle(color: CupertinoColors.white),
                ),
              )
            : MacosIconButton(
                boxConstraints: const BoxConstraints(
                    minHeight: 30, minWidth: 30, maxWidth: 30, maxHeight: 30),
                backgroundColor: secondaryStyle == true
                    ? CupertinoColors.activeOrange.color
                    : CupertinoColors.activeBlue.color,
                hoverColor: secondaryStyle == true
                    ? CupertinoColors.activeOrange.darkElevatedColor
                    : CupertinoColors.activeBlue.darkElevatedColor,
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
                    backgroundColor: secondaryStyle == true
                        ? Globals.brightness() == Brightness.dark
                            ? Colors.orange.shade800
                            : Colors.orange.shade600
                        : Globals.brightness() == Brightness.dark
                            ? Colors.blue.shade800
                            : Colors.blue.shade600),
            onPressed: onPressed,
          );
  }
}
