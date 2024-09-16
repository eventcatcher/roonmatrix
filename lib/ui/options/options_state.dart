import 'package:equatable/equatable.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/options.dart';

abstract class OptionsState extends Equatable {
  final DateTime? update;
  final String? ipStart;
  final String? ipEnd;
  final Options? options;
  final Map<String, String> searchFilter;
  final List<String> devices;
  final Map<String, dynamic> info;
  final Map<String, dynamic> config;
  final ConfigDefinition? definitions;
  final Map fieldValues;
  final String log;
  final bool idle;
  final bool subPageIdle;
  final String logMessage;

  const OptionsState({
    this.update,
    this.ipStart,
    this.ipEnd,
    this.options,
    this.searchFilter = const {"main": "", "info": "", "config": "", "log": ""},
    this.devices = const [],
    this.info = const {},
    this.config = const {},
    this.definitions,
    this.fieldValues = const {},
    this.log = '',
    this.idle = false,
    this.subPageIdle = false,
    this.logMessage = '',
  });

  @override
  List<Object> get props {
    List<Object> props = [
      searchFilter,
      devices,
      info,
      config,
      fieldValues,
      log,
      idle,
      subPageIdle,
      logMessage,
    ];

    if (ipStart != null) {
      props.add(ipStart!);
    }
    if (ipEnd != null) {
      props.add(ipEnd!);
    }
    if (definitions != null) {
      props.add(definitions!);
    }
    if (update != null) {
      props.add(update!);
    }
    if (options != null) {
      props.add(options!);
    }

    return props;
  }

  @override
  String toString() => 'OptionsState';
}

class OptionsStateInitial extends OptionsState {
  const OptionsStateInitial();

  @override
  String toString() => 'OptionsStateInitial';
}

class OptionsStateLoaded extends OptionsState {
  const OptionsStateLoaded({
    required super.update,
    required super.ipStart,
    required super.ipEnd,
    required super.options,
    required super.searchFilter,
    required super.devices,
    required super.info,
    required super.config,
    required super.definitions,
    required super.fieldValues,
    required super.log,
    required super.idle,
    required super.subPageIdle,
    required super.logMessage,
  });

  @override
  String toString() => 'OptionsStateLoaded';
}
