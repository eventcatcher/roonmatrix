import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';

class MapListItems extends StatefulWidget {
  final String? aligned;
  final String? label;
  final Color? labelColor;
  final String? placeholder;
  final ConfigDefinitionItem fieldDefinition;
  final List<dynamic> fieldValues;
  final bool? noVerticalSpace;
  final bool? readOnly;
  final bool? readOnlyColoredGrey;
  final bool? optionsWithVerticalSpace;
  final void Function(String value) onChanged;

  const MapListItems({
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
  MapListItemsState createState() => MapListItemsState();
}

class MapListItemsState extends State<MapListItems> {
  ConfigDefinitionItem get fieldDefinition => widget.fieldDefinition;
  List<dynamic> get fieldValues => widget.fieldValues;
  late TextEditingController textController;
  late EdgeInsetsGeometry margin;
  late OptionsBloc optionsBloc;

  @override
  void initState() {
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

    optionsBloc = BlocProvider.of<OptionsBloc>(context);
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
    List<Widget> colWidgets = [];

    for (int idx = 0; idx < fieldValues.length; idx++) {
      Map<String, dynamic> map = fieldValues[idx];
      List<Widget> rowWidgets = [];
      for (String key in map.keys) {
        String fieldType = fieldDefinition.type.structure
            .firstWhere((ItemTypeStructure el) => el.name == key)
            .type;
        Widget widget = Flexible(
          flex: 1,
          child: EditableSinglelineText(
            inputType: fieldType.startsWith('int')
                ? TextInputType.number
                : TextInputType.text,
            noCounter: true,
            label: key == ': '
                ? '[: ]'
                : key + optionsBloc.getListFieldUnit(fieldType),
            labelColor: Colors.red,
            borderColor: Colors.red.shade300,
            text: fieldValues[idx][key].toString(),
            errorMessageHandler: (String newValue) {
              if (fieldType.startsWith('int')) {
                if (newValue == '') {
                  return 'Zahlenfeld darf nicht leer sein';
                }
                return 'Zahlenwert ist ausserhalb des gültigen Bereichs';
              }
              if (fieldType.startsWith('url') &&
                  !optionsBloc.validateUrl(text: newValue, type: fieldType)) {
                return 'Url hat ein ungültiges Format';
              }

              return 'Textfeld darf nicht leer sein';
            },
            validation: (String text) {
              if (fieldType.startsWith('int')) {
                int? num = int.tryParse(text);
                if (num == null) {
                  return false;
                }
                return optionsBloc.validateNumber(num: num, type: fieldType);
              }

              if (fieldType.startsWith('url')) {
                return optionsBloc.validateUrl(text: text, type: fieldType);
              }

              if (fieldType.startsWith('string')) {
                return optionsBloc.validateText(text: text, type: fieldType);
              }

              return false;
            },
            onChanged: (String value) {
              if (mounted) {
                try {
                  setState(() => fieldValues[idx][key] =
                      (fieldType.startsWith('int') ? int.parse(value) : value));
                  returnJson(fieldValues);
                } catch (e) {
                  setState(() {
                    fieldValues[idx][key] = '';
                    returnJson(fieldValues);
                  });
                }
              }
            },
          ),
        );
        rowWidgets.add(widget);
      }
      rowWidgets.add(
        IconButton(
          onPressed: () {
            setState(() => fieldValues.removeAt(idx));
            returnJson(fieldValues);
          },
          icon: const Icon(Icons.clear),
        ),
      );
      colWidgets.add(Row(
        mainAxisSize: MainAxisSize.max,
        children: rowWidgets,
      ));
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
          label: const Text('add'),
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

    return Container(
      margin: margin,
      alignment: Alignment.topLeft,
      child: Container(
        margin:
            EdgeInsets.only(bottom: widget.noVerticalSpace == true ? 0 : 10),
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
              Column(children: colWidgets),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ),
    );
  }
}
