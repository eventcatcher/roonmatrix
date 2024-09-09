import 'package:equatable/equatable.dart';

abstract class SettingsState extends Equatable {
  final String ipStart;
  final String ipEnd;

  const SettingsState({
    this.ipStart = '',
    this.ipEnd = '',
  });

  @override
  List<Object> get props {
    List<Object> props = [
      ipStart,
      ipEnd,
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
  });

  @override
  String toString() => 'SettingsStateLoaded';
}
