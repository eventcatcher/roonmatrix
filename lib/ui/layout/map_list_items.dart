import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/icon_button_element.dart'
    show IconButtonElement;
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
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
  String? get label => widget.label;
  ConfigDefinitionItem get fieldDefinition => widget.fieldDefinition;

  Map<String, dynamic> translations = {};
  bool translationsLoaded = false;

  late List<dynamic> fieldValues;
  late TranslationsBloc translationsBloc;
  late EdgeInsetsGeometry margin;
  late MainBloc mainBloc;

  @override
  void initState() {
    fieldValues = widget.fieldValues;
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
          key: ValueKey('$label-${fieldValues.length}-$idx-$key'),
          translations: translations,
          inputType: fieldType.startsWith('int')
              ? TextInputType.number
              : TextInputType.text,
          formatters: fieldType.startsWith('int')
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          noCounter: true,
          label: (translations['config']?[key] ?? key) +
              mainBloc.getListFieldUnit(fieldType),
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
        rowWidgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: Platform.isLinux ? 28.0 : 31.0,
              right: 16.0,
            ),
            child: IconButtonElement(
              label: translations['openLinkButtonText'] ?? 'open link',
              noBackground: false,
              withCircle: false,
              readOnly: link.isEmpty ||
                  !isURL(link, requireTld: true, requireProtocol: true),
              size: 30,
              icon: Icon(Icons.link, color: Colors.white, size: 12),
              onPressed: link.isNotEmpty &&
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
                  : () {},
            ),
          ),
        );

        rowWidgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: Platform.isLinux ? 28.0 : 31.0,
              right: 16.0,
            ),
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
                    setState(() => fieldValues.removeAt(idx));
                    returnJson(fieldValues);
                  }
                }),
          ),
        );
      }
      if (deviceType == 'mobile') {
        colWidgets.addAll(rowWidgets);
      } else {
        colWidgets.add(Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rowWidgets,
        ));
      }

      if (deviceType == 'mobile') {
        colWidgets.add(const SizedBox(height: 6.0));

        if (link != '' &&
            isURL(link, requireTld: true, requireProtocol: true)) {
          List<Widget> buttonRow = [];

          buttonRow.add(Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: SharedWidgets.linkButton(
                link: link,
                translations: translations,
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
            ),
          ));

          buttonRow.add(Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
              child: SharedWidgets.removeButton(
                context: context,
                translations: translations,
                onAccepted: () {
                  setState(() => fieldValues.removeAt(idx));
                  returnJson(fieldValues);
                },
              ),
            ),
          ));

          colWidgets
              .add(Row(mainAxisSize: MainAxisSize.max, children: buttonRow));
        } else {
          colWidgets.add(Padding(
            padding:
                const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 16.0),
            child: SharedWidgets.removeButton(
              context: context,
              translations: translations,
              onAccepted: () {
                setState(() => fieldValues.removeAt(idx));
                returnJson(fieldValues);
              },
            ),
          ));
        }

        colWidgets.add(const SizedBox(height: 3.0));
      }
    }

    colWidgets.add(const SizedBox(height: 6.0));
    colWidgets.add(Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: SharedWidgets.addButton(
            context: context,
            textController: null,
            translations: translations,
            onAccepted: (dynamic value) {
              if (value is bool && value == true) {
                Map<String, dynamic> props = {};
                for (ItemTypeStructure typeStruct
                    in fieldDefinition.type.structure.toList()) {
                  props.putIfAbsent(typeStruct.name, () => '');
                }
                setState(() => fieldValues.add(props));
                returnJson(fieldValues);
              }
            }),
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
                left: 12.0, right: 12.0, top: 16.0, bottom: 5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...SharedWidgets.labelWidget(
                  label: widget.label,
                  labelColor: SharedWidgets.brightness() == Brightness.dark
                      ? SharedWidgets.textColor(context: context)
                      : widget.labelColor ??
                          SharedWidgets.textColor(context: context),
                ),
                Container(
                  margin: EdgeInsets.only(
                      bottom: widget.noVerticalSpace == true ? 0 : 10),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                          Radius.circular(SharedWidgets.inIosStyle() ? 8 : 5)),
                    ),
                    color: SharedWidgets.areaBackgroundColor(context: context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...(translationsLoaded ? getWidgets() : []),
                        const SizedBox(height: 6.0),
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
