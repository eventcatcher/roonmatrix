import 'package:equatable/equatable.dart';

abstract class ConnectionStatusEvent extends Equatable {
  const ConnectionStatusEvent([List props = const []]);
  @override
  List<Object> get props => [];
}

class SetConnectionStatusStateLoadDefaults extends ConnectionStatusEvent {
  const SetConnectionStatusStateLoadDefaults();

  @override
  List<Object> get props {
    List<Object> props = [];

    return props;
  }
}

class ConnectionStatusChanged extends ConnectionStatusEvent {
  final bool connected;

  const ConnectionStatusChanged({
    required this.connected,
  });

  @override
  List<Object> get props => [connected];
}
