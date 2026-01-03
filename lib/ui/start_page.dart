import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/helper/lifecycle_page_wrapper.dart';
import 'package:roonmatrix/ui/layout/burger_menu_wrapper.dart';
import 'package:roonmatrix/ui/layout/cover_row_animation.dart';
import 'package:roonmatrix/ui/layout/debug_message_card.dart';
import 'package:roonmatrix/ui/layout/device_list_item.dart';
import 'package:roonmatrix/ui/layout/devices_reload_button.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
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
import 'package:window_manager/window_manager.dart';

class StartPage extends StatefulWidget {
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final String title;

  const StartPage({
    super.key,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.title,
  });

  @override
  State<StartPage> createState() => StartPageState();
}

class StartPageState extends State<StartPage> with TickerProviderStateMixin {
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  String get title => widget.title;
  bool showExportButton = true;

  final GlobalKey windowKey = GlobalKey();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey itemListKey = GlobalKey();

  final double exportButtonPaddingIos = 14.0;
  final bool showExpandableSpeedSlider = false;

  Map<String, dynamic> translations = {};

  Orientation orientation = Orientation.portrait;
  double width = 1280;
  double height = 768;
  double scrollSpeedDevice = 1.0;
  double scrollSpeedScrollMatrix = 1.0;
  double? appBarHeight;
  double? navigationTop;

