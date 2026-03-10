import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/web_page_display.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_small.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class SpotifyConnectWebAuthPage extends StatefulWidget {
  final String name;
  final String ip;
  final String url;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final Function({required String url}) callbackUrl;

  const SpotifyConnectWebAuthPage({
    super.key,
    required this.name,
    required this.ip,
    required this.url,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.callbackUrl,
  });

  @override
  State<SpotifyConnectWebAuthPage> createState() =>
      SpotifyConnectWebAuthPageState();
}

class SpotifyConnectWebAuthPageState extends State<SpotifyConnectWebAuthPage> {
  String get name => widget.name;
  String get ip => widget.ip;
  String get url => widget.url;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  Function({required String url}) get callbackUrl => widget.callbackUrl;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> translations = {};
  String title = '';
  String macosVersion = '';
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

  @override
  void initState() {
    title =
        '$name : ${translations['spotifyConnectAuthText'] ?? 'Spotify Connect Authorize'}';

    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    mainBloc.getInfo(ip: ip);

    super.initState();
  }

  Widget body({
    required BuildContext context,
    required MainState mainState,
    required String url,
  }) =>
      Column(
        children: [
          Expanded(
            child: mainState.subPageIdle == true
                ? const LoadingIndicatorSmall()
                : WebPageDisplay(
                    title: 'URL: $url',
                    url: url,
                    translations: translations,
                    callbackUrl: callbackUrl),
          ),
          if (Globals.inIosStyle()) const SizedBox(height: 14.0),
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
                '$name : ${translations['spotifyConnectAuthText'] ?? 'Spotify Connect Authorize'}';
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
                  return SizedBox();
                }

                macosVersion = mainState.macosVersion;

                if (Globals.inIosStyle()) {
                  return CupertinoPageScaffold(
                    navigationBar: CupertinoNavigationBar(
                      brightness: Globals.brightness(),
                      middle: Text(title),
                      leading: CupertinoNavigationBarBackButton(),
                    ),
                    child: SafeArea(
                      child: body(
                          context: context, mainState: mainState, url: url),
                    ),
                  );
                }

                return Globals.inMacosStyle()
                    ? PageWithToolbarMacStyle(
                        translations: translations,
                        title: title,
                        standardDesktopSize: standardDesktopSize,
                        macosVersion: macosVersion,
                        body: body(
                            context: context, mainState: mainState, url: url),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      )
                    : PageWithToolbarFlutterStyle(
                        scaffoldKey: scaffoldKey,
                        translations: translations,
                        title: title,
                        sliderDefaultValue: 0.0,
                        showSlider: false,
                        showExpandableSpeedSlider: false,
                        scrollSpeedDevice: 1.0,
                        standardDesktopSize: standardDesktopSize,
                        body: body(
                            context: context, mainState: mainState, url: url),
                        resizeToFullWidth: () {
                          mainBloc.windowResizeToFullWidthAndMinimumHeight(
                              minDesktopSize: minDesktopSize);
                        },
                      );
              });
        });
  }
}
