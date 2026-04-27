import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/config_page.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/info_page.dart';
import 'package:roonmatrix/ui/details/live_control_page.dart';
import 'package:roonmatrix/ui/details/log_page.dart';
import 'package:roonmatrix/ui/details/message_page.dart';
import 'package:roonmatrix/ui/details/mini_player_page.dart';
import 'package:roonmatrix/ui/details/spotify_connect_web_auth_page.dart';
import 'package:roonmatrix/ui/layout/burger_menu.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_page.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';

class BurgerMenuWrapper extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String selectedDeviceIp;
  final Map<String, dynamic> info;
  final Map<String, dynamic> spotifyAuthUrls;
  final AnimationController animationController;
  final double? navigationTop;
  final bool isDrawerOpen;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final Function({required bool visibility}) setDrawerVisibility;

  const BurgerMenuWrapper({
    super.key,
    required this.navigatorKey,
    required this.scaffoldKey,
    required this.selectedDeviceIp,
    required this.info,
    required this.spotifyAuthUrls,
    required this.animationController,
    this.navigationTop,
    required this.isDrawerOpen,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.setDrawerVisibility,
  });

  @override
  State<BurgerMenuWrapper> createState() => _BurgerMenuWrapperState();
}

class _BurgerMenuWrapperState extends State<BurgerMenuWrapper> {
  GlobalKey<NavigatorState> get navigatorKey => widget.navigatorKey;
  GlobalKey<ScaffoldState> get scaffoldKey => widget.scaffoldKey;
  AnimationController get animationController => widget.animationController;
  double? get navigationTop => widget.navigationTop;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  Function({required bool visibility}) get setDrawerVisibility =>
      widget.setDrawerVisibility;

  final double navigationTopFallback = 84.0;
  final double navigationTopOffset = -40.0;
  final double navigationLeftOffset = 16.0;

  Map<String, dynamic> translations = {};
  String aboutAppMessage = '';
  bool translationsLoaded = false;

  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late SettingsBloc settingsBloc;
  late bool isDrawerOpen;

  @override
  void initState() {
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    isDrawerOpen = widget.isDrawerOpen;

    super.initState();
  }

  @override
  void didUpdateWidget(BurgerMenuWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    isDrawerOpen = widget.isDrawerOpen;
  }

