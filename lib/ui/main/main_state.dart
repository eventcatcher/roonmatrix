import 'package:equatable/equatable.dart';
import 'package:roonmatrix/model/config_definition.dart';

abstract class MainState extends Equatable {
  final DateTime? update;
  final String? ipStart;
  final String? ipEnd;
  final Map<String, String> searchFilter;
  final List<String> devices;
  final String? activeDeviceIp;
  final Map<String, bool> connected;
  final Map<String, bool> ping;
  final Map<String, dynamic> info;
  final Map<String, dynamic> config;
  final ConfigDefinition? definitions;
  final Map fieldValues;
  final String log;
  final bool idle;
  final bool subPageIdle;
  final String logMessage;
  final Map<String, dynamic> spotifyAuthUrls;
  final String macosVersion;

  const MainState(
      {this.update,
      this.ipStart,
      this.ipEnd,
      this.searchFilter = const {
        "main": "",
        "info": "",
        "config": "",
        "log": ""
      },
      this.devices = const [],
      this.activeDeviceIp,
      this.connected = const {},
      this.ping = const {},
      this.info = const {},
      this.config = const {},
      this.definitions,
      this.fieldValues = const {},
      this.log = '',
      this.idle = false,
      this.subPageIdle = false,
      this.logMessage = '',
      this.spotifyAuthUrls = const {},
      this.macosVersion = ''});

  MainState copyWith({
    DateTime? update,
    String? ipStart,
    String? ipEnd,
    Map<String, String>? searchFilter,
    List<String>? devices,
    String? activeDeviceIp,
    Map<String, bool>? connected,
    Map<String, bool>? ping,
    Map<String, dynamic>? info,
    Map<String, dynamic>? config,
    ConfigDefinition? definitions,
    Map? fieldValues,
    String? log,
    bool? idle,
    bool? subPageIdle,
    String? logMessage,
    Map<String, dynamic>? spotifyAuthUrls,
    String? macosVersion,
  }) {
    return MainStateLoaded(
      update: update ?? this.update,
      ipStart: ipStart ?? this.ipStart,
      ipEnd: ipEnd ?? this.ipEnd,
      searchFilter: searchFilter ?? this.searchFilter,
      devices: devices ?? this.devices,
      activeDeviceIp: activeDeviceIp ?? this.activeDeviceIp,
      connected: connected ?? this.connected,
      ping: ping ?? this.ping,
      info: info ?? this.info,
      config: config ?? this.config,
      definitions: definitions ?? this.definitions,
      fieldValues: fieldValues ?? this.fieldValues,
      log: log ?? this.log,
      idle: idle ?? this.idle,
      subPageIdle: subPageIdle ?? this.subPageIdle,
      logMessage: logMessage ?? this.logMessage,
      spotifyAuthUrls: spotifyAuthUrls ?? this.spotifyAuthUrls,
      macosVersion: macosVersion ?? this.macosVersion,
    );
  }

  @override
  List<Object> get props {
    List<Object> props = [
      searchFilter,
      devices,
      connected,
      ping,
      info,
      config,
      fieldValues,
      log,
      idle,
      subPageIdle,
      logMessage,
      spotifyAuthUrls,
      macosVersion,
    ];

    if (ipStart != null) {
      props.add(ipStart!);
    }
    if (ipEnd != null) {
      props.add(ipEnd!);
    }
    if (activeDeviceIp != null) {
      props.add(activeDeviceIp!);
    }
    if (definitions != null) {
      props.add(definitions!);
    }
    if (update != null) {
      props.add(update!);
    }

    return props;
  }

  @override
  String toString() => 'MainState';
}

class MainStateInitial extends MainState {
  const MainStateInitial();

  @override
  String toString() => 'MainStateInitial';
}

class MainStateLoaded extends MainState {
  const MainStateLoaded({
    required super.update,
    required super.ipStart,
    required super.ipEnd,
    required super.searchFilter,
    required super.devices,
    required super.activeDeviceIp,
    required super.connected,
    required super.ping,
    required super.info,
    required super.config,
    required super.definitions,
    required super.fieldValues,
    required super.log,
    required super.idle,
    required super.subPageIdle,
    required super.logMessage,
    required super.spotifyAuthUrls,
    required super.macosVersion,
  });

  @override
  String toString() => 'MainStateLoaded';
}
