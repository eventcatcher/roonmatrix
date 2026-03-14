import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/globals.dart';

class IconButtonElement extends StatelessWidget {
  final Icon icon;
  final String? label;
  final bool noBackground;
  final Color? backgroundColor;
  final Color? backgroundHoverColor;
  final Color? backgroundReadOnlyColor;
  final bool withCircle;
  final bool moreInfo;
  final bool readOnly;
  final double size;
  final VoidCallback onPressed;

  const IconButtonElement({
    super.key,
    required this.icon,
    this.label,
    this.noBackground = false,
    this.backgroundColor,
    this.backgroundHoverColor,
    this.backgroundReadOnlyColor,
    this.withCircle = false,
    this.moreInfo = false,
    this.readOnly = false,
    this.size = 48,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (Globals.inIosStyle()) {
      return CupertinoButton(
        disabledColor: backgroundReadOnlyColor != null
            ? CupertinoColors.transparent
            : CupertinoColors.systemGrey,
        padding: EdgeInsets.all(10),
        minSize: 10,
        color: noBackground
            ? null
            : readOnly
                ? backgroundReadOnlyColor ?? CupertinoColors.inactiveGray.color
                : backgroundColor ??
                    (moreInfo
                        ? CupertinoColors.activeOrange.color
                        : CupertinoColors.activeBlue.color),
        onPressed: readOnly ? null : onPressed,
        child: icon,
      );
    }

    macButton() => MacosIconButton(
          backgroundColor: noBackground
              ? null
              : readOnly
                  ? backgroundReadOnlyColor ??
                      CupertinoColors.inactiveGray.color
                  : backgroundColor ??
                      (moreInfo
                          ? CupertinoColors.activeOrange.color
                          : CupertinoColors.activeBlue.color),
          hoverColor: noBackground
              ? null
              : readOnly
                  ? backgroundReadOnlyColor ??
                      CupertinoColors.inactiveGray.color
                  : backgroundHoverColor ??
                      (moreInfo
                          ? CupertinoColors.activeOrange.darkElevatedColor
                          : CupertinoColors.activeBlue.darkElevatedColor),
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

    return Globals.inMacosStyle()
        ? withCircle
            ? CircleAvatar(
                radius: 20,
                backgroundColor: noBackground
                    ? null
                    : readOnly
                        ? backgroundReadOnlyColor ??
                            CupertinoColors.inactiveGray.color
                        : backgroundColor ??
                            (moreInfo
                                ? CupertinoColors.activeOrange.color
                                : CupertinoColors.activeBlue.color),
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
                        ? backgroundReadOnlyColor ??
                            CupertinoColors.inactiveGray.color
                        : backgroundColor ??
                            (moreInfo
                                ? CupertinoColors.activeOrange.color
                                : CupertinoColors.activeBlue.color),
                child: IconButton(
                  color: backgroundColor ??
                      (Globals.brightness() == Brightness.dark
                          ? moreInfo
                              ? Colors.orange.shade800
                              : Colors.blue.shade800
                          : moreInfo
                              ? Colors.orange.shade600
                              : Colors.blue.shade600),
                  icon: icon,
                  tooltip: label,
                  padding: EdgeInsets.zero,
                  onPressed: onPressed,
                ),
              )
            : Ink(
                width: size,
                height: size,
                decoration: ShapeDecoration(
                    color: noBackground
                        ? null
                        : readOnly
                            ? backgroundReadOnlyColor ?? Colors.grey
                            : backgroundColor ??
                                (Globals.brightness() == Brightness.dark
                                    ? moreInfo
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade800
                                    : moreInfo
                                        ? Colors.orange.shade600
                                        : Colors.blue.shade600),
                    shape: RoundedRectangleBorder(
                      borderRadius: Globals.borderRadius(),
                    )),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: Globals.borderRadius(),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      color: Colors.white,
                      splashRadius: 26,
                      hoverColor: backgroundHoverColor,
                      icon: icon,
                      tooltip: label,
                      onPressed: onPressed,
                    ),
                  ),
                ),
              );
  }
}
