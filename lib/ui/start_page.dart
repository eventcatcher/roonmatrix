import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/scroll_speed_variant.dart';
import 'package:roonmatrix/ui/layout/search_field.dart';
import 'package:roonmatrix/ui/helper/lifecycle_page_wrapper.dart';
import 'package:roonmatrix/ui/layout/burger_menu_wrapper.dart';
import 'package:roonmatrix/ui/layout/cover_row_animation.dart';
import 'package:roonmatrix/ui/layout/debug_message_card.dart';
import 'package:roonmatrix/ui/layout/device_list_item.dart';
import 'package:roonmatrix/ui/layout/devices_reload_button.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator_big.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_ios_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/zone_start_buttons.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:roonmatrix/ui/helper/string_extension.dart';

class StartPage extends StatefulWidget {
  final String title;
  final Size minDesktopSize;
  final Size standardDesktopSize;

  const StartPage({
    super.key,
    required this.title,
    required this.minDesktopSize,
    required this.standardDesktopSize,
  });

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> with TickerProviderStateMixin {
  String get title => widget.title;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;

  final GlobalKey windowKey = GlobalKey();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey itemListKey = GlobalKey();
  final double exportButtonPaddingIos = 14.0;
  final bool showExpandableSpeedSlider = false;
  final drawerOffsetToHide = -240.0;

  Map<String, dynamic> translations = {};
  Map<String, ConfigDefinition> definitions = {};

  Orientation orientation = Orientation.portrait;
  Map<String, dynamic> scrollSpeedDeviceMap = {};
  String activeIp = '';
  double width = 1280;
  double height = 768;
  double scrollSpeedDevice = 1.0;
  double? appBarHeight;
  double? navigationTop;

  bool translationsLoaded = false;
  bool saveIdle = false;
  bool settingsPageLoaded = false;
  bool isDrawerOpen = false;
  bool showExportButton = true;

  late SettingsBloc settingsBloc;
  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;
  late AnimationController animationController;

  @override
  void initState() {
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    translationsBloc = BlocProvider.of<TranslationsBloc>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    animationController.dispose();
  }

  void updateSizes(String caller) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    showExportButton = (Globals.isMobileDevice() &&
            orientation == Orientation.portrait) ||
        (Globals.isDesktopDevice() && height > (minDesktopSize.height + 75));
    // if (kDebugMode) {
    //   debugPrint(
    //       'StartPage/updateSizes => caller: $caller, width: $width, height: $height');
    // }
  }

