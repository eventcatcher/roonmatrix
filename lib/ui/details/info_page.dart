import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class InfoPage extends StatefulWidget {
  final bool showMacStyle;
  final String name;
  final String ip;
  final VoidCallback close;

  const InfoPage({
    super.key,
    required this.showMacStyle,
    required this.name,
    required this.ip,
    required this.close,
  });

  @override
  State<InfoPage> createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  bool get showMacStyle => widget.showMacStyle;
  String get name => widget.name;
  String get ip => widget.ip;
  VoidCallback get close => widget.close;

  Map<String, dynamic> translations = {};
  String title = '';
  bool translationsLoaded = false;
  bool saveIdle = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : Info';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);

    super.initState();
  }

  Widget body({
    required BuildContext context,
    required MainState mainState,
    required String infoStr,
  }) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SearchField(
              showMacStyle: showMacStyle,
              type: 'info',
              controller: mainBloc.getSearchController(type: 'info'),
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
                        child: Text(
                          infoStr,
                          style: TextStyle(
                            color: SharedWidgets.textColor(
                                showMacStyle: showMacStyle, context: context),
                          ),
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
                              name: name, ip: ip, type: 'info');
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
      );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
        bloc: translationsBloc,
        builder: (context, TranslationsState translationsState) {
          if (translationsState is TranslationsStateLoaded) {
            translations = translationsState.translations;
            translationsLoaded = translationsState.translationsLoaded;
            title = '$name : ${translations['infoPageHeaderText'] ?? 'Info'}';
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

                String search = mainState.searchFilter['info']!;
                Map<String, dynamic> info = Map.from(
                    (mainState.info[ip] ?? {}) as Map<String, dynamic>);
                if (search.isNotEmpty) {
                  info.removeWhere((key, value) =>
                      !key.toLowerCase().contains(search.toLowerCase()));
                }

                String infoStr = info
                    .map((k, v) {
                      return MapEntry(k, '$k: $v');
                    })
                    .values
                    .toList()
                    .join('\n');

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
                      child: body(
                          context: context,
                          mainState: mainState,
                          infoStr: infoStr),
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
                                  child: body(
                                      context: context,
                                      mainState: mainState,
                                      infoStr: infoStr),
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
                            context: context,
                            mainState: mainState,
                            infoStr: infoStr),
                      );
              });
        });
  }
}
