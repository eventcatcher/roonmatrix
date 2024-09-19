import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class KeyValItems extends StatefulWidget {
  final String? label;
  final Color? labelColor;
  final Map<String, dynamic> fieldValues;
  final bool? noVerticalSpace;
  final void Function(String value) onChanged;

  const KeyValItems({
    super.key,
    this.label,
    this.labelColor = Colors.black,
    required this.fieldValues,
    this.noVerticalSpace,
    required this.onChanged,
  });

  @override
  KeyValItemsState createState() => KeyValItemsState();
}

class KeyValItemsState extends State<KeyValItems> {
  String? get label => widget.label;
  Map<String, dynamic> get fieldValues => widget.fieldValues;

  Map<String, dynamic> translations = {};
  TextEditingController textController = TextEditingController();
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
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
        key: UniqueKey(),
        inputType: TextInputType.text,
        noCounter: true,
        label: key == ': ' ? '[: ]' : key,
        labelColor: Colors.red,
        borderColor: Colors.red.shade300,
        suffixIcon: IconButton(
          onPressed: () async {
            bool valid = await showDialog(
              context: context,
              builder: (context) {
                return SharedWidgets.removeItemDialog(
                  context: context,
                  translations: translations,
                );
              },
            );
            if (valid == true) {
              setState(() => fieldValues.remove(key));
              returnJson(fieldValues);
            }
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
            margin: const EdgeInsets.only(
                left: 12.0, right: 12.0, top: 16.0, bottom: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...SharedWidgets.labelWidget(
                    label: widget.label, labelColor: widget.labelColor),
                Container(
                  margin: EdgeInsets.only(
                      bottom: widget.noVerticalSpace == true ? 0 : 10),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...widgets,
                        const SizedBox(height: 6.0),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: translationsLoaded
                                ? SharedWidgets.addButton(
                                    context: context,
                                    textController: textController,
                                    translations: translations,
                                    onAccepted: (dynamic newKey) {
                                      if (newKey is String && newKey != '') {
                                        setState(() {
                                          fieldValues.putIfAbsent(
                                              newKey, () => '');
                                          returnJson(fieldValues);
                                        });
                                      }
                                    })
                                : const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }
}
