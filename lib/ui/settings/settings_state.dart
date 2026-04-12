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
  final Map<String, dynamic> scrollSpeedDeviceMap;
  final bool verticalTickerActive;
  final bool ledTickerInDeviceListActive;
  final bool ledTickerOnTickerPageActive;
  final bool ledTickerPixelShiftActive;
  final bool forceTickerUpdateActive;
  final bool miniPlayerAlwaysOnTop;
  final bool miniPlayerPreventCloseApp;
  final bool miniPlayerShowTextInfoOnTrackChange;
  final int miniPlayerTextInfoDuration;

  const SettingsState({
    this.ipStart = '',
    this.ipEnd = '',
    this.moreInfo = false,
    this.coverRowActive = true,
    this.coverRowArtist = false,
    this.coverRowAlbum = false,
    this.coverRowTrack = true,
    this.coverRowDynamicSize = true,
    this.scrollSpeedDeviceMap = const {},
    this.verticalTickerActive = false,
    this.ledTickerInDeviceListActive = false,
    this.ledTickerOnTickerPageActive = false,
    this.ledTickerPixelShiftActive = false,
    this.forceTickerUpdateActive = false,
    this.miniPlayerAlwaysOnTop = false,
    this.miniPlayerPreventCloseApp = false,
    this.miniPlayerShowTextInfoOnTrackChange = false,
    this.miniPlayerTextInfoDuration = 10,
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
    Map<String, dynamic>? scrollSpeedDeviceMap,
    bool? verticalTickerActive,
    bool? ledTickerInDeviceListActive,
    bool? ledTickerOnTickerPageActive,
    bool? ledTickerPixelShiftActive,
    bool? forceTickerUpdateActive,
    bool? miniPlayerAlwaysOnTop,
    bool? miniPlayerPreventCloseApp,
    bool? miniPlayerShowTextInfoOnTrackChange,
    int? miniPlayerTextInfoDuration,
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
      scrollSpeedDeviceMap: scrollSpeedDeviceMap ?? this.scrollSpeedDeviceMap,
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
      miniPlayerShowTextInfoOnTrackChange:
          miniPlayerShowTextInfoOnTrackChange ??
              this.miniPlayerShowTextInfoOnTrackChange,
      miniPlayerTextInfoDuration:
          miniPlayerTextInfoDuration ?? this.miniPlayerTextInfoDuration,
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
      scrollSpeedDeviceMap,
      verticalTickerActive,
      ledTickerInDeviceListActive,
      ledTickerOnTickerPageActive,
      ledTickerPixelShiftActive,
      forceTickerUpdateActive,
      miniPlayerAlwaysOnTop,
      miniPlayerPreventCloseApp,
      miniPlayerShowTextInfoOnTrackChange,
      miniPlayerTextInfoDuration,
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
    required super.scrollSpeedDeviceMap,
    required super.verticalTickerActive,
    required super.ledTickerInDeviceListActive,
    required super.ledTickerOnTickerPageActive,
    required super.ledTickerPixelShiftActive,
    required super.forceTickerUpdateActive,
    required super.miniPlayerAlwaysOnTop,
    required super.miniPlayerPreventCloseApp,
    required super.miniPlayerShowTextInfoOnTrackChange,
    required super.miniPlayerTextInfoDuration,
  });

  @override
  String toString() => 'SettingsStateLoaded';
}
