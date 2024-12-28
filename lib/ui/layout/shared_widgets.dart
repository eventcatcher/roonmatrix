import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/main.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/text_field_element.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedWidgets {
  static List<Widget> labelWidget(
          {required String? label, Color? labelColor}) =>
      label != null
          ? [
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  label,
                  overflow: TextOverflow
                      .ellipsis, // fade is maybe the better alternative, because you see more of the text
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 12.0,
                  ),
                ),
              ),
              const SizedBox(
                height: 4.0,
              ),
            ]
          : [];

  static Brightness brightness() {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness;
  }

  static Color textColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? CupertinoColors.white
          : CupertinoColors.black;
    }
    if (showMacStyle && Platform.isMacOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.white
          : MacosColors.black;
    }
    return Theme.of(context).colorScheme.inverseSurface;
  }

  static Color iconColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    return textColor(showMacStyle: showMacStyle, context: context);
  }

  static Color hintColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return CupertinoColors.systemGrey;
    }
    if (showMacStyle && Platform.isMacOS) {
      return MacosColors.systemGrayColor;
    }
    return Theme.of(context).hintColor;
  }

  static Color windowBackgroundColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.underPageBackgroundColor
          : CupertinoColors.white;
    }
    if (showMacStyle && Platform.isMacOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.underPageBackgroundColor
          : MacosColors.white;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color borderColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 60, 60, 60)
          : MacosColors.tickBackgroundColor;
    }
    if ((showMacStyle && Platform.isMacOS) || Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.systemGrayColor
          : MacosColors.tickBackgroundColor;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color elementBackgroundColorLighter({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? Theme.of(context).primaryColorLight
          : CupertinoColors.white;
    }
    if (showMacStyle && Platform.isMacOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? Theme.of(context).primaryColorLight
          : Colors.white;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color elementBackgroundColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    return windowBackgroundColor(showMacStyle: showMacStyle, context: context);
  }

  static Color areaBackgroundColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade100;
    }
    if (showMacStyle && Platform.isMacOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade100;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade100;
  }

  static Color resetIconColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Color(0xFFCCCCCC);
    }
    if ((showMacStyle && Platform.isMacOS) || Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Color(0xFFCCCCCC);
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade100;
  }

  static Color tileBackgroundColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.blue.shade100;
    }
    if (showMacStyle && Platform.isMacOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.blue.shade100; // MacosColors.systemTealColor;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade700
        : Colors.blue.shade100;
  }

  static Color textFieldBackgroundColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.controlColor
          : Color(0xffefefef);
    }
    if (showMacStyle && Platform.isMacOS) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.controlColor
          : Color(0xffefefef);
    }
    return Colors.grey.shade100;
  }

  static Color toolbarResizeButtonColor({
    required bool showMacStyle,
    required BuildContext context,
  }) {
    if (Platform.isIOS) {
      return CupertinoColors.systemGrey;
    }
    if (showMacStyle && Platform.isMacOS) {
      return MacosColors.systemGrayColor;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade300
        : Colors.white;
  }

  static AlertElement addItemWithNameDialog({
    required bool showMacStyle,
    required BuildContext context,
    required TextEditingController textController,
    required Map<String, dynamic> translations,
  }) =>
      AlertElement(
        showMacStyle: showMacStyle,
        title: translations['dialogAddItemTitle'] ?? 'Add a new item',
        content: TextFieldElement(
          showMacStyle: showMacStyle,
          controller: textController,
          autofocus: true,
          placeholder:
              translations['dialogAddItemHintText'] ?? "Enter here the name",
        ),
        button1Label: translations['dialogCancelButtonText'] ?? 'Cancel',
        onPressed1: () => Navigator.pop(context),
        button2Label: translations['dialogAddItemButtonText'] ?? 'Add',
        onPressed2: () {
          if (textController.text.isNotEmpty) {
            Navigator.pop(context, textController.text);
          }
        },
      );

  static AlertElement addItemDialog({
    required BuildContext context,
    required Map<String, dynamic> translations,
  }) =>
      AlertElement(
        showMacStyle: showMacStyle,
        title: translations['dialogAddItemTitle'] ?? 'Add a new item?',
        button1Label: translations['dialogCancelButtonText'] ?? 'Cancel',
        onPressed1: () => Navigator.pop(context, false),
        button2Label: translations['dialogAddItemButtonText'] ?? 'Add',
        onPressed2: () => Navigator.pop(context, true),
      );

  static AlertElement removeItemDialog({
    required BuildContext context,
    required Map<String, dynamic> translations,
  }) =>
      AlertElement(
        showMacStyle: showMacStyle,
        title: translations['dialogRemoveItemTitle'] ?? 'Remove item?',
        button1Label: translations['dialogCancelButtonText'] ?? 'Cancel',
        onPressed1: () => Navigator.pop(context, false),
        button2Label: translations['dialogRemoveButtonText'] ?? 'Remove',
        onPressed2: () => Navigator.pop(context, true),
      );

  static showPlatformSpecificDialog({
    required BuildContext context,
    required Function(BuildContext context) child,
    bool barrierDismissible = true,
  }) async {
    return Platform.isIOS
        ? await showCupertinoDialog(
            context: context,
            barrierDismissible: barrierDismissible,
            builder: (context) {
              return child(context);
            })
        : await showDialog(
            context: context,
            barrierDismissible: barrierDismissible,
            builder: (context) {
              return child(context);
            });
  }

  static IconTextButtonElement addButton({
    required BuildContext context,
    required bool showMacStyle,
    required TextEditingController? textController,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
  }) =>
      IconTextButtonElement(
        showMacStyle: showMacStyle,
        icon: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 20.0,
          ),
        ),
        label: translations['addButtonText'] ?? 'add',
        onPressed: () async {
          dynamic value = await showPlatformSpecificDialog(
            context: context,
            child: (BuildContext context) => textController != null
                ? addItemWithNameDialog(
                    context: context,
                    showMacStyle: showMacStyle,
                    textController: textController,
                    translations: translations,
                  )
                : addItemDialog(
                    context: context,
                    translations: translations,
                  ),
          );

          if (value != null) {
            onAccepted(value);
          }
        },
      );

  static IconButtonElement addIconButton({
    required BuildContext context,
    required bool showMacStyle,
    required TextEditingController? textController,
    bool disabled = false,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
    VoidCallback? onExit,
  }) =>
      IconButtonElement(
          showMacStyle: showMacStyle,
          icon: const Icon(
            Icons.add,
            color: Colors.white,
            size: 20.0,
          ),
          onPressed: () async {
            if (!disabled) {
              dynamic value = await SharedWidgets.showPlatformSpecificDialog(
                context: context,
                child: (BuildContext context) => textController != null
                    ? addItemWithNameDialog(
                        context: context,
                        showMacStyle: showMacStyle,
                        textController: textController,
                        translations: translations,
                      )
                    : addItemDialog(
                        context: context,
                        translations: translations,
                      ),
              );

              if (value == null) {
                if (onExit != null) {
                  onExit();
                }
              } else {
                onAccepted(value);
              }
            }
          });

  static IconButtonElement removeIconButton({
    required BuildContext context,
    required bool showMacStyle,
    required TextEditingController? textController,
    bool disabled = false,
    required Map<String, dynamic> translations,
    required VoidCallback onPressed,
  }) =>
      IconButtonElement(
        showMacStyle: showMacStyle,
        icon: const Icon(
          Icons.remove,
          color: Colors.white,
          size: 20.0,
        ),
        onPressed: () {
          if (!disabled) {
            onPressed();
          }
        },
      );

  static IconTextButtonElement removeButton({
    required BuildContext context,
    required Map<String, dynamic> translations,
    required VoidCallback onAccepted,
  }) =>
      IconTextButtonElement(
        showMacStyle: showMacStyle,
        style: ButtonStyle(
          minimumSize:
              WidgetStateProperty.all<Size>(const Size(double.infinity, 20)),
        ),
        icon: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Icon(
            Icons.remove,
            color: Colors.white,
            size: 20.0,
          ),
        ),
        label: translations['removeButtonText'] ?? 'remove',
        onPressed: () async {
          bool valid = await SharedWidgets.showPlatformSpecificDialog(
            context: context,
            child: (BuildContext context) => removeItemDialog(
              context: context,
              translations: translations,
            ),
          );
          if (valid == true) {
            onAccepted();
          }
        },
      );

  static IconTextButtonElement linkButton({
    required String link,
    required Map<String, dynamic> translations,
    required VoidCallback onPressed,
  }) {
    return IconTextButtonElement(
      showMacStyle: showMacStyle,
      style: ButtonStyle(
        minimumSize:
            WidgetStateProperty.all<Size>(const Size(double.infinity, 20)),
      ),
      icon: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Icon(
          Icons.link,
          color: Colors.white,
          size: 20.0,
        ),
      ),
      label: translations['openLinkButtonText'] ?? 'open link',
      onPressed: () async {
        final Uri url = Uri.parse(link);
        if (!await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        )) {
          if (kDebugMode) {
            print('Could not launch url: $url');
          }
        }
      },
    );
  }
}