  Future<void> openBurgerMenuItem({
    required String? key,
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
    required Map<String, dynamic> spotifyAuthUrls,
    required BuildContext context,
  }) async {
    if (key == 'about') {
      SharedWidgets.openAboutModal(
        context: context,
        aboutAppMessage: aboutAppMessage,
        translations: translations,
      );
    }
    if (key == 'settings') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        asDialog: true,
        page: SettingsPage(
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
    if (key == 'backToMain') {
      if (navigatorKey.currentState != null &&
          navigatorKey.currentState!.canPop()) {
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    }
    if (key == 'selectDeviceBefore') {
      mainBloc.selectDeviceBefore(ip: selectedDeviceIp);
    }
    if (key == 'selectDeviceNext') {
      mainBloc.selectDeviceNext(ip: selectedDeviceIp);
    }
    if (key == 'spotifyConnectAuth') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: SpotifyConnectWebAuthPage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          url: spotifyAuthUrls[selectedDeviceIp] ?? '*',
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
          callbackUrl: ({required String url}) => mainBloc
              .setSpotifyAuthRedirectUrl(ip: selectedDeviceIp, url: url),
        ),
      );
    }
    if (key == 'config') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: ConfigPage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
          close: () {
            Navigator.pop(context);
          },
        ),
      );
    }
    if (key == 'control') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: CoverPage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          translations: translations,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
    if (key == 'message') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: MessagePage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
    if (key == 'liveControl') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: LiveControlPage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
    if (key == 'monitoring') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: InfoPage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
    if (key == 'log') {
      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: LogPage(
          name: info[selectedDeviceIp]['name'],
          ip: selectedDeviceIp,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
    if (key == 'miniPlayer' && Globals.isDesktopDevice()) {
      bool miniPlayerAlwaysOnTop = settingsBloc.state.miniPlayerAlwaysOnTop;
      bool miniPlayerPreventCloseApp =
          settingsBloc.state.miniPlayerPreventCloseApp;
      bool miniPlayerShowTextInfoOnTrackChange =
          settingsBloc.state.miniPlayerShowTextInfoOnTrackChange;
      int miniPlayerTextInfoDuration =
          settingsBloc.state.miniPlayerTextInfoDuration;

      Map<String, dynamic> i = info[selectedDeviceIp];
      String controlId = i['control_id'];
      String zoneName = '-';
      if (i['channels'] != null && i['channels'][controlId] != null) {
        if (i['channels'][controlId] == 'webserver' ||
            i['channels'][controlId] == 'spotifyconnect') {
          zoneName = controlId;
        } else {
          zoneName = i['channels'][controlId];
        }
      }

      SharedWidgets.openPage(
        context: context,
        navigatorKey: navigatorKey,
        page: MiniPlayerPage(
          name: zoneName,
          ip: selectedDeviceIp,
          controlId: info['control_id'],
          miniPlayerAlwaysOnTop: miniPlayerAlwaysOnTop,
          miniPlayerPreventCloseApp: miniPlayerPreventCloseApp,
          miniPlayerShowTextInfoOnTrackChange:
              miniPlayerShowTextInfoOnTrackChange,
          miniPlayerTextInfoDuration: miniPlayerTextInfoDuration,
          translations: translations,
          minDesktopSize: minDesktopSize,
          standardDesktopSize: standardDesktopSize,
        ),
      );
    }
  }

  Widget burgerMenuRaw({
    required String selectedDeviceIp,
    required Map<String, dynamic> info,
    required Map<String, dynamic> spotifyAuthUrls,
    required bool noPop,
    required BuildContext context,
  }) {
    return BurgerMenu(
      key: ValueKey('BurgerMenu-$selectedDeviceIp-${Globals.brightness()}'),
      translations: translations,
      selectedDeviceIp: selectedDeviceIp,
      info: info,
      spotifyAuthUrls: spotifyAuthUrls,
      noPop: noPop,
      navigationTop: navigationTop,
      onClose:
          ({
            required String? key,
            required String selectedDeviceIp,
            required Map<String, dynamic> info,
          }) async {
            if (mounted) {
              setState(() {
                isDrawerOpen = false;
                setDrawerVisibility(visibility: isDrawerOpen);
                animationController.reverse();
              });
            }

            SchedulerBinding.instance.addPostFrameCallback((_) async {
              await openBurgerMenuItem(
                key: key,
                selectedDeviceIp: selectedDeviceIp,
                info: info,
                spotifyAuthUrls: spotifyAuthUrls,
                context: context,
              );
            });
          },
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder(
    bloc: translationsBloc,
    builder: (context, TranslationsState translationsState) {
      if (translationsState is TranslationsStateLoaded) {
        translations = translationsState.translations;
        aboutAppMessage = translationsState.aboutAppMessage;
        translationsLoaded = translationsState.translationsLoaded;
      }

      if (translationsState is! TranslationsStateLoaded ||
          !translationsLoaded) {
        return const SizedBox();
      }

      return Globals.inIosStyle()
          ? burgerMenuRaw(
              selectedDeviceIp: widget.selectedDeviceIp,
              info: widget.info,
              spotifyAuthUrls: widget.spotifyAuthUrls,
              noPop: true,
              context: context,
            )
          : Drawer(
              child: Stack(
                children: [
                  burgerMenuRaw(
                    selectedDeviceIp: widget.selectedDeviceIp,
                    info: widget.info,
                    spotifyAuthUrls: widget.spotifyAuthUrls,
                    noPop: false,
                    context: context,
                  ),
                  Positioned(
                    top:
                        (navigationTop ?? navigationTopFallback) +
                        navigationTopOffset,
                    left: navigationLeftOffset,
                    child: InkWell(
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () {
                        if (mounted) {
                          setState(() {
                            isDrawerOpen = false;
                            scaffoldKey.currentState?.openEndDrawer();
                          });
                        }
                      },
                      child: Icon(
                        CupertinoIcons.clear,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
    },
  );
}
