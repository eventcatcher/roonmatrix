import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/search_field.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';

class ConfigPage extends StatefulWidget {
  final String name;
  final String ip;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final VoidCallback close;

  const ConfigPage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.close,
  });

  @override
  State<ConfigPage> createState() => ConfigPageState();
}

class ConfigPageState extends State<ConfigPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  VoidCallback get close => widget.close;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final MacosTabController _controller = MacosTabController(
    initialIndex: 0,
    length: 2,
  );

  Map<String, dynamic> translations = {};
  Map fieldValues = {};
  List<Widget> formFields = [];
  String title = '';
  String jsonStr = '';
  String macosVersion = '';
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

  Widget tabEdit({
    required BuildContext widgetContext,
    required ColorScheme defaultColorScheme,
    required MainState mainState,
  }) =>
      SizedBox(
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
            if (Globals.inIosStyle()) const SizedBox(height: 14.0),
            Padding(
              padding: EdgeInsets.symmetric(
                  vertical: Globals.isDesktopDevice() ? 16.0 : 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTextButtonElement(
                    onMacAsText: true,
                    icon: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Icon(
                        Icons.save,
                        color: Colors.white,
                        size: 20.0,
                      ),
                    ),
                    label: (translations['saveButtonText'] ?? 'save')
                        .toString()
                        .toFirstUpper,
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

                            SharedWidgets.showSnackBar(
                                // ignore: use_build_context_synchronously
                                context: widgetContext,
                                doneMessage: translations['saveDoneMessage'] ??
                                    'save config successfully done',
                                failMessage:
                                    translations['saveFailedMessage'] ??
                                        'save config failed!',
                                valid: valid);

                            if (valid == true) {
                              if (widgetContext.mounted) {
                                Timer.periodic(const Duration(seconds: 3),
                                    (Timer timer) {
                                  timer.cancel();
                                  if (widgetContext.mounted) {
                                    Navigator.of(widgetContext).pop();
                                  }
                                });
                              }
                            }
                          },
                  ),
                ],
              ),
            ),
            if (Globals.inIosStyle()) const SizedBox(height: 14.0),
          ],
        ),
      );

  Widget tabView({
    required BuildContext widgetContext,
    required ColorScheme defaultColorScheme,
    required MainState mainState,
    required String jsonStr,
  }) {
    return Container(
      padding: EdgeInsets.only(
          top: Globals.inIosStyle() || Globals.inMacosStyle() ? 20.0 : 0.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SearchField(
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
                            color: ColorDefs.textColor(context: widgetContext),
                          ),
                          tags: {
                            'b': StyledTextTag(
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  backgroundColor: Globals.brightness() ==
                                          Brightness.dark
                                      ? const Color.fromARGB(255, 135, 94, 6)
                                      : const Color(0xFFffaf00)),
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          if (Globals.inIosStyle()) const SizedBox(height: 14.0),
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: Globals.isDesktopDevice() ? 16.0 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTextButtonElement(
                  onMacAsText: true,
                  icon: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                  label: (translations['exportButtonText'] ?? 'export')
                      .toString()
                      .toFirstUpper,
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

                          SharedWidgets.showSnackBar(
                              // ignore: use_build_context_synchronously
                              context: widgetContext,
                              doneMessage: translations['exportDoneMessage'] ??
                                  'export successfully done',
                              failMessage:
                                  translations['exportFailedMessage'] ??
                                      'export failed!',
                              valid: valid);
                        },
                ),
              ],
            ),
          ),
          if (Globals.inIosStyle()) const SizedBox(height: 14.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BuildContext widgetContext = context;
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
            if (Globals.inIosStyle()) {
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  brightness: Globals.brightness(),
                  middle: Text(title),
                ),
                child: SizedBox(),
              );
            }
            return Globals.inMacosStyle()
                ? MacosScaffold(
                    toolBar: ToolBar(
                      title: Text(title),
                      titleWidth: Globals.extendedTitleWidth,
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
                macosVersion = mainState.macosVersion;
                jsonStr = mainBloc.getPrettyJSONString(mainState.config[ip]);

                if (search.isNotEmpty) {
                  jsonStr = jsonStr.replaceAllMapped(
                      RegExp(search, caseSensitive: false), (match) {
                    return '<b>${match.group(0)}</b>';
                  });
                }

                if (mainState.definitions == null) {
                  return const LoadingIndicatorSmall();
                }

                ConfigDefinition defs = mainState.definitions!;
                fieldValues = mainState.fieldValues;
                validData = mainBloc.validateAll(
                    definitions: defs, fieldValues: fieldValues);
                formFields = mainBloc.getConfigFormFields(
                    context: context,
                    translations: translations,
                    fieldValues: fieldValues,
                    defs: defs,
                    updateFieldValues: ({
                      required String areaName,
                      required String fieldName,
                      required dynamic value,
                    }) {
                      if (mounted) {
                        setState(
                            () => fieldValues[areaName][fieldName] = value);
                      }
                    });

                if (Globals.inIosStyle()) {
                  return CupertinoPageScaffold(
                    navigationBar: CupertinoNavigationBar(
                      brightness: Globals.brightness(),
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
                                          widgetContext: widgetContext,
                                          defaultColorScheme:
                                              defaultColorScheme,
                                          mainState: mainState),
                                    ),
                                  ),
                                );
                              });
                            case 1:
                              return CupertinoTabView(
                                builder: (xcontext) {
                                  return SafeArea(
                                    child: CupertinoPageScaffold(
                                      child: Center(
                                        child: tabView(
                                            widgetContext: widgetContext,
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

                return Globals.inMacosStyle()
                    ? PageWithToolbarMacStyle(
                        title: title,
                        standardDesktopSize: standardDesktopSize,
                        macosVersion: macosVersion,
                        body: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: MacosTabView(
                            controller: _controller,
                            tabs: [
                              MacosTab(
                                  label:
                                      translations['configPageTabEditLabel'] ??
                                          'Edit'),
                              MacosTab(
                                label: translations['configPageTabReadLabel'] ??
                                    'View',
                              ),
                            ],
                            children: [
                              Center(
                                child: tabEdit(
                                    widgetContext: widgetContext,
                                    defaultColorScheme: defaultColorScheme,
                                    mainState: mainState),
                              ),
                              Center(
                                child: tabView(
                                    widgetContext: widgetContext,
                                    defaultColorScheme: defaultColorScheme,
                                    mainState: mainState,
                                    jsonStr: jsonStr),
                              ),
                            ],
                          ),
                        ),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      )
                    : PageWithToolbarFlutterStyle(
                        scaffoldKey: scaffoldKey,
                        title: title,
                        sliderDefaultValue: 0.0,
                        withTabController: true,
                        tabLength: 2,
                        tabBar: PreferredSize(
                          preferredSize: const Size.fromHeight(48.0),
                          child: Material(
                            color: Globals.brightness() == Brightness.dark
                                ? Colors.blue.shade800
                                : Colors.blue.shade400,
                            child: TabBar(
                              tabs: <Widget>[
                                Tab(
                                  text:
                                      translations['configPageTabEditLabel'] ??
                                          'Edit',
                                ),
                                Tab(
                                  text:
                                      translations['configPageTabReadLabel'] ??
                                          'View',
                                ),
                              ],
                            ),
                          ),
                        ),
                        showExpandableSpeedSlider: false,
                        scrollSpeedDevice: 1.0,
                        standardDesktopSize: standardDesktopSize,
                        drawer: null,
                        body: TabBarView(
                          children: <Widget>[
                            tabEdit(
                                widgetContext: widgetContext,
                                defaultColorScheme: defaultColorScheme,
                                mainState: mainState),
                            tabView(
                                widgetContext: widgetContext,
                                defaultColorScheme: defaultColorScheme,
                                mainState: mainState,
                                jsonStr: jsonStr),
                          ],
                        ),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      );
              });
        });
  }
}
