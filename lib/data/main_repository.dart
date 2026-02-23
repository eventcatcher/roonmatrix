import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/triangle_painter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class MainRepository {
  MainRepository();

  bool isRoonZone(String zoneName) {
    return !zoneName.endsWith('-Apple Music') &&
        !zoneName.endsWith('-SpotifyConnect') &&
        !zoneName.endsWith('-Spotify');
  }

  String getFormattedDateString({
    required String date,
    String languageCode = 'de',
    String format = 'dd.MM.yyyy HH:mm:ss',
  }) {
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

  Offset getZoneIconPositionBySize({
    required double size,
    required String zoneName,
  }) {
    if (zoneName.endsWith('-Apple Music')) {
      return Offset(size < Globals.zoneCornerFullSize ? -2.0 : -5.0,
          size < Globals.zoneCornerFullSize ? -2.0 : -3.0);
    }
    if (zoneName.endsWith('-SpotifyConnect')) {
      return Offset(size < Globals.zoneCornerFullSize ? 2.0 : 0,
          size < Globals.zoneCornerFullSize ? 4.0 : 5.0);
    }

    if (zoneName.endsWith('-Spotify')) {
      return Offset(2.0, size < Globals.zoneCornerFullSize ? 4.0 : 5.0);
    }

    return Offset(4.0, 5.0);
  }

  double getZoneIconDynamicSize({
    required double size,
    required String zoneName,
  }) {
    double factor = size < Globals.zoneCornerFullSize ? 0.65 : 1.0;
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

  Widget statusCorner({
    required Color color,
    double? size,
  }) =>
      SizedBox(
        width: size != null && size < Globals.zoneCornerFullSize ? 56 : 84,
        height: size != null && size < Globals.zoneCornerFullSize ? 56 : 84,
        child: ClipRRect(
          child: CustomPaint(
            painter: TrianglePainter(
              color: color,
            ),
          ),
        ),
      );

  double getSafeHeight({
    required FlutterView viewData,
  }) {
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
      if (Globals.isDesktopDevice()) {
        coverSize = preferredCoverSize;
      }

      if (Globals.isMobileDevice()) {
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

  String getZoneName({
    required Map<String, dynamic> info,
  }) {
    String zoneName = '';
    if (info['control_id'] != null) {
      String controlId = info['control_id'];
      if (info['channels'] != null && info['channels'][controlId] != null) {
        if (info['channels'][controlId] == 'webserver' ||
            info['channels'][controlId] == 'spotifyconnect') {
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

  void setCustomMessages({
    required Map<String, String> messages,
  }) async {
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

  String getSelectedPlayoutOptionKey({
    required String option,
    required Map<String, dynamic> translations,
  }) {
    if (option == translations['sendOptionForce'] ||
        option == 'Force Playout') {
      return 'force';
    }
    if (option == translations['sendOptionNextPlayout'] ||
        option == 'On next Playout') {
      return 'playout';
    }
    if (option == translations['sendOptionExclusive'] ||
        option == 'Exclusive Playout') {
      return 'exclusive';
    }

    return 'playout';
  }

  String getDebounceTag({
    required String? label,
  }) {
    String tag = "";

    if (label != null) {
      tag = label.replaceAll(" ", "-");
    } else {
      Uuid uuid = const Uuid();
      tag = uuid.v4();
    }

    return tag;
  }

  String? getCoverUrl({
    required Map<String, dynamic>? zone,
  }) =>
      zone != null &&
              zone['cover'] != null &&
              (zone['cover'] as String).isNotEmpty
          ? zone['cover']
          : null;

  String getTimeZonePlaycountText({
    required Map<String, dynamic> translations,
    required Map<String, dynamic> info,
    required String zoneName,
    String? ip,
    bool withLineBreak = false,
  }) {
    String text =
        '${translations['deviceListTime'] ?? 'time'}: ${getFormattedDateString(date: info['time'])}${withLineBreak ? '\n' : '  |  '}${translations['deviceListZone'] ?? 'zone'}: $zoneName  |  ${translations['deviceListPlaycount'] ?? 'playcount'}: ${info['playcount']}  ';
    if (ip != null) {
      text = 'IP: $ip  |  $text';
    }

    return text;
  }

  String getPercentText({
    required String valueType,
    required double sliderValue,
    required double max,
  }) =>
      '${valueType == '%' ? (sliderValue / max * 100).round() : sliderValue.floor()} $valueType';

  bool coverExistInZone({
    required Map<String, dynamic>? zone,
  }) =>
      zone?['cover'] != null && (zone!['cover'] as String).isNotEmpty;

  Map<String, dynamic> generateLogParts({
    required String logstr,
    required int logfileSliceSize,
  }) {
    String fullLog = logstr;
    int parts = 1;
    int offset = 0;
    List<int> logfilePartOffset = [];
    if (logstr.isNotEmpty) {
      logfilePartOffset = [0];
      parts = 0;
      do {
        parts++;
        if (fullLog.length > logfileSliceSize) {
          offset = logfilePartOffset[parts - 1];
          logstr = fullLog.substring(offset);
          if (logstr.length > logfileSliceSize) {
            int endOfLine = 0;
            if ((logfileSliceSize) < logstr.length) {
              endOfLine = logstr.substring(logfileSliceSize).indexOf('\n');
            }
            int partlen =
                logfileSliceSize + (endOfLine == -1 ? 0 : (endOfLine + 1));
            logstr = logstr.substring(0, partlen);
          }

          if (logfilePartOffset.length <= parts) {
            logfilePartOffset.add(offset + logstr.length);
          }
        }
      } while (fullLog.length > logfileSliceSize &&
          fullLog.length > (offset + logstr.length));
    }

    return {"parts": parts, "logfilePartOffset": logfilePartOffset};
  }

  bool dateTimeHeadHasChanged({
    required String newLog,
    required String lastLog,
    int dateTimeLength = 17,
  }) =>
      newLog.isNotEmpty &&
      lastLog.length != newLog.length &&
      (lastLog.isEmpty ||
          (lastLog.length > dateTimeLength &&
              newLog.length > dateTimeLength &&
              lastLog.substring(0, dateTimeLength) !=
                  newLog.substring(0, dateTimeLength)));
}
