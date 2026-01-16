import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/text_field_element.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================ style config============================

final bool showMacStyle = true; // show app in macos ui style (running on macos)
final bool showIosStyle =
    true; // show app in iOS ui style (running on macos or iOS)
final bool showSelectBoxInMacStyle = true;

// =====================================================================

class SharedWidgets {
  static bool isMobileDevice() {
    return Platform.isIOS || Platform.isAndroid || Platform.isFuchsia;
  }

  static bool isDesktopDevice() {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  static bool isLinux() {
    return Platform.isLinux;
  }

  static bool inIosStyle() {
    return (showIosStyle == true && Platform.isIOS) ||
        (!showMacStyle && showIosStyle == true && Platform.isMacOS);
  }

  static bool inMacosStyle() {
    return showMacStyle == true && Platform.isMacOS;
  }

  static bool selectBoxInMacStyle() {
    return showSelectBoxInMacStyle == true && inMacosStyle();
  }

  static String getZoneIcon({required String zoneName}) {
    if (zoneName.endsWith('-SpotifyConnect')) {
      return 'assets/icon/spotifyconnect.png';
    }
    if (zoneName.endsWith('-Spotify')) {
      return 'assets/icon/spotify.png';
    }
    if (zoneName.endsWith('-Apple Music')) {
      return 'assets/icon/applemusic.png';
    }

    return 'assets/icon/roon.png';
  }

  static String getZoneNameWithoutType({required String zoneName}) {
    return zoneName
        .replaceFirst('-SpotifyConnect', '')
        .replaceFirst('-Spotify', '')
        .replaceFirst('-Apple Music', '');
  }

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
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? CupertinoColors.white
          : CupertinoColors.black;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.white
          : MacosColors.black;
    }
    return Theme.of(context).colorScheme.inverseSurface;
  }

  static final Color hoverButtonBackground = Color.fromARGB(170, 200, 200, 200);

  static Color iconColor({
    required BuildContext context,
  }) {
    return textColor(context: context);
  }

  static Color hintColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return CupertinoColors.systemGrey;
    }
    if (SharedWidgets.inMacosStyle()) {
      return MacosColors.systemGrayColor;
    }
    return Theme.of(context).hintColor;
  }

  static Color windowBackgroundColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.underPageBackgroundColor
          : CupertinoColors.white;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.underPageBackgroundColor
          : MacosColors.white;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color borderColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 60, 60, 60)
          : MacosColors.tickBackgroundColor;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.systemGrayColor
          : MacosColors.tickBackgroundColor;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color elementBackgroundColorLighter({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? Theme.of(context).primaryColorLight
          : CupertinoColors.white;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? Theme.of(context).primaryColorLight
          : Colors.white;
    }
    return Theme.of(context).colorScheme.surface;
  }

  static Color elementBackgroundColor({
    required BuildContext context,
  }) {
    return windowBackgroundColor(context: context);
  }

  static Color selectboxBackgroundColor({
    required BuildContext context,
  }) {
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade800
        : MacosColors.white;
  }

  static Color areaBackgroundColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade100;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade100;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Color.fromARGB(255, 57, 55, 60)
        : Colors.grey.shade100;
  }

  static Color toolbarBackgroundColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.controlColor
          : const Color.fromARGB(255, 195, 219, 239);
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.controlColor
          : const Color.fromARGB(255, 195, 219, 239);
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.black26
        : const Color.fromARGB(255, 195, 219, 239);
  }

  static Color coverRowBackgroundColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade200;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.grey.shade200;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? const Color.fromARGB(255, 57, 55, 60)
        : Colors.grey.shade200;
  }

  static Color resetIconColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 171, 39, 32)
          : CupertinoColors.systemRed;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? const Color.fromARGB(255, 171, 39, 32)
          : MacosColors.appleRed;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? const Color.fromARGB(255, 171, 39, 32)
        : Colors.red.shade700;
  }

  static Color tileBackgroundColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.blue.shade100;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : Colors.blue.shade100; // MacosColors.systemTealColor;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? const Color.fromARGB(255, 57, 55, 60)
        : Colors.blue.shade100;
  }

  static Color buttonBlueColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : CupertinoColors.systemBlue;
    }
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.gridColor
          : MacosColors.systemBlueColor; // MacosColors.systemTealColor;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade700
        : Colors.blue.shade700;
  }

  static Color buttonRowBackgroundColor({
    required BuildContext context,
  }) {
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade600
        : Colors.blue.shade300;
  }

  static Color textFieldBackgroundColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      //return windowBackgroundColor(context: context);
      return SharedWidgets.brightness() == Brightness.dark
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemBackground;
    }
    //alternatingContentBackgroundColor, underPageBackgroundColor
    if (SharedWidgets.inMacosStyle()) {
      return SharedWidgets.brightness() == Brightness.dark
          ? MacosColors.alternatingContentBackgroundColor
          : Color(0xffefefef);
    }
    return windowBackgroundColor(context: context);
  }

  static Color toolbarResizeButtonColor({
    required BuildContext context,
  }) {
    if (SharedWidgets.inIosStyle()) {
      return CupertinoColors.systemGrey;
    }
    if (SharedWidgets.inMacosStyle()) {
      return MacosColors.systemGrayColor;
    }
    return SharedWidgets.brightness() == Brightness.dark
        ? Colors.grey.shade300
        : Colors.white;
  }

  static AlertElement addItemWithNameDialog({
    required BuildContext context,
    required TextEditingController textController,
    required Map<String, dynamic> translations,
  }) =>
      AlertElement(
        title: translations['dialogAddItemTitle'] ?? 'Add a new item',
        content: TextFieldElement(
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
    return SharedWidgets.inIosStyle()
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
    required TextEditingController? textController,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
  }) =>
      IconTextButtonElement(
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
    required TextEditingController? textController,
    bool disabled = false,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
    VoidCallback? onExit,
  }) =>
      IconButtonElement(
          readOnly: disabled,
          size: 40,
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
    required TextEditingController? textController,
    bool disabled = false,
    required Map<String, dynamic> translations,
    required VoidCallback onPressed,
  }) =>
      IconButtonElement(
        readOnly: disabled,
        size: 40,
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
        onMacAsText: true,
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
      onMacAsText: true,
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
            debugPrint('Could not launch url: $url');
          }
        }
      },
    );
  }

  static showSnackBar({
    required BuildContext context,
    required String doneMessage,
    required String failMessage,
    required bool valid,
  }) {
    if (valid == true) {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          snackBarPosition: SnackBarPosition.bottom,
          CustomSnackBar.success(
            message: doneMessage,
          ),
        );
      }
    } else {
      if (context.mounted) {
        showTopSnackBar(
          Overlay.of(context),
          snackBarPosition: SnackBarPosition.bottom,
          CustomSnackBar.error(
            message: failMessage,
          ),
        );
      }
    }
  }

  static void openAboutModal(
          {required BuildContext context,
          required String aboutAppMessage,
          required Map<String, dynamic> translations}) async =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
          ApproveModal(
            context: context,
            icon: Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: 64,
                height: 64,
                child: SvgPicture.asset(
                  'assets/svg/8-8-led-matrix-display-unit.svg',
                  allowDrawingOutsideViewBox: false,
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                ),
              ),
            ),
            title: "RoonMatrix",
            question: aboutAppMessage,
            okText: translations['okButtonText'] ?? 'OK',
            cancelText: '',
            onApproved: () {
              //
            },
          ).show();
        }
      });

  static void openSettingsPage({
    required BuildContext context,
    required Size minDesktopSize,
    required Size standardDesktopSize,
  }) =>
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (context.mounted) {
          await showGeneralDialog(
            context: context,
            //barrierColor: Colors.black12.withOpacity(0.6), // Background color
            barrierDismissible: false,
            barrierLabel: 'Dialog',
            transitionDuration: const Duration(milliseconds: 0),
            pageBuilder: (_, __, ___) {
              return SettingsPage(
                minDesktopSize: minDesktopSize,
                standardDesktopSize: standardDesktopSize,
                close: () {
                  Navigator.pop(context);
                },
              );
            },
          );
        }
      });

  static Future<String> getMacosVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final macosInfo = await deviceInfo.macOsInfo;
    final version = macosInfo.osRelease.replaceFirst('Version', '').trim();

    return version;
  }
}
