import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class ListItems extends StatefulWidget {
  final String? label;
  final Color? labelColor;
  final List<dynamic> fieldValues;
  final bool predefinedLength;
  final bool? noVerticalSpace;
  final void Function(String value) onChanged;

  const ListItems({
    super.key,
    this.label,
    this.labelColor = Colors.black,
    required this.fieldValues,
    required this.predefinedLength,
    this.noVerticalSpace,
    required this.onChanged,
  });

  @override
  ListItemsState createState() => ListItemsState();
}

class ListItemsState extends State<ListItems> {
  String? get label => widget.label;
  Color? get labelColor => widget.labelColor;
  bool get predefinedLength => widget.predefinedLength;
  bool? get noVerticalSpace => widget.noVerticalSpace;
  void Function(String value) get onChanged => widget.onChanged;

  Map<String, dynamic> translations = {};
  List<dynamic> fieldValues = [];
  List<Widget> widgets = [];
  TextEditingController textController = TextEditingController();
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late EdgeInsetsGeometry margin;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);

    fieldValues = widget.fieldValues;

    super.initState();
  }

  @override
  void didUpdateWidget(ListItems oldWidget) {
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
    String json = jsonEncode(fieldValues).replaceQuotesWithSpecialTags();

    onChanged(json);
  }

  List<Widget> getFields() {
    List<Widget> widgets = [];

    for (int idx = 0; idx < fieldValues.length; idx++) {
      Widget widget = EditableSinglelineText(
        key: ValueKey('$label-${fieldValues.length}-$idx'),
        translations: translations,
        inputType: TextInputType.text,
        noCounter: true,
        suffixIcon: predefinedLength
            ? null
            : IconButton(
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
                    setState(() => fieldValues.removeAt(idx));
                    returnJson(fieldValues);
                  }
                },
                icon: Globals.inIosStyle() || Globals.inMacosStyle()
                    ? Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: ColorDefs.resetIconColor(context: context),
                        size: 18.0,
                      )
                    : const Icon(Icons.clear),
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
                  labelColor: Globals.brightness() == Brightness.dark
                      ? ColorDefs.textColor(context: context)
                      : labelColor ?? ColorDefs.textColor(context: context),
                ),
                Container(
                  margin:
                      EdgeInsets.only(bottom: noVerticalSpace == true ? 0 : 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: Globals.borderRadius(),
                    ),
                    color: ColorDefs.areaBackgroundColor(context: context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...widgets,
                        if (!predefinedLength) ...[
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
                                      onAccepted: (dynamic value) {
                                        setState(() {
                                          fieldValues.add(textController.text);
                                          textController.text = '';
                                          returnJson(fieldValues);
                                        });
                                      })
                                  : const SizedBox(),
                            ),
                          ),
                        ],
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
