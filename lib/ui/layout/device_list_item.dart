import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roonmatrix/color_defs.dart';
import 'package:roonmatrix/data/main_repository.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/scroll_matrix_page.dart';
import 'package:roonmatrix/ui/layout/desktop_page_buttons.dart';
import 'package:roonmatrix/ui/layout/mobile_page_buttons.dart';
import 'package:roonmatrix/ui/layout/slider_hover_overlay.dart';
import 'package:roonmatrix/ui/layout/device_info.dart';
import 'package:roonmatrix/ui/main/main_bloc.dart';
import 'package:roonmatrix/ui/settings/settings_bloc.dart';
import 'package:updatable_ticker/updatable_ticker.dart';
import 'package:updatable_vertical_ticker/updatable_vertical_ticker.dart';

class DeviceListItem extends StatefulWidget {
  final GlobalKey itemListKey;
  final int index;
  final double width;
  final double height;
  final Orientation orientation;
  final Size minDesktopSize;
  final Size standardDesktopSize;
  final Map<String, dynamic> translations;
  final String ip;
  final String activeIp;
  final bool connected;
  final bool ping;
  final bool showSlider;
  final Map<String, dynamic> info;
  final String spotifyAuthUrl;
  final bool isSmallDeviceWidth;
  final bool moreInfo;
  final double scrollSpeedScrollMatrix;
  final double scrollSpeedDevice;
  final bool verticalTickerActive;
  final bool ledTickerInDeviceListActive;
  final bool ledTickerOnTickerPageActive;
  final bool ledTickerPixelShiftActive;
  final bool forceTickerUpdateActive;
  final void Function(String caller) updateSizes;

  const DeviceListItem({
    super.key,
    required this.itemListKey,
    required this.index,
    required this.width,
    required this.height,
    required this.orientation,
    required this.minDesktopSize,
    required this.standardDesktopSize,
    required this.translations,
    required this.ip,
    required this.activeIp,
    required this.connected,
    required this.ping,
    required this.showSlider,
    required this.info,
    required this.spotifyAuthUrl,
    required this.isSmallDeviceWidth,
    required this.moreInfo,
    required this.scrollSpeedScrollMatrix,
    required this.scrollSpeedDevice,
    required this.verticalTickerActive,
    required this.ledTickerInDeviceListActive,
    required this.ledTickerOnTickerPageActive,
    required this.ledTickerPixelShiftActive,
    required this.forceTickerUpdateActive,
    required this.updateSizes,
  });

  @override
  State<DeviceListItem> createState() => DeviceListItemState();
}

class DeviceListItemState extends State<DeviceListItem> {
  GlobalKey get itemListKey => widget.itemListKey;
  int get index => widget.index;
  double get width => widget.width;
  double get height => widget.height;
  Orientation get orientation => widget.orientation;
  Size get minDesktopSize => widget.minDesktopSize;
  Size get standardDesktopSize => widget.standardDesktopSize;
  Map<String, dynamic> get translations => widget.translations;
  String get activeIp => widget.activeIp;
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  bool get isSmallDeviceWidth => widget.isSmallDeviceWidth;
  bool get moreInfo => widget.moreInfo;
  bool get verticalTickerActive => widget.verticalTickerActive;
  bool get ledTickerInDeviceListActive => widget.ledTickerInDeviceListActive;
  bool get ledTickerOnTickerPageActive => widget.ledTickerOnTickerPageActive;
  bool get ledTickerPixelShiftActive => widget.ledTickerPixelShiftActive;
  bool get forceTickerUpdateActive => widget.forceTickerUpdateActive;
  void Function(String caller) get updateSizes => widget.updateSizes;

  final int cyclePause = 2;
  final double deviceListCoverSize = 68.0;
  final double mobileInfoPaddingRight = 40.0;
  final Color tileColor = Colors.lightBlueAccent;

  final double tickerTopOffset = 53.0;
  final double verticalTickerTopOffset = 53.0;
  final double tickerAreaHeight = 24.0;
  final double tickerFontSize = 14.0;
  final double tickerSpeedSliderWidth = 120.0;
  final double tickerHorizontalPadding = 8.0;