  Widget body() => AppLifecyclePageWrapper(
        onResume: () {
          if (kDebugMode) {
            debugPrint('AppLifecycle => onResume');
          }
          if (Globals.isMobileDevice() == true) {
            mainBloc.resetWebSocketServices();
          }
          WidgetsBinding.instance.addPostFrameCallback((timestamp) {
            mainBloc.restartPollingTimer();
            mainBloc.searching(idle: Globals.isMobileDevice());
          });
        },
        child: BlocBuilder(
            bloc: translationsBloc,
            builder: (context, TranslationsState translationsState) {
              if (translationsState is TranslationsStateLoaded) {
                translations = translationsState.translations;
                translationsLoaded = translationsState.translationsLoaded;
              }

              if (translationsState is! TranslationsStateLoaded ||
                  !translationsLoaded) {
                return const SizedBox();
              }

              return BlocBuilder(
                  bloc: settingsBloc,
                  builder: (context, SettingsState settingsState) {
                    if (settingsState is! SettingsStateLoaded) {
                      return SizedBox();
                    }

                    bool moreInfo = settingsState.moreInfo;
                    bool coverRowActive = settingsState.coverRowActive;
                    bool coverRowArtist = settingsState.coverRowArtist;
                    bool coverRowAlbum = settingsState.coverRowAlbum;
                    bool coverRowTrack = settingsState.coverRowTrack;
                    bool coverRowDynamicSize =
                        settingsState.coverRowDynamicSize;
                    bool verticalTickerActive =
                        settingsState.verticalTickerActive;
                    bool ledTickerInDeviceListActive =
                        settingsState.ledTickerInDeviceListActive;
                    bool ledTickerOnTickerPageActive =
                        settingsState.ledTickerOnTickerPageActive;
                    bool ledTickerPixelShiftActive =
                        settingsState.ledTickerPixelShiftActive;
                    bool forceTickerUpdateActive =
                        settingsState.forceTickerUpdateActive;
                    bool miniPlayerAlwaysOnTop =
                        settingsState.miniPlayerAlwaysOnTop;
                    bool miniPlayerPreventCloseApp =
                        settingsState.miniPlayerPreventCloseApp;
                    bool miniPlayerShowTextInfoOnTrackChange =
                        settingsState.miniPlayerShowTextInfoOnTrackChange;
                    int miniPlayerTextInfoDuration =
                        settingsState.miniPlayerTextInfoDuration;

                    scrollSpeedDeviceMap = settingsState.scrollSpeedDeviceMap;

                    return BlocBuilder(
                        bloc: mainBloc,
                        builder: (context, MainState mainState) {
                          if (kDebugMode) {
                            debugPrint(
                                'StartPage => mainState event $mainState @ ${DateTime.now().toLocal()}');
                          }
                          if (mainState is! MainStateLoaded) {
                            return SizedBox();
                          }

                          updateSizes('NotificationListener');

                          if ((mainState.ipStart == null ||
                                  mainState.ipEnd == null) &&
                              !settingsPageLoaded) {
                            settingsPageLoaded = true;
                            SharedWidgets.openSettingsPage(
                              context: context,
                              minDesktopSize: minDesktopSize,
                              standardDesktopSize: standardDesktopSize,
                            );
                          }

                          List<String> devices = mainBloc.getFilteredDevices();
                          String? activeDeviceIp = mainState.activeDeviceIp;
                          Map<String, dynamic> info = mainState.info;
                          Map<String, dynamic> spotifyAuthUrls =
                              mainState.spotifyAuthUrls;
                          bool idle = mainState.idle;
                          Map<String, bool> connected = mainState.connected;
                          Map<String, bool> ping = mainState.ping;
                          definitions = mainState.definitions;

                          if (kDebugMode) {
                            debugPrint(
                                'StartPage/body => state changed => rebuild, devices: ${devices.length}, idle: $idle');
                          }
                          return OrientationBuilder(
                              builder: (BuildContext context, Orientation o) {
                            if (o != orientation) {
                              orientation = o;
                              SchedulerBinding.instance
                                  .addPostFrameCallback((_) async {
                                if (mounted) {
                                  setState(() {
                                    orientation = o;
                                  });
                                }
                              });
                            }

                            double deviceWidth =
                                MediaQuery.of(context).size.width;
                            bool isSmallDeviceWidth = deviceWidth < 700;

                            return Container(
                              key: windowKey,
                              color: ColorDefs.windowBackgroundColor(
                                  context: context),
                              child: Center(
                                child: Column(
                                  children: <Widget>[
                                    // if (devices.isNotEmpty) // && kDebugMode
                                    //   Text(
                                    //       'new info @ ${DateTime.now().toLocal()}): ${mainBloc.replaceIllegalCharsInTickerString(str: info[devices[0]]['app_displaystr'] ?? 'empty')}',
                                    //       style: TextStyle(fontSize: 10.0)),

                                    // searchfield area
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                        right: 8.0,
                                      ),
                                      child: Wrap(
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.start,
                                        direction: Axis.horizontal,
                                        children: [
                                          SearchField(
                                            type: 'main',
                                            controller:
                                                mainBloc.getSearchController(
                                                    type: 'main'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (mainState.logMessage.isNotEmpty)
                                      DebugMessageCard(
                                        translations: translations,
                                        logMessage: mainState.logMessage,
                                      ),
                                    Expanded(
                                      flex: 1,
                                      child: idle == true
                                          ? LoadingIndicatorBig(
                                              message:
                                                  translations['scanMessage'] ??
                                                      'scan for devices')
                                          : devices.isEmpty
                                              ? DevicesReloadButton(
                                                  translations: translations)
                                              : mainState
                                                      .disableListItemsRendering
                                                  ? SizedBox()
                                                  : ListView.separated(
                                                      key: ValueKey(
                                                          'DeviceList-${devices.length}'),
                                                      separatorBuilder:
                                                          (context, index) =>
                                                              const Divider(
                                                                color: Colors
                                                                    .white,
                                                                height: 1,
                                                              ),
                                                      itemCount: devices.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        String ip =
                                                            devices[index];
                                                        bool connectedItem =
                                                            connected[ip] ??
                                                                false;
                                                        bool pingItem =
                                                            ping[ip] ?? false;
                                                        bool verticalOutput = activeIp
                                                                    .isNotEmpty &&
                                                                mainBloc.state
                                                                            .info[
                                                                        activeIp] !=
                                                                    null
                                                            ? mainBloc.state
                                                                            .info[
                                                                        activeIp]
                                                                    [
                                                                    'vertical_output'] ??
                                                                false
                                                            : false;

                                                        String scrollSpeedKey =
                                                            settingsBloc
                                                                .getScrollSpeedKey(
                                                          ip: ip,
                                                          variant:
                                                              ScrollSpeedVariant(
                                                            isStandAlone: false,
                                                            isLedVariant:
                                                                ledTickerInDeviceListActive,
                                                            isVertical:
                                                                verticalTickerActive &&
                                                                    verticalOutput,
                                                          ),
                                                        );
                                                        String
                                                            scrollSpeedStandAloneKey =
                                                            settingsBloc
                                                                .getScrollSpeedKey(
                                                          ip: ip,
                                                          variant:
                                                              ScrollSpeedVariant(
                                                            isStandAlone: true,
                                                            isLedVariant:
                                                                ledTickerOnTickerPageActive,
                                                            isVertical:
                                                                verticalTickerActive &&
                                                                    verticalOutput,
                                                          ),
                                                        );

                                                        return GestureDetector(
                                                          behavior:
                                                              HitTestBehavior
                                                                  .translucent,
                                                          onTap: () {
                                                            setState(() {
                                                              activeIp = ip;
                                                            });
                                                          },
                                                          child: DeviceListItem(
                                                            itemListKey:
                                                                itemListKey,
                                                            index: index,
                                                            width: width,
                                                            height: height,
                                                            orientation:
                                                                orientation,
                                                            minDesktopSize:
                                                                minDesktopSize,
                                                            standardDesktopSize:
                                                                standardDesktopSize,
                                                            translations:
                                                                translations,
                                                            ip: ip,
                                                            activeIp: activeIp,
                                                            connected:
                                                                connectedItem,
                                                            ping: pingItem,
                                                            showSlider:
                                                                definitions
                                                                    .containsKey(
                                                                        ip),
                                                            info: info,
                                                            spotifyAuthUrl:
                                                                spotifyAuthUrls[
                                                                        ip] ??
                                                                    '*',
                                                            isSmallDeviceWidth:
                                                                isSmallDeviceWidth,
                                                            moreInfo: moreInfo,
                                                            scrollSpeedScrollMatrix:
                                                                scrollSpeedDeviceMap[
                                                                        scrollSpeedStandAloneKey] ??
                                                                    1.0,
                                                            scrollSpeedDevice:
                                                                scrollSpeedDeviceMap[
                                                                        scrollSpeedKey] ??
                                                                    scrollSpeedDevice,
                                                            verticalTickerActive:
                                                                verticalTickerActive,
                                                            ledTickerInDeviceListActive:
                                                                ledTickerInDeviceListActive,
                                                            ledTickerOnTickerPageActive:
                                                                ledTickerOnTickerPageActive,
                                                            ledTickerPixelShiftActive:
                                                                ledTickerPixelShiftActive,
                                                            forceTickerUpdateActive:
                                                                forceTickerUpdateActive,
                                                            updateSizes:
                                                                updateSizes,
                                                          ),
                                                        );
                                                      }),
                                    ),

                                    if (Globals.isDesktopDevice() &&
                                        devices.isNotEmpty &&
                                        coverRowActive == true)
                                      CoverRowAnimation(
                                        viewData: View.of(context),
                                        mediaQueryData: MediaQuery.of(context),
                                        orientation: orientation,
                                        translations: translations,
                                        devices: devices,
                                        activeDeviceIp: activeDeviceIp,
                                        info: info,
                                        appBarHeight: appBarHeight,
                                        coverRowArtist: coverRowArtist,
                                        coverRowAlbum: coverRowAlbum,
                                        coverRowTrack: coverRowTrack,
                                        coverRowDynamicSize:
                                            coverRowDynamicSize,
                                        miniPlayerAlwaysOnTop:
                                            miniPlayerAlwaysOnTop,
                                        miniPlayerPreventCloseApp:
                                            miniPlayerPreventCloseApp,
                                        miniPlayerShowTextInfoOnTrackChange:
                                            miniPlayerShowTextInfoOnTrackChange,
                                        miniPlayerTextInfoDuration:
                                            miniPlayerTextInfoDuration,
                                        showExportButton: showExportButton,
                                        minDesktopSize: minDesktopSize,
                                        standardDesktopSize:
                                            standardDesktopSize,
                                      ),
                                    if (Globals.isMobileDevice() &&
                                        devices.isNotEmpty &&
                                        coverRowActive == true)
                                      Stack(
                                        children: [
                                          CoverRowAnimation(
                                            viewData: View.of(context),
                                            mediaQueryData:
                                                MediaQuery.of(context),
                                            orientation: orientation,
                                            translations: translations,
                                            devices: devices,
                                            activeDeviceIp: activeDeviceIp,
                                            info: info,
                                            appBarHeight: appBarHeight,
                                            coverRowArtist: coverRowArtist,
                                            coverRowAlbum: coverRowAlbum,
                                            coverRowTrack: coverRowTrack,
                                            coverRowDynamicSize:
                                                coverRowDynamicSize,
                                            miniPlayerAlwaysOnTop:
                                                miniPlayerAlwaysOnTop,
                                            miniPlayerPreventCloseApp:
                                                miniPlayerPreventCloseApp,
                                            miniPlayerShowTextInfoOnTrackChange:
                                                miniPlayerShowTextInfoOnTrackChange,
                                            miniPlayerTextInfoDuration:
                                                miniPlayerTextInfoDuration,
                                            showExportButton: showExportButton,
                                            minDesktopSize: minDesktopSize,
                                            standardDesktopSize:
                                                standardDesktopSize,
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: ZoneStartButtons(
                                              translations: translations,
                                              deviceWidth:
                                                  MediaQuery.of(context)
                                                      .size
                                                      .width,
                                              orientation: orientation,
                                              info: info,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (Globals.inIosStyle() &&
                                        orientation == Orientation.portrait)
                                      SizedBox(height: exportButtonPaddingIos),

                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: Globals.isDesktopDevice()
                                              ? 16.0
                                              : 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (showExportButton == true)
                                            Padding(
                                              padding: EdgeInsets.only(
                                                  right:
                                                      Globals.isDesktopDevice() &&
                                                              devices
                                                                  .isNotEmpty &&
                                                              coverRowActive ==
                                                                  true
                                                          ? 0.0
                                                          : 8.0),
                                              child: IconTextButtonElement(
                                                onMacAsText: true,
                                                icon: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                                  child: Icon(
                                                    Icons.download,
                                                    color: Colors.white,
                                                    size: 20.0,
                                                  ),
                                                ),
                                                label: (translations[
                                                            'exportButtonText'] ??
                                                        'export')
                                                    .toString()
                                                    .toFirstUpper,
                                                onPressed:
                                                    saveIdle == true ||
                                                            idle == true ||
                                                            devices.isEmpty
                                                        ? null
                                                        : () async {
                                                            setState(() {
                                                              saveIdle = true;
                                                            });
                                                            bool? valid =
                                                                await mainBloc
                                                                    .exportDevicesData();
                                                            setState(() {
                                                              saveIdle = false;
                                                            });
                                                            if (valid == null) {
                                                              return;
                                                            }

                                                            SharedWidgets
                                                                .showSnackBar(
                                                                    // ignore: use_build_context_synchronously
                                                                    context:
                                                                        context,
                                                                    doneMessage:
                                                                        translations['exportDoneMessage'] ??
                                                                            'export successfully done',
                                                                    failMessage:
                                                                        translations['exportFailedMessage'] ??
                                                                            'export failed!',
                                                                    valid:
                                                                        valid);
                                                          },
                                              ),
                                            ),
                                          if (Globals.isDesktopDevice() &&
                                              devices.isNotEmpty &&
                                              coverRowActive == true)
                                            Expanded(
                                              child: Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: ZoneStartButtons(
                                                  translations: translations,
                                                  deviceWidth:
                                                      MediaQuery.of(context)
                                                          .size
                                                          .width,
                                                  orientation: orientation,
                                                  info: info,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (Globals.inIosStyle() &&
                                        orientation == Orientation.portrait)
                                      SizedBox(height: exportButtonPaddingIos),
                                  ],
                                ),
                              ),
                            );
                          });
                        });
                  });
            }),
      );

  Widget bodyWithMenuDrawerOverlay(BuildContext context) => Stack(
        children: [
          SafeArea(
            child: body(),
          ),
          if (isDrawerOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    isDrawerOpen = false;
                    animationController.reverse();
                  });
                },
              ),
            ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeIn,
            top: navigationTop,
            bottom: 0.0,
            left: isDrawerOpen ? 0 : drawerOffsetToHide,
            child: Container(
              width: 230,
              //height: double.infinity,
              decoration: BoxDecoration(
                color: ColorDefs.windowBackgroundColor(context: context),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 5.0,
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                height: height,
                color: Colors.transparent, // background color of burger menu
                child: BurgerMenuWrapper(
                    scaffoldKey: scaffoldKey,
                    animationController: animationController,
                    navigationTop: navigationTop,
                    isDrawerOpen: isDrawerOpen,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    setDrawerVisibility: ({required bool visibility}) {
                      setState(() {
                        isDrawerOpen = visibility;
                      });
                    }),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (Globals.inIosStyle()) {
      return BlocBuilder(
          bloc: settingsBloc,
          builder: (context, SettingsState settingsState) {
            if (settingsState is! SettingsStateLoaded) {
              return SizedBox();
            }

            scrollSpeedDeviceMap = settingsState.scrollSpeedDeviceMap;

            bool ledTickerInDeviceListActive =
                settingsState.ledTickerInDeviceListActive;
            bool verticalTickerActive = settingsState.verticalTickerActive;
            bool verticalOutput =
                activeIp.isNotEmpty && mainBloc.state.info[activeIp] != null
                    ? mainBloc.state.info[activeIp]['vertical_output'] ?? false
                    : false;
            String scrollSpeedKey = settingsBloc.getScrollSpeedKey(
              ip: activeIp,
              variant: ScrollSpeedVariant(
                isStandAlone: false,
                isLedVariant: ledTickerInDeviceListActive,
                isVertical: verticalTickerActive && verticalOutput,
              ),
            );
            List<dynamic> list = mainBloc.getScrollDelayMinMax(
              ip: activeIp,
              verticalOutput: verticalOutput,
              verticalTickerActive: verticalTickerActive,
            );
            double sliderDefaultValue = list[3];

            return PageWithToolbarIosStyle(
              title: title,
              sliderDefaultValue: sliderDefaultValue,
              showSlider:
                  Globals.isMobileDevice() && definitions.containsKey(activeIp),
              showExpandableSpeedSlider: showExpandableSpeedSlider,
              scrollSpeedDevice: scrollSpeedDeviceMap[scrollSpeedKey] ?? 1.0,
              animationController: animationController,
              isDrawerOpen: isDrawerOpen,
              body: bodyWithMenuDrawerOverlay(context),
              sliderUpdateValue: activeIp.isNotEmpty
                  ? ({required double speed}) {
                      setState(() {
                        if (activeIp.isNotEmpty) {
                          scrollSpeedDeviceMap[scrollSpeedKey] = speed;
                        }
                        scrollSpeedDevice = speed;
                        settingsBloc.setScrollSpeedDevice(
                            key: scrollSpeedKey, speed: speed);
                      });
                    }
                  : null,
              setAppBarHeight: ({required double height}) {
                appBarHeight = height;
                navigationTop =
                    appBarHeight! + MediaQuery.of(context).padding.top;
              },
              setDrawerState: ({required bool open}) {
                setState(() {
                  isDrawerOpen = open;
                });
              },
            );
          });
    }

    if (Globals.inMacosStyle()) {
      return BlocBuilder(
          bloc: mainBloc,
          builder: (context, MainState mainState) {
            if (mainState is! MainStateLoaded) {
              return SizedBox();
            }

            return PageWithToolbarMacStyle(
              translations: translations,
              title: title,
              standardDesktopSize: standardDesktopSize,
              macosVersion: mainState.macosVersion,
              body: body(),
              resizeToFullWidth: () {
                mainBloc.windowResizeToFullWidthAndMinimumHeight(
                    minDesktopSize: minDesktopSize);
              },
            );
          });
    }

    return BlocBuilder(
        bloc: settingsBloc,
        builder: (context, SettingsState settingsState) {
          if (settingsState is! SettingsStateLoaded) {
            return SizedBox();
          }

          scrollSpeedDeviceMap = settingsState.scrollSpeedDeviceMap;

          bool ledTickerInDeviceListActive =
              settingsState.ledTickerInDeviceListActive;
          bool verticalTickerActive = settingsState.verticalTickerActive;
          bool verticalOutput =
              activeIp.isNotEmpty && mainBloc.state.info[activeIp] != null
                  ? mainBloc.state.info[activeIp]['vertical_output'] ?? false
                  : false;
          String scrollSpeedKey = settingsBloc.getScrollSpeedKey(
            ip: activeIp,
            variant: ScrollSpeedVariant(
              isStandAlone: false,
              isLedVariant: ledTickerInDeviceListActive,
              isVertical: verticalTickerActive && verticalOutput,
            ),
          );
          List<dynamic> list = mainBloc.getScrollDelayMinMax(
            ip: activeIp,
            verticalOutput: verticalOutput,
            verticalTickerActive: verticalTickerActive,
          );
          double sliderDefaultValue = list[3];

          return PageWithToolbarFlutterStyle(
            scaffoldKey: scaffoldKey,
            translations: translations,
            title: title,
            sliderDefaultValue: sliderDefaultValue,
            showSlider:
                Globals.isMobileDevice() && definitions.containsKey(activeIp),
            showExpandableSpeedSlider: showExpandableSpeedSlider,
            scrollSpeedDevice:
                scrollSpeedDeviceMap[scrollSpeedKey] ?? scrollSpeedDevice,
            standardDesktopSize: standardDesktopSize,
            drawer:
                Globals.inIosStyle() || Platform.isAndroid || Platform.isFuchsia
                    ? BurgerMenuWrapper(
                        scaffoldKey: scaffoldKey,
                        animationController: animationController,
                        navigationTop: navigationTop,
                        isDrawerOpen: isDrawerOpen,
                        minDesktopSize: minDesktopSize,
                        standardDesktopSize: standardDesktopSize,
                        setDrawerVisibility: ({required bool visibility}) {
                          setState(() {
                            isDrawerOpen = visibility;
                          });
                        })
                    : null,
            body: body(),
            resizeToFullWidth: () {
              mainBloc.windowResizeToFullWidthAndMinimumHeight(
                  minDesktopSize: minDesktopSize);
            },
            sliderUpdateValue: activeIp.isNotEmpty
                ? ({required double speed}) {
                    setState(() {
                      if (activeIp.isNotEmpty) {
                        scrollSpeedDeviceMap[scrollSpeedKey] = speed;
                      }
                      scrollSpeedDevice = speed;
                      settingsBloc.setScrollSpeedDevice(
                          key: scrollSpeedKey, speed: speed);
                    });
                  }
                : null,
            setAppBarHeight: ({required double height}) {
              if (Platform.isAndroid || Platform.isFuchsia) {
                appBarHeight = height;
                navigationTop =
                    appBarHeight! + MediaQuery.of(context).padding.top;
              }
            },
          );
        });
  }
}
