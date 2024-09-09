import 'package:equatable/equatable.dart';
import 'package:roonmatrix/model/options.dart';

abstract class OptionsEvent extends Equatable {
  const OptionsEvent([List props = const []]);
}

class ResetOptions extends OptionsEvent {
  @override
  List<Object> get props => [];
}

class SetLogMessage extends OptionsEvent {
  final String msg;

  const SetLogMessage({required this.msg});

  @override
  List<Object> get props => [msg];
}

class Searching extends OptionsEvent {
  final bool? idle;

  const Searching({this.idle});

  @override
  List<Object> get props => [idle ?? false];
}

class SetOptionsPolling extends OptionsEvent {
  final bool polling;

  const SetOptionsPolling({required this.polling});

  @override
  List<Object> get props => [polling];
}

class SetOptions extends OptionsEvent {
  final Options options;

  const SetOptions({required this.options});

  @override
  List<Object> get props => [options];
}

class SetSearchFilter extends OptionsEvent {
  final String type;
  final String filter;

  const SetSearchFilter({required this.type, required this.filter});

  @override
  List<Object> get props => [type, filter];
}

class LoadDevicesAndInfo extends OptionsEvent {
  final List<String> devices;
  final Map<String, dynamic> info;

  const LoadDevicesAndInfo({required this.devices, required this.info});

  @override
  List<Object> get props => [devices, info];
}

class GetInfo extends OptionsEvent {
  final String ip;

  const GetInfo({required this.ip});

  @override
  List<Object> get props => [ip];
}

class GetConfig extends OptionsEvent {
  final String ip;

  const GetConfig({required this.ip});

  @override
  List<Object> get props => [ip];
}

class GetLog extends OptionsEvent {
  final String ip;
  final int hours;

  const GetLog({required this.ip, required this.hours});

  @override
  List<Object> get props => [ip];
}

class ZoneControl extends OptionsEvent {
  final String ip;
  final String controlId;
  final String cmd;

  const ZoneControl(
      {required this.ip, required this.controlId, required this.cmd});

  @override
  List<Object> get props => [ip, controlId, cmd];
}

class SetIpRange extends OptionsEvent {
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
