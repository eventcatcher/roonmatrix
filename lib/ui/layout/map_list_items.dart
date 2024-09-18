import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:validators/validators.dart';

class MapListItems extends StatefulWidget {
  final String? label;
  final Color? labelColor;
  final ConfigDefinitionItem fieldDefinition;
  final List<dynamic> fieldValues;
  final bool? noVerticalSpace;
  final void Function(String value) onChanged;

  const MapListItems({
    super.key,
    this.label,
    this.labelColor = Colors.black,
    required this.fieldDefinition,
    required this.fieldValues,
    this.noVerticalSpace,
    required this.onChanged,
  });

  @override
  MapListItemsState createState() => MapListItemsState();
}

class MapListItemsState extends State<MapListItems> {
  ConfigDefinitionItem get fieldDefinition => widget.fieldDefinition;
  List<dynamic> get fieldValues => widget.fieldValues;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late EdgeInsetsGeometry margin;
  late MainBloc mainBloc;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    super.initState();
  }

  void returnJson(List<dynamic> fieldValues) {
    String json = jsonEncode(fieldValues).replaceAll('"', "'");
    widget.onChanged(json);
  }

  List<Widget> getWidgets() {
    List<Widget> colWidgets = [];
    double width = MediaQuery.of(context).size.width;

    String deviceType = width < 1024 ? 'mobile' : 'desktop';

    for (int idx = 0; idx < fieldValues.length; idx++) {
      Map<String, dynamic> map = fieldValues[idx];
      List<Widget> rowWidgets = [];
      String link = "";
      for (String key in map.keys) {
        if (key == 'url') {
          link = fieldValues[idx][key].toString();
        }
        String fieldType = fieldDefinition.type.structure
            .firstWhere((ItemTypeStructure el) => el.name == key)
            .type;
        Widget widget = EditableSinglelineText(
          inputType: fieldType.startsWith('int')
              ? TextInputType.number
              : TextInputType.text,
          formatters: fieldType.startsWith('int')
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          noCounter: true,
          label:
              key == ': ' ? '[: ]' : key + mainBloc.getListFieldUnit(fieldType),
          labelColor: Colors.red,
          borderColor: Colors.red.shade300,
          text: fieldValues[idx][key].toString(),
          errorMessageHandler: (String newValue) {
            return mainBloc.getFieldErrorMessage(
                value: newValue, type: fieldType, translations: translations);
          },
          validation: (String text) {
            if (fieldType.startsWith('int')) {
              int? num = int.tryParse(text);
              if (num == null) {
                return false;
              }
              return mainBloc.validateNumber(num: num, type: fieldType);
            }

            if (fieldType.startsWith('url')) {
              return mainBloc.validateUrl(text: text, type: fieldType);
            }

            if (fieldType.startsWith('string')) {
              return mainBloc.validateText(text: text, type: fieldType);
            }

            return false;
          },
          onChanged: (String value) {
            if (mounted) {
              try {
                setState(() => fieldValues[idx][key] =
                    (fieldType.startsWith('int') ? int.parse(value) : value));
                if (key == 'url') {
                  link = value;
                }
                returnJson(fieldValues);
              } catch (e) {
                setState(() {
                  fieldValues[idx][key] = '';
                  returnJson(fieldValues);
                });
              }
            }
          },
        );
        rowWidgets.add(
            deviceType == 'mobile' ? widget : Flexible(flex: 1, child: widget));
      }

      if (deviceType == 'desktop') {
        rowWidgets.add(Container(
          margin: const EdgeInsets.only(
            top: 18.0,
            right: 16.0,
          ),
          height: 38.0,
          child: IconButton(
            onPressed: link != '' &&
                    isURL(link, requireTld: true, requireProtocol: true)
                ? () async {
                    final Uri url = Uri.parse(link);
                    if (!await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    )) {
                      if (kDebugMode) {
                        print('Could not launch url: $url');
                      }
                    }
                  }
                : null,
            icon: const Icon(Icons.link),
          ),
        ));

        rowWidgets.add(
          Container(
            margin: const EdgeInsets.only(
              top: 18.0,
              right: 8.0,
            ),
            height: 38.0,
            child: IconButton(
              onPressed: () {
                setState(() => fieldValues.removeAt(idx));
                returnJson(fieldValues);
              },
              icon: const Icon(Icons.clear),
            ),
          ),
        );
      }
      if (deviceType == 'mobile') {
        colWidgets.addAll(rowWidgets);
      } else {
        colWidgets
            .add(Row(mainAxisSize: MainAxisSize.max, children: rowWidgets));
      }

      if (deviceType == 'mobile') {
        colWidgets.add(const SizedBox(height: 6.0));

        if (link != '' &&
            isURL(link, requireTld: true, requireProtocol: true)) {
          colWidgets.add(Padding(
            padding:
                const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 16.0),
            child: ElevatedButton.icon(
              style: ButtonStyle(
                minimumSize: WidgetStateProperty.all<Size>(
                    const Size(double.infinity, 20)),
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
            ),
          ));
        }

        colWidgets.add(Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 16.0),
          child: ElevatedButton.icon(
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all<Size>(
                  const Size(double.infinity, 20)),
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
              setState(() => fieldValues.removeAt(idx));
              returnJson(fieldValues);
            },
          ),
        ));
        colWidgets.add(const SizedBox(height: 3.0));
      }
    }

    colWidgets.add(const SizedBox(height: 6.0));
    colWidgets.add(Align(
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
            Map<String, dynamic> props = {};
            for (ItemTypeStructure typeStruct
                in fieldDefinition.type.structure.toList()) {
              props.putIfAbsent(typeStruct.name, () => '');
            }
            setState(() => fieldValues.add(props));
            returnJson(fieldValues);
          },
        ),
      ),
    ));
    colWidgets.add(const SizedBox(height: 6.0));

    return colWidgets;
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

          return Container(
            margin: const EdgeInsets.only(
                left: 16.0, right: 16.0, top: 16.0, bottom: 5.0),
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
                        overflow: TextOverflow.ellipsis,
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
                    Column(children: translationsLoaded ? getWidgets() : []),
                    const SizedBox(height: 6.0),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
