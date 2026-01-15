import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roonmatrix/ui/helper/triangle_painter.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainRepository {
  MainRepository();

  isRoonZone(String zoneName) {
    return !zoneName.endsWith('-Apple Music') &&
        !zoneName.endsWith('-SpotifyConnect') &&
        !zoneName.endsWith('-Spotify');
  }

  getFormattedDateString(
      {required String date,
      String languageCode = 'de',
      String format = 'dd.MM.yyyy HH:mm:ss'}) {
    String formattedDate =
        DateFormat(format, languageCode).format(DateTime.parse(date));

    return formattedDate;
  }

  Color getZoneColor(String zoneName) {
    if (zoneName.endsWith('-Apple Music')) {
      return Color(0xFFF50057);
    }
    if (zoneName.endsWith('-SpotifyConnect') || zoneName.endsWith('-Spotify')) {
      return Colors.green;
    }

    return Colors.blue.shade300;
  }

  Offset getZoneIconPosition({required String zoneName}) {
    if (zoneName.endsWith('-Apple Music')) {
      return Offset(-9.0, -2.0);
    }
    if (zoneName.endsWith('-SpotifyConnect')) {
      return Offset(0, 5.0);
    }

    if (zoneName.endsWith('-Spotify')) {
      return Offset(2.0, 5.0);
    }

    return Offset(4.0, 5.0);
  }

  Offset getZoneIconPositionBySize(
      {required double size, required String zoneName}) {
    if (zoneName.endsWith('-Apple Music')) {
      return Offset(size < 200 ? -2.0 : -5.0, size < 200 ? -2.0 : -3.0);
    }
    if (zoneName.endsWith('-SpotifyConnect')) {
      return Offset(size < 200 ? 2.0 : 0, size < 200 ? 4.0 : 5.0);
    }

    if (zoneName.endsWith('-Spotify')) {
      return Offset(2.0, size < 200 ? 4.0 : 5.0);
    }

    return Offset(4.0, 5.0);
  }

  double getZoneIconStaticSize({required String zoneName}) {
    if (zoneName.endsWith('-Apple Music')) {
      return 56.0;
    }
    if (zoneName.endsWith('-SpotifyConnect')) {
      return 44.0;
    }

    if (zoneName.endsWith('-Spotify')) {
      return 44.0;
    }

    return 40.0;
  }

  double getZoneIconDynamicSize(
      {required double size, required String zoneName}) {
    double factor = size < 200 ? 0.65 : 1.0;
    if (zoneName.endsWith('-Apple Music')) {
      return factor * 54.0;
    }
    if (zoneName.endsWith('-SpotifyConnect')) {
      return factor * 44.0;
    }

    if (zoneName.endsWith('-Spotify')) {
      return factor * 44.0;
    }

    return factor * 40.0;
  }

  statusCorner({required Color color, double? size}) => SizedBox(
        width: size != null && size < 200 ? 56 : 84,
        height: size != null && size < 200 ? 56 : 84,
        child: ClipRRect(
          child: CustomPaint(
            painter: TrianglePainter(
              color: color,
            ),
          ),
        ),
      );

  String replaceIllegalCharsInTickerString({
    required String str,
    bool replaceActiveZoneMarker = false,
  }) {
    if (str.length > 1 && str.startsWith('[') && str.endsWith(']')) {
      str = jsonDecode(str.replaceAll("'", '"')).join(
          ' '); // maybe troublemaker (should be replaced in python part on device)
      str = str.replaceAll('< ', ', ');
      str = str.replaceAll(' >', ': ');
    }
    if (replaceActiveZoneMarker) {
      str = str.replaceAll('[*]', '\u2736');
      str = str.replaceAll('=>', '\u21E2');
    }

    return str;
  }

  double getSafeHeight({required FlutterView viewData}) {
    //Safe area paddings in logical pixels
    double paddingTop = viewData.padding.top / viewData.devicePixelRatio;
    double paddingBottom = viewData.padding.bottom / viewData.devicePixelRatio;

    //Safe area in logical pixels
    double pixelRatio = viewData.devicePixelRatio;
    Size logicalScreenSize = viewData.physicalSize / pixelRatio;
    double logicalHeight = logicalScreenSize.height;
    double safeHeight = logicalHeight - paddingTop - paddingBottom;

    return safeHeight;
  }

  double getCoverSize({
    required FlutterView viewData,
    required MediaQueryData mediaQueryData,
    required bool coverRowDynamicSize,
    required bool showExportButton,
    required double? appBarHeight,
    required double itemListHeight,
  }) {
    final double minimumCoverSize = 100;
    final double smallCoverSize = 150;
    final double midCoverSize = 200;
    final double bigCoverSize = 250;
    final double exportButtonPaddingIos = 14.0;

    double coverSize = smallCoverSize;
    int minNumberOfListItems = 1;
    int minNumberOfCoversInRow = 2;

    if (!coverRowDynamicSize) {
      double boxSizeWidth = mediaQueryData.size.width;
      double boxSizeHeight = mediaQueryData.size.height;
      double preferredCoverSize =
          boxSizeWidth > minNumberOfCoversInRow * bigCoverSize &&
                  boxSizeHeight > minNumberOfCoversInRow * bigCoverSize
              ? bigCoverSize
              : boxSizeWidth > minNumberOfCoversInRow * midCoverSize &&
                      boxSizeHeight > minNumberOfCoversInRow * midCoverSize
                  ? midCoverSize
                  : smallCoverSize;
      if (SharedWidgets.isDesktopDevice()) {
        coverSize = preferredCoverSize;
      }

      if (SharedWidgets.isMobileDevice()) {
        double safeHeight = getSafeHeight(viewData: viewData);
        boxSizeHeight = safeHeight;

        double searchFieldAreaHeight = 44;
        double paddingTop = mediaQueryData.padding.top;
        double paddingBottom = mediaQueryData.padding.bottom;
        double exportButtonHeight =
            40; // height of export button (ios: CupertinoButton.filled)
        double exportButtonAreaHeight = showExportButton == true
            ? Platform.isIOS
                ? exportButtonHeight + 2 * exportButtonPaddingIos
                : 48 // height of export button (Android: ElevatedButton.icon)
            : 0;

        double partsToSubtract = (appBarHeight ?? 56) +
            searchFieldAreaHeight +
            exportButtonAreaHeight;
        double coverSizeMaxPossibleOnMobile = boxSizeHeight -
            partsToSubtract -
            minNumberOfListItems * itemListHeight;
        double listHeightArea = boxSizeHeight - partsToSubtract;
        int maxListCount = (listHeightArea / itemListHeight).floor();

        double listHeightMax = listHeightArea - preferredCoverSize;
        int listItemCount = (listHeightMax / itemListHeight).floor();
        coverSize = listHeightArea - (listItemCount * itemListHeight);
        if (listItemCount < minNumberOfListItems ||
            boxSizeWidth < minNumberOfCoversInRow * coverSize) {
          preferredCoverSize = smallCoverSize;
          listHeightMax = listHeightArea - preferredCoverSize;
          listItemCount = (listHeightMax / itemListHeight).floor();
          coverSize = listHeightArea - (listItemCount * itemListHeight);
        }
        if (listItemCount < minNumberOfListItems ||
            boxSizeWidth < minNumberOfCoversInRow * coverSize) {
          preferredCoverSize = smallCoverSize;
          listHeightMax = listHeightArea - preferredCoverSize;
          listItemCount = (listHeightMax / itemListHeight).ceil();
          coverSize = listHeightArea - (listItemCount * itemListHeight);
        }

        if (boxSizeWidth < minNumberOfCoversInRow * coverSize) {
          if (listItemCount < maxListCount) {
            listItemCount += 1;
            double testCoverSize =
                listHeightArea - (listItemCount * itemListHeight);
            if (testCoverSize >= minimumCoverSize) {
              coverSize = testCoverSize;
            }
          }
        }
        if (coverSize < minimumCoverSize &&
            listItemCount > minNumberOfListItems) {
          listItemCount -= 1;
          coverSize = listHeightArea - (listItemCount * itemListHeight);
        }

        if (kDebugMode) {
          debugPrint(
              'MainBloc/getCoverSize => boxSizeHeight: $boxSizeHeight, paddingTop: $paddingTop, paddingBottom: $paddingBottom, exportButtonAreaHeight: $exportButtonAreaHeight, partsToSubtract: $partsToSubtract, listHeightArea: $listHeightArea, listHeightMax: $listHeightMax, preferredCoverSize: $preferredCoverSize, minNumberOfListItems: $minNumberOfListItems, listItemCount: $listItemCount, itemListHeight: $itemListHeight, coverSizeMaxPossibleOnMobile: $coverSizeMaxPossibleOnMobile');
        }
      }
    }

    return coverSize;
  }

  String getZoneName({required Map<String, dynamic> info}) {
    String zoneName = '';
    if (info['control_id'] != null) {
      String controlId = info['control_id'];
      if (info['channels'] != null && info['channels'][controlId] != null) {
        if (info['channels'][controlId] == 'webserver') {
          zoneName = controlId;
        } else {
          zoneName = info['channels'][controlId];
        }
      }
    }

    return zoneName;
  }

  Future<Map<String, String>> getCustomMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messagesStr = prefs.getString('customMessages');
    Map<String, String> customMessages = messagesStr != null &&
            messagesStr.isNotEmpty &&
            messagesStr.substring(0, 1) == '{'
        ? (jsonDecode(messagesStr) as Map<String, dynamic>)
            .map((String k, dynamic v) => MapEntry(k, v as String))
        : {};
    return customMessages;
  }

  setCustomMessages({required Map<String, String> messages}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('customMessages', jsonEncode(messages));
  }

  Map<String, dynamic>? getZoneDataForControlId(Map<String, dynamic>? info) {
    Map<String, dynamic>? zone;

    if (info != null && info != {} && info.keys.contains('channels')) {
      String? controlId = info['control_id'];
      Map<String, dynamic> channels = info['channels'];

      if (controlId != null &&
          controlId.isNotEmpty &&
          channels.keys.contains(controlId)) {
        if (channels[controlId] == 'webserver' ||
            channels[controlId] == 'spotifyconnect') {
          List<String> controlIdParts = info['control_id'].split('-');
          String serverName = controlIdParts[0];
          String zoneName = controlIdParts[1];
          if (info['web_playouts'][serverName] != null) {
            List<dynamic> zones = info['web_playouts'][serverName];
            zone = zones.firstWhereOrNull(
                (dynamic el) => (el['zone'] as String) == zoneName);
          }
        } else {
          String zoneName = channels[controlId];
          if (info['roon_playouts'][zoneName] != null) {
            zone = info['roon_playouts'][zoneName];
          }
        }
      }
    }

    return zone;
  }
}
