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
  final bool verticalTickerActive;
  final bool ledTickerInDeviceListActive;
  final bool ledTickerOnTickerPageActive;

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
    this.scrollSpeedDevice = 1.0,
    this.scrollSpeedScrollMatrix = 1.0,
    this.verticalTickerActive = false,
    this.ledTickerInDeviceListActive = false,
    this.ledTickerOnTickerPageActive = false,
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
    double? scrollSpeedDevice,
    double? scrollSpeedScrollMatrix,
    bool? verticalTickerActive,
    bool? ledTickerInDeviceListActive,
    bool? ledTickerOnTickerPageActive,
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
      scrollSpeedDevice: scrollSpeedDevice ?? this.scrollSpeedDevice,
      scrollSpeedScrollMatrix:
          scrollSpeedScrollMatrix ?? this.scrollSpeedScrollMatrix,
      verticalTickerActive: verticalTickerActive ?? this.verticalTickerActive,
      ledTickerInDeviceListActive:
          ledTickerInDeviceListActive ?? this.ledTickerInDeviceListActive,
      ledTickerOnTickerPageActive:
          ledTickerOnTickerPageActive ?? this.ledTickerOnTickerPageActive,
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
      scrollSpeedDevice,
      scrollSpeedScrollMatrix,
      verticalTickerActive,
      ledTickerInDeviceListActive,
      ledTickerOnTickerPageActive,
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
    required super.scrollSpeedDevice,
    required super.scrollSpeedScrollMatrix,
    required super.verticalTickerActive,
    required super.ledTickerInDeviceListActive,
    required super.ledTickerOnTickerPageActive,
  });

  @override
  String toString() => 'SettingsStateLoaded';
}
