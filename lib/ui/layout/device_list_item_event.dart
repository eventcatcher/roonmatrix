import 'package:equatable/equatable.dart';

abstract class DeviceListItemEvent extends Equatable {
  const DeviceListItemEvent([List props = const []]);
}

class DeviceListItemStateLoadDefaults extends DeviceListItemEvent {
  const DeviceListItemStateLoadDefaults();

  @override
  List<Object> get props => [];
}

class SetExpandableMenuOpened extends DeviceListItemEvent {
  final bool enabled;

  const SetExpandableMenuOpened({required this.enabled});

  @override
  List<Object> get props => [enabled];
}
