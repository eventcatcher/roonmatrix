import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/select_box_with_icon.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:styled_text/tags/styled_text_tag.dart';
import 'package:styled_text/widgets/styled_text.dart';

class LogPage extends StatefulWidget {
  final String name;
  final String ip;
  final VoidCallback close;

  const LogPage({
    super.key,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<LogPage> createState() => LogPageState();
}

class LogPageState extends State<LogPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  Map<String, dynamic> translations = {};
  String title = '';
  int hours = 1;
  bool translationsLoaded = false;
  bool saveIdle = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : Log';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getLog(ip: ip, hours: hours);

    super.initState();
  }

  Widget body({
    required BuildContext context,
    required MainState mainState,
    required String log,
  }) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SearchField(
              type: 'log',
              controller: mainBloc.getSearchController(type: 'log'),
            ),
          ),
          SelectBoxWithIcon(
            translations: translations,
            options: translationsBloc.state.logHoursOptions,
            placeholder:
                translations['pleaseSelectPlaceholder'] ?? 'Please Select',
            selected: hours.toString(),
            onChanged: (String? value) {
              if (mounted && value != null) {
                setState(() => hours = int.parse(value));
                mainBloc.getLog(ip: ip, hours: hours);
              }
            },
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
                          text: log,
                          style: TextStyle(
                            color: SharedWidgets.textColor(context: context),
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
          if (SharedWidgets.inIosStyle()) const SizedBox(height: 14.0),
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
                  onMacAsText: true,
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
                              name: name, ip: ip, type: 'log');
                          setState(() {
                            saveIdle = false;
                          });
                          if (valid == null) {
                            return;
                          }
                          if (valid == true) {
                            if (context.mounted &&
                                !SharedWidgets.inMacosStyle() &&
                                !SharedWidgets.inIosStyle()) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    translations['exportDoneMessage'] ??
                                        'export successfully done'),
                                backgroundColor: Colors.green,
                              ));
                            }
                          } else {
                            if (context.mounted &&
                                !SharedWidgets.inMacosStyle() &&
                                !SharedWidgets.inIosStyle()) {
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
          if (SharedWidgets.inIosStyle()) const SizedBox(height: 14.0),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
            title = '$name :  ${translations['logPageHeaderText'] ?? 'Log'}';
          }

          if (translationsState is! TranslationsStateLoaded ||
              !translationsLoaded) {
            if (SharedWidgets.inIosStyle()) {
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  brightness: SharedWidgets.brightness(),
                  middle: Text(title),
                ),
                child: SizedBox(),
              );
            }
            return SharedWidgets.inMacosStyle()
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

                String search = mainState.searchFilter['log']!;
                String log = mainState.log;
                if (log.isNotEmpty) {
                  if (log.endsWith('"')) {
                    log = log.substring(0, log.length - 1);
                  }
                  if (log.startsWith('"')) {
                    log = log.substring(1);
                  }
                  log = log.replaceAll('\\n', '\n');
                  if (search.isNotEmpty) {
                    log = log.replaceAll(
                        RegExp(search, caseSensitive: false), '<b>$search</b>');
                  }
                }

                if (SharedWidgets.inIosStyle()) {
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
                        child: body(
                            context: context, mainState: mainState, log: log)),
                  );
                }

                return SharedWidgets.inMacosStyle()
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
                                  child: body(
                                      context: context,
                                      mainState: mainState,
                                      log: log),
                                ),
                              );
                            }),
                          ),
                        ],
                      )
                    : Scaffold(
                        appBar: AppBar(
                          title: Text(title),
                          actions: const [],
                        ),
                        body: body(
                            context: context, mainState: mainState, log: log),
                      );
              });
        });
  }
}
