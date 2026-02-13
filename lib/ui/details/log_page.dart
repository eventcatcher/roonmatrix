import 'package:extended_text/extended_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/layout/search_field.dart';
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

  const LogPage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<LogPage> createState() => LogPageState();
}

class LogPageState extends State<LogPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final int logfileSliceSize = 500000;
  final int dateTimeLength = 17;

  Map<String, dynamic> translations = {};
  List<int> logfilePartOffset = [];
  String lastLog = '';
  String title = '';
  String macosVersion = '';
  int hours = 1;
  int logfileParts = 1;
  int logfilePart = 1;
  bool translationsLoaded = false;
  bool saveIdle = false;
  bool refreshLog = false;
  bool filterLog = false;

  late TranslationsBloc translationsBloc;
  late MainRepository mainRepository;
  late MainBloc mainBloc;

  @override
  void initState() {
    title = '$name : Log';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getLog(ip: ip, hours: hours);

    super.initState();
  }

  List<Widget> logfilePartSelection({
    required String logstr,
    double splashRadius = 16.0,
    double fontSize = 16.0,
    Duration visibilityAnimation = const Duration(milliseconds: 2000),
  }) =>
      [
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: visibilityAnimation,
          child: IconButton(
            padding: const EdgeInsets.only(bottom: 2.0),
            splashRadius: splashRadius,
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
          duration: visibilityAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              '${translations['filesize'] ?? 'filesize'}: ${logstr.length.readableFileSize(base1024: true)}',
              style: TextStyle(
                  fontSize: fontSize,
                  color: ColorDefs.textColor(context: context)),
            ),
          ),
        ),
        SizedBox(width: 8.0),
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: visibilityAnimation,
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: splashRadius,
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
          duration: visibilityAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              '$logfilePart / $logfileParts',
              style: TextStyle(
                  fontSize: fontSize,
                  color: ColorDefs.textColor(context: context)),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: !refreshLog && logstr.isNotEmpty ? 1.0 : 0.0,
          duration: visibilityAnimation,
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: splashRadius,
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
                    if (value != null) {
                      mainBloc.getLog(ip: ip, hours: int.parse(value));
                      if (mounted) {
                        setState(() {
                          hours = int.parse(value);
                          logfilePart = 1;
                          logfilePartOffset = [];
                        });
                      }
                    }
                  },
                ),
              ),
              if (Globals.isDesktopDevice())
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
          if (Globals.isMobileDevice())
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
                              color: ColorDefs.textColor(context: context)),
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
          if (Globals.inIosStyle()) const SizedBox(height: 14.0),
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
                  logstr = logstr.onlyMatchedLinesFilter(
                    logstr: logstr,
                    filterLog: filterLog,
                    match: '[bg-orange]',
                  );

                  if (mainRepository.dateTimeHeadHasChanged(
                      newLog: logstr, lastLog: lastLog)) {
                    Map<String, dynamic> data = mainRepository.generateLogParts(
                      logstr: logstr,
                      logfileSliceSize: logfileSliceSize,
                    );
                    int newLogfileParts = data['parts'];
                    logfilePartOffset = data['logfilePartOffset'];

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
                        child: body(
                            context: context,
                            mainState: mainState,
                            logstr: logstr)),
                  );
                }

                return Globals.inMacosStyle()
                    ? PageWithToolbarMacStyle(
                        title: title,
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
