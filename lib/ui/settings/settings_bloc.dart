import 'dart:convert';

import 'package:flutter/foundation.dart';
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
        double scrollSpeedDevice = prefs.getDouble('scrollSpeedDevice') ?? 1.0;
        String scrollSpeedDeviceMapJsonStr =
            prefs.getString('scrollSpeedDeviceMap') ?? '';
        Map<String, dynamic> scrollSpeedDeviceMap =
            scrollSpeedDeviceMapJsonStr.isNotEmpty
                ? jsonDecode(scrollSpeedDeviceMapJsonStr)
                : {};
        double scrollSpeedScrollMatrix =
            prefs.getDouble('scrollSpeedScrollMatrix') ?? 1.0;
        String scrollSpeedScrollMatrixDeviceMapJsonStr =
            prefs.getString('scrollSpeedScrollMatrixDeviceMap') ?? '';
        Map<String, dynamic> scrollSpeedScrollMatrixDeviceMap =
            scrollSpeedScrollMatrixDeviceMapJsonStr.isNotEmpty
                ? jsonDecode(scrollSpeedScrollMatrixDeviceMapJsonStr)
                : {};
        if (kDebugMode) {
          debugPrint('load scrollSpeedDeviceMap: $scrollSpeedDeviceMap');
          debugPrint(
              'load scrollSpeedScrollMatrixDeviceMap: $scrollSpeedScrollMatrixDeviceMap');
        }
        bool verticalTickerActive =
            prefs.getBool('verticalTickerActive') ?? true;
        bool ledTickerInDeviceListActive =
            prefs.getBool('ledTickerInDeviceListActive') ?? true;
        bool ledTickerOnTickerPageActive =
            prefs.getBool('ledTickerOnTickerPageActive') ?? true;
        bool forceTickerUpdateActive =
            prefs.getBool('forceTickerUpdateActive') ?? false;

        emit(SettingsStateLoaded(
          ipStart: validIp ? ipStart! : state.ipStart,
          ipEnd: validIp ? ipEnd! : state.ipEnd,
          moreInfo: moreInfo,
          coverRowActive: coverRowActive,
          coverRowArtist: coverRowArtist,
          coverRowAlbum: coverRowAlbum,
          coverRowTrack: coverRowTrack,
          coverRowDynamicSize: coverRowDynamicSize,
          scrollSpeedDevice: scrollSpeedDevice,
          scrollSpeedDeviceMap: scrollSpeedDeviceMap,
          scrollSpeedScrollMatrix: scrollSpeedScrollMatrix,
          scrollSpeedScrollMatrixDeviceMap: scrollSpeedScrollMatrixDeviceMap,
          verticalTickerActive: verticalTickerActive,
          ledTickerInDeviceListActive: ledTickerInDeviceListActive,
          ledTickerOnTickerPageActive: ledTickerOnTickerPageActive,
          forceTickerUpdateActive: forceTickerUpdateActive,
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

      if (event is SetScrollSpeedDevice) {
        String ip = event.ip;
        double scrollSpeedDevice = event.speed;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setDouble('scrollSpeedDevice', scrollSpeedDevice);

        if (ip.isNotEmpty) {
          Map<String, dynamic> scrollSpeedDeviceMap =
              Map<String, dynamic>.from(state.scrollSpeedDeviceMap);
          scrollSpeedDeviceMap[ip] = scrollSpeedDevice;
          prefs.setString(
              'scrollSpeedDeviceMap', jsonEncode(scrollSpeedDeviceMap));
          if (kDebugMode) {
            debugPrint('save scrollSpeedDeviceMap: $scrollSpeedDeviceMap');
          }

          emit(state.copyWith(
            scrollSpeedDeviceMap: scrollSpeedDeviceMap,
            scrollSpeedDevice: scrollSpeedDevice,
          ));
        } else {
          emit(state.copyWith(
            scrollSpeedDevice: scrollSpeedDevice,
          ));
        }
      }

      if (event is SetScrollSpeedScrollMatrix) {
        String ip = event.ip;
        double scrollSpeedScrollMatrix = event.speed;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setDouble('scrollSpeedScrollMatrix', scrollSpeedScrollMatrix);

        if (ip.isNotEmpty) {
          Map<String, dynamic> scrollSpeedScrollMatrixDeviceMap =
              Map<String, dynamic>.from(state.scrollSpeedScrollMatrixDeviceMap);
          scrollSpeedScrollMatrixDeviceMap[ip] = scrollSpeedScrollMatrix;
          prefs.setString('scrollSpeedScrollMatrixDeviceMap',
              jsonEncode(scrollSpeedScrollMatrixDeviceMap));
          if (kDebugMode) {
            debugPrint(
                'save scrollSpeedScrollMatrixDeviceMap: $scrollSpeedScrollMatrixDeviceMap');
          }

          emit(state.copyWith(
            scrollSpeedScrollMatrixDeviceMap: scrollSpeedScrollMatrixDeviceMap,
            scrollSpeedScrollMatrix: scrollSpeedScrollMatrix,
          ));
        } else {
          emit(state.copyWith(
            scrollSpeedScrollMatrix: scrollSpeedScrollMatrix,
          ));
        }
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

      if (event is SetForceTickerUpdateActiveMode) {
        bool enabled = event.enabled;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('forceTickerUpdateActive', enabled);

        emit(state.copyWith(
          forceTickerUpdateActive: enabled,
        ));
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
      'scrollSpeedDevice',
      'scrollSpeedDeviceMap',
      'scrollSpeedScrollMatrix',
      'scrollSpeedScrollMatrixDeviceMap',
      'verticalTickerActive',
      'ledTickerInDeviceListActive',
      'ledTickerOnTickerPageActive',
      'forceTickerUpdateActive',
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
    required String ip,
    required double speed,
  }) {
    add(SetScrollSpeedDevice(ip: ip, speed: speed));
  }

  void setScrollSpeedScrollMatrix({
    required String ip,
    required double speed,
  }) {
    add(SetScrollSpeedScrollMatrix(ip: ip, speed: speed));
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

  void setForceTickerUpdateActiveMode({
    required bool enabled,
  }) {
    add(SetForceTickerUpdateActiveMode(enabled: enabled));
  }
}
