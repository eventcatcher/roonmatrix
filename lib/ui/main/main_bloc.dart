import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/ui/helper/triangle_painter.dart';
import 'package:roonmatrix/ui/helper/websocket_service.dart';
import 'package:roonmatrix/ui/main/main_event.dart';
import 'package:roonmatrix/ui/main/main_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
//ignore:depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';
import 'package:window_manager/window_manager.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  final FileRepository fileRepository;

  final Map<String, TextEditingController> conrollerSearch = {
    "main": TextEditingController(),
    "info": TextEditingController(),
    "config": TextEditingController(),
    "log": TextEditingController()
  };
  final List<String> allowedDeviceTypes = ['roonmatrix', 'coverplayer'];
  final int pollingIntervalInSeconds = 30;
  final int port = 8000;

  http.Client client = http.Client();
  Map<String, dynamic> translations = {};
  List<WebSocketService> services = [];

  String? ipStart;
  String? ipEnd;
  bool isScanning = false;
  Timer? timer;
  Display? primaryDisplay;

  MainBloc({required this.fileRepository}) : super(const MainStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<MainEvent>((event, emit) async {
      if (event is SetIpRange) {
        String? ipStart = event.ipStart;
        String? ipEnd = event.ipEnd;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: ipStart,
          ipEnd: ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          subPageIdle: state.subPageIdle,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));
      }

      if (event is SetLogMessage) {
        String logMessage = event.msg;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          subPageIdle: state.subPageIdle,
          logMessage: logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));
      }

      if (event is ResetWebSocketServices) {
        debugPrint('ResetWebSocketServices, services: ${services.length}');
        for (WebSocketService service in services) {
          service.dispose();
        }
        services = [];
      }

      if (event is LoadDevices) {
        List<String> existingServiceUrls =
            services.map((WebSocketService el) => el.url).toList();

        for (String ip in event.devices) {
          String url = 'ws://$ip:$port/ws';
          // WebSocketService service =
          //     services.firstWhere((WebSocketService el) => el.url == url);

          if (!existingServiceUrls.contains(url)) {
            if (kDebugMode) {
              debugPrint('vvvv add WebSocketService $url');
            }
            services.add(WebSocketService(
              url,
              onMessage: (jsonStr) {
                if (jsonStr.isNotEmpty &&
                    jsonStr.startsWith('{') &&
                    jsonStr.endsWith('}')) {
                  dynamic info = jsonDecode(jsonStr);
                  if (kDebugMode) {
                    debugPrint(
                        'vvvv WebSocketService received data from device ${info['name']} @ ${DateTime.now().toLocal()}, app_displaystr: ${info['app_displaystr']}');
                  }
                  add(LoadInfo(ip: ip, info: info));
                }
              },
            )..connect());
            getInfo(ip: ip);
          }
        }

        List<String> newWebSocketUrls =
            event.devices.map((String ip) => 'ws://$ip:$port/ws').toList();
        List<WebSocketService> servicesToRemove = [];
        for (WebSocketService service in services) {
          if (!newWebSocketUrls.contains(service.url)) {
            if (kDebugMode) {
              debugPrint('vvvv remove WebSocketService ${service.url}');
            }
            service.dispose();
            servicesToRemove.add(service);
          }
        }
        if (servicesToRemove.isNotEmpty) {
          for (WebSocketService service in servicesToRemove) {
            services.remove(service);
          }
        }

        if (kDebugMode) {
          debugPrint('vvvv active websocket connections: ${services.length}');
        }

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: state.searchFilter,
          devices: event.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: false,
          subPageIdle: state.subPageIdle,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));
      }

      if (event is LoadInfo) {
        Map<String, dynamic> info = Map<String, dynamic>.from(state.info);
        info[event.ip] = event.info;
        if (kDebugMode) {
          debugPrint(
              'vvvv LoadInfo, ip: ${event.ip}, app_displaystr: ${info[event.ip]['app_displaystr']}');
        }

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          subPageIdle: state.subPageIdle,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));
      }

      if (event is SetSearchFilter) {
        String type = event.type;
        String filter = event.filter;
        Map<String, String> searchFilter = Map.from(state.searchFilter);
        searchFilter[type] = filter;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          subPageIdle: state.subPageIdle,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));
      }

      if (event is Searching) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        ipStart = prefs.getString('ipStart');
        ipEnd = prefs.getString('ipEnd');
        bool idle = event.idle ?? false;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: ipStart,
          ipEnd: ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: idle,
          subPageIdle: state.subPageIdle,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));

        searchDevices();
      }

      if (event is GetInfo) {
        String ip = event.ip;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          subPageIdle: true,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));

        try {
          String url = 'http://$ip:$port/info/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.get(uri);
            if (response.statusCode == 200) {
              if (response.body.substring(0, 1) == '{') {
                Map<String, dynamic> json = jsonDecode(filterIllegalChars(
                        text: utf8.decode(response.bodyBytes),
                        messageHeader: 'GetInfo/info (raw)'))
                    as Map<String, dynamic>;

                Map<String, dynamic> info =
                    Map<String, dynamic>.from(state.info);
                Map<String, dynamic> spotifyAuthUrls =
                    Map<String, dynamic>.from(state.spotifyAuthUrls);

                String spotifyAuthUrl = '';
                if (json.containsKey('spotify_auth_url')) {
                  spotifyAuthUrl = json['spotify_auth_url'];
                  spotifyAuthUrls[ip] = spotifyAuthUrl;
                  json.remove('spotify_auth_url');
                }

                info[ip] = json;

                emit(MainStateLoaded(
                  update: DateTime.now(),
                  ipStart: state.ipStart,
                  ipEnd: state.ipEnd,
                  searchFilter: state.searchFilter,
                  devices: state.devices,
                  info: info,
                  config: state.config,
                  definitions: state.definitions,
                  fieldValues: state.fieldValues,
                  log: state.log,
                  idle: state.idle,
                  subPageIdle: false,
                  logMessage: state.logMessage,
                  spotifyAuthUrls: spotifyAuthUrls,
                ));
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('error by access to $url: $e');
            }
            emit(MainStateLoaded(
              update: DateTime.now(),
              ipStart: state.ipStart,
              ipEnd: state.ipEnd,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
              definitions: state.definitions,
              fieldValues: state.fieldValues,
              log: state.log,
              idle: state.idle,
              subPageIdle: false,
              logMessage: state.logMessage,
              spotifyAuthUrls: state.spotifyAuthUrls,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GetInfo try/catch error: $e');
          }
          emit(MainStateLoaded(
            update: DateTime.now(),
            ipStart: state.ipStart,
            ipEnd: state.ipEnd,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            definitions: state.definitions,
            fieldValues: state.fieldValues,
            log: state.log,
            idle: state.idle,
            subPageIdle: false,
            logMessage: state.logMessage,
            spotifyAuthUrls: state.spotifyAuthUrls,
          ));
        }
      }

      if (event is GetConfig) {
        String ip = event.ip;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          subPageIdle: true,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));

        try {
          String url = 'http://$ip:$port/config/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.get(uri);
            if (response.statusCode == 200) {
              if (response.body.substring(0, 1) == '{') {
                Map<String, dynamic> json =
                    jsonDecode(utf8.decode(response.bodyBytes))
                        as Map<String, dynamic>;

                ConfigDefinition definitions =
                    ConfigDefinition.fromJson(json['definitions']);

                Map fieldValues =
                    getFieldValues(defs: definitions, json: json['config']);

                emit(MainStateLoaded(
                  update: DateTime.now(),
                  ipStart: state.ipStart,
                  ipEnd: state.ipEnd,
                  searchFilter: state.searchFilter,
                  devices: state.devices,
                  info: state.info,
                  config: json['config'],
                  definitions: definitions,
                  fieldValues: fieldValues,
                  log: state.log,
                  idle: state.idle,
                  subPageIdle: false,
                  logMessage: state.logMessage,
                  spotifyAuthUrls: state.spotifyAuthUrls,
                ));
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('error by access to $url: $e');
            }
            emit(MainStateLoaded(
              update: DateTime.now(),
              ipStart: state.ipStart,
              ipEnd: state.ipEnd,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
              definitions: state.definitions,
              fieldValues: state.fieldValues,
              log: state.log,
              idle: state.idle,
              subPageIdle: false,
              logMessage: state.logMessage,
              spotifyAuthUrls: state.spotifyAuthUrls,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GetConfig try/catch error: $e');
          }
          emit(MainStateLoaded(
            update: DateTime.now(),
            ipStart: state.ipStart,
            ipEnd: state.ipEnd,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            definitions: state.definitions,
            fieldValues: state.fieldValues,
            log: state.log,
            idle: state.idle,
            subPageIdle: false,
            logMessage: state.logMessage,
            spotifyAuthUrls: state.spotifyAuthUrls,
          ));
        }
      }

      if (event is GetLog) {
        String ip = event.ip;
        int hours = event.hours;

        emit(MainStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: '',
          idle: state.idle,
          subPageIdle: true,
          logMessage: state.logMessage,
          spotifyAuthUrls: state.spotifyAuthUrls,
        ));

        Map<String, String> headers = {
          "Content-Type": 'application/json',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "hours": hours,
        };

        try {
          String url = 'http://$ip:$port/log/';
          Uri uri = Uri.parse(url);
          try {
            if (kDebugMode) {
              debugPrint('websocket log request @ ${DateTime.now().toLocal()}');
            }
            var response = await client.post(uri,
                headers: headers, body: json.encode(payload));
            if (kDebugMode) {
              debugPrint(
                  'websocket log response  @ ${DateTime.now().toLocal()} => statuscode: ${response.statusCode}, bodyBytes: ${response.contentLength}');
            }
            if (response.statusCode == 200) {
              Uint8List bytes = response.bodyBytes;
              if (kDebugMode) {
                debugPrint(
                    'websocket log @ ${DateTime.now().toLocal()} => decompress now...');
              }
              String log = decompressZlib(bytes);
              if (kDebugMode) {
                debugPrint(
                    'websocket log @ ${DateTime.now().toLocal()} => decompress done, log size: ${log.length}');
              }

              emit(MainStateLoaded(
                update: DateTime.now(),
                ipStart: state.ipStart,
                ipEnd: state.ipEnd,
                searchFilter: state.searchFilter,
                devices: state.devices,
                info: state.info,
                config: state.config,
                definitions: state.definitions,
                fieldValues: state.fieldValues,
                log: log,
                idle: state.idle,
                subPageIdle: false,
                logMessage: state.logMessage,
                spotifyAuthUrls: state.spotifyAuthUrls,
              ));
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('error by access to $url: $e');
            }
            emit(MainStateLoaded(
              update: DateTime.now(),
              ipStart: state.ipStart,
              ipEnd: state.ipEnd,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
              definitions: state.definitions,
              fieldValues: state.fieldValues,
              log: '',
              idle: state.idle,
              subPageIdle: false,
              logMessage: state.logMessage,
              spotifyAuthUrls: state.spotifyAuthUrls,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GetLog try/catch error: $e');
          }
          emit(MainStateLoaded(
            update: DateTime.now(),
            ipStart: state.ipStart,
            ipEnd: state.ipEnd,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            definitions: state.definitions,
            fieldValues: state.fieldValues,
            log: '',
            idle: state.idle,
            subPageIdle: false,
            logMessage: state.logMessage,
            spotifyAuthUrls: state.spotifyAuthUrls,
          ));
        }
      }

      if (event is ZoneControl) {
        String ip = event.ip;
        String controlId = event.controlId;
        String cmd = event.cmd; // previous, next, shufflemode, playmode
        bool enable = event.enable;

        Map<String, String> headers = {
          "Content-Type": 'application/json; charset=utf-8',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "control_id": controlId,
          "cmd": cmd,
          'enable': enable
        };

        try {
          String url = 'http://$ip:$port/zone_control/';
          Uri uri = Uri.parse(url);
          try {
            if (kDebugMode) {
              debugPrint('send zone_control => payload: $payload');
            }
            var response = await client.post(uri,
                headers: headers, body: json.encode(payload));

            if (response.statusCode == 200) {
              if (state.info.containsKey(ip)) {
                Map<String, dynamic> info =
                    Map<String, dynamic>.from(state.info);
                if (cmd == 'switch') {
                  info[ip]['control_id'] = controlId;

                  emit(MainStateLoaded(
                    update: DateTime.now(),
                    ipStart: state.ipStart,
                    ipEnd: state.ipEnd,
                    searchFilter: state.searchFilter,
                    devices: state.devices,
                    info: info,
                    config: state.config,
                    definitions: state.definitions,
                    fieldValues: state.fieldValues,
                    log: state.log,
                    idle: state.idle,
                    subPageIdle: state.subPageIdle,
                    logMessage: state.logMessage,
                    spotifyAuthUrls: state.spotifyAuthUrls,
                  ));
                }
              }
              if (kDebugMode) {
                debugPrint(
                    'zoneControl => ip: $ip, controlId: $controlId, cmd: $cmd${payload['enable'] != null ? ', enable: $enable' : ''}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('ZoneControl error by access to $url: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ZoneControl error: $e');
          }
        }
      }

      if (event is SetSpotifyAuthRedirectUrl) {
        String ip = event.ip;
        String url = event.url;

        Map<String, String> headers = {
          "Content-Type": 'application/json; charset=utf-8',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "url": url,
        };

        try {
          String url = 'http://$ip:$port/spotify_auth_redirect_url/';
          Uri uri = Uri.parse(url);
          try {
            if (kDebugMode) {
              debugPrint('send spotify_auth_redirect_url => payload: $payload');
            }
            var response = await client.post(uri,
                headers: headers, body: json.encode(payload));

            if (response.statusCode == 200) {
              String success = response.body;
              if (kDebugMode) {
                debugPrint(
                    'send spotify_auth_redirect_url => response: $success');
              }

              Map<String, dynamic> spotifyAuthUrls =
                  Map<String, dynamic>.from(state.spotifyAuthUrls);
              spotifyAuthUrls[ip] = '*';

              emit(MainStateLoaded(
                update: DateTime.now(),
                ipStart: state.ipStart,
                ipEnd: state.ipEnd,
                searchFilter: state.searchFilter,
                devices: state.devices,
                info: state.info,
                config: state.config,
                definitions: state.definitions,
                fieldValues: state.fieldValues,
                log: state.log,
                idle: state.idle,
                subPageIdle: state.subPageIdle,
                logMessage: state.logMessage,
                spotifyAuthUrls: spotifyAuthUrls,
              ));
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  'SetSpotifyAuthRedirectUrl error by access to $url: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SetSpotifyAuthRedirectUrl error: $e');
          }
        }
      }

      if (event is RestartPollingTimer) {
        if (timer == null || !timer!.isActive) {
          timer?.cancel();
          setPollingTimer();
        }
      }
    });

    setPollingTimer();
    searching(idle: true);
  }

  // ============== //
  // public methods //
  // ============== //

  void stringExportToFile(String fileStr) async {
    if (fileStr.isNotEmpty) {
      FileSaveLocation? result;
      String fileName =
          'stringExport-${DateFormat('yyyyMMddTHHmmss').format(DateTime.now())}.txt';
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        result = await getSaveLocation(suggestedName: fileName);
        if (result == null) {
          // Operation was canceled by the user.
          return Future.value(null);
        }
      }

      if (result != null) {
        List<int> encoded = utf8.encode(fileStr);
        final Uint8List fileData = Uint8List.fromList(encoded);
        const String mimeType = 'text/plain';
        final XFile textFile =
            XFile.fromData(fileData, mimeType: mimeType, name: fileName);

        if (kDebugMode) {
          debugPrint('stringExportToFile');
        }
        textFile.saveTo(result.path);
      }
    }
  }

  Future<bool?> exportData(
      {required String name, required String ip, required String type}) async {
    if (state.devices.isNotEmpty) {
      String search = state.searchFilter[type] as String;
      String fileStr = '';

      if (type == 'info') {
        Map<String, dynamic> info =
            Map.from(state.info[ip] as Map<String, dynamic>);
        if (search.isNotEmpty) {
          info.removeWhere((key, value) =>
              !key.toLowerCase().contains(search.toLowerCase()));
        }

        fileStr = info
            .map((k, v) {
              return MapEntry(k, '$k: $v');
            })
            .values
            .toList()
            .join('\n');
      }

      if (type == 'config') {
        fileStr = getPrettyJSONString(state.config);
      }

      if (type == 'log') {
        String log = state.log;
        if (log.isNotEmpty) {
          if (log.endsWith('"')) {
            log = log.substring(0, log.length - 1);
          }
          if (log.startsWith('"')) {
            log = log.substring(1);
          }
          log = log.replaceAll('\\n', '\n');
        }
        fileStr = log;
      }

      FileSaveLocation? result;
      String fileName =
          'roonmatrix-$name-$type-${DateFormat('yyyyMMddTHHmmss').format(DateTime.now())}.txt';
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        result = await getSaveLocation(suggestedName: fileName);
        if (result == null) {
          // Operation was canceled by the user.
          return Future.value(null);
        }
      }

      List<int> encoded = utf8.encode(fileStr);
      final Uint8List fileData = Uint8List.fromList(encoded);
      const String mimeType = 'text/plain';
      final XFile textFile =
          XFile.fromData(fileData, mimeType: mimeType, name: fileName);

      try {
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          await textFile.saveTo(result!.path);
        } else {
          await fileRepository.write(
              subFolder: '', fileName: fileName, bytes: fileData);
        }
        return Future.value(true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('save of $fileName error: $e');
        }
        return Future.value(false);
      }
    }

    return Future.value(null);
  }

  String? getFieldType({required ConfigDefinitionItem fieldDefinition}) {
    String? fieldType;

    if (fieldDefinition.editable == true) {
      fieldType = 'text';

      if (fieldDefinition.type.type.startsWith('multiline')) {
        fieldType = 'multiline-text';
      }

      if (fieldDefinition.type.type.startsWith('int')) {
        fieldType = 'int';
      }

      if (fieldDefinition.type.type == 'bool') {
        fieldType = 'bool';
      }

      if (fieldDefinition.type.type.startsWith('list')) {
        fieldType = 'list';
        if (fieldDefinition.type.structure.isEmpty) {
          fieldType = fieldDefinition.type.type.startsWith('list(')
              ? 'listItemsPredefinedLength'
              : 'listItems';
        }
        if (fieldDefinition.type.structure.length == 2) {
          List<String> names = ['key', 'val'];
          String name1 = fieldDefinition.type.structure[0].name;
          String name2 = fieldDefinition.type.structure[1].name;
          if (name1 != name2 &&
              names.contains(name1) &&
              names.contains(name2)) {
            fieldType = 'keyValItems';
          }
        }
      }
    }

    return fieldType;
  }

  Map getFieldValues(
      {required ConfigDefinition defs, required Map<String, dynamic> json}) {
    Map fieldValues = {};

    for (String areaKey in json.keys) {
      Map<String, dynamic> area = json[areaKey];
      if (area.keys.isNotEmpty) {
        fieldValues[areaKey] = {};

        for (String fieldKey in area.keys) {
          ConfigDefinitionItem? fieldDefinition = defs.area
              .firstWhereOrNull((ConfigDefinitionArea el) => el.name == areaKey)
              ?.items
              .firstWhereOrNull(
                  (ConfigDefinitionItem el) => el.name == fieldKey);
          if (fieldDefinition != null) {
            String? fieldType = getFieldType(fieldDefinition: fieldDefinition);
            if (fieldType != null) {
              if (fieldType == 'int') {
                fieldValues[areaKey][fieldKey] = int.parse(area[fieldKey]);
              }
              if (fieldType == 'bool') {
                fieldValues[areaKey][fieldKey] =
                    bool.parse(area[fieldKey].toString().toLowerCase());
              }
              if (fieldType == 'text' ||
                  fieldType == 'multiline-text' ||
                  fieldType.startsWith('list') ||
                  fieldType == 'keyValItems') {
                fieldValues[areaKey][fieldKey] = area[fieldKey];
              }
              if (kDebugMode) {
                debugPrint(
                    'area: $areaKey, field: $fieldKey, value: ${fieldValues[areaKey][fieldKey]}, fieldType: $fieldType');
              }
            }
          }
        }
      }
    }

    return fieldValues;
  }

  bool validateUrl({required String text, required String type}) {
    bool valid = true;

    if (type.startsWith('url(')) {
      List<String> protocols = type.substring(4, type.length - 1).split(',');
      valid = false;
      if (protocols.isNotEmpty) {
        for (String protocol in protocols) {
          if (text.startsWith('$protocol://')) {
            valid = true;
          }
        }
        if (valid == true) {
          valid = isURL(text, requireTld: true, requireProtocol: true);
        }
      }
    }

    return valid;
  }

  bool validateNumber({required int num, required String type}) {
    bool valid = true;

    if (type.startsWith('int(')) {
      List<String> minMax = type.substring(4, type.length - 1).split(',');
      if (minMax.length == 2) {
        int? min = int.tryParse(minMax[0]);
        int? max = int.tryParse(minMax[1]);
        if (min != null && max != null && (num < min || num > max)) {
          valid = false;
        }
      }
    }

    return valid;
  }

  bool validateText(
      {required String text,
      ConfigDefinitionItem? fieldDefinition,
      required String type}) {
    bool valid = true;

    if (text == '') {
      valid = false;
    }

    if (type.startsWith('string(')) {
      List<String> minMax = type.substring(7, type.length - 1).split(',');
      int? min = int.tryParse(minMax[0]);
      int? max = int.tryParse(minMax[1]);
      if (min != null &&
          max != null &&
          (text.length < min || text.length > max)) {
        valid = false;
      }
    }

    if (valid == true &&
        fieldDefinition != null &&
        fieldDefinition.unit == 'json' &&
        fieldDefinition.type.structure.isNotEmpty) {
      if (text.length < 2) {
        valid = false;
      }
      if (valid == true && !text.startsWith('{')) {
        valid = false;
      }
      if (valid == true && !text.endsWith('}')) {
        valid = false;
      }
      if (valid == true) {
        try {
          jsonDecode(text.replaceAll("'", '"'));
        } catch (e) {
          valid = false;
        }
      }
    }

    if (valid == true &&
        fieldDefinition != null &&
        fieldDefinition.unit == 'json list' &&
        fieldDefinition.type.structure.isNotEmpty) {
      if (text.length < 2) {
        valid = false;
      }
      if (text == '[]') {
        return true;
      }
      if (valid == true && !text.startsWith('[{')) {
        valid = false;
      }
      if (valid == true && !text.endsWith('}]')) {
        valid = false;
      }
      if (valid == true) {
        try {
          jsonDecode(text.replaceAll("'", '"'));
        } catch (e) {
          valid = false;
        }
      }
    }

    if (valid == true && type.startsWith('url')) {
      valid = validateUrl(text: text, type: type);
    }

    return valid;
  }

  bool validateList({
    required String jsonStr,
    required ConfigDefinitionItem fieldDefinition,
  }) {
    bool valid = true;
    List<dynamic> fieldValues = jsonDecode(jsonStr.replaceAll("'", '"'));

    for (int idx = 0; idx < fieldValues.length; idx++) {
      if (getFieldType(fieldDefinition: fieldDefinition) != null &&
          getFieldType(fieldDefinition: fieldDefinition)!
              .startsWith('listItems')) {
        List<dynamic> items = fieldValues[idx];
        for (int key = 0; key < items.length; key++) {
          bool itemValid =
              validateText(text: fieldValues[idx][key], type: 'string');
          if (itemValid == false) {
            return false;
          }
        }
      } else {
        Map<String, dynamic> map = fieldValues[idx];
        for (String key in map.keys) {
          String fieldType = fieldDefinition.type.structure
              .firstWhere((ItemTypeStructure el) => el.name == key)
              .type;

          if (fieldType.startsWith('int')) {
            int? num = int.tryParse(fieldValues[idx][key].toString());
            if (num == null) {
              return false;
            }
            bool itemValid = validateNumber(num: num, type: fieldType);
            if (itemValid == false) {
              return false;
            }
          }

          if (fieldType.startsWith('url')) {
            bool itemValid =
                validateUrl(text: fieldValues[idx][key], type: fieldType);
            if (itemValid == false) {
              return false;
            }
          }

          if (fieldType.startsWith('string') || fieldType.endsWith('string')) {
            bool itemValid =
                validateText(text: fieldValues[idx][key], type: fieldType);
            if (itemValid == false) {
              return false;
            }
          }
        }
      }
    }

    return valid;
  }

  String filterIllegalChars(
      {required String text, String messageHeader = '*'}) {
    if (kDebugMode) {
      //debugPrint('$messageHeader: $text');
    }

    String filtered = text;
    //filtered = filtered.replaceAll(r'\\\"', "'");

    return filtered;
  }

  bool validateAll(
      {required ConfigDefinition definitions, required Map fieldValues}) {
    bool validData = false;
    bool test = true;
    outerLoop:
    for (String areaKey in fieldValues.keys) {
      for (String fieldKey in fieldValues[areaKey].keys) {
        ConfigDefinitionItem? fieldDefinition = definitions.area
            .firstWhereOrNull((ConfigDefinitionArea el) => el.name == areaKey)
            ?.items
            .firstWhereOrNull((ConfigDefinitionItem el) => el.name == fieldKey);
        if (fieldDefinition != null &&
            fieldDefinition.editable == true &&
            !fieldDefinition.noValidation) {
          String? fieldType = getFieldType(fieldDefinition: fieldDefinition);
          if (fieldType != null) {
            if (fieldType == 'int') {
              test = fieldValues[areaKey][fieldKey] != '' &&
                  validateNumber(
                      num: int.parse(fieldValues[areaKey][fieldKey].toString()),
                      type: fieldDefinition.type.type);
            } else if (fieldType == 'list') {
              test = validateList(
                  jsonStr: fieldValues[areaKey][fieldKey].toString(),
                  fieldDefinition: fieldDefinition);
            } else {
              test = validateText(
                  text: fieldValues[areaKey][fieldKey].toString(),
                  fieldDefinition: fieldDefinition,
                  type: fieldDefinition.type.type);
            }

            if (!test) break outerLoop;
          }
        }
      }
    }
    validData = test;

    return validData;
  }

  String getListFieldUnit(String type) {
    String unit = '';

    if (type.startsWith('int(')) {
      List<String> minMax = type.substring(4, type.length - 1).split(',');
      if (minMax.length == 2) {
        int? min = int.tryParse(minMax[0]);
        int? max = int.tryParse(minMax[1]);
        if (min != null && max != null) {
          unit = ' ($min-$max)';
        }
      }
    }

    // if (type.startsWith('url')) {
    //   unit = ' (url)';
    // }

    return unit;
  }

  Future<bool> setCustomMessage(
      {required String ip,
      required String message,
      required String option}) async {
    Map<String, String> headers = {
      "Content-Type": 'application/json',
      "Accept": 'application/json',
    };

    Map<String, dynamic> payload = {
      "message": message,
      "option": option,
    };

    try {
      String url = 'http://$ip:$port/message/';
      Uri uri = Uri.parse(url);
      try {
        var response = await client.post(uri,
            headers: headers, body: json.encode(payload));
        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('message => ip: $ip, payload: $payload');
          }

          return Future.value(true);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Message error by access to $url: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Message error: $e');
      }
      return Future.value(false);
    }

    return Future.value(false);
  }

  Future<bool> saveConfig(
      {required String name, required String ip, required dynamic data}) async {
    if (state.devices.isNotEmpty) {
      try {
        String jsonStr = jsonEncode(data);
        if (kDebugMode) {
          debugPrint('saveConfig, name: $name, ip: $ip, data: $jsonStr');
        }

        Map<String, String> headers = {
          "Content-Type": 'application/json; charset=utf-8',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "data": jsonStr,
        };

        try {
          String url = 'http://$ip:$port/setup/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.post(uri,
                headers: headers, body: json.encode(payload));

            if (response.statusCode == 200) {
              if (kDebugMode) {
                debugPrint('setup => ip: $ip, data: $jsonStr');
              }
              return Future.value(true);
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Setup error by access to $url: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Setup error: $e');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Setup error: $e');
        }
      }
    }

    return Future.value(false);
  }

  Future<bool> saveLiveControl(
      {required String ip,
      required String control,
      required String value}) async {
    Map<String, String> headers = {
      "Content-Type": 'application/json',
      "Accept": 'application/json',
    };

    Map<String, dynamic> payload = {
      "control": control,
      "value": value,
    };

    try {
      String url = 'http://$ip:$port/livecontrol/';
      Uri uri = Uri.parse(url);
      try {
        var response = await client.post(uri,
            headers: headers, body: json.encode(payload));
        if (response.statusCode == 200) {
          if (kDebugMode) {
            debugPrint('LiveControl => ip: $ip, payload: $payload');
          }

          return Future.value(true);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('LiveControl error by access to $url: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LiveControl error: $e');
      }
      return Future.value(false);
    }

    return Future.value(false);
  }

  Future<bool?> exportDevicesData() async {
    if (state.devices.isNotEmpty) {
      String search = state.searchFilter['main'] as String;
      String fileStr = '';
      String fileName =
          'roonmatrix-devices-${DateFormat('yyyyMMddTHHmmss').format(DateTime.now())}.txt';

      for (int idx = 0; idx < state.devices.length; idx++) {
        dynamic i = state.info[state.devices[idx]];
        if (search.isEmpty ||
            (i['name'] as String)
                .toLowerCase()
                .contains(search.toLowerCase())) {
          String zoneName = '';
          if (i['control_id'] != null) {
            String controlId = i['control_id'];
            if (i['channels'] != null && i['channels'][controlId] != null) {
              if (i['channels'][controlId] == 'webserver' ||
                  i['channels'][controlId] == 'spotifyconnect') {
                zoneName = controlId;
              } else {
                zoneName = i['channels'][controlId];
              }
            }
          }
          fileStr +=
              'name: ${i['name']}  |  ip: ${state.devices[idx]}  |  time: ${i['time']}  |  zone: $zoneName  |  playcount: ${i['playcount']}\n';
        }
      }

      if (fileStr.isNotEmpty) {
        FileSaveLocation? result;
        if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
          result = await getSaveLocation(suggestedName: fileName);
          if (result == null) {
            // Operation was canceled by the user.
            return Future.value(null);
          }
        }

        List<int> encoded = utf8.encode(fileStr);
        final Uint8List fileData = Uint8List.fromList(encoded);
        const String mimeType = 'text/plain';
        final XFile textFile =
            XFile.fromData(fileData, mimeType: mimeType, name: fileName);

        try {
          if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
            await textFile.saveTo(result!.path);
          } else {
            await fileRepository.write(
                subFolder: '', fileName: fileName, bytes: fileData);
          }
          return Future.value(true);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('save of $fileName error: $e');
          }
          return Future.value(false);
        }
      }
    }

    return Future.value(null);
  }

  Future<bool> isPortOpen(String ip, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> parallelScan({
    required String subnet,
    required int start,
    required int end,
    required int port,
  }) async {
    final List<Future> futures = <Future>[];
    final List<String> found = [];
    const timeout = Duration(milliseconds: 300);

    for (int i = start; i <= end; i++) {
      String ip = '$subnet.$i';
      futures.add(isPortOpen(ip, port, timeout).then((open) {
        if (open) {
          if (kDebugMode) {
            debugPrint('Open: $ip:$port');
          }
          found.add(ip);
        }
      }));
    }

    if (futures.isNotEmpty) await Future.wait(futures);

    return found;
  }

  Future<void> searchDevices() async {
    if (kDebugMode) {
      debugPrint('searchDevices, isScanning: $isScanning');
    }

    if (isScanning == true) {
      if (kDebugMode) {
        debugPrint('networkscan is running...');
      }
    } else {
      List<String> devices = [];
      isScanning = true;

      try {
        if (kDebugMode) {
          debugPrint('start networkscan');
        }

        if (ipStart != null && ipEnd != null) {
          final int firstHostId = int.parse(ipStart!.split('.').last);
          final int lastHostId = int.parse(ipEnd!.split('.').last);
          final String subnet =
              ipStart!.substring(0, ipStart!.lastIndexOf('.'));

          List<String> ipList = await parallelScan(
            subnet: subnet,
            start: firstHostId,
            end: lastHostId,
            port: port,
          );

          for (String ip in ipList) {
            if (kDebugMode) {
              debugPrint('found device on ip: $ip');
            }

            String url = 'http://$ip:$port/';
            Uri uri = Uri.parse(url);

            if (kDebugMode) {
              debugPrint('test rest-api route: $url');
            }
            try {
              var response = await client.get(uri);
              if (response.statusCode == 200) {
                if (response.body.substring(0, 1) == '{') {
                  Map<String, dynamic> json = jsonDecode(filterIllegalChars(
                          text: utf8.decode(response.bodyBytes),
                          messageHeader: 'searchDevices/type (raw)'))
                      as Map<String, dynamic>;
                  if (json['type'] != null &&
                      json['name'] != null &&
                      json['time'] != null &&
                      allowedDeviceTypes.contains(json['type'])) {
                    if (kDebugMode) {
                      debugPrint(
                          '${json['type']} device found on ip: $ip, name: ${json['name']}, time: ${json['time']}');
                    }

                    devices.add(ip);
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                debugPrint('error by access to $url: $e');
              }
            }
          }

          if (devices.isNotEmpty && state.info.isEmpty) {
            List<String> iplist = state.info.keys.toList();
            for (var device in devices) {
              if (!iplist.contains(device)) {
                if (kDebugMode) {
                  debugPrint('get missing info data at start: $device');
                }
                getInfo(ip: device);
              }
            }
          }
          add(LoadDevices(devices: devices));
        }

        isScanning = false;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('general ip scan error: $e');
        }

        isScanning = false;
      }
    }
  }

  TextEditingController getSearchController({required String type}) =>
      conrollerSearch[type]!;

  String getPrettyJSONString(jsonObject) {
    JsonEncoder encoder = const JsonEncoder.withIndent("     ");
    String jsonStr = encoder.convert(jsonObject);

    return jsonStr;
  }

  Map<String, dynamic>? getZoneDataForControlId(Map<String, dynamic>? info) {
    Map<String, dynamic>? zone;

    if (info != null && info != {} && info.keys.contains('channels')) {
      String? controlId = info['control_id'];
      Map<String, dynamic> channels = info['channels'];

      if (controlId != null &&
          controlId.isNotEmpty &&
          channels.keys.contains(controlId)) {
        if (channels[controlId] == 'webserver' ||
            channels[controlId] == 'spotifyconnect') {
          List<String> controlIdParts = info['control_id'].split('-');
          String serverName = controlIdParts[0];
          String zoneName = controlIdParts[1];
          if (info['web_playouts'][serverName] != null) {
            List<dynamic> zones = info['web_playouts'][serverName];
            zone = zones.firstWhereOrNull(
                (dynamic el) => (el['zone'] as String) == zoneName);
          }
        } else {
          String zoneName = channels[controlId];
          if (info['roon_playouts'][zoneName] != null) {
            zone = info['roon_playouts'][zoneName];
          }
        }
      }
    }

    return zone;
  }

  setPollingTimer() {
    debugPrint(
        'setPollingTimer, pollingIntervalInSeconds: $pollingIntervalInSeconds');
    timer = Timer.periodic(Duration(seconds: pollingIntervalInSeconds),
        (Timer timer) {
      searching(idle: state.devices.isEmpty);
    });
  }

  String getNumberFieldErrorMessage(
      {required String value, required Map<String, dynamic> translations}) {
    if (value == '') {
      return translations['configNumberFieldEmptyError'] ??
          'Number field cannot be empty';
    }
    return translations['configNumberFieldRangeError'] ??
        'Number field is out of valid range';
  }

  String getFieldErrorMessage(
      {required String value,
      required String type,
      required Map<String, dynamic> translations}) {
    if (type.startsWith('int')) {
      return getNumberFieldErrorMessage(
          value: value, translations: translations);
    }

    if (value == '') {
      return translations['configTextFieldEmptyError'] ??
          'Text field cannot be empty';
    }

    if (type.startsWith('url') && !validateUrl(text: value, type: type)) {
      return translations['configTextFieldUrlInvalidError'] ?? 'Url is invalid';
    }

    if (type.startsWith('string(')) {
      List<String> minMax = type.substring(7, type.length - 1).split(',');
      int? min = int.tryParse(minMax[0]);
      int? max = int.tryParse(minMax[1]);
      if (min != null &&
          max != null &&
          (value.length < min || value.length > max)) {}
      return translations['configTextFieldRangeError'] ??
          'Text field is out of valid range';
    }

    return translations['configTextFieldJsonError'] ??
        'Text field has no valid Json';
  }

  Future<Display> getPrimaryDisplay() async =>
      primaryDisplay ??= await screenRetriever.getPrimaryDisplay();

  Future<void> windowResizeToFullWidthAndMinimumHeight(
      {required Size minDesktopSize}) async {
    Display primaryDisplay = await getPrimaryDisplay();
    Size newSize = Size(primaryDisplay.size.width, minDesktopSize.height + 10);

    await windowManager.setPosition(Offset.zero);
    windowManager.setSize(newSize, animate: true);
  }

  Future<void> windowResize({required Size minDesktopSize}) async {
    Size newSize = Size(minDesktopSize.width, minDesktopSize.height);

    await windowManager.setPosition(Offset.zero);
    windowManager.setSize(newSize, animate: true);
  }

  Future<Map<String, String>> getCustomMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messagesStr = prefs.getString('customMessages');
    Map<String, String> customMessages = messagesStr != null &&
            messagesStr.isNotEmpty &&
            messagesStr.substring(0, 1) == '{'
        ? (jsonDecode(messagesStr) as Map<String, dynamic>)
            .map((String k, dynamic v) => MapEntry(k, v as String))
        : {};
    return customMessages;
  }

  setCustomMessages({required Map<String, String> messages}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('customMessages', jsonEncode(messages));
  }

  String decompressZlib(Uint8List data) {
    return utf8.decode(ZLibCodec().decode(data));
  }

  CoverModel? getRoonCoverModel({
    required Map<String, dynamic> channels,
    required String zoneName,
    required dynamic zone,
    required bool idle,
  }) {
    String? coverUrl = zone['cover'];
    if (channels.values.contains(zoneName) &&
        ((!idle && zone['status'] == 'playing') ||
            (idle == true && zone['status'] != 'playing'))) {
      String controlId =
          channels.keys.firstWhere((el) => channels[el] == zoneName);
      CoverModel coverModel = CoverModel(
        controlId: controlId,
        zoneName: zoneName,
        coverUrl: coverUrl ?? '',
        artist: zone['artist'] ?? '',
        album: zone['album'] ?? '',
        track: zone['track'] ?? '',
        status: zone['status'],
      );

      return coverModel;
    }

    return null;
  }

  CoverModel? getWebCoverModel({
    required Map<String, dynamic> channels,
    required String zoneName,
    required dynamic zone,
    required bool idle,
    required bool showWebCoverNotRunning,
  }) {
    String? coverUrl = zone['cover'];
    if (channels.keys.contains(zoneName) &&
        ((!idle && zone['status'] == 'playing') ||
            (idle == true && zone['status'] == 'paused') ||
            (idle == true &&
                showWebCoverNotRunning == true &&
                zone['status'] == 'not running'))) {
      CoverModel coverModel = CoverModel(
        controlId: zoneName,
        zoneName: zoneName,
        coverUrl: coverUrl ?? '',
        artist: zone['artist'] ?? '',
        album: zone['album'] ?? '',
        track: zone['track'] ?? '',
        status: zone['status'] ?? '',
      );

      return coverModel;
    }

    return null;
  }

  List<CoverModel> getCoversModel({
    required Map<String, dynamic>? info,
    required bool showWebCoverNotRunning,
  }) {
    List<CoverModel> covers = [];

    if (info != null && info != {}) {
      if (info.keys.isNotEmpty) {
        Map<String, dynamic> roonPlayouts =
            info[info.keys.first]['roon_playouts'];
        Map<String, dynamic> channels = info[info.keys.first]['channels'];

        for (String zoneName in roonPlayouts.keys) {
          CoverModel? coverModel = getRoonCoverModel(
            channels: channels,
            zoneName: zoneName,
            zone: roonPlayouts[zoneName],
            idle: false,
          );
          if (coverModel != null) {
            covers.add(coverModel);
          }
        }

        Map<String, dynamic> webPlayouts =
            info[info.keys.first]['web_playouts'];
        for (String serverName in webPlayouts.keys) {
          List<dynamic> zones = webPlayouts[serverName];
          for (dynamic zone in zones) {
            if (zone != null) {
              String zoneName = '$serverName-${zone['zone']}';

              CoverModel? coverModel = getWebCoverModel(
                channels: channels,
                zoneName: zoneName,
                zone: zone,
                idle: false,
                showWebCoverNotRunning: showWebCoverNotRunning,
              );
              if (coverModel != null) {
                covers.add(coverModel);
              }
            }
          }
        }

        for (String zoneName in roonPlayouts.keys) {
          CoverModel? coverModel = getRoonCoverModel(
            channels: channels,
            zoneName: zoneName,
            zone: roonPlayouts[zoneName],
            idle: true,
          );
          if (coverModel != null) {
            covers.add(coverModel);
          }
        }

        for (String serverName in webPlayouts.keys) {
          List<dynamic> zones = webPlayouts[serverName];
          for (dynamic zone in zones) {
            if (zone != null) {
              String zoneName = '$serverName-${zone['zone']}';

              CoverModel? coverModel = getWebCoverModel(
                channels: channels,
                zoneName: zoneName,
                zone: zone,
                idle: true,
                showWebCoverNotRunning: showWebCoverNotRunning,
              );
              if (coverModel != null) {
                covers.add(coverModel);
              }
            }
          }
        }
      }
    }

    return covers;
  }

  isRoonZone(String zoneName) {
    return !zoneName.endsWith('-Apple Music') &&
        !zoneName.endsWith('-SpotifyConnect') &&
        !zoneName.endsWith('-Spotify');
  }

  getFormattedDateString(
      {required String date,
      String languageCode = 'de',
      String format = 'dd.MM.yyyy HH:mm:ss'}) {
    String formattedDate =
        DateFormat(format, languageCode).format(DateTime.parse(date));

    return formattedDate;
  }

  Offset getZoneIconPosition(
      {required double size, required CoverModel coverModel}) {
    if (coverModel.zoneName.endsWith('-Apple Music')) {
      return Offset(size < 200 ? -2.0 : -5.0, size < 200 ? -2.0 : -3.0);
    }
    if (coverModel.zoneName.endsWith('-SpotifyConnect')) {
      return Offset(size < 200 ? 2.0 : 0, size < 200 ? 4.0 : 5.0);
    }

    if (coverModel.zoneName.endsWith('-Spotify')) {
      return Offset(2.0, size < 200 ? 4.0 : 5.0);
    }

    return Offset(4.0, 5.0);
  }

  Color getZoneColor(CoverModel coverModel) {
    if (coverModel.zoneName.endsWith('-Apple Music')) {
      return Color(0xFFF50057);
    }
    if (coverModel.zoneName.endsWith('-SpotifyConnect') ||
        coverModel.zoneName.endsWith('-Spotify')) {
      return Colors.green;
    }

    return Colors.blue.shade300;
  }

  double getZoneIconSize(
      {required double size, required CoverModel coverModel}) {
    double factor = size < 200 ? 0.65 : 1.0;
    if (coverModel.zoneName.endsWith('-Apple Music')) {
      return factor * 54.0;
    }
    if (coverModel.zoneName.endsWith('-SpotifyConnect')) {
      return factor * 44.0;
    }

    if (coverModel.zoneName.endsWith('-Spotify')) {
      return factor * 44.0;
    }

    return factor * 40.0;
  }

  statusCorner({required double size, required Color color}) => SizedBox(
        width: size < 200 ? 56 : 84,
        height: size < 200 ? 56 : 84,
        child: ClipRRect(
          child: CustomPaint(
            painter: TrianglePainter(
              color: color,
            ),
          ),
        ),
      );

  String replaceIllegalCharsInTickerString(String str) {
    if (str.length > 1 && str.startsWith('[') && str.endsWith(']')) {
      str = jsonDecode(str.replaceAll("'", '"')).join(
          ' '); // maybe troublemaker (should be replaced in python part on device)
      str = str.replaceAll('< ', ', ');
      str = str.replaceAll(' >', ': ');
    }

    return str;
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void restartPollingTimer() {
    add(RestartPollingTimer());
  }

  void resetWebSocketServices() {
    add(ResetWebSocketServices());
  }

  void setIpRange({required String? ipStart, required String? ipEnd}) {
    add(SetIpRange(ipStart: ipStart, ipEnd: ipEnd));
  }

  void setLogMessage({required String msg}) {
    add(SetLogMessage(msg: msg));
  }

  void searching({bool? idle}) {
    add(Searching(idle: idle));
  }

  void getInfo({required String ip}) {
    add(GetInfo(ip: ip));
  }

  void getConfig({required String ip}) {
    add(GetConfig(ip: ip));
  }

  void getLog({required String ip, required int hours}) {
    add(GetLog(ip: ip, hours: hours));
  }

  void zoneControl(
      {required String ip,
      required String controlId,
      required String cmd,
      bool enable = false}) {
    add(ZoneControl(ip: ip, controlId: controlId, cmd: cmd, enable: enable));
  }

  void setSpotifyAuthRedirectUrl({
    required String ip,
    required String url,
  }) {
    if (kDebugMode) {
      debugPrint('setSpotifyAuthRedirectUrl => ip: $ip, url: $url');
    }
    add(SetSpotifyAuthRedirectUrl(ip: ip, url: url));
  }

  void setSearchFilter({required String type, required String filter}) {
    add(SetSearchFilter(type: type, filter: filter));
  }

  @override
  Future<void> close() {
    timer?.cancel();
    for (WebSocketService service in services) {
      service.dispose();
    }
    return super.close();
  }
}
