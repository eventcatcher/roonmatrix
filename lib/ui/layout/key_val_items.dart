import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart'
    show IconButtonElement;
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
  Color? get labelColor => widget.labelColor;
  bool? get noVerticalSpace => widget.noVerticalSpace;
  void Function(String value) get onChanged => widget.onChanged;

  Map<String, dynamic> translations = {};
  TextEditingController textController = TextEditingController();
  Map<String, dynamic> fieldValues = {};
  List<Widget> widgets = [];
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);

    fieldValues = widget.fieldValues;

    super.initState();
  }

  @override
  void didUpdateWidget(KeyValItems oldWidget) {
    super.didUpdateWidget(oldWidget);

    fieldValues = widget.fieldValues;
    widgets = getFields();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  void returnJson(fieldValues) {
    String json = jsonEncode(fieldValues).replaceDoubleQuotesWithSingleQuotes();
    onChanged(json);
  }

  List<Widget> getFields() {
    List<Widget> widgets = [];

    for (String key in fieldValues.keys) {
      Widget widget = Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: EditableSinglelineText(
              translations: translations,
              key: ValueKey('$label-$key'),
              inputType: TextInputType.text,
              noCounter: true,
              label: key == ': ' ? '[: ]' : key,
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
            child: IconButtonElement(
                label: translations['removeButtonText'] ?? 'remove',
                noBackground: false,
                withCircle: false,
                size: 30,
                icon: Icon(Icons.remove, color: Colors.white, size: 12),
                onPressed: () async {
                  bool valid = await SharedWidgets.showPlatformSpecificDialog(
                    context: context,
                    child: (BuildContext context) =>
                        SharedWidgets.removeItemDialog(
                      context: context,
                      translations: translations,
                    ),
                  );
                  if (valid == true) {
                    setState(() => fieldValues.remove(key));
                    returnJson(fieldValues);
                  }
                }),
          ),
        ],
      );
      widgets.add(widget);
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: translationsBloc,
      builder: (context, TranslationsState translationsState) {
        if (translationsState is TranslationsStateLoaded) {
          translations = translationsState.translations;
          translationsLoaded = translationsState.translationsLoaded;
        }

        if (!translationsLoaded) {
          return SizedBox();
        }
        widgets = getFields();

        return Container(
          margin: const EdgeInsets.only(
              left: 12.0, right: 12.0, top: 16.0, bottom: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...SharedWidgets.labelWidget(
                label: label,
                labelColor: SharedWidgets.brightness() == Brightness.dark
                    ? SharedWidgets.textColor(context: context)
                    : labelColor ?? SharedWidgets.textColor(context: context),
              ),
              Container(
                margin:
                    EdgeInsets.only(bottom: noVerticalSpace == true ? 0 : 10),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: SharedWidgets.borderRadius(),
                  ),
                  color: SharedWidgets.areaBackgroundColor(context: context),
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
      },
    );
  }
}
