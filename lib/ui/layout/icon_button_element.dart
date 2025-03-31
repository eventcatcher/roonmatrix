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
    this.size = 48,
    this.readOnly = false,
  });

  final Icon icon;
  final bool noBackground;
  final bool withCircle;
  final bool moreInfo;
  final bool readOnly;
  final String? label;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (SharedWidgets.inIosStyle()) {
      return CupertinoButton.filled(
        disabledColor: CupertinoColors.systemGrey,
        padding: EdgeInsets.all(10),
        minSize: 10,
        onPressed: readOnly ? null : onPressed,
        child: icon,
      );
    }

    macButton() => MacosIconButton(
          backgroundColor: noBackground
              ? null
              : readOnly
                  ? CupertinoColors.inactiveGray.color
                  : moreInfo
                      ? CupertinoColors.activeOrange.color
                      : CupertinoColors.activeBlue.color,
          hoverColor: noBackground
              ? null
              : readOnly
                  ? CupertinoColors.inactiveGray.color
                  : moreInfo
                      ? CupertinoColors.activeOrange.darkElevatedColor
                      : CupertinoColors.activeBlue.darkElevatedColor,
          disabledColor: CupertinoColors.systemGrey,
          borderRadius: withCircle ? BorderRadius.circular(45.0) : null,
          icon: icon,
          pressedOpacity: 1,
          boxConstraints: BoxConstraints(
              minHeight: size, minWidth: size, maxWidth: size, maxHeight: size),
          semanticLabel: label,
          onPressed: onPressed,
          mouseCursor: SystemMouseCursors.click,
        );

    return SharedWidgets.inMacosStyle()
        ? withCircle
            ? CircleAvatar(
                radius: 20,
                backgroundColor: noBackground
                    ? null
                    : readOnly
                        ? CupertinoColors.inactiveGray.color
                        : moreInfo
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
                backgroundColor: noBackground
                    ? null
                    : readOnly
                        ? CupertinoColors.inactiveGray.color
                        : moreInfo
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
            : Ink(
                width: 30.0,
                height: 30.0,
                decoration: ShapeDecoration(
                    color: noBackground
                        ? null
                        : readOnly
                            ? Colors.grey
                            : SharedWidgets.brightness() == Brightness.dark
                                ? moreInfo
                                    ? Colors.orange.shade800
                                    : Colors.blue.shade800
                                : moreInfo
                                    ? Colors.orange.shade600
                                    : Colors.blue.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5)),
                    )),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  color: Colors.white,
                  icon: icon,
                  tooltip: label,
                  onPressed: onPressed,
                ),
              );
  }
}
