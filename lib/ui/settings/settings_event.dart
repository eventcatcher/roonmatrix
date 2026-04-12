import 'package:equatable/equatable.dart';
import 'package:roonmatrix/model/scroll_speed_variant.dart';

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

class GetScrollSpeedVariant extends SettingsEvent {
  final String ip;
  final ScrollSpeedVariant variant;

  const GetScrollSpeedVariant({
    required this.ip,
    required this.variant,
  });

  @override
  List<Object> get props => [ip, variant];
}

class SetScrollSpeedDevice extends SettingsEvent {
  final String key;
  final double speed;

  const SetScrollSpeedDevice({
    required this.key,
    required this.speed,
  });

  @override
  List<Object> get props => [key, speed];
}

class SetVerticalTickerActiveMode extends SettingsEvent {
  final bool enabled;

  const SetVerticalTickerActiveMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetLedTickerInDeviceListActiveMode extends SettingsEvent {
  final bool enabled;

  const SetLedTickerInDeviceListActiveMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetLedTickerOnTickerPageActiveMode extends SettingsEvent {
  final bool enabled;

  const SetLedTickerOnTickerPageActiveMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetLedTickerPixelShiftActiveMode extends SettingsEvent {
  final bool enabled;

  const SetLedTickerPixelShiftActiveMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetForceTickerUpdateActiveMode extends SettingsEvent {
  final bool enabled;

  const SetForceTickerUpdateActiveMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetMiniPlayerAlwaysOnTopMode extends SettingsEvent {
  final bool enabled;

  const SetMiniPlayerAlwaysOnTopMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetMiniPlayerPreventCloseAppMode extends SettingsEvent {
  final bool enabled;

  const SetMiniPlayerPreventCloseAppMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetMiniPlayerShowTextInfoOnTrackChangeMode extends SettingsEvent {
  final bool enabled;

  const SetMiniPlayerShowTextInfoOnTrackChangeMode({
    required this.enabled,
  });

  @override
  List<Object> get props => [enabled];
}

class SetMiniPlayerTextInfoDuration extends SettingsEvent {
  final int seconds;

  const SetMiniPlayerTextInfoDuration({
    required this.seconds,
  });

  @override
  List<Object> get props => [seconds];
}
