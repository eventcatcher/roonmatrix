import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:roonmatrix/model/scroll_speed_variant.dart';
import 'package:roonmatrix/ui/settings/settings_event.dart';
import 'package:roonmatrix/ui/settings/settings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<SettingsEvent>((event, emit) async {
      if (event is SettingsStateLoadDefaults) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        String? ipStart = prefs.getString('ipStart');
        String? ipEnd = prefs.getString('ipEnd');
        bool validIp = validateIp(ip: ipStart) && validateIp(ip: ipEnd);
        bool moreInfo = prefs.getBool('moreInfo') ?? false;
        bool coverRowActive = prefs.getBool('coverRowActive') ?? true;
        bool coverRowArtist = prefs.getBool('coverRowArtist') ?? true;
        bool coverRowAlbum = prefs.getBool('coverRowAlbum') ?? true;
        bool coverRowTrack = prefs.getBool('coverRowTrack') ?? true;
        bool coverRowDynamicSize =
            prefs.getBool('coverRowDynamicSize') ?? false;
        String scrollSpeedDeviceMapJsonStr =
            prefs.getString('scrollSpeedDeviceMap') ?? '';
        Map<String, dynamic> scrollSpeedDeviceMap =
            scrollSpeedDeviceMapJsonStr.isNotEmpty
                ? jsonDecode(scrollSpeedDeviceMapJsonStr)
                : {};
        if (kDebugMode) {
          debugPrint(
              'speedcheck => load scrollSpeedDeviceMap: $scrollSpeedDeviceMap');
        }
        bool verticalTickerActive =
            prefs.getBool('verticalTickerActive') ?? true;
        bool ledTickerInDeviceListActive =
            prefs.getBool('ledTickerInDeviceListActive') ?? true;
        bool ledTickerOnTickerPageActive =
            prefs.getBool('ledTickerOnTickerPageActive') ?? true;
        bool ledTickerPixelShiftActive =
            prefs.getBool('ledTickerPixelShiftActive') ?? true;
        bool forceTickerUpdateActive =
            prefs.getBool('forceTickerUpdateActive') ?? false;
        bool miniPlayerAlwaysOnTop =
            prefs.getBool('miniPlayerAlwaysOnTop') ?? true;
        bool miniPlayerPreventCloseApp =
            prefs.getBool('miniPlayerPreventCloseApp') ?? true;
        bool miniPlayerShowTextInfoOnTrackChange =
            prefs.getBool('miniPlayerShowTextInfoOnTrackChange') ?? true;
        int miniPlayerTextInfoDuration =
            prefs.getInt('miniPlayerTextInfoDuration') ?? 10;

        emit(SettingsStateLoaded(
          ipStart: validIp ? ipStart! : state.ipStart,
          ipEnd: validIp ? ipEnd! : state.ipEnd,
          moreInfo: moreInfo,
          coverRowActive: coverRowActive,
          coverRowArtist: coverRowArtist,
          coverRowAlbum: coverRowAlbum,
          coverRowTrack: coverRowTrack,
          coverRowDynamicSize: coverRowDynamicSize,
          scrollSpeedDeviceMap: scrollSpeedDeviceMap,
          verticalTickerActive: verticalTickerActive,
          ledTickerInDeviceListActive: ledTickerInDeviceListActive,
          ledTickerOnTickerPageActive: ledTickerOnTickerPageActive,
          ledTickerPixelShiftActive: ledTickerPixelShiftActive,
          forceTickerUpdateActive: forceTickerUpdateActive,
          miniPlayerAlwaysOnTop: miniPlayerAlwaysOnTop,
          miniPlayerPreventCloseApp: miniPlayerPreventCloseApp,
          miniPlayerShowTextInfoOnTrackChange:
              miniPlayerShowTextInfoOnTrackChange,
          miniPlayerTextInfoDuration: miniPlayerTextInfoDuration,
        ));
      }

      if (event is SetIpRange) {
        String ipStart = event.ipStart;
        String ipEnd = event.ipEnd;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        if (validateIp(ip: ipStart) && validateIp(ip: ipEnd)) {
          prefs.setString('ipStart', ipStart);
          prefs.setString('ipEnd', ipEnd);
        }

        emit(state.copyWith(
          ipStart: ipStart,
          ipEnd: ipEnd,
        ));
      }

      if (event is SetMoreInfoMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('moreInfo', enabled);

        emit(state.copyWith(
          moreInfo: enabled,
        ));
      }

      if (event is SetCoverRowActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowActive', enabled);

        emit(state.copyWith(
          coverRowActive: enabled,
        ));
      }

      if (event is SetCoverRowArtistMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowArtist', enabled);

        emit(state.copyWith(
          coverRowArtist: enabled,
        ));
      }
      if (event is SetCoverRowAlbumMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowAlbum', enabled);

        emit(state.copyWith(
          coverRowAlbum: enabled,
        ));
      }

      if (event is SetCoverRowTrackMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowTrack', enabled);

        emit(state.copyWith(
          coverRowTrack: enabled,
        ));
      }

      if (event is SetCoverRowDynamicSizeMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowDynamicSize', enabled);

        emit(state.copyWith(
          coverRowDynamicSize: enabled,
        ));
      }

      if (event is SetVerticalTickerActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('verticalTickerActive', enabled);

        emit(state.copyWith(
          verticalTickerActive: enabled,
        ));
      }

      if (event is SetLedTickerInDeviceListActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('ledTickerInDeviceListActive', enabled);

        emit(state.copyWith(
          ledTickerInDeviceListActive: enabled,
        ));
      }

      if (event is SetLedTickerOnTickerPageActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('ledTickerOnTickerPageActive', enabled);

        emit(state.copyWith(
          ledTickerOnTickerPageActive: enabled,
        ));
      }

      if (event is SetLedTickerPixelShiftActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('ledTickerPixelShiftActive', enabled);

        emit(state.copyWith(
          ledTickerPixelShiftActive: enabled,
        ));
      }

      if (event is SetForceTickerUpdateActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('forceTickerUpdateActive', enabled);

        emit(state.copyWith(
          forceTickerUpdateActive: enabled,
        ));
      }

      if (event is SetMiniPlayerAlwaysOnTopMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('miniPlayerAlwaysOnTop', enabled);

        emit(state.copyWith(
          miniPlayerAlwaysOnTop: enabled,
        ));
      }

      if (event is SetMiniPlayerPreventCloseAppMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('miniPlayerPreventCloseApp', enabled);

        emit(state.copyWith(
          miniPlayerPreventCloseApp: enabled,
        ));
      }

      if (event is SetMiniPlayerShowTextInfoOnTrackChangeMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('miniPlayerShowTextInfoOnTrackChange', enabled);

        emit(state.copyWith(
          miniPlayerShowTextInfoOnTrackChange: enabled,
        ));
      }

      if (event is SetMiniPlayerTextInfoDuration) {
        int seconds = event.seconds;

        if (seconds > 0) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setInt('miniPlayerTextInfoDuration', seconds);

          emit(state.copyWith(
            miniPlayerTextInfoDuration: seconds,
          ));
        }
      }

      if (event is SetScrollSpeedDevice) {
        String key = event.key;
        double scrollSpeedDevice = event.speed;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setDouble('scrollSpeedDevice', scrollSpeedDevice);

        if (key.isNotEmpty && key.contains('.')) {
          Map<String, dynamic> scrollSpeedDeviceMap =
              Map<String, dynamic>.from(state.scrollSpeedDeviceMap);
          scrollSpeedDeviceMap[key] = scrollSpeedDevice;
          prefs.setString(
              'scrollSpeedDeviceMap', jsonEncode(scrollSpeedDeviceMap));
          if (kDebugMode) {
            debugPrint(
                'speedcheck => save scrollSpeedDeviceMap: $scrollSpeedDeviceMap');
          }

          emit(state.copyWith(
            scrollSpeedDeviceMap: scrollSpeedDeviceMap,
          ));
        }
      }
    });

    loadDefaults();
  }

  // ============== //
  // public methods //
  // ============== //

  Future<void> deletePrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> prefsToRemoveList = [
      'ipStart',
      'ipEnd',
      'moreInfo',
      'coverRowActive',
      'coverRowArtist',
      'coverRowAlbum',
      'coverRowTrack',
      'coverRowDynamicSize',
      'scrollSpeedDeviceMap',
      'verticalTickerActive',
      'ledTickerInDeviceListActive',
      'ledTickerOnTickerPageActive',
      'ledTickerPixelShiftActive',
      'forceTickerUpdateActive',
      'miniPlayerAlwaysOnTop',
      'miniPlayerPreventCloseApp',
      'miniPlayerShowTextInfoOnTrackChange',
      'miniPlayerTextInfoDuration',
    ];
    for (String key in prefsToRemoveList) {
      await prefs.remove(key);
    }
  }

  bool validateIp({
    required String? ip,
  }) =>
      ip != null &&
      ip.isNotEmpty &&
      ip.split('.').length == 4 &&
      ip.split('.').every((String el) => el.isNotEmpty && el.length <= 3);

  bool validateIpRange({
    required String? ipStart,
    required String? ipEnd,
  }) {
    if (validateIp(ip: ipStart) && validateIp(ip: ipEnd)) {
      int lastDot = ipStart!.lastIndexOf('.');
      String firstPart = ipStart.substring(0, lastDot + 1);
      if (ipEnd!.startsWith(firstPart)) {
        int? lastPartStart = int.tryParse(ipStart.substring(lastDot + 1));
        int? lastPartEnd = int.tryParse(ipEnd.substring(lastDot + 1));
        return lastPartStart != null &&
            lastPartEnd != null &&
            lastPartEnd >= lastPartStart;
      }
    }

    return false;
  }

  String getIpFieldErrorMessage({
    required String value,
    required Map<String, dynamic> translations,
  }) {
    if (value.isEmpty) {
      return translations['settingsIpFieldEmptyError'] ??
          'IP field cannot be empty';
    }

    if (!validateIp(ip: value)) {
      return translations['settingsIpFieldInvalidError'] ?? 'IP is invalid';
    }

    return '';
  }

  String getScrollSpeedKey({
    required String ip,
    required ScrollSpeedVariant variant,
  }) {
    String key =
        '$ip-${variant.isStandAlone}-${variant.isLedVariant}-${variant.isVertical}';

    return key;
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void loadDefaults() {
    add(SettingsStateLoadDefaults());
  }

  void setIpRange({
    required String ipStart,
    required String ipEnd,
  }) {
    add(SetIpRange(ipStart: ipStart, ipEnd: ipEnd));
  }

  void setMoreInfoMode({
    required bool enabled,
  }) {
    add(SetMoreInfoMode(enabled: enabled));
  }

  void setCoverRowActiveMode({
    required bool enabled,
  }) {
    add(SetCoverRowActiveMode(enabled: enabled));
  }

  void setCoverRowArtistMode({
    required bool enabled,
  }) {
    add(SetCoverRowArtistMode(enabled: enabled));
  }

  void setCoverRowAlbumMode({
    required bool enabled,
  }) {
    add(SetCoverRowAlbumMode(enabled: enabled));
  }

  void setCoverRowTrackMode({
    required bool enabled,
  }) {
    add(SetCoverRowTrackMode(enabled: enabled));
  }

  void setCoverRowDynamicSizeMode({
    required bool enabled,
  }) {
    add(SetCoverRowDynamicSizeMode(enabled: enabled));
  }

  void setScrollSpeedDevice({
    required String key,
    required double speed,
  }) {
    add(SetScrollSpeedDevice(key: key, speed: speed));
  }

  void setVerticalTickerActiveMode({
    required bool enabled,
  }) {
    add(SetVerticalTickerActiveMode(enabled: enabled));
  }

  void setLedTickerInDeviceListActiveMode({
    required bool enabled,
  }) {
    add(SetLedTickerInDeviceListActiveMode(enabled: enabled));
  }

  void setLedTickerOnTickerPageActiveMode({
    required bool enabled,
  }) {
    add(SetLedTickerOnTickerPageActiveMode(enabled: enabled));
  }

  void setLedTickerPixelShiftActiveMode({
    required bool enabled,
  }) {
    add(SetLedTickerPixelShiftActiveMode(enabled: enabled));
  }

  void setForceTickerUpdateActiveMode({
    required bool enabled,
  }) {
    add(SetForceTickerUpdateActiveMode(enabled: enabled));
  }

  void setMiniPlayerAlwaysOnTopMode({
    required bool enabled,
  }) {
    add(SetMiniPlayerAlwaysOnTopMode(enabled: enabled));
  }

  void setMiniPlayerPreventCloseAppMode({
    required bool enabled,
  }) {
    add(SetMiniPlayerPreventCloseAppMode(enabled: enabled));
  }

  void setMiniPlayerShowTextInfoOnTrackChangeMode({
    required bool enabled,
  }) {
    add(SetMiniPlayerShowTextInfoOnTrackChangeMode(enabled: enabled));
  }

  void setMiniPlayerTextInfoDuration({
    required int seconds,
  }) {
    add(SetMiniPlayerTextInfoDuration(seconds: seconds));
  }
}
