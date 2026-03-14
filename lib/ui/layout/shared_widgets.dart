import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/alert_element.dart';
import 'package:roonmatrix/ui/layout/approve_modal.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/text_field_element.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedWidgets {
  static List<Widget> labelWidget({
    required String? label,
    Color? labelColor,
  }) =>
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
  }) async =>
      Globals.inIosStyle()
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
    required IconData icon,
    bool disabled = false,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
    VoidCallback? onExit,
  }) =>
      IconButtonElement(
          readOnly: disabled,
          backgroundColor: Colors.transparent,
          backgroundReadOnlyColor: Colors.transparent,
          backgroundHoverColor: Colors.blue.shade800.withAlpha(30),
          size: 40,
          icon: Icon(
            icon,
            color: disabled
                ? Globals.inMacosStyle() || Globals.inIosStyle()
                    ? CupertinoColors.inactiveGray.color
                    : Colors.grey
                : Globals.brightness() == Brightness.dark
                    ? Colors.blue.shade600
                    : Colors.blue.shade800,
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

  static IconButtonElement restyledIconButton({
    required BuildContext context,
    required IconData icon,
    bool disabled = false,
    required VoidCallback onPressed,
  }) =>
      IconButtonElement(
        readOnly: disabled,
        backgroundColor: Colors.transparent,
        backgroundReadOnlyColor: Colors.transparent,
        backgroundHoverColor: Colors.blue.shade800.withAlpha(30),
        size: 40,
        icon: Icon(
          icon,
          color: disabled
              ? Globals.inMacosStyle() || Globals.inIosStyle()
                  ? CupertinoColors.inactiveGray.color
                  : Colors.grey
              : Globals.brightness() == Brightness.dark
                  ? Colors.blue.shade600
                  : Colors.blue.shade800,
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

  static void showSnackBar({
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

  static void openAboutModal({
    required BuildContext context,
    required String aboutAppMessage,
    required Map<String, dynamic> translations,
  }) async =>
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
                  Globals.placeholderSvgAssetPath(),
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
              );
            },
          );
        }
      });

  static TableRow getTableRowFormatted({
    required String label,
    required String text,
    required double fontSize,
    required Color color,
    int? maxLines,
  }) =>
      TableRow(children: [
        TableCell(
          child: Container(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        TableCell(
          child: Text(
            text,
            maxLines: maxLines ?? 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              color: color,
            ),
          ),
        ),
      ]);

  static double measureTextSize({
    required BuildContext context,
    required String text,
    required TextStyle style,
  }) {
    if (text.isEmpty) return 0;

    final TextScaler textScaler = MediaQuery.of(context).textScaler;

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    return tp.width;
  }

  static void showIosPickerDialog({
    required BuildContext context,
    required Map<String, dynamic> translations,
    required Map<String, dynamic> options,
    required String? selected,
    required bool showValue,
    required bool isObject,
    required VoidCallback onApproved,
    required Function(int index) onSelectedItemChanged,
  }) {
    final double height = 216.0;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        final BuildContext modalContext = context;
        return Container(
          height: height,
          padding: const EdgeInsets.only(top: 6.0),
          // The Bottom margin is provided to align the popup above the system navigation bar.
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          // Provide a background color for the popup.
          color: CupertinoColors.systemBackground.resolveFrom(context),
          // Use a SafeArea widget to avoid system overlaps.
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CupertinoButton(
                      child: Text(
                          translations['dialogCancelButtonText'] ?? 'Cancel'),
                      onPressed: () {
                        Navigator.pop(modalContext);
                      },
                    ),
                    Expanded(
                      child: SizedBox(),
                    ),
                    CupertinoButton(
                      child: Text(translations['okButtonText'] ?? 'OK'),
                      onPressed: () {
                        onApproved();
                        Navigator.pop(modalContext);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    magnification: 1.22,
                    squeeze: 1.2,
                    useMagnifier: true,
                    itemExtent: 48,
                    scrollController: FixedExtentScrollController(
                      initialItem: selected != null
                          ? isObject
                              ? options.values.toList().indexOf(selected)
                              : options.keys.toList().indexOf(selected)
                          : 0,
                    ),
                    onSelectedItemChanged: (int index) =>
                        onSelectedItemChanged(index),
                    children:
                        List<Widget>.generate(options.length, (int index) {
                      return Center(
                        child: Text(
                          showValue
                              ? isObject
                                  ? options.values.toList()[index]['name']
                                  : options.values.toList()[index]
                              : options.keys.toList()[index],
                          style: TextStyle(fontSize: 13.0),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
