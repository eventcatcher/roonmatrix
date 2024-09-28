import 'package:equatable/equatable.dart';

abstract class MainEvent extends Equatable {
  const MainEvent([List props = const []]);
}

class SetLogMessage extends MainEvent {
  final String msg;

  const SetLogMessage({required this.msg});

  @override
  List<Object> get props => [msg];
}

class Searching extends MainEvent {
  final bool? idle;

  const Searching({this.idle});

  @override
  List<Object> get props => [idle ?? false];
}

class SetSearchFilter extends MainEvent {
  final String type;
  final String filter;

  const SetSearchFilter({required this.type, required this.filter});

  @override
  List<Object> get props => [type, filter];
}

class LoadDevicesAndInfo extends MainEvent {
  final List<String> devices;
  final Map<String, dynamic> info;

  const LoadDevicesAndInfo({required this.devices, required this.info});

  @override
  List<Object> get props => [devices, info];
}

class GetInfo extends MainEvent {
  final String ip;

  const GetInfo({required this.ip});

  @override
  List<Object> get props => [ip];
}

class GetConfig extends MainEvent {
  final String ip;

  const GetConfig({required this.ip});

  @override
  List<Object> get props => [ip];
}

class GetLog extends MainEvent {
  final String ip;
  final int hours;

  const GetLog({required this.ip, required this.hours});

  @override
  List<Object> get props => [ip, hours];
}

class ZoneControl extends MainEvent {
  final String ip;
  final String controlId;
  final String cmd;

  const ZoneControl(
      {required this.ip, required this.controlId, required this.cmd});

  @override
  List<Object> get props => [ip, controlId, cmd];
}

class SetIpRange extends MainEvent {
  final String? ipStart;
  final String? ipEnd;

  const SetIpRange({required this.ipStart, required this.ipEnd});

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
