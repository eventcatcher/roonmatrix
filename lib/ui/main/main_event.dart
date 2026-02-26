import 'package:equatable/equatable.dart';

abstract class MainEvent extends Equatable {
  const MainEvent([List props = const []]);
}

class MainStateLoadDefaults extends MainEvent {
  const MainStateLoadDefaults();

  @override
  List<Object> get props => [];
}

class RestartPollingTimer extends MainEvent {
  const RestartPollingTimer();

  @override
  List<Object> get props => [];
}

class AddWebSocketService extends MainEvent {
  final String ip;

  const AddWebSocketService({
    required this.ip,
  });

  @override
  List<Object> get props => [ip];
}

class ResetWebSocketServices extends MainEvent {
  const ResetWebSocketServices();

  @override
  List<Object> get props => [];
}

class SetLogMessage extends MainEvent {
  final String msg;

  const SetLogMessage({
    required this.msg,
  });

  @override
  List<Object> get props => [msg];
}

class Searching extends MainEvent {
  final bool? idle;

  const Searching({
    this.idle,
  });

  @override
  List<Object> get props => [idle ?? false];
}

class SetSearchFilter extends MainEvent {
  final String type;
  final String filter;

  const SetSearchFilter({
    required this.type,
    required this.filter,
  });

  @override
  List<Object> get props => [type, filter];
}

class LoadDevices extends MainEvent {
  final List<String> devices;

  const LoadDevices({
    required this.devices,
  });

  @override
  List<Object> get props => [devices];
}

class LoadInfo extends MainEvent {
  final String ip;
  final dynamic info;

  const LoadInfo({
    required this.ip,
    required this.info,
  });

  @override
  List<Object> get props => [ip, info];
}

class GetInfo extends MainEvent {
  final String ip;

  const GetInfo({
    required this.ip,
  });

  @override
  List<Object> get props => [ip];
}

class GetConfig extends MainEvent {
  final String ip;

  const GetConfig({
    required this.ip,
  });

  @override
  List<Object> get props => [ip];
}

class UpdateStateConfig extends MainEvent {
  final String ip;
  final Map<String, dynamic> config;

  const UpdateStateConfig({
    required this.ip,
    required this.config,
  });

  @override
  List<Object> get props => [ip, config];
}

class GetLog extends MainEvent {
  final String ip;
  final int hours;

  const GetLog({
    required this.ip,
    required this.hours,
  });

  @override
  List<Object> get props => [ip, hours];
}

class ZoneControl extends MainEvent {
  final String ip;
  final String controlId;
  final String cmd;
  final bool enable;

  const ZoneControl({
    required this.ip,
    required this.controlId,
    required this.cmd,
    required this.enable,
  });

  @override
  List<Object> get props => [ip, controlId, cmd, enable];
}

class SetSpotifyAuthRedirectUrl extends MainEvent {
  final String ip;

  final String url;

  const SetSpotifyAuthRedirectUrl({
    required this.ip,
    required this.url,
  });

  @override
  List<Object> get props => [ip, url];
}

class SetIpRange extends MainEvent {
  final String? ipStart;
  final String? ipEnd;

  const SetIpRange({
    required this.ipStart,
    required this.ipEnd,
  });

  @override
  List<Object> get props {
    List<Object> props = [];
    if (ipStart != null) {
      props.add(ipStart!);
    }
    if (ipEnd != null) {
      props.add(ipEnd!);
    }

    return props;
  }
}

class SetPing extends MainEvent {
  final String ip;
  final bool ping;

  const SetPing({
    required this.ip,
    required this.ping,
  });

  @override
  List<Object> get props => [ip, ping];
}

class SetConnected extends MainEvent {
  final String ip;
  final bool connected;

  const SetConnected({
    required this.ip,
    required this.connected,
  });

  @override
  List<Object> get props => [ip, connected];
}
