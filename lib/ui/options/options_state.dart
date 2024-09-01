import 'package:equatable/equatable.dart';
import 'package:roonmatrix/model/options.dart';

abstract class OptionsState extends Equatable {
  final DateTime? update;
  final Options? options;

  final Map<String, String> searchFilter;

  final List<String> devices;
  final Map<String, dynamic> info;
  final Map<String, dynamic> config;
  final Map fieldValues;
  final String log;
  final bool idle;
  final String logMessage;

  const OptionsState({
    this.update,
    this.options,
    this.searchFilter = const {"main": "", "info": "", "config": "", "log": ""},
    this.devices = const [],
    this.info = const {},
    this.config = const {},
    this.fieldValues = const {},
    this.log = '',
    this.idle = false,
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
      logMessage,
    ];

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
    required super.options,
    required super.searchFilter,
    required super.devices,
    required super.info,
    required super.config,
    required super.fieldValues,
    required super.log,
    required super.idle,
    required super.logMessage,
  });

  @override
  String toString() => 'OptionsStateLoaded';
}
