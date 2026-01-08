import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/helper/rich_parser.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/select_box_with_icon.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class LogPage extends StatefulWidget {
  final String name;
  final String ip;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final VoidCallback close;

  const LogPage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.close,
  });

  @override
  State<LogPage> createState() => LogPageState();
}

class LogPageState extends State<LogPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  VoidCallback get close => widget.close;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> translations = {};
  List<int> logfilePartOffset = [];
  String lastLog = '';
  String title = '';
  String macosVersion = '';
  int hours = 1;
  int logfileSliceSize = 500000;
  int logfileParts = 1;
  int logfilePart = 1;
  bool translationsLoaded = false;
  bool saveIdle = false;
  bool refreshLog = false;
  bool filterLog = false;

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

  List<Widget> logfilePartSelection({required String logstr}) => [
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          child: IconButton(
            padding: const EdgeInsets.only(bottom: 2.0),
            splashRadius: 16.0,
            hoverColor: Colors.transparent,
            onPressed: () {
              setState(() {
                filterLog = !filterLog;
              });
            },
            icon: Icon(
              Icons.filter_alt,
              size: 24,
              color: filterLog ? Colors.green : Colors.grey,
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              '${translations['filesize'] ?? 'filesize'}: ${logstr.length.readableFileSize(base1024: true)}',
              style: TextStyle(
                  fontSize: 16.0,
                  color: SharedWidgets.textColor(context: context)),
            ),
          ),
        ),
        SizedBox(width: 8.0),
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: 16.0,
            hoverColor: Colors.transparent,
            onPressed: () {
              if (logfilePart > 1) {
                setState(() {
                  logfilePart -= 1;
                  refreshLog = true;
                });
              }
            },
            icon: Icon(
              Icons.arrow_left,
              size: 40,
              color: logfilePart > 1 ? Colors.green : Colors.grey,
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '$logfilePart / $logfileParts',
              style: TextStyle(
                  fontSize: 16.0,
                  color: SharedWidgets.textColor(context: context)),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 2000),
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: 16.0,
            hoverColor: Colors.transparent,
            onPressed: () {
              if (logfilePart < logfileParts) {
                setState(() {
                  logfilePart += 1;
                  refreshLog = true;
                });
              }
            },
            icon: Icon(
              Icons.arrow_right,
              size: 40,
              color: logfilePart < logfileParts ? Colors.green : Colors.grey,
            ),
          ),
        ),
        if (refreshLog == true)
          SizedBox(
              width: 20.0,
              height: 20.0,
              child: const CircularProgressIndicator()),
      ];

  Widget body({
    required BuildContext context,
    required MainState mainState,
    required String logstr,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: SelectBoxWithIcon(
                  translations: translations,
                  options: translationsBloc.state.logHoursOptions,
                  placeholder: translations['pleaseSelectPlaceholder'] ??
                      'Please Select',
                  selected: hours.toString(),
                  onChanged: (String? value) {
                    if (mounted && value != null) {
                      setState(() {
                        hours = int.parse(value);
                        logfilePart = 1;
                        logfilePartOffset = [];
                      });
                      mainBloc.getLog(ip: ip, hours: hours);
                    }
                  },
                ),
              ),
              if (SharedWidgets.isDesktopDevice())
                Flexible(
                  flex: 1,
                  child: SizedBox(
                      width: 400.0,
                      child: Row(
                          children:
                              logfilePartSelection(logstr: mainState.log))),
                ),
            ],
          ),
          if (SharedWidgets.isMobileDevice())
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: logfilePartSelection(logstr: mainState.log),
            ),
          Expanded(
            child: mainState.subPageIdle == true
                ? const LoadingIndicatorSmall()
                : ListView(
                    shrinkWrap: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ExtendedText(
                          logstr,
                          specialTextSpanBuilder: RichParser(),
                          style: TextStyle(
                              color: SharedWidgets.textColor(context: context)),
                        ),
                      ),
                    ],
                  ),
          ),
          if (SharedWidgets.inIosStyle()) const SizedBox(height: 14.0),
          Padding(
            padding: EdgeInsets.symmetric(
                vertical: SharedWidgets.isDesktopDevice() ? 16.0 : 0),
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

                          SharedWidgets.showSnackBar(
                              // ignore: use_build_context_synchronously
                              context: context,
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
          if (SharedWidgets.inIosStyle()) const SizedBox(height: 14.0),
        ],
      );

  int generateLogParts(String logstr) {
    String fullLog = logstr;
    int part = 1;
    int offset = 0;
    logfilePartOffset = [];
    if (logstr.isNotEmpty) {
      logfilePartOffset = [0];
      part = 0;
      do {
        part++;
        if (fullLog.length > logfileSliceSize) {
          offset = logfilePartOffset[part - 1];
          logstr = fullLog.substring(offset);
          if (logstr.length > logfileSliceSize) {
            int endOfLine = 0;
            if ((logfileSliceSize) < logstr.length) {
              endOfLine = logstr.substring(logfileSliceSize).indexOf('\n');
            }
            int partlen =
                logfileSliceSize + (endOfLine == -1 ? 0 : (endOfLine + 1));
            logstr = logstr.substring(0, partlen);
          }

          if (logfilePartOffset.length <= part) {
            logfilePartOffset.add(offset + logstr.length);
          }
        }
      } while (fullLog.length > logfileSliceSize &&
          fullLog.length > (offset + logstr.length));
    }

    return part;
  }

  String showOnlyMatchedLines(String logstr) {
    if (!filterLog || logstr.isEmpty) {
      return logstr;
    }

    List<String> matchedLines = [];
    List<String> lines = logstr.split('\n');
    for (String line in lines) {
      if (line.contains('[bg-orange]')) {
        matchedLines.add(line);
      }
    }

    return matchedLines.join('\n');
  }

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

                macosVersion = mainState.macosVersion;
                String search = mainState.searchFilter['log']!;
                String logstr = mainState.log;
                if (logstr.isNotEmpty) {
                  if (logstr.endsWith('"')) {
                    logstr = logstr.substring(0, logstr.length - 1);
                  }
                  if (logstr.startsWith('"')) {
                    logstr = logstr.substring(1);
                  }
                  logstr = logstr
                      .replaceAll('\\n', '\n')
                      .removeNumericBrackets()
                      .removeEmptyBrackets();
                  if (search.isNotEmpty) {
                    logstr = logstr.replaceAllMapped(
                        RegExp(search, caseSensitive: false), (match) {
                      return '[bg-orange]${match.group(0)}[/bg-orange]';
                    });
                  }
                  logstr = showOnlyMatchedLines(logstr);

                  if (logstr.isNotEmpty &&
                      lastLog.length != logstr.length &&
                      (lastLog.isEmpty ||
                          (lastLog.length > 17 &&
                              logstr.length > 17 &&
                              lastLog.substring(0, 17) !=
                                  logstr.substring(0, 17)))) {
                    int newLogfileParts = generateLogParts(logstr);
                    if (newLogfileParts != logfileParts &&
                        logfilePart > newLogfileParts) {
                      logfilePart = 1;
                    }
                    logfileParts = newLogfileParts;
                  }
                  if (logfilePartOffset.length > 1 && logstr.isNotEmpty) {
                    logstr = logstr.substring(
                        logfilePartOffset[logfilePart - 1],
                        logfilePartOffset[logfilePart]);
                  }

                  if (refreshLog == true) {
                    SchedulerBinding.instance.addPostFrameCallback((_) async {
                      if (mounted) {
                        setState(() {
                          refreshLog = false;
                        });
                      }
                    });
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
                            context: context,
                            mainState: mainState,
                            logstr: logstr)),
                  );
                }

                return SharedWidgets.inMacosStyle()
                    ? PageWithToolbarMacStyle(
                        title: name,
                        standardDesktopSize: standardDesktopSize,
                        macosVersion: macosVersion,
                        body: body(
                            context: context,
                            mainState: mainState,
                            logstr: logstr),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      )
                    : PageWithToolbarFlutterStyle(
                        scaffoldKey: scaffoldKey,
                        title: title,
                        showExpandableSpeedSlider: false,
                        scrollSpeedDevice: 1.0,
                        standardDesktopSize: standardDesktopSize,
                        body: body(
                            context: context,
                            mainState: mainState,
                            logstr: logstr),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      );
              });
        });
  }
}
