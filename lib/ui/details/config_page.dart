import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/main.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/editable_singleline_text.dart';
import 'package:roonmatrix/ui/layout/headline.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/key_val_items.dart';
import 'package:roonmatrix/ui/layout/list_items.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/map_list_items.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/switch_button.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfigPage extends StatefulWidget {
  final bool showMacStyle;
  final String name;
  final String ip;
  final VoidCallback close;

  const ConfigPage({
    super.key,
    required this.showMacStyle,
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

  final MacosTabController _controller = MacosTabController(
    initialIndex: 0,
    length: 2,
  );

  Map<String, dynamic> translations = {};
  Map fieldValues = {};
  List<Widget> formFields = [];
  String title = '';
  bool translationsLoaded = false;
  bool saveIdle = false;
  bool validData = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : Config';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getConfig(ip: ip);

    super.initState();
  }

  List<Widget> getFormFields({required ConfigDefinition defs}) {
    List<Widget> widgets = [];

    for (ConfigDefinitionArea area in defs.area) {
      List<Widget> fields = [];

      for (ConfigDefinitionItem fieldDefinition in area.items) {
        String? fieldType =
            mainBloc.getFieldType(fieldDefinition: fieldDefinition);
        if (fieldType != null && fieldDefinition.editable == true) {
          if (kDebugMode) {
            print(
                'area: ${area.name}, field: ${fieldDefinition.name}, value: ${fieldValues[area.name][fieldDefinition.name]}, fieldType: $fieldType');
          }

          Widget? widgetField;

          String label = (translations['config']?[fieldDefinition.name] ??
              fieldDefinition.label);
          if (!fieldType.startsWith('list') &&
              fieldType != 'list' &&
              fieldType != 'keyValItems') {
            label += (fieldDefinition.unit != ''
                ? ' (${translations['config']?[fieldDefinition.unit] ?? fieldDefinition.unit})'
                : '');
          }

          if (fieldType == 'text') {
            widgetField = Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: EditableSinglelineText(
                showMacStyle: showMacStyle,
                inputType: TextInputType.text,
                noCounter: true,
                label: label,
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
                  return mainBloc.getFieldErrorMessage(
                      value: newValue,
                      type: fieldDefinition.type.type,
                      translations: translations);
                },
                validation: (String text) => mainBloc.validateText(
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
                showMacStyle: showMacStyle,
                inputType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                noCounter: true,
                label: label,
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
                  return mainBloc.getFieldErrorMessage(
                      value: newValue,
                      type: fieldType,
                      translations: translations);
                },
                validation: (String text) {
                  int? num = int.tryParse(text);
                  if (num == null) {
                    return false;
                  }
                  return mainBloc.validateNumber(
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
                showMacStyle: showMacStyle,
                label: label,
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
          if (fieldType.startsWith('listItems')) {
            List<dynamic> json = jsonDecode(
                (fieldValues[area.name][fieldDefinition.name] as String)
                    .replaceAll("'", '"'));
            widgetField = ListItems(
              showMacStyle: showMacStyle,
              label: label,
              fieldValues: json,
              predefinedLength: fieldType.endsWith('PredefinedLength'),
              onChanged: (String value) {
                setState(
                    () => fieldValues[area.name][fieldDefinition.name] = value);
              },
            );
          }
          if (fieldType == 'keyValItems') {
            Map<String, dynamic> json = jsonDecode(
                (fieldValues[area.name][fieldDefinition.name] as String)
                    .replaceAll("'", '"'));
            widgetField = KeyValItems(
              showMacStyle: showMacStyle,
              label: label,
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
              showMacStyle: showMacStyle,
              label: label,
              fieldDefinition: fieldDefinition,
              fieldValues: json,
              onChanged: (String value) {
                setState(
                    () => fieldValues[area.name][fieldDefinition.name] = value);
              },
            );
          }
          if (widgetField != null) {
            if (fieldDefinition.link != '') {
              fields.add(Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(child: widgetField),
                  Container(
                    margin: const EdgeInsets.only(
                      top: 18.0,
                      right: 16.0,
                    ),
                    height: 38.0,
                    child: IconButton(
                      onPressed: () async {
                        final Uri url = Uri.parse(fieldDefinition.link == '*'
                            ? fieldDefinition.value.toString()
                            : fieldDefinition.link.toString());
                        if (!await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        )) {
                          if (kDebugMode) {
                            print('Could not launch url: $url');
                          }
                        }
                      },
                      icon: const Icon(Icons.link),
                    ),
                  ),
                ],
              ));
            } else {
              fields.add(widgetField);
            }
          }
        }
      }
      Widget widgetArea = Card(
        color: SharedWidgets.windowBackgroundColor(
            showMacStyle: showMacStyle, context: context),
        child: Column(
          children: [
            Headline(
              showMacStyle: showMacStyle,
              text: translations['config']?[area.name] ?? area.name,
            ),
            ...fields
          ],
        ),
      );
      widgets.add(widgetArea);
    }

    return widgets;
  }

  Widget tabEdit({
    required BuildContext context,
    required ColorScheme defaultColorScheme,
    required MainState mainState,
  }) =>
      Container(
        color: SharedWidgets.windowBackgroundColor(
            showMacStyle: showMacStyle, context: context),
        child: Column(
          children: [
            Expanded(
              child: mainState.subPageIdle == true
                  ? const LoadingIndicatorSmall()
                  : ListView(
                      shrinkWrap: true,
                      children: [...formFields],
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical:
                      Platform.isMacOS || Platform.isWindows || Platform.isLinux
                          ? 16.0
                          : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTextButtonElement(
                    showMacStyle: showMacStyle,
                    icon: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(
                        Icons.save,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    label: translations['saveButtonText'] ?? 'save',
                    onPressed: !validData ||
                            saveIdle == true ||
                            mainState.subPageIdle == true
                        ? null
                        : () async {
                            setState(() {
                              saveIdle = true;
                            });
                            bool valid = await mainBloc.saveConfig(
                                name: name, ip: ip, data: fieldValues);
                            setState(() {
                              saveIdle = false;
                            });
                            if (valid == true) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      translations['saveDoneMessage'] ??
                                          "save config successfully done"),
                                  backgroundColor: Colors.green,
                                ));

                                Timer.periodic(const Duration(seconds: 3),
                                    (Timer timer) {
                                  timer.cancel();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                });
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      translations['saveFailedMessage'] ??
                                          "save config failed!"),
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
      );

  tabView({
    required BuildContext context,
    required ColorScheme defaultColorScheme,
    required MainState mainState,
    required String jsonStr,
  }) =>
      Container(
        padding: EdgeInsets.only(
            top: Platform.isIOS || Platform.isMacOS ? 20.0 : 0.0),
        color: SharedWidgets.windowBackgroundColor(
            showMacStyle: showMacStyle, context: context),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SearchField(
                showMacStyle: showMacStyle,
                type: 'config',
                controller: mainBloc.getSearchController(type: 'config'),
              ),
            ),
            Expanded(
              child: mainState.subPageIdle == true
                  ? const LoadingIndicatorSmall()
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: StyledText(
                            text: jsonStr,
                            style: TextStyle(
                              color: SharedWidgets.textColor(
                                  showMacStyle: showMacStyle, context: context),
                            ),
                            tags: {
                              'b': StyledTextTag(
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: SharedWidgets.brightness() ==
                                            Brightness.dark
                                        ? Colors.red.shade300
                                        : Colors.red),
                              ),
                            },
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical:
                      Platform.isMacOS || Platform.isWindows || Platform.isLinux
                          ? 16.0
                          : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTextButtonElement(
                    showMacStyle: showMacStyle,
                    icon: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    label: translations['exportButtonText'] ?? 'export',
                    onPressed: saveIdle == true || mainState.subPageIdle == true
                        ? null
                        : () async {
                            setState(() {
                              saveIdle = true;
                            });
                            bool? valid = await mainBloc.exportData(
                                name: name, ip: ip, type: 'config');
                            setState(() {
                              saveIdle = false;
                            });
                            if (valid == null) {
                              return;
                            }
                            if (valid == true) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      translations['exportDoneMessage'] ??
                                          'export successfully done'),
                                  backgroundColor: Colors.green,
                                ));
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      translations['exportFailedMessage'] ??
                                          'export failed!'),
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
      );

  Widget body({
    required BuildContext context,
    required ColorScheme defaultColorScheme,
    required MainState mainState,
    required String jsonStr,
  }) =>
      TabBarView(
        children: <Widget>[
          tabEdit(
              context: context,
              defaultColorScheme: defaultColorScheme,
              mainState: mainState),
          tabView(
              context: context,
              defaultColorScheme: defaultColorScheme,
              mainState: mainState,
              jsonStr: jsonStr),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final ColorScheme defaultColorScheme = Theme.of(context).colorScheme;

    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
            title =
                '$name : ${translations['configPageHeaderText'] ?? 'Config'}';
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
            if (Platform.isIOS) {
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  brightness: SharedWidgets.brightness(),
                  middle: Text(title),
                ),
                child: SizedBox(),
              );
            }
            return showMacStyle == true && Platform.isMacOS
                ? MacosScaffold(
                    toolBar: ToolBar(
                      title: Text(title),
                      titleWidth: 200.0,
                      leading: MacosBackButton(
                        onPressed: () => Navigator.pop(context),
                        fillColor: Colors.transparent,
                      ),
                      actions: [],
                    ),
                    children: [
                      ContentArea(
                        builder: ((context, scrollController) {
                          return MacosWindow(
                            child: Material(
                              child: SizedBox(),
                            ),
                          );
                        }),
                      ),
                    ],
                  )
                : Scaffold(
                    appBar: AppBar(
                      title: Text(title),
                    ),
                    body: const SizedBox());
          }

          return BlocBuilder(
              bloc: mainBloc,
              builder: (context, MainState mainState) {
                if (mainState is! MainStateLoaded) {
                  return Container();
                }

                String search = mainState.searchFilter['config']!;
                String jsonStr = mainBloc.getPrettyJSONString(mainState.config);
                if (search.isNotEmpty) {
                  jsonStr = jsonStr.replaceAll(
                      RegExp(search, caseSensitive: false), '<b>$search</b>');
                }

                if (mainState.definitions == null) {
                  return const LoadingIndicatorSmall();
                }

                ConfigDefinition defs = mainState.definitions!;
                fieldValues = mainState.fieldValues;
                validData = mainBloc.validateAll(
                    definitions: defs, fieldValues: fieldValues);
                formFields = getFormFields(defs: defs);

                if (Platform.isIOS) {
                  return CupertinoPageScaffold(
                    navigationBar: CupertinoNavigationBar(
                      brightness: SharedWidgets.brightness(),
                      middle: Text(title),
                      leading: CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: CupertinoNavigationBarBackButton(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    child: SafeArea(
                      child: CupertinoTabScaffold(
                        tabBar: CupertinoTabBar(
                          items: <BottomNavigationBarItem>[
                            BottomNavigationBarItem(
                                icon: Icon(CupertinoIcons.pencil),
                                label: translations['configPageTabEditLabel'] ??
                                    'Edit'),
                            BottomNavigationBarItem(
                                icon: Icon(CupertinoIcons.eye),
                                label: translations['configPageTabReadLabel'] ??
                                    'View'),
                          ],
                        ),
                        tabBuilder: (context, index) {
                          switch (index) {
                            case 0:
                              return CupertinoTabView(builder: (context) {
                                return SafeArea(
                                  child: CupertinoPageScaffold(
                                    child: Center(
                                      child: tabEdit(
                                          context: context,
                                          defaultColorScheme:
                                              defaultColorScheme,
                                          mainState: mainState),
                                    ),
                                  ),
                                );
                              });
                            case 1:
                              return CupertinoTabView(
                                builder: (context) {
                                  return SafeArea(
                                    child: CupertinoPageScaffold(
                                      child: Center(
                                        child: tabView(
                                            context: context,
                                            defaultColorScheme:
                                                defaultColorScheme,
                                            mainState: mainState,
                                            jsonStr: jsonStr),
                                      ),
                                    ),
                                  );
                                },
                              );
                            default:
                              return SizedBox();
                          }
                        },
                      ),
                    ),
                  );
                }

                return showMacStyle == true && Platform.isMacOS
                    ? MacosScaffold(
                        toolBar: ToolBar(
                          title: Text(title),
                          titleWidth: 1000.0,
                          leading: MacosBackButton(
                            onPressed: () => Navigator.pop(context),
                            fillColor: Colors.transparent,
                          ),
                          actions: [],
                        ),
                        children: [
                          ContentArea(
                            builder: ((context, scrollController) {
                              return Material(
                                child: MacosWindow(
                                  child: MacosTabView(
                                    controller: _controller,
                                    tabs: [
                                      MacosTab(
                                          label: translations[
                                                  'configPageTabEditLabel'] ??
                                              'Edit'),
                                      MacosTab(
                                        label: translations[
                                                'configPageTabReadLabel'] ??
                                            'View',
                                      ),
                                    ],
                                    children: [
                                      Center(
                                        child: tabEdit(
                                            context: context,
                                            defaultColorScheme:
                                                defaultColorScheme,
                                            mainState: mainState),
                                      ),
                                      Center(
                                        child: tabView(
                                            context: context,
                                            defaultColorScheme:
                                                defaultColorScheme,
                                            mainState: mainState,
                                            jsonStr: jsonStr),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      )
                    : DefaultTabController(
                        initialIndex: 0,
                        length: 2,
                        child: Scaffold(
                          appBar: AppBar(
                            title: Text(title),
                            actions: const [],
                            bottom: PreferredSize(
                              preferredSize: const Size.fromHeight(48.0),
                              child: Material(
                                color: SharedWidgets.brightness() ==
                                        Brightness.dark
                                    ? Colors.blue.shade800
                                    : Colors.blue.shade400,
                                child: TabBar(
                                  tabs: <Widget>[
                                    Tab(
                                      text: translations[
                                              'configPageTabEditLabel'] ??
                                          'Edit',
                                    ),
                                    Tab(
                                      text: translations[
                                              'configPageTabReadLabel'] ??
                                          'View',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          body: body(
                              context: context,
                              defaultColorScheme: defaultColorScheme,
                              mainState: mainState,
                              jsonStr: jsonStr),
                        ),
                      );
              });
        });
  }
}
