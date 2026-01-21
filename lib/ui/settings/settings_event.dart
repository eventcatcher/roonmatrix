import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent([List props = const []]);
}

class SettingsStateLoadDefaults extends SettingsEvent {
  const SettingsStateLoadDefaults();

  @override
  List<Object> get props => [];
}

class SetIpRange extends SettingsEvent {
  final String ipStart;
  final String ipEnd;

  const SetIpRange({
    required this.ipStart,
    required this.ipEnd,
  });

  @override
  List<Object> get props => [ipStart, ipEnd];
}

class SetMoreInfoMode extends SettingsEvent {
  final bool enabled;

  const SetMoreInfoMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetCoverRowActiveMode extends SettingsEvent {
  final bool enabled;

  const SetCoverRowActiveMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetCoverRowArtistMode extends SettingsEvent {
  final bool enabled;

  const SetCoverRowArtistMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetCoverRowAlbumMode extends SettingsEvent {
  final bool enabled;

  const SetCoverRowAlbumMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetCoverRowTrackMode extends SettingsEvent {
  final bool enabled;

  const SetCoverRowTrackMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetCoverRowDynamicSizeMode extends SettingsEvent {
  final bool enabled;

  const SetCoverRowDynamicSizeMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetScrollSpeedDevice extends SettingsEvent {
  final double speed;

  const SetScrollSpeedDevice({
    required this.speed,
  });

  @override
  List<Object> get props => [speed];
}

class SetScrollSpeedScrollMatrix extends SettingsEvent {
  final double speed;

  const SetScrollSpeedScrollMatrix({
    required this.speed,
  });

  @override
  List<Object> get props => [speed];
}
