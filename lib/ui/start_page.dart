import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/scroll_matrix_page.dart';
import 'package:roonmatrix/ui/details/searchfield.dart';
import 'package:roonmatrix/ui/helper/lifecycle_page_wrapper.dart';
import 'package:roonmatrix/ui/layout/burger_menu_wrapper.dart';
import 'package:roonmatrix/ui/layout/cover_row_animation.dart';
import 'package:roonmatrix/ui/layout/debug_message_card.dart';
import 'package:roonmatrix/ui/layout/desktop_page_buttons.dart';
import 'package:roonmatrix/ui/layout/devices_reload_button.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_flutter_style.dart';
import 'package:roonmatrix/ui/layout/icon_text_button_element.dart';
import 'package:roonmatrix/ui/layout/loading_indicator.dart';
import 'package:roonmatrix/ui/layout/mobile_page_buttons.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_ios_style.dart';
import 'package:roonmatrix/ui/layout/page_with_toolbar_mac_style.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/slider_hover_overlay.dart';
import 'package:roonmatrix/ui/layout/small_cover_with_device_info.dart';
import 'package:roonmatrix/ui/layout/zone_start_buttons.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:roonmatrix/ui/translations/translations_bloc.dart';
import 'package:roonmatrix/ui/translations/translations_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:updatable_ticker/updatable_ticker.dart';
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

  final GlobalKey keyZoneNotRunningButtonsKey = GlobalKey();
  final GlobalKey windowKey = GlobalKey();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey itemListKey = GlobalKey();
  final double exportButtonPaddingIos = 14.0;
  final double deviceListCoverSize = 40.0;

  AnimationController? animationController;
  Map<String, dynamic> info = {};
  Map<String, dynamic> translations = {};
  List<String> devices = [];
  Map<String, dynamic> spotifyAuthUrls = {};

  double? appBarHeight;
  double? navigationTop;
  double itemListHeight = 84;
  Orientation orientation = Orientation.portrait;
  double width = 1280;
  double height = 768;
  Map<String, double> infoOpacityLevel = {};
  double scrollSpeedDevice = 1.0;
  double scrollSpeedScrollMatrix = 1.0;

  bool translationsLoaded = false;
  bool idle = false;
  bool saveIdle = false;
  bool settingsPageLoaded = false;
  bool isDrawerOpen = false;
  bool moreInfo = false;
  bool coverRowActiv = false;
  bool coverRowArtist = false;
  bool coverRowAlbum = false;
  bool coverRowTrack = false;
  bool coverRowDynamicSize = false;
  bool showExpandableSpeedSlider = false;

  late SettingsBloc settingsBloc;
  late TranslationsBloc translationsBloc;
  late MainBloc mainBloc;

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
    animationController?.dispose();
  }

  updateSizes(String caller) {
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    showExportButton = (SharedWidgets.isMobileDevice() &&
            orientation == Orientation.portrait) ||
        (SharedWidgets.isDesktopDevice() &&
            height > (minDesktopSize.height + 75));
    // if (kDebugMode) {
    //   debugPrint(
    //       'yyyy StartPage/updateSizes => caller: $caller, width: $width, height: $height');
    // }
  }

  body() => AppLifecyclePageWrapper(
        onResume: () {
          debugPrint('AppLifecycle => onResume');
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

                    moreInfo = settingsState.moreInfo;
                    coverRowActiv = settingsState.coverRowActiv;
                    coverRowArtist = settingsState.coverRowArtist;
                    coverRowAlbum = settingsState.coverRowAlbum;
                    coverRowTrack = settingsState.coverRowTrack;
                    coverRowDynamicSize = settingsState.coverRowDynamicSize;
                    scrollSpeedDevice = settingsState.scrollSpeedDevice;
                    scrollSpeedScrollMatrix =
                        settingsState.scrollSpeedScrollMatrix;

                    return BlocBuilder(
                        bloc: mainBloc,
                        builder: (context, MainState mainState) {
                          if (kDebugMode) {
                            debugPrint(
                                'yyyy StartPage => mainState event $mainState @ ${DateTime.now().toLocal()}');
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

                          devices = mainBloc.getFilteredDevices();
                          info = mainState.info;
                          spotifyAuthUrls = mainState.spotifyAuthUrls;
                          idle = mainState.idle;

                          if (kDebugMode) {
                            debugPrint(
                                'yyyy StartPage/body => state changed => rebuild, devices: ${devices.length}, idle: $idle');
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
                                                    Map<String, dynamic> i =
                                                        info[ip];
                                                    String spotifyAuthUrl =
                                                        spotifyAuthUrls[ip] ??
                                                            '*';

                                                    double
                                                        itemInfoOpacityLevel =
                                                        infoOpacityLevel[ip] ??
                                                            1.0;

                                                    String scrollText = mainBloc
                                                        .replaceIllegalCharsInTickerString(
                                                            i['app_displaystr'] ??
                                                                '');
                                                    String hash = md5
                                                        .convert(utf8
                                                            .encode(scrollText))
                                                        .toString();
                                                    if (kDebugMode) {
                                                      debugPrint(
                                                          'yyyy StartPage => new info received on index $index @ ${DateTime.now().toLocal()}), hash: $hash, scrollText: $scrollText');
                                                    }

                                                    String zoneName = mainBloc
                                                        .getZoneName(info: i);

                                                    Map<String, dynamic>? zone =
                                                        mainBloc
                                                            .getZoneDataForControlId(
                                                                i);
                                                    String? coverUrl = zone !=
                                                                null &&
                                                            zone['cover'] !=
                                                                null &&
                                                            (zone['cover']
                                                                    as String)
                                                                .isNotEmpty
                                                        ? zone['cover']
                                                        : null;

                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      if (!mounted) return;

                                                      RenderBox? box;
                                                      BuildContext?
                                                          itemContext =
                                                          itemListKey
                                                              .currentContext;
                                                      if (mounted &&
                                                          itemContext != null) {
                                                        RenderObject?
                                                            renderObject =
                                                            itemContext
                                                                .findRenderObject();
                                                        if (renderObject
                                                                is RenderBox &&
                                                            renderObject
                                                                .attached) {
                                                          box = renderObject;
                                                        }
                                                      }
                                                      if (box != null) {
                                                        itemListHeight =
                                                            1 + box.size.height;
                                                      }
                                                    });

                                                    return Container(
                                                      key: index == 0
                                                          ? itemListKey
                                                          : null,
                                                      color: SharedWidgets
                                                          .tileBackgroundColor(
                                                              context: context),
                                                      height:
                                                          itemListHeight - 1,
                                                      padding: EdgeInsets.only(
                                                        left: 8.0,
                                                        right: 8.0,
                                                      ),
                                                      child: Stack(
                                                        children: [
                                                          ListTile(
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                    0),
                                                            tileColor: Colors
                                                                .lightBlueAccent,
                                                            iconColor:
                                                                Colors.black,
                                                            textColor: SharedWidgets
                                                                .textColor(
                                                                    context:
                                                                        context),
                                                            title: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                SizedBox(
                                                                  width:
                                                                      deviceListCoverSize,
                                                                  height:
                                                                      deviceListCoverSize,
                                                                  child:
                                                                      IconButton(
                                                                    padding:
                                                                        EdgeInsets
                                                                            .zero,
                                                                    onPressed: () =>
                                                                        showGeneralDialog(
                                                                      context:
                                                                          context,
                                                                      // barrierColor: Colors
                                                                      //     .black12
                                                                      //     .withOpacity(
                                                                      //         0.6), // Background color
                                                                      barrierDismissible:
                                                                          false,
                                                                      barrierLabel:
                                                                          'Dialog',
                                                                      transitionDuration:
                                                                          const Duration(
                                                                              milliseconds: 0),
                                                                      pageBuilder: (_,
                                                                          __,
                                                                          ___) {
                                                                        return CoverPage(
                                                                          name:
                                                                              i['name'],
                                                                          ip: devices[
                                                                              index],
                                                                          translations:
                                                                              translations,
                                                                        );
                                                                      },
                                                                    ),
                                                                    icon:
                                                                        AnimatedSwitcher(
                                                                      duration: Duration(
                                                                          milliseconds:
                                                                              2000),
                                                                      switchInCurve:
                                                                          Curves
                                                                              .easeIn,
                                                                      switchOutCurve:
                                                                          Curves
                                                                              .easeOut,
                                                                      child: coverUrl !=
                                                                              null
                                                                          ? Image
                                                                              .network(
                                                                              coverUrl,
                                                                              width: deviceListCoverSize,
                                                                              height: deviceListCoverSize,
                                                                              key: ValueKey('DeviceCover$index$coverUrl'),
                                                                            )
                                                                          : SvgPicture
                                                                              .asset(
                                                                              'assets/svg/8-8-led-matrix-display-unit.svg',
                                                                              allowDrawingOutsideViewBox: false,
                                                                              fit: BoxFit.cover,
                                                                              clipBehavior: Clip.hardEdge,
                                                                            ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    width: 8.0),
                                                                Flexible(
                                                                  flex: 1,
                                                                  fit: FlexFit
                                                                      .loose,
                                                                  child: DeviceInfo(
                                                                      ip: devices[
                                                                          index],
                                                                      info:
                                                                          info),
                                                                ),
                                                                SharedWidgets
                                                                        .isDesktopDevice()
                                                                    ? Row(
                                                                        // desktop variant
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          Text(
                                                                            '${translations['deviceListTime'] ?? 'time'}: ${mainBloc.getFormattedDateString(date: i['time'])}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${i['playcount']}  ',
                                                                            softWrap:
                                                                                true,
                                                                            maxLines:
                                                                                2,
                                                                            overflow:
                                                                                TextOverflow.fade,
                                                                          ),
                                                                          DesktopPageButtons(
                                                                            translations:
                                                                                translations,
                                                                            ip: ip,
                                                                            info:
                                                                                info,
                                                                            spotifyAuthUrl:
                                                                                spotifyAuthUrl,
                                                                            moreInfo:
                                                                                moreInfo,
                                                                          )
                                                                        ],
                                                                      )
                                                                    : Flexible(
                                                                        flex: 2,
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            if (isSmallDeviceWidth ==
                                                                                true)
                                                                              Padding(
                                                                                padding: EdgeInsets.only(top: Platform.isAndroid ? 14.0 : 11.0, right: 8.0),
                                                                                child: Text('${i['playcount']}', softWrap: true, overflow: TextOverflow.fade, style: const TextStyle(fontSize: 9)),
                                                                              ),
                                                                            if (!isSmallDeviceWidth)
                                                                              AnimatedOpacity(
                                                                                opacity: itemInfoOpacityLevel,
                                                                                duration: const Duration(milliseconds: 400),
                                                                                child: Text(
                                                                                  '${translations['deviceListTime'] ?? 'time'}: ${mainBloc.getFormattedDateString(date: i['time'])}\n${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${i['playcount']}  ',
                                                                                  softWrap: true,
                                                                                  maxLines: 2,
                                                                                  overflow: TextOverflow.fade,
                                                                                  style: const TextStyle(fontSize: 11),
                                                                                ),
                                                                              ),
                                                                            SizedBox(width: 40.0)
                                                                          ],
                                                                        ),
                                                                      ),
                                                              ],
                                                            ),
                                                          ),
                                                          if (SharedWidgets
                                                              .isMobileDevice())
                                                            Positioned(
                                                              top: Platform
                                                                      .isAndroid
                                                                  ? 4.0
                                                                  : 7.0,
                                                              right: 0.0,
                                                              child:
                                                                  MobilePageButtons(
                                                                translations:
                                                                    translations,
                                                                moreInfo:
                                                                    moreInfo,
                                                                zoneName:
                                                                    zoneName,
                                                                ip: ip,
                                                                spotifyAuthUrl:
                                                                    spotifyAuthUrl,
                                                                zoneData: i,
                                                                isExpanded: (
                                                                    {required bool
                                                                        mode}) {
                                                                  setState(() {
                                                                    infoOpacityLevel[
                                                                        ip] = mode ==
                                                                            true
                                                                        ? 0.0
                                                                        : 1.0;
                                                                  });
                                                                },
                                                                setSpotifyAuthRedirectUrl: (
                                                                    {required String
                                                                        url}) {
                                                                  mainBloc.setSpotifyAuthRedirectUrl(
                                                                      ip: ip,
                                                                      url: url);
                                                                },
                                                              ),
                                                            ),
                                                          Positioned(
                                                              top: 60,
                                                              child: InkWell(
                                                                onTap: () =>
                                                                    showGeneralDialog(
                                                                  context:
                                                                      context,
                                                                  // barrierColor: Colors
                                                                  //     .black12
                                                                  //     .withOpacity(
                                                                  //         0.6), // Background color
                                                                  barrierDismissible:
                                                                      false,
                                                                  barrierLabel:
                                                                      'Dialog',
                                                                  transitionDuration:
                                                                      const Duration(
                                                                          milliseconds:
                                                                              0),
                                                                  pageBuilder:
                                                                      (_, __,
                                                                          ___) {
                                                                    return ScrollMatrixPage(
                                                                      ip: devices[
                                                                          index],
                                                                      scrollSpeed:
                                                                          scrollSpeedScrollMatrix,
                                                                      name: i[
                                                                          'name'],
                                                                      translations:
                                                                          translations,
                                                                      minDesktopSize:
                                                                          minDesktopSize,
                                                                      speedChanged:
                                                                          (double
                                                                              speed) {
                                                                        scrollSpeedScrollMatrix =
                                                                            speed;
                                                                        settingsBloc.setScrollSpeedScrollMatrix(
                                                                            speed:
                                                                                speed);
                                                                      },
                                                                      close:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                    );
                                                                  },
                                                                ),
                                                                child: NotificationListener<
                                                                    SizeChangedLayoutNotification>(
                                                                  onNotification:
                                                                      (notification) {
                                                                    updateSizes(
                                                                        'NotificationListener');
                                                                    build(
                                                                        context);
                                                                    return false;
                                                                  },
                                                                  child:
                                                                      SizeChangedLayoutNotifier(
                                                                    child:
                                                                        SizedBox(
                                                                      key: ValueKey(
                                                                          'UpdatableTickerWrapper-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                      width: MediaQuery.of(context)
                                                                              .size
                                                                              .width -
                                                                          16,
                                                                      height:
                                                                          24.0,
                                                                      child:
                                                                          UpdatableTicker(
                                                                        key: ValueKey(
                                                                            'UpdatableTickerStartPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                                                        updatableText:
                                                                            scrollText,
                                                                        style:
                                                                            TextStyle(
                                                                          fontFamily:
                                                                              'whiteCupertino subtitle',
                                                                          fontSize:
                                                                              14.0,
                                                                          color:
                                                                              SharedWidgets.textColor(
                                                                            context:
                                                                                context,
                                                                          ),
                                                                        ),
                                                                        pixelsPerSecond:
                                                                            50 *
                                                                                scrollSpeedDevice,
                                                                        forceUpdate:
                                                                            false,
                                                                        separator:
                                                                            '    ////    ',
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              )),
                                                          if (SharedWidgets
                                                              .isDesktopDevice())
                                                            Positioned(
                                                              bottom: -10,
                                                              right: 0,
                                                              child:
                                                                  SliderHoverOverlay(
                                                                translations:
                                                                    translations,
                                                                width: 120,
                                                                value:
                                                                    scrollSpeedDevice,
                                                                updateValue:
                                                                    (double
                                                                        value) {
                                                                  setState(() {
                                                                    scrollSpeedDevice =
                                                                        value;
                                                                    settingsBloc
                                                                        .setScrollSpeedDevice(
                                                                            speed:
                                                                                value);
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                        ],
                                                      ),
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
                                          vertical: Platform.isMacOS ||
                                                  Platform.isWindows ||
                                                  Platform.isLinux
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
                    animationController!.reverse();
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
                child: animationController != null
                    ? BurgerMenuWrapper(
                        scaffoldKey: scaffoldKey,
                        animationController: animationController!,
                        navigationTop: navigationTop,
                        isDrawerOpen: isDrawerOpen,
                      )
                    : SizedBox(),
              ),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    updateSizes('build');

    if (SharedWidgets.inIosStyle()) {
      if (animationController == null) {
        return SizedBox();
      }
      return PageWithToolbarIosStyle(
        title: title,
        showExpandableSpeedSlider: showExpandableSpeedSlider,
        scrollSpeedDevice: scrollSpeedDevice,
        animationController: animationController!,
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
          navigationTop = appBarHeight! + MediaQuery.of(context).padding.top;
        },
        setDrawerState: ({required bool open}) {
          setState(() {
            isDrawerOpen = open;
          });
        },
      );
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

    return PageWithToolbarFlutterStyle(
      scaffoldKey: scaffoldKey,
      title: title,
      showExpandableSpeedSlider: showExpandableSpeedSlider,
      scrollSpeedDevice: scrollSpeedDevice,
      standardDesktopSize: standardDesktopSize,
      windowManager: windowManager,
      drawer:
          SharedWidgets.inIosStyle() || Platform.isAndroid || Platform.isFuchsia
              ? animationController != null
                  ? BurgerMenuWrapper(
                      scaffoldKey: scaffoldKey,
                      animationController: animationController!,
                      navigationTop: navigationTop,
                      isDrawerOpen: isDrawerOpen,
                    )
                  : SizedBox()
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
          navigationTop = appBarHeight! + MediaQuery.of(context).padding.top;
        }
      },
    );
  }
}
