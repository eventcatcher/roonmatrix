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
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? ipStart = prefs.getString('ipStart');
        String? ipEnd = prefs.getString('ipEnd');
        bool validIp = validateIp(ip: ipStart) && validateIp(ip: ipEnd);
        bool moreInfo = prefs.getBool('moreInfo') ?? false;
        bool coverRowActiv = prefs.getBool('coverRowActiv') ?? false;
        bool coverRowTrack = prefs.getBool('coverRowTrack') ?? false;
        bool coverRowDynamicSize =
            prefs.getBool('coverRowDynamicSize') ?? false;

        emit(SettingsStateLoaded(
          ipStart: validIp ? ipStart! : state.ipStart,
          ipEnd: validIp ? ipEnd! : state.ipEnd,
          moreInfo: moreInfo,
          coverRowActiv: coverRowActiv,
          coverRowTrack: coverRowTrack,
          coverRowDynamicSize: coverRowDynamicSize,
        ));
      }

      if (event is SetIpRange) {
        String ipStart = event.ipStart;
        String ipEnd = event.ipEnd;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        if (validateIp(ip: ipStart) && validateIp(ip: ipEnd)) {
          prefs.setString('ipStart', ipStart);
          prefs.setString('ipEnd', ipEnd);
        }

        emit(SettingsStateLoaded(
          ipStart: ipStart,
          ipEnd: ipEnd,
          moreInfo: state.moreInfo,
          coverRowActiv: state.coverRowActiv,
          coverRowTrack: state.coverRowTrack,
          coverRowDynamicSize: state.coverRowDynamicSize,
        ));
      }

      if (event is SetMoreInfoMode) {
        bool enabled = event.enabled;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('moreInfo', enabled);

        emit(SettingsStateLoaded(
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          moreInfo: enabled,
          coverRowActiv: state.coverRowActiv,
          coverRowTrack: state.coverRowTrack,
          coverRowDynamicSize: state.coverRowDynamicSize,
        ));
      }

      if (event is SetCoverRowActiveMode) {
        bool enabled = event.enabled;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowActiv', enabled);

        emit(SettingsStateLoaded(
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          moreInfo: state.moreInfo,
          coverRowActiv: enabled,
          coverRowTrack: state.coverRowTrack,
          coverRowDynamicSize: state.coverRowDynamicSize,
        ));
      }

      if (event is SetCoverRowTrackeMode) {
        bool enabled = event.enabled;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowTrack', enabled);

        emit(SettingsStateLoaded(
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          moreInfo: state.moreInfo,
          coverRowActiv: state.coverRowActiv,
          coverRowTrack: enabled,
          coverRowDynamicSize: state.coverRowDynamicSize,
        ));
      }

      if (event is SetCoverRowDynamicSizeMode) {
        bool enabled = event.enabled;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('coverRowDynamicSize', enabled);

        emit(SettingsStateLoaded(
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          moreInfo: state.moreInfo,
          coverRowActiv: state.coverRowActiv,
          coverRowTrack: state.coverRowTrack,
          coverRowDynamicSize: enabled,
        ));
      }
    });

    loadDefaults();
  }

  // ============== //
  // public methods //
  // ============== //

  Future<void> deletePrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("ipStart");
    await prefs.remove("ipEnd");
    await prefs.remove("moreInfo");
    await prefs.remove("coverRowActiv");
    await prefs.remove("coverRowTrack");
    await prefs.remove("coverRowDynamicSize");
  }

  bool validateIp({required String? ip}) =>
      ip != null &&
      ip.isNotEmpty &&
      ip.split('.').length == 4 &&
      ip.split('.').every((String el) => el.isNotEmpty && el.length <= 3);

  bool validateIpRange({required String? ipStart, required String? ipEnd}) {
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

  String getIpFieldErrorMessage(
      {required String value, required Map<String, dynamic> translations}) {
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

  void setIpRange({required String ipStart, required String ipEnd}) {
    add(SetIpRange(ipStart: ipStart, ipEnd: ipEnd));
  }

  void setMoreInfoMode({required bool enabled}) {
    add(SetMoreInfoMode(enabled: enabled));
  }

  void setCoverRowActiveMode({required bool enabled}) {
    add(SetCoverRowActiveMode(enabled: enabled));
  }

  void setCoverRowTrackeMode({required bool enabled}) {
    add(SetCoverRowTrackeMode(enabled: enabled));
  }

  void setCoverRowDynamicSizeMode({required bool enabled}) {
    add(SetCoverRowDynamicSizeMode(enabled: enabled));
  }
}
