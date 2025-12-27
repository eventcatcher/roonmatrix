import 'package:equatable/equatable.dart';

abstract class ConnectionStatusState extends Equatable {
  final bool connected;

  const ConnectionStatusState({
    this.connected = true,
  });

  @override
  List<Object> get props => [
        connected,
      ];
  @override
  String toString() => 'ConnectionStatusState';
}

class ConnectionStatusStateInitial extends ConnectionStatusState {
  const ConnectionStatusStateInitial();

  @override
  String toString() => 'ConnectionStatusStateInitial';
}

class ConnectionStatusStateLoaded extends ConnectionStatusState {
  const ConnectionStatusStateLoaded({
    required super.connected,
  });

  @override
  String toString() => 'ConnectionStatusStateLoaded';
}
