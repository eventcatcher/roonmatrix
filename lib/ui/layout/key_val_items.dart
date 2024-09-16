import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class KeyValItems extends StatefulWidget {
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final ConfigDefinitionItem? fieldDefinition;
  final Map<String, dynamic> fieldValues;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final bool? readOnlyColoredGrey;
  final bool? optionsWithVerticalSpace;
  final void Function(String value) onChanged;

  const KeyValItems({
    super.key,
    this.aligned,
    this.label,
    this.labelColor = Colors.black,
    this.placeholder,
    required this.fieldDefinition,
    required this.fieldValues,
    this.noVerticalSpace,
    this.readOnly,
    this.readOnlyColoredGrey = false,
    this.optionsWithVerticalSpace,
    required this.onChanged,
  });

  @override
  KeyValItemsState createState() => KeyValItemsState();
}

class KeyValItemsState extends State<KeyValItems> {
  Map<String, dynamic> get fieldValues => widget.fieldValues;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late TextEditingController textController;
  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);

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

  returnJson(fieldValues) {
    String json = jsonEncode(fieldValues).replaceAll('"', "'");
    widget.onChanged(json);
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    for (String key in fieldValues.keys) {
      Widget widget = EditableSinglelineText(
        inputType: TextInputType.text,
        noCounter: true,
        label: key == ': ' ? '[: ]' : key,
        labelColor: Colors.red,
        borderColor: Colors.red.shade300,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => fieldValues.remove(key));
            returnJson(fieldValues);
          },
          icon: const Icon(Icons.clear),
        ),
        text: fieldValues[key].toString(),
        onChanged: (value) {
          if (mounted) {
            try {
              setState(() => fieldValues[key] = value);
              returnJson(fieldValues);
            } catch (e) {
              setState(() {
                fieldValues[key] = '';
                returnJson(fieldValues);
              });
            }
          }
        },
      );
      widgets.add(widget);
    }

    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
          }

          return Container(
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
                    const SizedBox(height: 6.0),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: translationsLoaded
                            ? ElevatedButton.icon(
                                icon: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 20.0,
                                  ),
                                ),
                                label: Text(
                                    translations['addButtonText'] ?? 'add'),
                                onPressed: () async {
                                  String? newKey = await showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(translations[
                                                'dialogAddItemTitle'] ??
                                            'Add a new item'),
                                        content: TextField(
                                          controller: textController,
                                          autofocus: true,
                                          decoration: InputDecoration(
                                              hintText: translations[
                                                      'dialogAddItemHintText'] ??
                                                  "Enter here the name of the new item"),
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
                                              if (textController
                                                  .text.isNotEmpty) {
                                                Navigator.pop(context,
                                                    textController.text);
                                              }
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  if (newKey != null) {
                                    setState(() {
                                      fieldValues.putIfAbsent(newKey, () => '');
                                      returnJson(fieldValues);
                                    });
                                  }
                                },
                              )
                            : const SizedBox(),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
