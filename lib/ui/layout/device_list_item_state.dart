import 'package:equatable/equatable.dart';

abstract class DeviceListItemState extends Equatable {
  final bool expandableMenuOpened;

  const DeviceListItemState({this.expandableMenuOpened = false});

  DeviceListItemState copyWith({bool? expandableMenuOpened}) {
    return DeviceListItemStateLoaded(
      expandableMenuOpened: expandableMenuOpened ?? this.expandableMenuOpened,
    );
  }

  @override
  List<Object> get props {
    List<Object> props = [expandableMenuOpened];

    return props;
  }

  @override
  String toString() => 'DeviceListItemState';
}

class DeviceListItemStateInitial extends DeviceListItemState {
  const DeviceListItemStateInitial();

  @override
  String toString() => 'DeviceListItemStateInitial';
}

class DeviceListItemStateLoaded extends DeviceListItemState {
  const DeviceListItemStateLoaded({required super.expandableMenuOpened});

  @override
  String toString() => 'DeviceListItemStateLoaded';
}
