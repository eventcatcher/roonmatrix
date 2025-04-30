import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  final String ipStart;
  final String ipEnd;
  final bool moreInfo;
  final bool coverRowActiv;
  final bool coverRowTrack;
  final bool coverRowDynamicSize;

  const SettingsState({
    this.ipStart = '',
    this.ipEnd = '',
    this.moreInfo = false,
    this.coverRowActiv = true,
    this.coverRowTrack = true,
    this.coverRowDynamicSize = true,
  });

  @override
  List<Object> get props {
    List<Object> props = [
      ipStart,
      ipEnd,
      moreInfo,
      coverRowActiv,
      coverRowTrack,
      coverRowDynamicSize,
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
    required super.coverRowTrack,
    required super.coverRowDynamicSize,
  });

  @override
  String toString() => 'SettingsStateLoaded';
}
