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
