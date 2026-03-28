import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  final String ipStart;
  final String ipEnd;
  final bool moreInfo;
  final bool coverRowActive;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final bool coverRowDynamicSize;
  final double scrollSpeedDevice;
  final Map<String, dynamic> scrollSpeedDeviceMap;
  final double scrollSpeedScrollMatrix;
  final Map<String, dynamic> scrollSpeedScrollMatrixDeviceMap;
  final bool verticalTickerActive;
  final bool ledTickerInDeviceListActive;
  final bool ledTickerOnTickerPageActive;
  final bool ledTickerPixelShiftActive;
  final bool forceTickerUpdateActive;
  final bool miniPlayerAlwaysOnTop;
  final bool miniPlayerPreventCloseApp;

  const SettingsState({
    this.ipStart = '',
    this.ipEnd = '',
    this.moreInfo = false,
    this.coverRowActive = true,
    this.coverRowArtist = false,
    this.coverRowAlbum = false,
    this.coverRowTrack = true,
    this.coverRowDynamicSize = true,
    this.scrollSpeedDevice = 1.0,
    this.scrollSpeedDeviceMap = const {},
    this.scrollSpeedScrollMatrix = 1.0,
    this.scrollSpeedScrollMatrixDeviceMap = const {},
    this.verticalTickerActive = false,
    this.ledTickerInDeviceListActive = false,
    this.ledTickerOnTickerPageActive = false,
    this.ledTickerPixelShiftActive = false,
    this.forceTickerUpdateActive = false,
    this.miniPlayerAlwaysOnTop = false,
    this.miniPlayerPreventCloseApp = false,
  });

  SettingsState copyWith({
    String? ipStart,
    String? ipEnd,
    bool? moreInfo,
    bool? coverRowActive,
    bool? coverRowArtist,
    bool? coverRowAlbum,
    bool? coverRowTrack,
    bool? coverRowDynamicSize,
    double? scrollSpeedDevice,
    Map<String, dynamic>? scrollSpeedDeviceMap,
    double? scrollSpeedScrollMatrix,
    Map<String, dynamic>? scrollSpeedScrollMatrixDeviceMap,
    bool? verticalTickerActive,
    bool? ledTickerInDeviceListActive,
    bool? ledTickerOnTickerPageActive,
    bool? ledTickerPixelShiftActive,
    bool? forceTickerUpdateActive,
    bool? miniPlayerAlwaysOnTop,
    bool? miniPlayerPreventCloseApp,
  }) {
    return SettingsStateLoaded(
      ipStart: ipStart ?? this.ipStart,
      ipEnd: ipEnd ?? this.ipEnd,
      moreInfo: moreInfo ?? this.moreInfo,
      coverRowActive: coverRowActive ?? this.coverRowActive,
      coverRowArtist: coverRowArtist ?? this.coverRowArtist,
      coverRowAlbum: coverRowAlbum ?? this.coverRowAlbum,
      coverRowTrack: coverRowTrack ?? this.coverRowTrack,
      coverRowDynamicSize: coverRowDynamicSize ?? this.coverRowDynamicSize,
      scrollSpeedDevice: scrollSpeedDevice ?? this.scrollSpeedDevice,
      scrollSpeedDeviceMap: scrollSpeedDeviceMap ?? this.scrollSpeedDeviceMap,
      scrollSpeedScrollMatrix:
          scrollSpeedScrollMatrix ?? this.scrollSpeedScrollMatrix,
      scrollSpeedScrollMatrixDeviceMap: scrollSpeedScrollMatrixDeviceMap ??
          this.scrollSpeedScrollMatrixDeviceMap,
      verticalTickerActive: verticalTickerActive ?? this.verticalTickerActive,
      ledTickerInDeviceListActive:
          ledTickerInDeviceListActive ?? this.ledTickerInDeviceListActive,
      ledTickerOnTickerPageActive:
          ledTickerOnTickerPageActive ?? this.ledTickerOnTickerPageActive,
      ledTickerPixelShiftActive:
          ledTickerPixelShiftActive ?? this.ledTickerPixelShiftActive,
      forceTickerUpdateActive:
          forceTickerUpdateActive ?? this.forceTickerUpdateActive,
      miniPlayerAlwaysOnTop:
          miniPlayerAlwaysOnTop ?? this.miniPlayerAlwaysOnTop,
      miniPlayerPreventCloseApp:
          miniPlayerPreventCloseApp ?? this.miniPlayerPreventCloseApp,
    );
  }

  @override
  List<Object> get props {
    List<Object> props = [
      ipStart,
      ipEnd,
      moreInfo,
      coverRowActive,
      coverRowArtist,
      coverRowAlbum,
      coverRowTrack,
      coverRowDynamicSize,
      scrollSpeedDevice,
      scrollSpeedDeviceMap,
      scrollSpeedScrollMatrix,
      scrollSpeedScrollMatrixDeviceMap,
      verticalTickerActive,
      ledTickerInDeviceListActive,
      ledTickerOnTickerPageActive,
      ledTickerPixelShiftActive,
      forceTickerUpdateActive,
      miniPlayerAlwaysOnTop,
      miniPlayerPreventCloseApp,
    ];

    return props;
  }

  @override
  String toString() => 'SettingsState';
}

class SettingsStateInitial extends SettingsState {
  const SettingsStateInitial();

  @override
  String toString() => 'SettingsStateInitial';
}

class SettingsStateLoaded extends SettingsState {
  const SettingsStateLoaded({
    required super.ipStart,
    required super.ipEnd,
    required super.moreInfo,
    required super.coverRowActive,
    required super.coverRowArtist,
    required super.coverRowAlbum,
    required super.coverRowTrack,
    required super.coverRowDynamicSize,
    required super.scrollSpeedDevice,
    required super.scrollSpeedDeviceMap,
    required super.scrollSpeedScrollMatrix,
    required super.scrollSpeedScrollMatrixDeviceMap,
    required super.verticalTickerActive,
    required super.ledTickerInDeviceListActive,
    required super.ledTickerOnTickerPageActive,
    required super.ledTickerPixelShiftActive,
    required super.forceTickerUpdateActive,
    required super.miniPlayerAlwaysOnTop,
    required super.miniPlayerPreventCloseApp,
  });

  @override
  String toString() => 'SettingsStateLoaded';
}
