import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class IconButtonElement extends StatelessWidget {
  const IconButtonElement({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.noBackground = false,
    this.withCircle = false,
    this.moreInfo = false,
  });

  final Icon icon;
  final bool noBackground;
  final bool withCircle;
  final bool moreInfo;
  final String? label;
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

    macButton() => MacosIconButton(
          backgroundColor: noBackground
              ? null
              : moreInfo
                  ? CupertinoColors.activeOrange.color
                  : CupertinoColors.activeBlue.color,
          hoverColor: moreInfo
              ? CupertinoColors.activeOrange.darkElevatedColor
              : CupertinoColors.activeBlue.darkElevatedColor,
          disabledColor: CupertinoColors.systemGrey,
          borderRadius: withCircle ? BorderRadius.circular(45.0) : null,
          icon: icon,
          pressedOpacity: 1,
          boxConstraints: const BoxConstraints(
              minHeight: 48, minWidth: 48, maxWidth: 48, maxHeight: 48),
          semanticLabel: label,
          onPressed: onPressed,
          mouseCursor: SystemMouseCursors.click,
        );

    return SharedWidgets.inMacosStyle()
        ? withCircle
            ? CircleAvatar(
                radius: 20,
                backgroundColor: moreInfo
                    ? CupertinoColors.activeOrange.color
                    : CupertinoColors.activeBlue.color,
                child: label != null
                    ? MacosTooltip(
                        message: label!,
                        child: macButton(),
                      )
                    : macButton(),
              )
            : label != null
                ? MacosTooltip(
                    message: label!,
                    child: macButton(),
                  )
                : macButton()
        : withCircle
            ? CircleAvatar(
                radius: 18,
                backgroundColor: moreInfo
                    ? CupertinoColors.activeOrange.color
                    : CupertinoColors.activeBlue.color,
                child: IconButton(
                  color: SharedWidgets.brightness() == Brightness.dark
                      ? moreInfo
                          ? Colors.orange.shade800
                          : Colors.blue.shade800
                      : moreInfo
                          ? Colors.orange.shade600
                          : Colors.blue.shade600,
                  icon: icon,
                  tooltip: label,
                  padding: EdgeInsets.zero,
                  onPressed: onPressed,
                ),
              )
            : IconButton(
                color: SharedWidgets.brightness() == Brightness.dark
                    ? moreInfo
                        ? Colors.orange.shade800
                        : Colors.blue.shade800
                    : moreInfo
                        ? Colors.orange.shade600
                        : Colors.blue.shade600,
                icon: icon,
                tooltip: label,
                onPressed: onPressed,
              );
  }
}
