import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/model/config_definition.dart';
import 'package:roonmatrix/model/config_definition_area.dart';
import 'package:roonmatrix/model/config_definition_item.dart';
import 'package:roonmatrix/model/cover_model.dart';
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/ui/helper/websocket_service.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';
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

  final Map<String, TextEditingController> controllerSearch = {
    "main": TextEditingController(),
    "info": TextEditingController(),
    "config": TextEditingController(),
    "log": TextEditingController()
  };
  final List<String> allowedDeviceTypes = ['roonmatrix', 'coverplayer'];
  final int pollingIntervalInSeconds = 30;
  final int reconnectDelayInSeconds = 3;
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
      if (event is MainStateLoadDefaults) {
        if (SharedWidgets.inMacosStyle()) {
          String macosVersion = await SharedWidgets.getMacosVersion();

          emit(state.copyWith(
            update: DateTime.now(),
            macosVersion: macosVersion,
          ));
        }
      }

      if (event is SetIpRange) {
        String? ipStart = event.ipStart;
        String? ipEnd = event.ipEnd;

        emit(state.copyWith(
          update: DateTime.now(),
          ipStart: ipStart,
          ipEnd: ipEnd,
        ));
      }

      if (event is SetLogMessage) {
        String logMessage = event.msg;

        emit(state.copyWith(
          update: DateTime.now(),
          logMessage: logMessage,
        ));
      }

      if (event is ResetWebSocketServices) {
        if (kDebugMode) {
          debugPrint(
              'ResetWebSocketServices @ ${DateTime.now().toLocal()}, services: ${services.length}');
        }
        for (WebSocketService service in services) {
          service.dispose();
        }
        services = [];
      }

      if (event is SetPing) {
        String ip = event.ip;
        bool ping = event.ping;

        Map<String, bool> pingList = Map.from(state.ping);
        pingList[ip] = ping;
        emit(state.copyWith(
          update: DateTime.now(),
          ping: pingList,
        ));
      }

      if (event is SetConnected) {
        String ip = event.ip;
        bool connected = event.connected;

        Map<String, bool> connectedList = Map.from(state.connected);
        connectedList[ip] = connected;

        String? activeDeviceIp = getFirstDeviceConnectedIp(
            activeDeviceIp: state.activeDeviceIp ?? ip,
            info: state.info,
            connected: connectedList);
        if (kDebugMode && activeDeviceIp != state.activeDeviceIp) {
          debugPrint('activeDeviceIp: $activeDeviceIp');
        }

        emit(state.copyWith(
          update: DateTime.now(),
          connected: connectedList,
          activeDeviceIp: activeDeviceIp,
        ));
      }

      if (event is AddWebSocketService) {
        String ip = event.ip;
        String url = 'ws://$ip:$port/ws';
        bool exist = false;

        for (WebSocketService service in services) {
          if (url == service.url) {
            exist = true;
            if (kDebugMode) {
              debugPrint(
                  'ws123 WebSocketService @ ${DateTime.now().toLocal()}: ${service.url} => found and therefore not added again');
            }

            break;
          }
        }

        if (!exist) {
          WebSocketService service = WebSocketService(
              ip: ip,
              port: port,
              onMessage: (String jsonStr) {
                if (jsonStr.isNotEmpty &&
                    jsonStr.startsWith('{') &&
                    jsonStr.endsWith('}')) {
                  dynamic info = jsonDecode(jsonStr);
                  if (kDebugMode) {
                    debugPrint(
                        'WebSocketService received data @ ${DateTime.now().toLocal()} from device ${info['name']} @ ${DateTime.now().toLocal()}, app_displaystr: ${info['app_displaystr']}');
                  }
                  add(LoadInfo(ip: ip, info: info));
                }
              },
              onPing: () {
                setPing(ip: ip, ping: true);
              },
              onConnect: (bool connected) {
                setConnected(ip: ip, connected: connected);
                if (!connected) {
                  List<WebSocketService> servicesToRemove = [];
                  for (WebSocketService service in services) {
                    if (url == service.url) {
                      if (kDebugMode) {
                        debugPrint(
                            'ws123 remove WebSocketService @ ${DateTime.now().toLocal()}: ${service.url}');
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

                  Future.delayed(Duration(seconds: reconnectDelayInSeconds),
                      () => addWebSocketService(ip: ip));
                }
              });

          services.add(service..connect());
        }
      }

      if (event is LoadDevices) {
        List<String> existingServiceUrls =
            services.map((WebSocketService el) => el.url).toList();

        for (String ip in event.devices) {
          String url = 'ws://$ip:$port/ws';

          if (!existingServiceUrls.contains(url)) {
            if (kDebugMode) {
              debugPrint(
                  'add WebSocketService @ ${DateTime.now().toLocal()}: $url');
            }

            addWebSocketService(ip: ip);
            getInfo(ip: ip);
          }
        }

        List<String> newWebSocketUrls =
            event.devices.map((String ip) => 'ws://$ip:$port/ws').toList();
        List<WebSocketService> servicesToRemove = [];
        for (WebSocketService service in services) {
          if (!newWebSocketUrls.contains(service.url)) {
            if (kDebugMode) {
              debugPrint(
                  'ws123 remove WebSocketService @ ${DateTime.now().toLocal()}: ${service.url}');
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
          debugPrint('active websocket connections: ${services.length}');
        }

        emit(state.copyWith(
          update: DateTime.now(),
          devices: event.devices,
          idle: false,
        ));
      }

      if (event is LoadInfo) {
        Map<String, dynamic> info = Map<String, dynamic>.from(state.info);
        info[event.ip] = event.info;
        if (kDebugMode) {
          debugPrint(
              'LoadInfo, ip: ${event.ip}, app_displaystr: ${info[event.ip]['app_displaystr']}');
        }

        emit(state.copyWith(
          update: DateTime.now(),
          info: info,
        ));
      }

      if (event is SetSearchFilter) {
        String type = event.type;
        String filter = event.filter;

        Map<String, String> searchFilter = Map.from(state.searchFilter);
        searchFilter[type] = filter;

        emit(state.copyWith(
          update: DateTime.now(),
          searchFilter: searchFilter,
        ));
      }

      if (event is Searching) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        ipStart = prefs.getString('ipStart');
        ipEnd = prefs.getString('ipEnd');
        bool idle = event.idle ?? false;

        emit(state.copyWith(
          update: DateTime.now(),
          ipStart: ipStart,
          ipEnd: ipEnd,
          idle: idle,
        ));

        searchDevices();
      }

      if (event is GetInfo) {
        String ip = event.ip;

        emit(state.copyWith(
          update: DateTime.now(),
          subPageIdle: true,
        ));

        String url = 'http://$ip:$port/info/';
        try {
          Uri uri = Uri.parse(url);

          var response = await client.get(uri);
          if (response.statusCode == 200) {
            if (response.body.substring(0, 1) == '{') {
              Map<String, dynamic> json = jsonDecode(
                      filterIllegalCharsFromJsonStr(
                          text: utf8.decode(response.bodyBytes),
                          messageHeader: 'GetInfo/info (raw)'))
                  as Map<String, dynamic>;

              Map<String, dynamic> info = Map<String, dynamic>.from(state.info);
              Map<String, dynamic> spotifyAuthUrls =
                  Map<String, dynamic>.from(state.spotifyAuthUrls);

              String spotifyAuthUrl = '';
              if (json.containsKey('spotify_auth_url')) {
                spotifyAuthUrl = json['spotify_auth_url'];
                spotifyAuthUrls[ip] = spotifyAuthUrl;
                json.remove('spotify_auth_url');
              }

              info[ip] = json;

              String? activeDeviceIp = getFirstDeviceConnectedIp(
                  activeDeviceIp: state.activeDeviceIp ?? ip,
                  info: info,
                  connected: state.connected);
              if (kDebugMode && activeDeviceIp != state.activeDeviceIp) {
                debugPrint('activeDeviceIp: $activeDeviceIp');
              }

              emit(state.copyWith(
                update: DateTime.now(),
                info: info,
                subPageIdle: false,
                spotifyAuthUrls: spotifyAuthUrls,
                activeDeviceIp: activeDeviceIp,
              ));
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GetInfo error by access to $url: $e');
          }
          emit(state.copyWith(
            update: DateTime.now(),
            subPageIdle: false,
          ));
        }
      }

      if (event is GetConfig) {
        String ip = event.ip;

        emit(state.copyWith(
          update: DateTime.now(),
          subPageIdle: true,
        ));

        String url = 'http://$ip:$port/config/';
        try {
          Uri uri = Uri.parse(url);

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

              emit(state.copyWith(
                update: DateTime.now(),
                config: json['config'],
                definitions: definitions,
                fieldValues: fieldValues,
                subPageIdle: false,
              ));
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GetConfig error by access to $url: $e');
          }
          emit(state.copyWith(
            update: DateTime.now(),
            subPageIdle: false,
          ));
        }
      }

      if (event is GetLog) {
        String ip = event.ip;
        int hours = event.hours;

        emit(state.copyWith(
          update: DateTime.now(),
          log: '',
          subPageIdle: true,
        ));

        Map<String, String> headers = {
          "Content-Type": 'application/json',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "hours": hours,
        };

        String url = 'http://$ip:$port/log/';
        try {
          Uri uri = Uri.parse(url);

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

            emit(state.copyWith(
              update: DateTime.now(),
              log: log,
              subPageIdle: false,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('GetLog error by access to $url: $e');
          }
          emit(state.copyWith(
            update: DateTime.now(),
            log: '',
            subPageIdle: false,
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

        String url = 'http://$ip:$port/zone_control/';
        try {
          Uri uri = Uri.parse(url);

          if (kDebugMode) {
            debugPrint('send zone_control => payload: $payload');
          }
          var response = await client.post(uri,
              headers: headers, body: json.encode(payload));

          if (response.statusCode == 200) {
            if (state.info.containsKey(ip)) {
              Map<String, dynamic> info = Map<String, dynamic>.from(state.info);
              if (cmd == 'switch') {
                info[ip]['control_id'] = controlId;

                emit(state.copyWith(
                  update: DateTime.now(),
                  info: info,
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
      }

      if (event is SetSpotifyAuthRedirectUrl) {
        String ip = event.ip;

        Map<String, String> headers = {
          "Content-Type": 'application/json; charset=utf-8',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "url": event.url,
        };

        String url = 'http://$ip:$port/spotify_auth_redirect_url/';
        try {
          Uri uri = Uri.parse(url);

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

            emit(state.copyWith(
              update: DateTime.now(),
              spotifyAuthUrls: spotifyAuthUrls,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('SetSpotifyAuthRedirectUrl error by access to $url: $e');
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
      if (SharedWidgets.isDesktopDevice()) {
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
      if (SharedWidgets.isDesktopDevice()) {
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
        if (SharedWidgets.isDesktopDevice()) {
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

  String filterIllegalCharsFromJsonStr(
      {required String text, String messageHeader = '*'}) {
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

    String url = 'http://$ip:$port/message/';
    try {
      Uri uri = Uri.parse(url);

      var response =
          await client.post(uri, headers: headers, body: json.encode(payload));
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
      return Future.value(false);
    }

    return Future.value(false);
  }

  Future<bool> saveConfig(
      {required String name, required String ip, required dynamic data}) async {
    if (state.devices.isNotEmpty) {
      Map<String, String> headers = {
        "Content-Type": 'application/json; charset=utf-8',
        "Accept": 'application/json',
      };
      String jsonStr = '';

      try {
        jsonStr = jsonEncode(data);
        if (kDebugMode) {
          debugPrint('saveConfig, name: $name, ip: $ip, data: $jsonStr');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Setup jsonEncode error: $e');
        }
        Future.value(false);
      }

      String url = 'http://$ip:$port/setup/';
      try {
        Uri uri = Uri.parse(url);
        Map<String, dynamic> payload = {
          "data": jsonStr,
        };

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

    String url = 'http://$ip:$port/livecontrol/';
    try {
      Uri uri = Uri.parse(url);

      var response =
          await client.post(uri, headers: headers, body: json.encode(payload));
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
        if (SharedWidgets.isDesktopDevice()) {
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
          if (SharedWidgets.isDesktopDevice()) {
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
                  Map<String, dynamic> json = jsonDecode(
                          filterIllegalCharsFromJsonStr(
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
      String hash = md5
          .convert(utf8.encode(
              '$controlId-${zone['artist']}-${zone['album']}-${zone['track']}-${zone['status']}-$coverUrl'))
          .toString();
      bool isRadio = zone['total'] == null;
      CoverModel coverModel = CoverModel(
        hash: hash,
        controlId: controlId,
        zoneName: zoneName,
        isRadio: isRadio,
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
    // debugPrint(
    //     'showWebCoverNotRunning: $showWebCoverNotRunning, idle: $idle, status: ${zone['status']}');
    if (channels.keys.contains(zoneName) &&
        ((!idle && zone['status'] == 'playing') ||
            (idle == true && zone['status'] == 'paused') ||
            (idle == true &&
                showWebCoverNotRunning == true &&
                zone['status'] == 'not running'))) {
      bool isRadio = zone['zone'] == 'Apple Music' &&
          zone['sourcetype'] == 'stream' &&
          zone['position'] ==
              '0'; // if this is a radio stream, set this prop to true (at the moment a radio stream is recognized by sourcetype is stream and playpos is 0, because playpos is not counting on radio streams)
      String hash = md5
          .convert(utf8.encode(
              '$zoneName-${zone['artist']}-${zone['album']}-${zone['track']}-${zone['status']}-$coverUrl'))
          .toString();
      CoverModel coverModel = CoverModel(
        hash: hash,
        controlId: zoneName,
        zoneName: zoneName,
        isRadio: isRadio,
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

  List<CoverModel> getCoversModel({required bool showWebCoverNotRunning}) {
    Map<String, dynamic> info = state.info;
    String? activeDeviceIp = state.activeDeviceIp;

    List<CoverModel> covers = [];

    if (info != {}) {
      if (info.keys.isNotEmpty) {
        if (activeDeviceIp == null) {
          return [];
        }

        if (kDebugMode) {
          debugPrint(
              'getCoversModel from connected device with ip: $activeDeviceIp');
        }
        Map<String, dynamic> roonPlayouts =
            info[activeDeviceIp]['roon_playouts'];
        Map<String, dynamic> channels = info[activeDeviceIp]['channels'];

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

        Map<String, dynamic> webPlayouts = info[activeDeviceIp]['web_playouts'];
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

  String? getFirstDeviceConnectedIp({
    required String? activeDeviceIp,
    required Map<String, dynamic>? info,
    required Map<String, bool> connected,
  }) {
    if (info == null || info.keys.isEmpty) {
      return null;
    }

    if (activeDeviceIp != null &&
        connected.containsKey(activeDeviceIp) &&
        connected[activeDeviceIp] == true) {
      return activeDeviceIp;
    }

    for (String ip in info.keys) {
      if (connected.containsKey(ip) && connected[ip] == true) {
        return ip;
      }
    }

    return info.keys.first;
  }

  TextEditingController getSearchController({required String type}) =>
      controllerSearch[type]!;

  String getPrettyJSONString(jsonObject) {
    JsonEncoder encoder = const JsonEncoder.withIndent("     ");
    String jsonStr = encoder.convert(jsonObject);

    return jsonStr;
  }

  setPollingTimer() {
    if (kDebugMode) {
      debugPrint(
          'setPollingTimer, pollingIntervalInSeconds: $pollingIntervalInSeconds');
    }
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

  Future<void> windowResize({required Size size, Offset? position}) async {
    Size newSize = Size(size.width, size.height);

    await windowManager.setPosition(position ?? Offset.zero);
    windowManager.setSize(newSize, animate: true);
  }

  String decompressZlib(Uint8List data) {
    return utf8.decode(ZLibCodec().decode(data));
  }

  List<String> getFilteredDevices() {
    if (state.devices.isEmpty) {
      return [];
    }

    return state.devices
        .where((String el) =>
            state.info.containsKey(el) &&
            (state.info[el]['name'] as String)
                .toLowerCase()
                .contains((state.searchFilter['main'] as String).toLowerCase()))
        .toList()
      ..sort((String a, String b) => state.info.containsKey(a) &&
              (state.info[a] as Map).containsKey('name')
          ? (state.info[a]['name'] as String)
              .toLowerCase()
              .compareTo((state.info[b]['name'] as String).toLowerCase())
          : a.compareTo(b));
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void loadDefaults() {
    add(MainStateLoadDefaults());
  }

  void restartPollingTimer() {
    add(RestartPollingTimer());
  }

  void addWebSocketService({required String ip}) {
    add(AddWebSocketService(ip: ip));
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

  void setPing({required String ip, required bool ping}) {
    add(SetPing(ip: ip, ping: ping));
  }

  void setConnected({required String ip, required bool connected}) {
    add(SetConnected(ip: ip, connected: connected));
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
