import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent([List props = const []]);
}

class SetIpRange extends SettingsEvent {
  final String ipStart;
  final String ipEnd;

  const SetIpRange({required this.ipStart, required this.ipEnd});

  @override
  List<Object> get props => [ipStart, ipEnd];
}

class SetMoreInfoMode extends SettingsEvent {
  final bool enabled;

  const SetMoreInfoMode({required this.enabled});

  @override
  List<Object> get props => [enabled];
}
