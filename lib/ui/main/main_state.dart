import 'package:equatable/equatable.dart';
import 'package:roonmatrix/model/config_definition.dart';

abstract class MainState extends Equatable {
  final DateTime? update;
  final String? ipStart;
  final String? ipEnd;
  final Map<String, String> searchFilter;
  final List<String> devices;
  final String? activeDeviceIp;
  final String selectedDeviceIp;
  final Map<String, bool> tileExpanded;
  final Map<String, bool> connected;
  final Map<String, bool> ping;
  final Map<String, Set<String>> notifications;
  final Map<String, dynamic> info;
  final Map<String, dynamic> config;
  final Map<String, ConfigDefinition> definitions;
  final Map fieldValues;
  final String log;
  final bool idle;
  final bool disableListItemsRendering;
  final bool subPageIdle;
  final String logMessage;
  final Map<String, dynamic> spotifyAuthUrls;
  final String macosVersion;
  final String iosVersion;
  final int iosMajorVersion;
  final String iosModel;
  final bool isIPad;

  const MainState({
    this.update,
    this.ipStart,
    this.ipEnd,
    this.searchFilter = const {"main": "", "info": "", "config": "", "log": ""},
    this.devices = const [],
    this.activeDeviceIp,
    this.selectedDeviceIp = '',
    this.tileExpanded = const {},
    this.connected = const {},
    this.ping = const {},
    this.notifications = const {},
    this.info = const {},
    this.config = const {},
    this.definitions = const {},
    this.fieldValues = const {},
    this.log = '',
    this.idle = false,
    this.disableListItemsRendering = false,
    this.subPageIdle = false,
    this.logMessage = '',
    this.spotifyAuthUrls = const {},
    this.macosVersion = '',
    this.iosVersion = '',
    this.iosMajorVersion = 0,
    this.iosModel = '',
    this.isIPad = false,
  });

  MainState copyWith({
    DateTime? update,
    String? ipStart,
    String? ipEnd,
    Map<String, String>? searchFilter,
    List<String>? devices,
    String? activeDeviceIp,
    String? selectedDeviceIp,
    Map<String, bool>? tileExpanded,
    Map<String, bool>? connected,
    Map<String, bool>? ping,
    Map<String, Set<String>>? notifications,
    Map<String, dynamic>? info,
    Map<String, dynamic>? config,
    Map<String, ConfigDefinition>? definitions,
    Map? fieldValues,
    String? log,
    bool? idle,
    bool? disableListItemsRendering,
    bool? subPageIdle,
    String? logMessage,
    Map<String, dynamic>? spotifyAuthUrls,
    String? macosVersion,
    String? iosVersion,
    int? iosMajorVersion,
    String? iosModel,
    bool? isIPad,
  }) {
    return MainStateLoaded(
      update: update ?? this.update,
      ipStart: ipStart ?? this.ipStart,
      ipEnd: ipEnd ?? this.ipEnd,
      searchFilter: searchFilter ?? this.searchFilter,
      devices: devices ?? this.devices,
      activeDeviceIp: activeDeviceIp ?? this.activeDeviceIp,
      selectedDeviceIp: selectedDeviceIp ?? this.selectedDeviceIp,
      tileExpanded: tileExpanded ?? this.tileExpanded,
      connected: connected ?? this.connected,
      ping: ping ?? this.ping,
      notifications: notifications ?? this.notifications,
      info: info ?? this.info,
      config: config ?? this.config,
      definitions: definitions ?? this.definitions,
      fieldValues: fieldValues ?? this.fieldValues,
      log: log ?? this.log,
      idle: idle ?? this.idle,
      disableListItemsRendering:
          disableListItemsRendering ?? this.disableListItemsRendering,
      subPageIdle: subPageIdle ?? this.subPageIdle,
      logMessage: logMessage ?? this.logMessage,
      spotifyAuthUrls: spotifyAuthUrls ?? this.spotifyAuthUrls,
      macosVersion: macosVersion ?? this.macosVersion,
      iosVersion: iosVersion ?? this.iosVersion,
      iosMajorVersion: iosMajorVersion ?? this.iosMajorVersion,
      iosModel: iosModel ?? this.iosModel,
      isIPad: isIPad ?? this.isIPad,
    );
  }

  @override
  List<Object> get props {
    List<Object> props = [
      searchFilter,
      devices,
      selectedDeviceIp,
      connected,
      ping,
      notifications,
      info,
      tileExpanded,
      config,
      definitions,
      fieldValues,
      log,
      idle,
      disableListItemsRendering,
      subPageIdle,
      logMessage,
      spotifyAuthUrls,
      macosVersion,
      iosVersion,
      iosMajorVersion,
      iosModel,
      isIPad,
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
    required super.selectedDeviceIp,
    required super.tileExpanded,
    required super.connected,
    required super.ping,
    required super.notifications,
    required super.info,
    required super.config,
    required super.definitions,
    required super.fieldValues,
    required super.log,
    required super.idle,
    required super.disableListItemsRendering,
    required super.subPageIdle,
    required super.logMessage,
    required super.spotifyAuthUrls,
    required super.macosVersion,
    required super.iosVersion,
    required super.iosMajorVersion,
    required super.iosModel,
    required super.isIPad,
  });

  @override
  String toString() => 'MainStateLoaded';
}
