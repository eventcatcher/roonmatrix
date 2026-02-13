import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';
import 'package:roonmatrix/ui/layout/search_field.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class InfoPage extends StatefulWidget {
  final String name;
  final String ip;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const InfoPage({
    super.key,
    required this.name,
    required this.ip,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<InfoPage> createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> translations = {};
  String title = '';
  String macosVersion = '';
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
                            color: ColorDefs.textColor(context: context),
                          ),
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
                              name: name, ip: ip, type: 'info');
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
            title =
                '$name : ${translations['infoPageHeaderText'] ?? 'Monitoring'}';
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
                String search = mainState.searchFilter['info']!;
                Map<String, dynamic> info =
                    Map<String, dynamic>.from(mainState.info[ip] ?? {});
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
                          infoStr: infoStr),
                    ),
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
                            infoStr: infoStr),
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
                            infoStr: infoStr),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      );
              });
        });
  }
}