  bool translationsLoaded = false;
  bool saveIdle = false;
  bool settingsPageLoaded = false;
  bool isDrawerOpen = false;

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
    showExportButton = (SharedWidgets.isMobileDevice() &&
            orientation == Orientation.portrait) ||
        (SharedWidgets.isDesktopDevice() &&
            height > (minDesktopSize.height + 75));
    // if (kDebugMode) {
    //   debugPrint(
    //       'StartPage/updateSizes => caller: $caller, width: $width, height: $height');
    // }
  }

  body() => AppLifecyclePageWrapper(
        onResume: () {
          if (kDebugMode) {
            debugPrint('AppLifecycle => onResume');
          }
          if (SharedWidgets.isMobileDevice() == true) {
            mainBloc.resetWebSocketServices();
          }
          WidgetsBinding.instance.addPostFrameCallback((timestamp) {
            mainBloc.restartPollingTimer();
            mainBloc.searching(idle: SharedWidgets.isMobileDevice());
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
                    bool coverRowActiv = settingsState.coverRowActiv;
                    bool coverRowArtist = settingsState.coverRowArtist;
                    bool coverRowAlbum = settingsState.coverRowAlbum;
                    bool coverRowTrack = settingsState.coverRowTrack;
                    bool coverRowDynamicSize =
                        settingsState.coverRowDynamicSize;

                    scrollSpeedDevice = settingsState.scrollSpeedDevice;
                    scrollSpeedScrollMatrix =
                        settingsState.scrollSpeedScrollMatrix;

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
                            SharedWidgets.openSettingsPage(context);
                          }

                          List<String> devices = mainBloc.getFilteredDevices();
                          Map<String, dynamic> info = mainState.info;
                          Map<String, dynamic> spotifyAuthUrls =
                              mainState.spotifyAuthUrls;
                          bool idle = mainState.idle;

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
                              color: SharedWidgets.windowBackgroundColor(
                                  context: context),
                              child: Center(
                                child: Column(
                                  children: <Widget>[
                                    // if (devices.isNotEmpty) // && kDebugMode
                                    //   Text(
                                    //       'new info @ ${DateTime.now().toLocal()}): ${mainBloc.replaceIllegalCharsInTickerString(info[devices[0]]['app_displaystr'] ?? 'empty')}',
                                    //       style: TextStyle(fontSize: 10.0)),

                                    // searchfield area
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 8.0, right: 8.0),
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
                                              : ListView.separated(
                                                  key: ValueKey(
                                                      'deviceList${devices.length}'),
                                                  separatorBuilder:
                                                      (context, index) =>
                                                          const Divider(
                                                            color: Colors.white,
                                                            height: 1,
                                                          ),
                                                  itemCount: devices.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    String ip = devices[index];

                                                    return DeviceListItem(
                                                      itemListKey: itemListKey,
                                                      index: index,
                                                      width: width,
                                                      height: height,
                                                      orientation: orientation,
                                                      minDesktopSize:
                                                          minDesktopSize,
                                                      translations:
                                                          translations,
                                                      ip: ip,
                                                      info: info,
                                                      spotifyAuthUrl:
                                                          spotifyAuthUrls[ip] ??
                                                              '*',
                                                      isSmallDeviceWidth:
                                                          isSmallDeviceWidth,
                                                      moreInfo: moreInfo,
                                                      scrollSpeedScrollMatrix:
                                                          scrollSpeedScrollMatrix,
                                                      scrollSpeedDevice:
                                                          scrollSpeedDevice,
                                                      updateSizes: updateSizes,
                                                    );
                                                  }),
                                    ),

                                    if (SharedWidgets.isDesktopDevice() &&
                                        devices.isNotEmpty &&
                                        coverRowActiv == true)
                                      CoverRowAnimation(
                                        viewData: View.of(context),
                                        mediaQueryData: MediaQuery.of(context),
                                        orientation: orientation,
                                        translations: translations,
                                        devices: devices,
                                        info: info,
                                        appBarHeight: appBarHeight,
                                        coverRowArtist: coverRowArtist,
                                        coverRowAlbum: coverRowAlbum,
                                        coverRowTrack: coverRowTrack,
                                        coverRowDynamicSize:
                                            coverRowDynamicSize,
                                        showExportButton: showExportButton,
                                      ),
                                    if (SharedWidgets.isMobileDevice() &&
                                        devices.isNotEmpty &&
                                        coverRowActiv == true)
                                      Stack(
                                        children: [
                                          CoverRowAnimation(
                                            viewData: View.of(context),
                                            mediaQueryData:
                                                MediaQuery.of(context),
                                            orientation: orientation,
                                            translations: translations,
                                            devices: devices,
                                            info: info,
                                            appBarHeight: appBarHeight,
                                            coverRowArtist: coverRowArtist,
                                            coverRowAlbum: coverRowAlbum,
                                            coverRowTrack: coverRowTrack,
                                            coverRowDynamicSize:
                                                coverRowDynamicSize,
                                            showExportButton: showExportButton,
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
                                    if (SharedWidgets.inIosStyle() &&
                                        orientation == Orientation.portrait)
                                      SizedBox(height: exportButtonPaddingIos),

                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical:
                                              SharedWidgets.isDesktopDevice()
                                                  ? 16.0
                                                  : 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (showExportButton == true)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8.0),
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
                                                label: translations[
                                                        'exportButtonText'] ??
                                                    'export',
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
                                          if (SharedWidgets.isDesktopDevice() &&
                                              devices.isNotEmpty &&
                                              coverRowActiv == true)
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
                                    if (SharedWidgets.inIosStyle() &&
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

  bodyWithMenuDrawerOverlay(BuildContext context) => Stack(
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
            left: isDrawerOpen ? 0 : -240,
            child: Container(
              width: 230,
              height: double.infinity,
              decoration: BoxDecoration(
                color: SharedWidgets.windowBackgroundColor(context: context),
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

    if (SharedWidgets.inIosStyle()) {
      return BlocBuilder(
          bloc: settingsBloc,
          builder: (context, SettingsState settingsState) {
            if (settingsState is! SettingsStateLoaded) {
              return SizedBox();
            }

            scrollSpeedDevice = settingsState.scrollSpeedDevice;

            return PageWithToolbarIosStyle(
              title: title,
              showExpandableSpeedSlider: showExpandableSpeedSlider,
              scrollSpeedDevice: scrollSpeedDevice,
              animationController: animationController,
              isDrawerOpen: isDrawerOpen,
              body: bodyWithMenuDrawerOverlay(context),
              resizeToFullWidth: () {
                mainBloc.windowResizeToFullWidthAndMinimumHeight(
                    minDesktopSize: minDesktopSize);
              },
              sliderUpdateValue: ({required double speed}) {
                setState(() {
                  scrollSpeedDevice = speed;
                  settingsBloc.setScrollSpeedDevice(speed: speed);
                });
              },
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

    if (SharedWidgets.inMacosStyle()) {
      return PageWithToolbarMacStyle(
        title: title,
        standardDesktopSize: standardDesktopSize,
        windowManager: windowManager,
        body: body(),
        resizeToFullWidth: () {
          mainBloc.windowResizeToFullWidthAndMinimumHeight(
              minDesktopSize: minDesktopSize);
        },
      );
    }

    return BlocBuilder(
        bloc: settingsBloc,
        builder: (context, SettingsState settingsState) {
          if (settingsState is! SettingsStateLoaded) {
            return SizedBox();
          }

          scrollSpeedDevice = settingsState.scrollSpeedDevice;

          return PageWithToolbarFlutterStyle(
            scaffoldKey: scaffoldKey,
            title: title,
            showExpandableSpeedSlider: showExpandableSpeedSlider,
            scrollSpeedDevice: scrollSpeedDevice,
            standardDesktopSize: standardDesktopSize,
            windowManager: windowManager,
            drawer: SharedWidgets.inIosStyle() ||
                    Platform.isAndroid ||
                    Platform.isFuchsia
                ? BurgerMenuWrapper(
                    scaffoldKey: scaffoldKey,
                    animationController: animationController,
                    navigationTop: navigationTop,
                    isDrawerOpen: isDrawerOpen,
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
            sliderUpdateValue: ({required double speed}) {
              setState(() {
                scrollSpeedDevice = speed;
                settingsBloc.setScrollSpeedDevice(speed: speed);
              });
            },
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
