import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  static AlertDialog addItemWithNameDialog({
    required BuildContext context,
    required TextEditingController textController,
    required Map<String, dynamic> translations,
  }) =>
      AlertDialog(
        title: Text(translations['dialogAddItemTitle'] ?? 'Add a new item'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
              hintText: translations['dialogAddItemHintText'] ??
                  "Enter here the name of the new item"),
        ),
        actions: [
          TextButton(
            child: Text(translations['dialogCancelButtonText'] ?? 'Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(translations['dialogAddItemButtonText'] ?? 'Add'),
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Navigator.pop(context, textController.text);
              }
            },
          ),
        ],
      );

  static AlertDialog addItemDialog({
    required BuildContext context,
    required Map<String, dynamic> translations,
  }) =>
      AlertDialog(
        title: Text(translations['dialogAddItemTitle'] ?? 'Add a new item?'),
        actions: [
          TextButton(
            child: Text(translations['dialogCancelButtonText'] ?? 'Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(translations['dialogAddItemButtonText'] ?? 'Add'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

  static AlertDialog removeItemDialog({
    required BuildContext context,
    required Map<String, dynamic> translations,
  }) =>
      AlertDialog(
        title: Text(translations['dialogRemoveItemTitle'] ?? 'Remove item?'),
        actions: [
          TextButton(
            child: Text(translations['dialogCancelButtonText'] ?? 'Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text(translations['dialogRemoveButtonText'] ?? 'Remove'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      );

  static ElevatedButton addButton({
    required BuildContext context,
    required TextEditingController? textController,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
  }) =>
      ElevatedButton.icon(
        icon: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 20.0,
          ),
        ),
        label: Text(translations['addButtonText'] ?? 'add'),
        onPressed: () async {
          dynamic value = await showDialog(
            context: context,
            builder: (context) {
              return textController != null
                  ? addItemWithNameDialog(
                      context: context,
                      textController: textController,
                      translations: translations,
                    )
                  : addItemDialog(
                      context: context,
                      translations: translations,
                    );
            },
          );
          if (value != null) {
            onAccepted(value);
          }
        },
      );

  static IconButton addIconButton({
    required BuildContext context,
    required TextEditingController? textController,
    bool disabled = false,
    required Map<String, dynamic> translations,
    required void Function(dynamic value) onAccepted,
  }) =>
      IconButton(
        icon: const Icon(
          Icons.add,
          color: Colors.white,
          size: 20.0,
        ),
        onPressed: disabled == true
            ? null
            : () async {
                dynamic value = await showDialog(
                  context: context,
                  builder: (context) {
                    return textController != null
                        ? addItemWithNameDialog(
                            context: context,
                            textController: textController,
                            translations: translations,
                          )
                        : addItemDialog(
                            context: context,
                            translations: translations,
                          );
                  },
                );
                if (value != null) {
                  onAccepted(value);
                }
              },
      );

  static ElevatedButton removeButton({
    required BuildContext context,
    required Map<String, dynamic> translations,
    required VoidCallback onAccepted,
  }) =>
      ElevatedButton.icon(
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
        label: Text(translations['removeButtonText'] ?? 'remove'),
        onPressed: () async {
          bool valid = await showDialog(
            context: context,
            builder: (context) {
              return removeItemDialog(
                context: context,
                translations: translations,
              );
            },
          );
          if (valid == true) {
            onAccepted();
          }
        },
      );

  static ElevatedButton linkButton({
    required String link,
    required Map<String, dynamic> translations,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
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
      label: Text(translations['openLinkButtonText'] ?? 'open link'),
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
