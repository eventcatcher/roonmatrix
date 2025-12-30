import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  final String ipStart;
  final String ipEnd;
  final bool moreInfo;
  final bool coverRowActiv;
  final bool coverRowArtist;
  final bool coverRowAlbum;
  final bool coverRowTrack;
  final bool coverRowDynamicSize;
  final double scrollSpeedDevice;
  final double scrollSpeedScrollMatrix;

  const SettingsState({
    this.ipStart = '',
    this.ipEnd = '',
    this.moreInfo = false,
    this.coverRowActiv = true,
    this.coverRowArtist = false,
    this.coverRowAlbum = false,
    this.coverRowTrack = true,
    this.coverRowDynamicSize = true,
    this.scrollSpeedDevice = 1.0,
    this.scrollSpeedScrollMatrix = 1.0,
  });

  SettingsState copyWith({
    String? ipStart,
    String? ipEnd,
    bool? moreInfo,
    bool? coverRowActiv,
    bool? coverRowArtist,
    bool? coverRowAlbum,
    bool? coverRowTrack,
    bool? coverRowDynamicSize,
    double? scrollSpeedDevice,
    double? scrollSpeedScrollMatrix,
  }) {
    return SettingsStateLoaded(
      ipStart: ipStart ?? this.ipStart,
      ipEnd: ipEnd ?? this.ipEnd,
      moreInfo: moreInfo ?? this.moreInfo,
      coverRowActiv: coverRowActiv ?? this.coverRowActiv,
      coverRowArtist: coverRowArtist ?? this.coverRowArtist,
      coverRowAlbum: coverRowAlbum ?? this.coverRowAlbum,
      coverRowTrack: coverRowTrack ?? this.coverRowTrack,
      coverRowDynamicSize: coverRowDynamicSize ?? this.coverRowDynamicSize,
      scrollSpeedDevice: scrollSpeedDevice ?? this.scrollSpeedDevice,
      scrollSpeedScrollMatrix:
          scrollSpeedScrollMatrix ?? this.scrollSpeedScrollMatrix,
    );
  }

  @override
  List<Object> get props {
    List<Object> props = [
      ipStart,
      ipEnd,
      moreInfo,
      coverRowActiv,
      coverRowArtist,
      coverRowAlbum,
      coverRowTrack,
      coverRowDynamicSize,
      scrollSpeedDevice,
      scrollSpeedScrollMatrix,
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
    required super.coverRowActiv,
    required super.coverRowArtist,
    required super.coverRowAlbum,
    required super.coverRowTrack,
    required super.coverRowDynamicSize,
    required super.scrollSpeedDevice,
    required super.scrollSpeedScrollMatrix,
  });

  @override
  String toString() => 'SettingsStateLoaded';
}
