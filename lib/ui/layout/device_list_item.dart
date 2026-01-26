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
  final bool connected;
  final bool ping;
  final Map<String, dynamic> info;
  final String spotifyAuthUrl;
  final bool isSmallDeviceWidth;
  final bool moreInfo;
  final double scrollSpeedScrollMatrix;
  final double scrollSpeedDevice;
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
    required this.connected,
    required this.ping,
    required this.info,
    required this.spotifyAuthUrl,
    required this.isSmallDeviceWidth,
    required this.moreInfo,
    required this.scrollSpeedScrollMatrix,
    required this.scrollSpeedDevice,
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
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  bool get isSmallDeviceWidth => widget.isSmallDeviceWidth;
  bool get moreInfo => widget.moreInfo;
  void Function(String caller) get updateSizes => widget.updateSizes;

  final double deviceListCoverSize = 40.0;
  final double mobileInfoPaddingRight = 40.0;
  final Color tileColor = Colors.lightBlueAccent;
  final Duration animatedOpacityForTimeZonePlaycountText =
      const Duration(milliseconds: 400);

  final double tickerTopOffset = 60.0;
  final double tickerAreaHeight = 24.0;
  final double tickerFontSize = 14.0;
  final double tickerPixelPerSecondFactor = 50.0;
  final double tickerSpeedSliderWidth = 120.0;

  double infoOpacityLevel = 1.0;
  double itemListHeight = 84;

  late MainRepository mainRepository;
  late MainBloc mainBloc;
  late SettingsBloc settingsBloc;
  late String ip;
  late bool connected;
  late bool ping;
  late Map<String, dynamic> info;
  late double scrollSpeedScrollMatrix;
  late double scrollSpeedDevice;

  @override
  void initState() {
    mainRepository = RepositoryProvider.of<MainRepository>(context);
    mainBloc = BlocProvider.of<MainBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);

    updateProps();

    super.initState();
  }

  @override
  void didUpdateWidget(DeviceListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    updateProps();

    //print('ip: $ip, scrollText: ${info[ip]['app_displaystr'] ?? ''}');
  }

  void updateProps() {
    ip = widget.ip;
    connected = widget.connected;
    ping = widget.ping;
    info = widget.info;
    scrollSpeedScrollMatrix = widget.scrollSpeedScrollMatrix;
    scrollSpeedDevice = widget.scrollSpeedDevice;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> i = info[ip];

    String scrollText = mainRepository.replaceIllegalCharsInTickerString(
      str: i['app_displaystr'] ?? '',
      replaceActiveZoneMarker: true,
    );
    String hash = md5.convert(utf8.encode(scrollText)).toString();
    if (kDebugMode) {
      debugPrint(
          'DeviceListItem => new info received on index $index @ ${DateTime.now().toLocal()}), hash: $hash, scrollText: $scrollText');
    }

    String zoneName = mainRepository.getZoneName(info: i);

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

    return Container(
      key: index == 0 ? itemListKey : null, // only first item with key
      color: ColorDefs.tileBackgroundColor(context: context),
      height: itemListHeight - 1,
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Stack(
        children: [
          //Text('scrollText: $scrollText'),
          ListTile(
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
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => showGeneralDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierLabel: 'Dialog',
                      transitionDuration: const Duration(milliseconds: 0),
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
                      duration: Globals.coverSwitchDefaultFadeAnimationDuration,
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      child: coverUrl != null
                          ? Image.network(
                              coverUrl,
                              width: deviceListCoverSize,
                              height: deviceListCoverSize,
                              key: ValueKey('DeviceCover$index$coverUrl'),
                            )
                          : SvgPicture.asset(
                              Globals.placeholderAssetPath(),
                              allowDrawingOutsideViewBox: false,
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                DeviceInfo(
                  ip: ip,
                  connected: connected,
                  ping: ping,
                  info: info,
                  deviceListCoverSize: deviceListCoverSize,
                  onFinishedPing: () {
                    mainBloc.setPing(ip: ip, ping: false);
                  },
                ),
                Expanded(
                  child: Globals.isDesktopDevice()
                      ? Row(
                          // desktop variant
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                mainRepository.getTimeZonePlaycountText(
                                  translations: translations,
                                  info: i,
                                  zoneName: zoneName,
                                ),
                                softWrap: true,
                                maxLines: 2,
                                overflow: TextOverflow.fade,
                                style: TextStyle(fontSize: 14.0),
                              ),
                            ),
                            DesktopPageButtons(
                              translations: translations,
                              ip: ip,
                              info: info,
                              spotifyAuthUrl: spotifyAuthUrl,
                              moreInfo: moreInfo,
                              minDesktopSize: minDesktopSize,
                              standardDesktopSize: standardDesktopSize,
                            )
                          ],
                        )
                      : SizedBox(
                          height: deviceListCoverSize,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (isSmallDeviceWidth == true)
                                Padding(
                                  padding: EdgeInsets.only(right: 12.0),
                                  child: Text('${i['playcount']}',
                                      softWrap: true,
                                      overflow: TextOverflow.fade,
                                      style: const TextStyle(fontSize: 9)),
                                ),
                              if (!isSmallDeviceWidth)
                                AnimatedOpacity(
                                  opacity: infoOpacityLevel,
                                  duration:
                                      animatedOpacityForTimeZonePlaycountText,
                                  child: Text(
                                    mainRepository.getTimeZonePlaycountText(
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
          if (Globals.isMobileDevice())
            Positioned(
              top: Platform.isAndroid ? 4.0 : 7.0,
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
              top: tickerTopOffset,
              child: InkWell(
                onTap: () => showGeneralDialog(
                  context: context,
                  barrierDismissible: false,
                  barrierLabel: 'Dialog',
                  transitionDuration: const Duration(milliseconds: 0),
                  pageBuilder: (_, __, ___) {
                    return ScrollMatrixPage(
                      ip: ip,
                      scrollSpeed: scrollSpeedScrollMatrix,
                      name: i['name'],
                      translations: translations,
                      minDesktopSize: minDesktopSize,
                      standardDesktopSize: standardDesktopSize,
                      speedChanged: (double speed) {
                        scrollSpeedScrollMatrix = speed;
                        settingsBloc.setScrollSpeedScrollMatrix(speed: speed);
                      },
                    );
                  },
                ),
                child: NotificationListener<SizeChangedLayoutNotification>(
                  onNotification: (notification) {
                    updateSizes('NotificationListener');
                    build(context);
                    return false;
                  },
                  child: SizeChangedLayoutNotifier(
                    child: SizedBox(
                      key: ValueKey(
                          'UpdatableTickerWrapper-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                      width: MediaQuery.of(context).size.width - 16,
                      height: tickerAreaHeight,
                      child: UpdatableTicker(
                        key: ValueKey(
                            'UpdatableTickerStartPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                        updatableText: scrollText,
                        style: TextStyle(
                          fontFamily: Globals.tickerFontFamily,
                          fontSize: tickerFontSize,
                          color: ColorDefs.textColor(
                            context: context,
                          ),
                        ),
                        pixelsPerSecond:
                            tickerPixelPerSecondFactor * scrollSpeedDevice,
                        forceUpdate: false,
                        separator: Globals.tickerSeparator,
                      ),
                    ),
                  ),
                ),
              )),
          if (Globals.isDesktopDevice())
            Positioned(
              bottom: -10,
              right: 0,
              child: SliderHoverOverlay(
                label: '${translations['speed'] ?? 'speed:'}:',
                width: tickerSpeedSliderWidth,
                value: scrollSpeedDevice,
                updateValue: (double value) {
                  settingsBloc.setScrollSpeedDevice(speed: value);
                  setState(() {
                    scrollSpeedDevice = value;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