  final double ledGap = 0.2;
  final Color ledOnColor = Colors.red.shade400;
  final Color ledOffColor = const Color(0xFF000000);
  final double ledTickerPadding = 2.0;
  final double ledTickerBorderSize = 1.0;
  final double ledSizeDefault = 3.0;
  double ledSize = 3.0;
  double sliderDefaultValue = 1.0;

  List<String> verticalTextLines = [];
  int scrollDuration = 0;
  int linePause = 0;
  double infoOpacityLevel = 1.0;
  double itemListHeight = 84;
  double ledSizeBefore = 0;
  int ledModules = 9;
  bool ledTickerInDeviceListActiveBefore = false;
  bool verticalTickerActiveBefore = false;

  double pixelsPerSecond = 20;
  double scrollDelay = 25.0;
  int scrollDelayMin = 1;
  int scrollDelayMax = 100;
  int defaultDelay = 25;

  late MainRepository mainRepository;
  late MainBloc mainBloc;
  late SettingsBloc settingsBloc;
  late String ip;
  late bool connected;
  late bool ping;
  late Map<String, dynamic> info;
  late double scrollSpeedScrollMatrix;
  late double scrollSpeedDevice;
  late double ledSingleModuleSize;
  late double tickerWidth;
  late bool verticalOutput;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);

    ledTickerInDeviceListActiveBefore = ledTickerInDeviceListActive;
    verticalTickerActiveBefore = verticalTickerActive;
    ledSingleModuleSize = ledSize * 8 + ledGap * 8;
    tickerWidth = ledTickerInDeviceListActive
        ? ledModules * ledSize * 8 +
            2 * ledTickerPadding +
            2 * ledTickerBorderSize
        : ledModules * tickerFontSize * Globals.verticalTickerWidthFactor;

    updateProps();

    super.initState();
  }

  @override
  void didUpdateWidget(DeviceListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    updateProps();

    //print('ip: $ip, scrollText: ${info[ip]['app_displaystr'] ?? ''}');
  }

  double getPixelsPerSecond({
    required String? ip,
    required double fontSize,
    required double sliderValue,
  }) {
    if (ip == null || ip.isEmpty) {
      return 15.0;
    }

    List<dynamic> list = mainBloc.getPixelsPerSecond(
        ip: ip,
        isScrollMatrixPage: false,
        verticalOutput: verticalOutput,
        verticalTickerActive: verticalTickerActive,
        ledTickerActive: ledTickerInDeviceListActive,
        fontSize: fontSize,
        ledSize: ledSize,
        sliderValue: sliderValue);

    defaultDelay = list[0];
    scrollDelayMin = list[1];
    scrollDelayMax = list[2];
    sliderDefaultValue = list[3];
    scrollDelay = list[4];
    pixelsPerSecond = list[5];

    return pixelsPerSecond;
  }

  void updateProps() {
    ip = widget.ip;
    connected = widget.connected;
    ping = widget.ping;
    info = widget.info;
    scrollSpeedScrollMatrix = widget.scrollSpeedScrollMatrix;
    scrollSpeedDevice = widget.scrollSpeedDevice;

    Map<String, dynamic> i = info[ip];
    ledModules = i['led_modules'];
    verticalOutput = i['vertical_output'] ?? false;

    double ledSizeNew = ledSize;
    double nettoWidth =
        width - deviceListCoverSize - tickerHorizontalPadding * 3 - 3;
    if (ledModules * ledSize * 8 + ledGap * 8 >
        nettoWidth - tickerHorizontalPadding * 2) {
      ledSizeNew = nettoWidth / (ledModules * 8 + ledGap * 8);
      if (ledSizeNew > ledSizeDefault) {
        ledSizeNew = ledSizeDefault;
      }
    } else {
      ledSizeNew = ledSizeDefault;
    }

    if (ledSizeNew != ledSizeBefore ||
        ledTickerInDeviceListActiveBefore != ledTickerInDeviceListActive ||
        verticalTickerActiveBefore != verticalTickerActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            ledSize = ledSizeNew;
            ledSizeBefore = ledSize;
            ledTickerInDeviceListActiveBefore = ledTickerInDeviceListActive;
            verticalTickerActiveBefore = verticalTickerActive;
            verticalOutput = i['vertical_output'] ?? false;
            ledSingleModuleSize = ledSize * 8 + ledGap * 8;

            tickerWidth = ledTickerInDeviceListActive
                ? ledModules * ledSize * 8 +
                    2 * ledTickerPadding +
                    2 * ledTickerBorderSize
                : ledModules *
                    tickerFontSize *
                    Globals.verticalTickerWidthFactor;
          });
        }
      });
    }

    pixelsPerSecond = getPixelsPerSecond(
      ip: ip,
      fontSize: tickerFontSize,
      sliderValue: scrollSpeedDevice,
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> i = info[ip];

    double tickerHeight = ledTickerInDeviceListActive
        ? ledSingleModuleSize + ledTickerPadding * 2 + ledTickerBorderSize * 2
        : tickerAreaHeight;

    String scrollText = verticalOutput && verticalTickerActive
        ? ''
        : mainBloc.replaceIllegalCharsInTickerString(
            ip: ip,
            verticalOutput: verticalOutput,
            verticalTickerActive: verticalTickerActive,
            str: i['app_displaystr'] ?? '',
            replaceActiveZoneMarker: !ledTickerInDeviceListActive,
          );

    if (verticalOutput && verticalTickerActive) {
      List<String> lines = [];
      for (String line in List<String>.from(i['vert_strlines'])) {
        String filteredLine = mainBloc.replaceIllegalCharsInTickerString(
          ip: ip,
          verticalOutput: verticalOutput,
          verticalTickerActive: verticalTickerActive,
          str: line,
          replaceActiveZoneMarker: !ledTickerInDeviceListActive,
        );
        lines.add(filteredLine);
      }
      verticalTextLines = lines;
    }

    String hash = md5.convert(utf8.encode(scrollText)).toString();
    if (kDebugMode) {
      debugPrint(
          'DeviceListItem => new info received on index $index @ ${DateTime.now().toLocal()}), hash: $hash, scrollText: $scrollText');
    }

    String zoneName = mainRepository.getZoneName(info: i);
    bool idle = mainRepository.getIdleMode(info: i);

    Map<String, dynamic>? zone = mainRepository.getZoneDataForControlId(i);
    String? coverUrl = mainRepository.getCoverUrl(zone: zone);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      RenderBox? box;
      BuildContext? itemContext = itemListKey.currentContext;
      if (mounted && itemContext != null) {
        RenderObject? renderObject = itemContext.findRenderObject();
        if (renderObject is RenderBox && renderObject.attached) {
          box = renderObject;
        }
      }
      if (box != null) {
        itemListHeight = 1 + box.size.height;
      }
    });

    return Stack(
      children: [
        Container(
          key: index == 0 ? itemListKey : null, // only first item with key
          color: ColorDefs.tileBackgroundColor(context: context),
          height: itemListHeight - 1,
          padding: EdgeInsets.only(
            left: tickerHorizontalPadding,
            right: tickerHorizontalPadding,
          ),
          child: Stack(
            children: [
              Padding(
                padding:
                    EdgeInsets.symmetric(vertical: tickerHorizontalPadding),
                child: ListTile(
                  minVerticalPadding: 0.0,
                  contentPadding: EdgeInsets.all(0),
                  tileColor: tileColor,
                  iconColor: Colors.black,
                  textColor: ColorDefs.textColor(context: context),
                  title: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: deviceListCoverSize,
                        height: deviceListCoverSize,
                        child: Tooltip(
                          message: translations['openCoverPageButtonLabel'] ??
                              'Open album cover view and device control page',
                          waitDuration: Globals.tooltipWaitDuration,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => showGeneralDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return CoverPage(
                                  name: i['name'],
                                  ip: ip,
                                  translations: translations,
                                  minDesktopSize: minDesktopSize,
                                  standardDesktopSize: standardDesktopSize,
                                );
                              },
                            ),
                            icon: AnimatedSwitcher(
                              duration: Globals
                                  .coverSwitchDefaultFadeAnimationDuration,
                              switchInCurve: Curves.easeIn,
                              switchOutCurve: Curves.easeOut,
                              child: coverUrl != null
                                  ? Image.network(
                                      coverUrl,
                                      width: deviceListCoverSize,
                                      height: deviceListCoverSize,
                                      colorBlendMode: idle
                                          ? ColorDefs.idleZoneColorBlendMode
                                          : null,
                                      color: idle
                                          ? ColorDefs.idleZoneIconColor
                                          : null,
                                      key: ValueKey(
                                          'DeviceCover-${widget.ip}-$coverUrl'),
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return SvgPicture.asset(
                                          Globals.placeholderSvgAssetPath(),
                                          allowDrawingOutsideViewBox: false,
                                          fit: BoxFit.cover,
                                          clipBehavior: Clip.hardEdge,
                                        );
                                      },
                                    )
                                  : SvgPicture.asset(
                                      Globals.placeholderSvgAssetPath(),
                                      allowDrawingOutsideViewBox: false,
                                      fit: BoxFit.cover,
                                      colorFilter: idle
                                          ? ColorDefs.idleZoneIconColorFilter
                                          : null,
                                      clipBehavior: Clip.hardEdge,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      DeviceInfo(
                        translations: translations,
                        ip: ip,
                        connected: connected,
                        ping: ping,
                        info: info,
                        height: Globals.mobileExpandableButtonSize - 4,
                        onFinishedPing: () {
                          mainBloc.setPing(ip: ip, ping: false);
                        },
                      ),
                      Expanded(
                        child: Globals.isDesktopDevice()
                            ? SizedBox(
                                height:
                                    width <= Globals.mobilePageButtonsMaxWidth
                                        ? Globals.mobileExpandableButtonSize
                                        : null,
                                child: Row(
                                  // desktop variant
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: width >
                                              Globals
                                                  .deviceListItemSwitchBoundaryFullInfo
                                          ? Text(
                                              mainRepository
                                                  .getTimeZonePlaycountText(
                                                translations: translations,
                                                info: i,
                                                zoneName: zoneName,
                                              ),
                                              softWrap: true,
                                              maxLines: 2,
                                              overflow: TextOverflow.fade,
                                              style: TextStyle(
                                                  fontSize: width >
                                                          Globals
                                                              .mobilePageButtonsMaxWidth
                                                      ? 14.0
                                                      : 12.0,
                                                  height: 1.3),
                                            )
                                          : Padding(
                                              padding:
                                                  EdgeInsets.only(right: 12.0),
                                              child: Text('${i['playcount']}',
                                                  softWrap: true,
                                                  overflow: TextOverflow.fade,
                                                  style: const TextStyle(
                                                      fontSize: 9,
                                                      height: 1.3)),
                                            ),
                                    ),
                                    if (width >
                                        Globals.mobilePageButtonsMaxWidth)
                                      DesktopPageButtons(
                                        translations: translations,
                                        ip: ip,
                                        info: info,
                                        spotifyAuthUrl: spotifyAuthUrl,
                                        moreInfo: moreInfo,
                                        minDesktopSize: minDesktopSize,
                                        standardDesktopSize:
                                            standardDesktopSize,
                                      )
                                  ],
                                ),
                              )
                            : SizedBox(
                                height: Globals.mobileExpandableButtonSize,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isSmallDeviceWidth == true)
                                      Padding(
                                        padding: EdgeInsets.only(right: 12.0),
                                        child: Text('${i['playcount']}',
                                            softWrap: true,
                                            overflow: TextOverflow.fade,
                                            style:
                                                const TextStyle(fontSize: 9)),
                                      ),
                                    if (!isSmallDeviceWidth)
                                      AnimatedOpacity(
                                        opacity: infoOpacityLevel,
                                        duration: Duration(milliseconds: 400),
                                        child: Text(
                                          mainRepository
                                              .getTimeZonePlaycountText(
                                            translations: translations,
                                            info: i,
                                            zoneName: zoneName,
                                            withLineBreak: true,
                                          ),
                                          softWrap: true,
                                          maxLines: 2,
                                          overflow: TextOverflow.fade,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    SizedBox(width: mobileInfoPaddingRight)
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              if (Globals.isMobileDevice() ||
                  width <= Globals.mobilePageButtonsMaxWidth)
                Positioned(
                  top: 9.0,
                  right: 0.0,
                  child: MobilePageButtons(
                    translations: translations,
                    moreInfo: moreInfo,
                    zoneName: zoneName,
                    ip: ip,
                    spotifyAuthUrl: spotifyAuthUrl,
                    zoneData: i,
                    minDesktopSize: minDesktopSize,
                    standardDesktopSize: standardDesktopSize,
                    isExpanded: ({required bool mode}) {
                      setState(() {
                        infoOpacityLevel = mode == true ? 0.0 : 1.0;
                      });
                    },
                    setSpotifyAuthRedirectUrl: ({required String url}) {
                      mainBloc.setSpotifyAuthRedirectUrl(ip: ip, url: url);
                    },
                  ),
                ),
              Positioned(
                  top: (verticalOutput && verticalTickerActive
                          ? ledTickerInDeviceListActive
                              ? verticalTickerTopOffset
                              : verticalTickerTopOffset - 1.5
                          : tickerTopOffset) +
                      (ledTickerInDeviceListActive
                          ? 21 - (ledSingleModuleSize + 2 * ledTickerPadding)
                          : 0),
                  left: deviceListCoverSize + 8,
                  child: NotificationListener<SizeChangedLayoutNotification>(
                    onNotification: (notification) {
                      updateSizes('NotificationListener');
                      build(context);
                      return false;
                    },
                    child: SizeChangedLayoutNotifier(
                      child: Container(
                        alignment: ledTickerInDeviceListActive ||
                                (verticalOutput && verticalTickerActive)
                            ? Alignment.centerLeft
                            : Alignment.center,
                        key: ValueKey(
                            'UpdatableTickerWrapper-${widget.ip}-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                        width: MediaQuery.of(context).size.width -
                            2 * tickerHorizontalPadding,
                        height: tickerHeight,
                        child: Tooltip(
                          message:
                              translations['openScrollMatrixPageButtonLabel'] ??
                                  'Open ticker view',
                          waitDuration: Globals.tooltipWaitDuration,
                          child: InkWell(
                            onTap: () => showGeneralDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierLabel: 'Dialog',
                              transitionDuration:
                                  const Duration(milliseconds: 0),
                              pageBuilder: (_, __, ___) {
                                return ScrollMatrixPage(
                                  ip: ip,
                                  scrollSpeed: scrollSpeedScrollMatrix,
                                  name: i['name'],
                                  translations: translations,
                                  minDesktopSize: minDesktopSize,
                                  standardDesktopSize: standardDesktopSize,
                                  verticalTickerActive: verticalTickerActive,
                                  ledTickerOnTickerPageActive:
                                      ledTickerOnTickerPageActive,
                                  ledTickerPixelShiftActive:
                                      ledTickerPixelShiftActive,
                                  forceTickerUpdateActive:
                                      forceTickerUpdateActive,
                                  speedChanged: (double speed) {
                                    scrollSpeedScrollMatrix = speed;
                                    settingsBloc.setScrollSpeedScrollMatrix(
                                        ip: ip, speed: speed);
                                  },
                                );
                              },
                            ),
                            child: verticalOutput && verticalTickerActive
                                ? Container(
                                    width: tickerWidth,
                                    padding: ledTickerInDeviceListActive
                                        ? EdgeInsets.all(ledTickerPadding)
                                        : EdgeInsets.symmetric(
                                            vertical: 2.0,
                                          ),
                                    decoration: ledTickerInDeviceListActive
                                        ? BoxDecoration(
                                            border: Border.all(
                                            width: ledTickerBorderSize,
                                            color: Colors.blue,
                                          ))
                                        : BoxDecoration(
                                            borderRadius:
                                                Globals.borderRadius(),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Globals.brightness() ==
                                                        Brightness.dark
                                                    ? Colors.grey.shade700
                                                        .withValues(alpha: 0.25)
                                                    : Colors.grey.withValues(
                                                        alpha: 0.25),
                                                spreadRadius: 0,
                                                blurRadius: 0,
                                              ),
                                            ],
                                          ),
                                    child: ledTickerInDeviceListActive
                                        ? Container(
                                            color: ledTickerPixelShiftActive
                                                ? Colors.black
                                                : Colors.grey.shade800,
                                            child: UpdatableVerticalLedTicker(
                                              key: ValueKey(
                                                'UpdatableTickerStartPage-${widget.ip}-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height',
                                              ),
                                              modules: ledModules,
                                              useProportionalFont: true,
                                              enableSmoothScrolling:
                                                  ledTickerPixelShiftActive,
                                              center: true,
                                              ledSize: ledSize,
                                              ledGap: ledGap,
                                              onColor: ledOnColor,
                                              offColor: ledOffColor,
                                              texts: verticalTextLines,
                                              scrollDuration: Duration(
                                                  milliseconds:
                                                      (scrollDelay * 8)
                                                          .floor()),
                                              linePause: Duration(
                                                  seconds: i[
                                                      'vertical_scroll_delay']),
                                              cyclePause:
                                                  Duration(seconds: cyclePause),
                                            ),
                                          )
                                        : UpdatableVerticalTicker(
                                            key: ValueKey(
                                              'UpdatableTickerStartPage-${widget.ip}-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height',
                                            ),
                                            texts: verticalTextLines,
                                            scrollDuration: Duration(
                                                milliseconds:
                                                    (scrollDelay * 8).floor()),
                                            linePause: Duration(
                                                seconds:
                                                    i['vertical_scroll_delay']),
                                            cyclePause:
                                                Duration(seconds: cyclePause),
                                            textStyle: TextStyle(
                                              fontSize: tickerFontSize,
                                              color: ColorDefs.textColor(
                                                  context: context),
                                            ),
                                          ),
                                  )
                                : ledTickerInDeviceListActive
                                    ? Container(
                                        width: tickerWidth,
                                        padding:
                                            EdgeInsets.all(ledTickerPadding),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                width: ledTickerBorderSize,
                                                color: Colors.blue)),
                                        child: Container(
                                          color: ledTickerPixelShiftActive
                                              ? Colors.black
                                              : Colors.grey.shade800,
                                          child: UpdatableLedTicker(
                                            key: ValueKey(
                                                'UpdatableTickerStartPage-${widget.ip}-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                            updatableText: scrollText,
                                            modules: ledModules,
                                            useProportionalFont: true,
                                            enableSmoothScrolling:
                                                ledTickerPixelShiftActive,
                                            ledSize: ledSize,
                                            ledGap: ledGap,
                                            onColor: ledOnColor,
                                            offColor: ledOffColor,
                                            pixelsPerSecond: pixelsPerSecond,
                                            forceUpdate:
                                                forceTickerUpdateActive,
                                            separator: Globals.tickerSeparator,
                                          ),
                                        ),
                                      )
                                    : UpdatableTicker(
                                        key: ValueKey(
                                            'UpdatableTickerStartPage-${widget.ip}-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                                        updatableText: scrollText,
                                        style: TextStyle(
                                          fontFamily: Globals.tickerFontFamily,
                                          fontSize: tickerFontSize,
                                          color: ColorDefs.textColor(
                                            context: context,
                                          ),
                                        ),
                                        pixelsPerSecond: getPixelsPerSecond(
                                          ip: ip,
                                          fontSize: tickerFontSize,
                                          sliderValue: scrollSpeedDevice,
                                        ),
                                        forceUpdate: forceTickerUpdateActive,
                                        separator: Globals.tickerSeparator,
                                      ),
                          ),
                        ),
                      ),
                    ),
                  )),
              if (Globals.isDesktopDevice() && widget.showSlider == true)
                Positioned(
                  bottom: -10,
                  right: 0,
                  child: SliderHoverOverlay(
                    label: '${translations['speed'] ?? 'speed:'}:',
                    width: tickerSpeedSliderWidth,
                    min: Globals.sliderMinValue,
                    max: Globals.sliderMaxValue,
                    defaultValue: sliderDefaultValue,
                    value: scrollSpeedDevice,
                    updateValue: (double value) {
                      settingsBloc.setScrollSpeedDevice(ip: ip, speed: value);
                      setState(() {
                        scrollSpeedDevice = value;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        if (Globals.isMobileDevice() && ip == activeIp)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 5.0,
              height: itemListHeight - 1,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Colors.blue.shade800,
                    width: 4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
