import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/headline.dart';
import 'package:roonmatrix/ui/layout/key_val_items.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/layout/map_list_items.dart';
import 'package:roonmatrix/ui/layout/switch_button.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';

class ConfigPage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const ConfigPage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<ConfigPage> createState() => ConfigPageState();
}

class ConfigPageState extends State<ConfigPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  List<Widget> formFields = [];
  Map fieldValues = {};
  bool saveIdle = false;
  bool validData = false;

  late OptionsBloc optionsBloc;

  @override
  void initState() {
    optionsBloc = BlocProvider.of<OptionsBloc>(context);
    optionsBloc.getConfig(ip: ip);

    super.initState();
  }

  List<Widget> getFormFields({required ConfigDefinition defs}) {
    List<Widget> widgets = [];

    for (ConfigDefinitionArea area in defs.area) {
      List<Widget> fields = [];

      for (ConfigDefinitionItem fieldDefinition in area.items) {
        String? fieldType =
            optionsBloc.getFieldType(fieldDefinition: fieldDefinition);
        if (fieldType != null && fieldDefinition.editable == true) {
          if (kDebugMode) {
            print(
                'area: ${area.name}, field: ${fieldDefinition.name}, value: ${fieldValues[area.name][fieldDefinition.name]}, fieldType: $fieldType');
          }

          Widget? widgetField;
          if (fieldType == 'text') {
            widgetField = Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: EditableSinglelineText(
                inputType: TextInputType.text,
                noCounter: true,
                label: fieldDefinition.label +
                    (fieldDefinition.unit != ''
                        ? ' (${fieldDefinition.unit})'
                        : ''),
                labelColor: Colors.red,
                borderColor: Colors.red.shade300,
                text: fieldValues[area.name][fieldDefinition.name],
                filter: (String text) {
                  if (text == '') {
                    setState(() {
                      fieldValues[area.name][fieldDefinition.name] = '';
                    });
                  }
                  return text;
                },
                errorMessageHandler: (String newValue) {
                  if (newValue == '') {
                    return 'Textfeld darf nicht leer sein';
                  }

                  if (fieldDefinition.type.type.startsWith('url') &&
                      !optionsBloc.validateUrl(
                          text: newValue, type: fieldDefinition.type.type)) {
                    return 'Url hat ein ungültiges Format';
                  }

                  return 'Textfeld ist kein gültiges Json';
                },
                validation: (String text) => optionsBloc.validateText(
                    text: text,
                    fieldDefinition: fieldDefinition,
                    type: fieldDefinition.type.type),
                onChanged: (value) {
                  if (mounted) {
                    setState(() =>
                        fieldValues[area.name][fieldDefinition.name] = value);
                  }
                },
              ),
            );
          }
          if (fieldType == 'int') {
            widgetField = Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: EditableSinglelineText(
                inputType: TextInputType.number,
                noCounter: true,
                label: fieldDefinition.label +
                    (fieldDefinition.unit != ''
                        ? ' (${fieldDefinition.unit})'
                        : ''),
                labelColor: Colors.red,
                borderColor: Colors.red.shade300,
                text: fieldValues[area.name][fieldDefinition.name].toString(),
                filter: (String text) {
                  if (text == '') {
                    setState(() {
                      fieldValues[area.name][fieldDefinition.name] = '';
                    });
                  }
                  return text;
                },
                errorMessageHandler: (String newValue) {
                  if (newValue == '') {
                    return 'Zahlenfeld darf nicht leer sein';
                  }
                  return 'Zahlenwert ist ausserhalb des gültigen Bereichs';
                },
                validation: (String text) {
                  int? num = int.tryParse(text);
                  if (num == null) {
                    return false;
                  }
                  return optionsBloc.validateNumber(
                      num: num, type: fieldDefinition.type.type);
                },
                onChanged: (value) {
                  if (mounted) {
                    try {
                      setState(() => fieldValues[area.name]
                          [fieldDefinition.name] = int.parse(value));
                    } catch (e) {
                      setState(() {
                        fieldValues[area.name][fieldDefinition.name] = '';
                      });
                    }
                  }
                },
              ),
            );
          }
          if (fieldType == 'bool') {
            widgetField = Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: SwitchButton(
                label: fieldDefinition.label +
                    (fieldDefinition.unit != ''
                        ? ' (${fieldDefinition.unit})'
                        : ''),
                labelColor: Colors.red,
                enabled: fieldValues[area.name][fieldDefinition.name],
                onChanged: (value) {
                  if (mounted) {
                    setState(() =>
                        fieldValues[area.name][fieldDefinition.name] = value);
                  }
                },
              ),
            );
          }
          if (fieldType == 'keyValItems') {
            Map<String, dynamic> json = jsonDecode(
                (fieldValues[area.name][fieldDefinition.name] as String)
                    .replaceAll("'", '"'));
            widgetField = KeyValItems(
              label: fieldDefinition.label,
              labelColor: Colors.red,
              fieldDefinition: fieldDefinition,
              fieldValues: json,
              onChanged: (String value) {
                setState(
                    () => fieldValues[area.name][fieldDefinition.name] = value);
              },
            );
          }
          if (fieldType == 'list') {
            List<dynamic> json = jsonDecode(
                (fieldValues[area.name][fieldDefinition.name] as String)
                    .replaceAll("'", '"'));
            widgetField = MapListItems(
              label: fieldDefinition.label,
              labelColor: Colors.red,
              fieldDefinition: fieldDefinition,
              fieldValues: json,
              onChanged: (String value) {
                setState(
                    () => fieldValues[area.name][fieldDefinition.name] = value);
              },
            );
          }
          if (widgetField != null) {
            fields.add(widgetField);
          }
        }
      }
      Widget widgetArea = Card(
        child: Column(
          children: [Headline(text: area.name), ...fields],
        ),
      );
      widgets.add(widgetArea);
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: optionsBloc,
        builder: (context, OptionsState optionsState) {
          if (optionsState is! OptionsStateLoaded) {
            return Container();
          }

          String search = optionsState.searchFilter['config']!;
          String jsonStr = optionsBloc.getPrettyJSONString(optionsState.config);
          if (search.isNotEmpty) {
            jsonStr = jsonStr.replaceAll(
                RegExp(search, caseSensitive: false), '<b>$search</b>');
          }

          if (optionsState.definitions == null) {
            return const LoadingIndicator();
          }
          ConfigDefinition defs = optionsState.definitions!;
          fieldValues = optionsState.fieldValues;
          validData = optionsBloc.validateAll(
              definitions: defs, fieldValues: fieldValues);
          formFields = getFormFields(defs: defs);

          return DefaultTabController(
            initialIndex: 0,
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text('$name : Config'),
                actions: const [],
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(48.0),
                  child: Material(
                    color: Colors.lightBlue,
                    child: TabBar(
                      tabs: <Widget>[
                        Tab(
                          text: 'Edit',
                        ),
                        Tab(
                          text: 'Read',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              body: TabBarView(
                children: <Widget>[
                  Column(
                    children: [
                      Expanded(
                        child: optionsState.idle == true
                            ? const LoadingIndicator()
                            : ListView(
                                shrinkWrap: true,
                                children: [...formFields],
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: Platform.isMacOS ||
                                    Platform.isWindows ||
                                    Platform.isLinux
                                ? 16.0
                                : 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              icon: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Icon(
                                  Icons.save,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                              label: const Text('save'),
                              onPressed: !validData ||
                                      saveIdle == true ||
                                      optionsState.idle == true
                                  ? null
                                  : () async {
                                      setState(() {
                                        saveIdle = true;
                                      });
                                      bool valid = await optionsBloc.saveConfig(
                                          name: name,
                                          ip: ip,
                                          data: fieldValues);
                                      setState(() {
                                        saveIdle = false;
                                      });
                                      if (valid == true) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                "save config successfully done"),
                                            backgroundColor: Colors.green,
                                          ));
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content:
                                                Text("save config failed!"),
                                            backgroundColor: Colors.red,
                                          ));
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                      if (Platform.isIOS) const SizedBox(height: 14.0),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SearchField(
                          type: 'config',
                          controller:
                              optionsBloc.getSearchController(type: 'config'),
                        ),
                      ),
                      Expanded(
                        child: optionsState.idle == true
                            ? const LoadingIndicator()
                            : ListView(
                                shrinkWrap: true,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: StyledText(
                                      text: jsonStr,
                                      tags: {
                                        'b': StyledTextTag(
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: Platform.isMacOS ||
                                    Platform.isWindows ||
                                    Platform.isLinux
                                ? 16.0
                                : 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              icon: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Icon(
                                  Icons.download,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                              ),
                              label: const Text('export'),
                              onPressed:
                                  saveIdle == true || optionsState.idle == true
                                      ? null
                                      : () async {
                                          setState(() {
                                            saveIdle = true;
                                          });
                                          bool? valid =
                                              await optionsBloc.exportData(
                                                  name: name,
                                                  ip: ip,
                                                  type: 'config');
                                          setState(() {
                                            saveIdle = false;
                                          });
                                          if (valid == null) {
                                            return;
                                          }
                                          if (valid == true) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                content: Text(
                                                    "export successfully done"),
                                                backgroundColor: Colors.green,
                                              ));
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                content: Text("export failed!"),
                                                backgroundColor: Colors.red,
                                              ));
                                            }
                                          }
                                        },
                            ),
                          ],
                        ),
                      ),
                      if (Platform.isIOS) const SizedBox(height: 14.0),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }
}
