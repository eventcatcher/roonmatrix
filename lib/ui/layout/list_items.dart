import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';

class ListItems extends StatefulWidget {
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final ConfigDefinitionItem? fieldDefinition;
  final List<dynamic> fieldValues;
  final bool predefinedLength;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final bool? readOnlyColoredGrey;
  final bool? optionsWithVerticalSpace;
  final void Function(String value) onChanged;

  const ListItems({
    super.key,
    this.aligned,
    this.label,
    this.labelColor = Colors.black,
    this.placeholder,
    required this.fieldDefinition,
    required this.fieldValues,
    required this.predefinedLength,
    this.noVerticalSpace,
    this.readOnly,
    this.readOnlyColoredGrey = false,
    this.optionsWithVerticalSpace,
    required this.onChanged,
  });

  @override
  ListItemsState createState() => ListItemsState();
}

class ListItemsState extends State<ListItems> {
  List<dynamic> get fieldValues => widget.fieldValues;
  String? get label => widget.label;
  bool get predefinedLength => widget.predefinedLength;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;

  late TextEditingController textController;
  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    getTranslations();

    switch (widget.aligned) {
      case "left":
        margin = const EdgeInsets.only(
            left: 16.0, right: 8.0, top: 16.0, bottom: 5.0);
        break;
      case "right":
        margin = const EdgeInsets.only(
            left: 8.0, right: 16.0, top: 16.0, bottom: 5.0);
        break;
      case "leftSmallBottom":
        margin = const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 5.0);
        break;
      case "rightSmallBottom":
        margin = const EdgeInsets.only(left: 8.0, right: 16.0, bottom: 5.0);
        break;
      case "horizontal":
        margin = const EdgeInsets.only(left: 16.0, right: 16.0);
        break;
      case "horizontalSmallBottom":
        margin = const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 5.0);
        break;
      case "inline":
        margin = const EdgeInsets.all(0);
        break;
      default:
        margin = const EdgeInsets.only(
            left: 16.0, right: 16.0, top: 16.0, bottom: 5.0);
    }
    textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> getTranslations() async {
    String translationsJsonString =
        await rootBundle.loadString('assets/json/translations.json');
    translations = jsonDecode(translationsJsonString);
    setState(() {
      translationsLoaded = true;
    });
  }

  returnJson(fieldValues) {
    String json = jsonEncode(fieldValues).replaceAll('"', "'");
    widget.onChanged(json);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    for (int idx = 0; idx < fieldValues.length; idx++) {
      Widget widget = EditableSinglelineText(
        inputType: TextInputType.text,
        noCounter: true,
        labelColor: Colors.red,
        borderColor: Colors.red.shade300,
        suffixIcon: predefinedLength
            ? null
            : IconButton(
                onPressed: () {
                  setState(() => fieldValues.removeAt(idx));
                  returnJson(fieldValues);
                },
                icon: const Icon(Icons.clear),
              ),
        text: fieldValues[idx].toString(),
        onChanged: (value) {
          if (mounted) {
            try {
              setState(() => fieldValues[idx] = value);
              returnJson(fieldValues);
            } catch (e) {
              setState(() {
                fieldValues[idx] = '';
                returnJson(fieldValues);
              });
            }
          }
        },
      );
      widgets.add(widget);
    }

    return translationsLoaded
        ? Container(
            margin: margin,
            alignment: Alignment.topLeft,
            child: Container(
              margin: EdgeInsets.only(
                  bottom: widget.noVerticalSpace == true ? 0 : 10),
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.label != null) ...[
                      Text(
                        widget.label!,
                        overflow: TextOverflow
                            .ellipsis, // fade is maybe the better alternative, because you see more of the text
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: widget.labelColor,
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(
                        height: 4.0,
                      ),
                    ],
                    Column(children: widgets),
                    if (!predefinedLength) ...[
                      const SizedBox(height: 6.0),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: ElevatedButton.icon(
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
                              String? newKey = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                        translations['dialogAddItemTitle'] ??
                                            'Add a new item'),
                                    content: TextField(
                                      controller: textController,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                          hintText: translations[
                                                  'dialogAddItemValueHintText'] ??
                                              'Enter here the value of the new item'),
                                    ),
                                    actions: [
                                      TextButton(
                                        child: Text(translations[
                                                'dialogAddItemCancelButtonText'] ??
                                            'Cancel'),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(translations[
                                                'dialogAddItemAddButtonText'] ??
                                            'Add'),
                                        onPressed: () {
                                          if (textController.text.isNotEmpty) {
                                            Navigator.pop(
                                                context, textController.text);
                                          }
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (newKey != null) {
                                setState(() {
                                  fieldValues.add(textController.text);
                                  textController.text = '';
                                  returnJson(fieldValues);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12.0),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox();
  }
}
