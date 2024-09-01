import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/headline.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/layout/switch_button.dart';
import 'package:roonmatrix/ui/options/options_bloc.dart';
import 'package:roonmatrix/ui/options/options_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';
import 'package:validators/validators.dart';

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

  bool validateText({required String text, required String fieldKey}) {
    bool valid = true;
    if (text == '') {
      valid = false;
    }

    if (valid == true && optionsBloc.jsonMapFields.contains(fieldKey)) {
      if (text.length < 2) {
        valid = false;
      }
      if (valid == true && !text.startsWith('{')) {
        valid = false;
      }
      if (valid == true && !text.endsWith('}')) {
        valid = false;
      }
      if (valid == true) {
        try {
          jsonDecode(text.replaceAll("'", '"'));
        } catch (e) {
          valid = false;
        }
      }
    }

    if (valid == true && optionsBloc.jsonListOfMapFields.contains(fieldKey)) {
      if (text.length < 2) {
        valid = false;
      }
      if (text == '[]') {
        return true;
      }
      if (valid == true && !text.startsWith('[{')) {
        valid = false;
      }
      if (valid == true && !text.endsWith('}]')) {
        valid = false;
      }
      if (valid == true) {
        try {
          jsonDecode(text.replaceAll("'", '"'));
        } catch (e) {
          valid = false;
        }
      }
    }

    if (valid == true) {
      valid = validateUrl(text: text, fieldKey: fieldKey);
    }

    return valid;
  }

  bool validateUrl({required String text, required String fieldKey}) {
    bool valid = true;
    List<String>? protocols = optionsBloc.listOfUrlFields[fieldKey];

    if (protocols != null) {
      valid = false;
      for (String protocol in protocols) {
        if (text.startsWith('$protocol://')) {
          valid = true;
        }
      }
      if (valid == true) {
        valid = isURL(text, requireTld: true, requireProtocol: true);
      }
    }

    return valid;
  }

  bool validateNumber({required int num, required String fieldKey}) {
    bool valid = true;

    Map<String, int>? obj = optionsBloc.listOfHexFields[fieldKey];
    if (obj != null) {
      int min = obj['min']!;
      int max = obj['max']!;
      if (num < min || num > max) {
        valid = false;
      }
    }

    return valid;
  }

  List<Widget> getFormFields({required Map<String, dynamic> json}) {
    List<Widget> widgets = [];

    for (String areaKey in json.keys) {
      Map<String, dynamic> area = json[areaKey];
      if (area.keys.isNotEmpty) {
        List<Widget> fields = [];

        for (String fieldKey in area.keys) {
          String? fieldType = optionsBloc.getFieldType(
              fieldKey: fieldKey, fieldValue: area[fieldKey]);
          if (fieldType != null) {
            if (kDebugMode) {
              print(
                  'area: $areaKey, field: $fieldKey, value: ${fieldValues[areaKey][fieldKey]}, fieldType: $fieldType');
            }

            Widget? widgetField;
            if (fieldType == 'text') {
              widgetField = Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: EditableSinglelineText(
                  inputType: TextInputType.text,
                  noCounter: true,
                  label: fieldKey +
                      (optionsBloc.valueTypes[fieldKey] != null
                          ? ' (${optionsBloc.valueTypes[fieldKey]})'
                          : ''),
                  labelColor: Colors.red,
                  borderColor: Colors.red.shade300,
                  text: fieldValues[areaKey][fieldKey],
                  filter: (String text) {
                    if (text == '') {
                      setState(() {
                        fieldValues[areaKey][fieldKey] = '';
                      });
                    }
                    return text;
                  },
                  errorMessageHandler: (String newValue) {
                    if (newValue == '') {
                      return 'Textfeld darf nicht leer sein';
                    }

                    List<String>? protocols =
                        optionsBloc.listOfUrlFields[fieldKey];
                    if (protocols != null &&
                        !validateUrl(text: newValue, fieldKey: fieldKey)) {
                      return 'Url hat ein ungültiges Format';
                    }

                    return 'Textfeld ist kein gültiges Json';
                  },
                  validation: (String text) =>
                      validateText(text: text, fieldKey: fieldKey),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => fieldValues[areaKey][fieldKey] = value);
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
                  label: fieldKey +
                      (optionsBloc.valueTypes[fieldKey] != null
                          ? ' (${optionsBloc.valueTypes[fieldKey]})'
                          : ''),
                  labelColor: Colors.red,
                  borderColor: Colors.red.shade300,
                  text: fieldValues[areaKey][fieldKey].toString(),
                  filter: (String text) {
                    if (text == '') {
                      setState(() {
                        fieldValues[areaKey][fieldKey] = '';
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
                    return validateNumber(num: num, fieldKey: fieldKey);
                  },
                  onChanged: (value) {
                    if (mounted) {
                      try {
                        setState(() =>
                            fieldValues[areaKey][fieldKey] = int.parse(value));
                      } catch (e) {
                        setState(() {
                          fieldValues[areaKey][fieldKey] = '';
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
                  label: fieldKey,
                  labelColor: Colors.red,
                  enabled: fieldValues[areaKey][fieldKey],
                  onChanged: (value) {
                    if (mounted) {
                      setState(() => fieldValues[areaKey][fieldKey] = value);
                    }
                  },
                ),
              );
            }
            if (widgetField != null) {
              fields.add(widgetField);
            }
          }
        }
        Widget widgetArea = Card(
          child: Column(
            children: [Headline(text: areaKey), ...fields],
          ),
        );
        widgets.add(widgetArea);
      }
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
          Map<String, dynamic> json = jsonDecode(jsonStr);
          if (search.isNotEmpty) {
            jsonStr = jsonStr.replaceAll(
                RegExp(search, caseSensitive: false), '<b>$search</b>');
          }

          validData = false;
          bool test = true;
          outerLoop:
          for (Map obj in fieldValues.values) {
            for (String fieldKey in obj.keys) {
              String? fieldType = optionsBloc.getFieldType(
                  fieldKey: fieldKey, fieldValue: obj[fieldKey]);
              if (fieldType == 'int') {
                test = validateNumber(
                    num: int.parse(obj[fieldKey].toString()),
                    fieldKey: fieldKey);
              } else {
                test = validateText(
                    text: obj[fieldKey].toString(), fieldKey: fieldKey);
              }

              if (!test) break outerLoop;
            }
          }
          validData = test;

          fieldValues = optionsState.fieldValues;
          formFields = getFormFields(json: json);

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
