import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:roonmatrix/ui/details/cover_page.dart';
import 'package:roonmatrix/ui/details/scroll_matrix_page.dart';
import 'package:roonmatrix/ui/layout/desktop_page_buttons.dart';
import 'package:roonmatrix/ui/layout/mobile_page_buttons.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:roonmatrix/ui/layout/slider_hover_overlay.dart';
import 'package:roonmatrix/ui/layout/small_cover_with_device_info.dart';
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
  final Map<String, dynamic> translations;
  final String ip;
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
    required this.translations,
    required this.ip,
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
  Map<String, dynamic> get translations => widget.translations;
  String get spotifyAuthUrl => widget.spotifyAuthUrl;
  bool get isSmallDeviceWidth => widget.isSmallDeviceWidth;
  bool get moreInfo => widget.moreInfo;

  double infoOpacityLevel = 1.0;
  double itemListHeight = 84;
  final double deviceListCoverSize = 40.0;

  late MainBloc mainBloc;
  late SettingsBloc settingsBloc;
  late String ip;
  late Map<String, dynamic> info;
  late double scrollSpeedScrollMatrix;
  late double scrollSpeedDevice;

  @override
  void initState() {
    mainBloc = BlocProvider.of<MainBloc>(context);
    settingsBloc = BlocProvider.of<SettingsBloc>(context);
    ip = widget.ip;
    info = widget.info;
    scrollSpeedScrollMatrix = widget.scrollSpeedScrollMatrix;
    scrollSpeedDevice = widget.scrollSpeedDevice;
    super.initState();
  }

  @override
  void didUpdateWidget(DeviceListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    ip = widget.ip;
    info = widget.info;
    scrollSpeedScrollMatrix = widget.scrollSpeedScrollMatrix;
    scrollSpeedDevice = widget.scrollSpeedDevice;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> i = info[ip];

    String scrollText =
        mainBloc.replaceIllegalCharsInTickerString(i['app_displaystr'] ?? '');
    String hash = md5.convert(utf8.encode(scrollText)).toString();
    if (kDebugMode) {
      debugPrint(
          'yyyy StartPage => new info received on index $index @ ${DateTime.now().toLocal()}), hash: $hash, scrollText: $scrollText');
    }

    String zoneName = mainBloc.getZoneName(info: i);

    Map<String, dynamic>? zone = mainBloc.getZoneDataForControlId(i);
    String? coverUrl = zone != null &&
            zone['cover'] != null &&
            (zone['cover'] as String).isNotEmpty
        ? zone['cover']
        : null;

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
      key: index == 0 ? itemListKey : null,
      color: SharedWidgets.tileBackgroundColor(context: context),
      height: itemListHeight - 1,
      padding: EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Stack(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(0),
            tileColor: Colors.lightBlueAccent,
            iconColor: Colors.black,
            textColor: SharedWidgets.textColor(context: context),
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
                      // barrierColor: Colors
                      //     .black12
                      //     .withOpacity(
                      //         0.6), // Background color
                      barrierDismissible: false,
                      barrierLabel: 'Dialog',
                      transitionDuration: const Duration(milliseconds: 0),
                      pageBuilder: (_, __, ___) {
                        return CoverPage(
                          name: i['name'],
                          ip: ip,
                          translations: translations,
                        );
                      },
                    ),
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: 2000),
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
                              'assets/svg/8-8-led-matrix-display-unit.svg',
                              allowDrawingOutsideViewBox: false,
                              fit: BoxFit.cover,
                              clipBehavior: Clip.hardEdge,
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Flexible(
                  flex: 1,
                  fit: FlexFit.loose,
                  child: DeviceInfo(ip: ip, info: info),
                ),
                SharedWidgets.isDesktopDevice()
                    ? Row(
                        // desktop variant
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${translations['deviceListTime'] ?? 'time'}: ${mainBloc.getFormattedDateString(date: i['time'])}  |  ${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${i['playcount']}  ',
                            softWrap: true,
                            maxLines: 2,
                            overflow: TextOverflow.fade,
                          ),
                          DesktopPageButtons(
                            translations: translations,
                            ip: ip,
                            info: info,
                            spotifyAuthUrl: spotifyAuthUrl,
                            moreInfo: moreInfo,
                          )
                        ],
                      )
                    : Flexible(
                        flex: 2,
                        child: Row(
                          children: [
                            if (isSmallDeviceWidth == true)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: Platform.isAndroid ? 14.0 : 11.0,
                                    right: 8.0),
                                child: Text('${i['playcount']}',
                                    softWrap: true,
                                    overflow: TextOverflow.fade,
                                    style: const TextStyle(fontSize: 9)),
                              ),
                            if (!isSmallDeviceWidth)
                              AnimatedOpacity(
                                opacity: infoOpacityLevel,
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
          if (SharedWidgets.isMobileDevice())
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
              top: 60,
              child: InkWell(
                onTap: () => showGeneralDialog(
                  context: context,
                  // barrierColor: Colors
                  //     .black12
                  //     .withOpacity(
                  //         0.6), // Background color
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
                      speedChanged: (double speed) {
                        scrollSpeedScrollMatrix = speed;
                        settingsBloc.setScrollSpeedScrollMatrix(speed: speed);
                      },
                      close: () {
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
                child: NotificationListener<SizeChangedLayoutNotification>(
                  onNotification: (notification) {
                    widget.updateSizes('NotificationListener');
                    build(context);
                    return false;
                  },
                  child: SizeChangedLayoutNotifier(
                    child: SizedBox(
                      key: ValueKey(
                          'UpdatableTickerWrapper-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                      width: MediaQuery.of(context).size.width - 16,
                      height: 24.0,
                      child: UpdatableTicker(
                        key: ValueKey(
                            'UpdatableTickerStartPage-${orientation == Orientation.portrait ? 'portrait' : 'landscape'}-${width}x$height'),
                        updatableText: scrollText,
                        style: TextStyle(
                          fontFamily: 'whiteCupertino subtitle',
                          fontSize: 14.0,
                          color: SharedWidgets.textColor(
                            context: context,
                          ),
                        ),
                        pixelsPerSecond: 50 * scrollSpeedDevice,
                        forceUpdate: false,
                        separator: '    ////    ',
                      ),
                    ),
                  ),
                ),
              )),
          if (SharedWidgets.isDesktopDevice())
            Positioned(
              bottom: -10,
              right: 0,
              child: SliderHoverOverlay(
                translations: translations,
                width: 120,
                value: scrollSpeedDevice,
                updateValue: (double value) {
                  setState(() {
                    scrollSpeedDevice = value;
                    settingsBloc.setScrollSpeedDevice(speed: value);
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}
