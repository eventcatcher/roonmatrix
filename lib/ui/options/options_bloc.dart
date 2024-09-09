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
import 'package:roonmatrix/model/item_type_structure.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/ui/options/options_event.dart';
import 'package:roonmatrix/ui/options/options_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
//ignore:depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:validators/validators.dart';

class OptionsBloc extends Bloc<OptionsEvent, OptionsState> {
  final FileRepository fileRepository;

  final Map<String, TextEditingController> conrollerSearch = {
    "main": TextEditingController(),
    "info": TextEditingController(),
    "config": TextEditingController(),
    "log": TextEditingController()
  };
  final bool logDebugMessage = false;
  final int pollingIntervalInSeconds = 30;
  final int port = 8000;
  final int timeoutInMilliseconds = 500;
  final int logTextDelayInMilliseconds = 500;
  http.Client client = http.Client();
  Map<String, dynamic> logHoursOptions = {};
  String? ipStart;
  String? ipEnd;
  bool isScanning = false;
  Timer? timer;

  generateLogHours() {
    for (int i = 1; i <= 24; i++) {
      logHoursOptions[i.toString()] = {
        "name": "$i hour${i > 1 ? 's' : ''} ago",
        "fontWeight": FontWeight.normal,
        "icon": null
      };
    }
  }

  OptionsBloc({required this.fileRepository})
      : super(const OptionsStateInitial()) {
    generateLogHours();

    // ====================== //
    // event to state handler //
    // ====================== //
    on<OptionsEvent>((event, emit) async {
      if (event is SetIpRange) {
        String? ipStart = event.ipStart;
        String? ipEnd = event.ipEnd;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: ipStart,
          ipEnd: ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          logMessage: state.logMessage,
        ));
      }

      if (event is ResetOptions) {
        setPollingTimer(stateBefore: state.options?.polling, newState: false);
        Options options = Options((OptionsBuilder b) => b..polling = false);

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          logMessage: state.logMessage,
        ));

        saveOptions(options);
      }

      if (event is SetLogMessage) {
        String logMessage = event.msg;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          logMessage: logMessage,
        ));
      }

      if (event is LoadDevicesAndInfo) {
        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: event.devices,
          info: event.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: false,
          logMessage: state.logMessage,
        ));
      }

      if (event is SetOptionsPolling) {
        bool polling = event.polling;
        setPollingTimer(stateBefore: state.options?.polling, newState: polling);
        Options options =
            state.options!.rebuild((OptionsBuilder b) => b..polling = polling);

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          logMessage: state.logMessage,
        ));

        saveOptions(options);
      }

      if (event is SetOptions) {
        Options options = event.options;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          logMessage: state.logMessage,
        ));
      }

      if (event is SetSearchFilter) {
        String type = event.type;
        String filter = event.filter;
        Map<String, String> searchFilter = Map.from(state.searchFilter);
        searchFilter[type] = filter;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: state.options,
          searchFilter: searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: state.idle,
          logMessage: state.logMessage,
        ));
      }

      if (event is Searching) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        ipStart = prefs.getString('ipStart');
        ipEnd = prefs.getString('ipEnd');

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: ipStart,
          ipEnd: ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: true,
          logMessage: state.logMessage,
        ));

        searchDevices();
      }

      if (event is GetInfo) {
        String ip = event.ip;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: true,
          logMessage: state.logMessage,
        ));

        try {
          String url = 'http://$ip:$port/info/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.get(uri);
            if (response.statusCode == 200) {
              if (response.body.substring(0, 1) == '{') {
                Map<String, dynamic> json =
                    jsonDecode(response.body) as Map<String, dynamic>;

                Map<String, dynamic> info = state.info;
                info[ip] = json;

                emit(OptionsStateLoaded(
                  update: DateTime.now(),
                  ipStart: state.ipStart,
                  ipEnd: state.ipEnd,
                  options: state.options,
                  searchFilter: state.searchFilter,
                  devices: state.devices,
                  info: info,
                  config: state.config,
                  definitions: state.definitions,
                  fieldValues: state.fieldValues,
                  log: state.log,
                  idle: false,
                  logMessage: state.logMessage,
                ));
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('error by access to $url: $e');
            }
            emit(OptionsStateLoaded(
              update: DateTime.now(),
              ipStart: state.ipStart,
              ipEnd: state.ipEnd,
              options: state.options,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
              definitions: state.definitions,
              fieldValues: state.fieldValues,
              log: state.log,
              idle: false,
              logMessage: state.logMessage,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          emit(OptionsStateLoaded(
            update: DateTime.now(),
            ipStart: state.ipStart,
            ipEnd: state.ipEnd,
            options: state.options,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            definitions: state.definitions,
            fieldValues: state.fieldValues,
            log: state.log,
            idle: false,
            logMessage: state.logMessage,
          ));
        }
      }

      if (event is GetConfig) {
        String ip = event.ip;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: state.log,
          idle: true,
          logMessage: state.logMessage,
        ));

        try {
          String url = 'http://$ip:$port/config/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.get(uri);
            if (response.statusCode == 200) {
              if (response.body.substring(0, 1) == '{') {
                Map<String, dynamic> json =
                    jsonDecode(response.body) as Map<String, dynamic>;

                ConfigDefinition definitions =
                    ConfigDefinition.fromJson(json['definitions']);

                Map fieldValues =
                    getFieldValues(defs: definitions, json: json['config']);

                emit(OptionsStateLoaded(
                  update: DateTime.now(),
                  ipStart: state.ipStart,
                  ipEnd: state.ipEnd,
                  options: state.options,
                  searchFilter: state.searchFilter,
                  devices: state.devices,
                  info: state.info,
                  config: json['config'],
                  definitions: definitions,
                  fieldValues: fieldValues,
                  log: state.log,
                  idle: false,
                  logMessage: state.logMessage,
                ));
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('error by access to $url: $e');
            }
            emit(OptionsStateLoaded(
              update: DateTime.now(),
              ipStart: state.ipStart,
              ipEnd: state.ipEnd,
              options: state.options,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
              definitions: state.definitions,
              fieldValues: state.fieldValues,
              log: state.log,
              idle: false,
              logMessage: state.logMessage,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          emit(OptionsStateLoaded(
            update: DateTime.now(),
            ipStart: state.ipStart,
            ipEnd: state.ipEnd,
            options: state.options,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            definitions: state.definitions,
            fieldValues: state.fieldValues,
            log: state.log,
            idle: false,
            logMessage: state.logMessage,
          ));
        }
      }

      if (event is GetLog) {
        String ip = event.ip;
        int hours = event.hours;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          ipStart: state.ipStart,
          ipEnd: state.ipEnd,
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          definitions: state.definitions,
          fieldValues: state.fieldValues,
          log: '',
          idle: true,
          logMessage: state.logMessage,
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
            var response = await client.post(uri,
                headers: headers, body: json.encode(payload));
            if (response.statusCode == 200) {
              emit(OptionsStateLoaded(
                update: DateTime.now(),
                ipStart: state.ipStart,
                ipEnd: state.ipEnd,
                options: state.options,
                searchFilter: state.searchFilter,
                devices: state.devices,
                info: state.info,
                config: state.config,
                definitions: state.definitions,
                fieldValues: state.fieldValues,
                log: response.body,
                idle: false,
                logMessage: state.logMessage,
              ));
            }
          } catch (e) {
            if (kDebugMode) {
              print('error by access to $url: $e');
            }
            emit(OptionsStateLoaded(
              update: DateTime.now(),
              ipStart: state.ipStart,
              ipEnd: state.ipEnd,
              options: state.options,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
              definitions: state.definitions,
              fieldValues: state.fieldValues,
              log: '',
              idle: false,
              logMessage: state.logMessage,
            ));
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          emit(OptionsStateLoaded(
            update: DateTime.now(),
            ipStart: state.ipStart,
            ipEnd: state.ipEnd,
            options: state.options,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            definitions: state.definitions,
            fieldValues: state.fieldValues,
            log: '',
            idle: false,
            logMessage: state.logMessage,
          ));
        }
      }

      if (event is ZoneControl) {
        String ip = event.ip;
        String controlId = event.controlId;
        String cmd = event.cmd; // previous, next, shufflemode, playmode

        Map<String, String> headers = {
          "Content-Type": 'application/json',
          "Accept": 'application/json',
        };

        Map<String, dynamic> payload = {
          "control_id": controlId,
          "cmd": cmd,
        };

        try {
          String url = 'http://$ip:$port/zone_control/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.post(uri,
                headers: headers, body: json.encode(payload));

            if (response.statusCode == 200) {
              if (kDebugMode) {
                print(
                    'zoneControl => ip: $ip, controlId: $controlId, cmd: $cmd');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('ZoneControl error by access to $url: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('ZoneControl error: $e');
          }
        }
      }
    });

    setPollingTimer(stateBefore: state.options?.polling, newState: true);
    searching();
  }

  // ============== //
  // public methods //
  // ============== //

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
          print('save of $fileName error: $e');
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

      if (fieldDefinition.type.type.startsWith('int')) {
        fieldType = 'int';
      }

      if (fieldDefinition.type.type == 'bool') {
        fieldType = 'bool';
      }

      if (fieldDefinition.type.type == 'list') {
        fieldType = 'list';
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
                  fieldType == 'list' ||
                  fieldType == 'keyValItems') {
                fieldValues[areaKey][fieldKey] = area[fieldKey];
              }
              if (kDebugMode) {
                print(
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

        if (fieldType.startsWith('string')) {
          bool itemValid =
              validateText(text: fieldValues[idx][key], type: fieldType);
          if (itemValid == false) {
            return false;
          }
        }
      }
    }

    return valid;
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
        if (fieldDefinition != null && fieldDefinition.editable == true) {
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

  Future<bool> saveConfig(
      {required String name, required String ip, required dynamic data}) async {
    if (state.devices.isNotEmpty) {
      try {
        String jsonStr = jsonEncode(data);
        if (kDebugMode) {
          print('saveConfig, name: $name, ip: $ip, data: $jsonStr');
        }

        Map<String, String> headers = {
          "Content-Type": 'application/json',
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
                print('setup => ip: $ip, data: $jsonStr');
              }
              return Future.value(true);
            }
          } catch (e) {
            if (kDebugMode) {
              print('Setup error by access to $url: $e');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Setup error: $e');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Setup error: $e');
        }
      }
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
              if (i['channels'][controlId] == 'webserver') {
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
            print('save of $fileName error: $e');
          }
          return Future.value(false);
        }
      }
    }

    return Future.value(null);
  }

  void saveOptions(Options options) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/options.json';
    debugPrint('saveOptions => filePath: $filePath');
    File file = File(filePath);

    Map<String, dynamic> map = options.toJson();
    String jsonStr = jsonEncode(map);

    file.writeAsString(jsonStr);
  }

  Future<Options> loadOptions(Options optionPresets) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;
    String filePath = '$appDocPath/options.json';
    File file = File(filePath);

    Options options;

    if (file.existsSync() == true) {
      List<String> lines = file.readAsLinesSync();
      if (lines.isNotEmpty) {
        options = Options.fromJson(jsonDecode(lines.first));
      } else {
        options = optionPresets;
        saveOptions(options);
      }
    } else {
      options = optionPresets;
      saveOptions(options);
    }

    debugPrint('loadOptions => filePath: $filePath');
    debugPrint(options.toString());
    setOptions(options: options);

    return options;
  }

  Future<void> searchDevices() async {
    if (kDebugMode) {
      print('searchDevices, isScanning: $isScanning');
    }

    if (isScanning == true) {
      if (logDebugMessage == true) {
        await Future.delayed(
            Duration(milliseconds: logTextDelayInMilliseconds));
        addToLogMessage(msg: 'networkscan is running...');
        await Future.delayed(
            Duration(milliseconds: logTextDelayInMilliseconds));
      }
    } else {
      List<String> devices = [];
      Map<String, dynamic> info = {};
      isScanning = true;

      try {
        addToLogMessage(msg: 'start networkscan', clear: true);
        if (logDebugMessage == true) {
          await Future.delayed(
              Duration(milliseconds: logTextDelayInMilliseconds));
        }

        if (ipStart != null && ipEnd != null) {
          final int firstHostId = int.parse(ipStart!.split('.').last);
          final int lastHostId = int.parse(ipEnd!.split('.').last);
          final String subnet =
              ipStart!.substring(0, ipStart!.lastIndexOf('.'));

          for (int i = firstHostId; i <= lastHostId; i++) {
            String ip = '$subnet.$i';
            await Socket.connect(ip, port,
                    timeout: Duration(milliseconds: timeoutInMilliseconds))
                .then((socket) async {
              if (logDebugMessage == true) {
                await Future.delayed(
                    Duration(milliseconds: logTextDelayInMilliseconds));
                addToLogMessage(msg: 'found device on ip: $ip');
                await Future.delayed(
                    Duration(milliseconds: logTextDelayInMilliseconds));
              }
              if (kDebugMode) {
                print('found device on ip: $ip');
              }

              String url = 'http://$ip:$port/info/';
              Uri uri = Uri.parse(url);
              addToLogMessage(msg: 'test rest-api route: $url');
              try {
                var response = await client.get(uri);
                if (response.statusCode == 200) {
                  if (response.body.substring(0, 1) == '{') {
                    Map<String, dynamic> json =
                        jsonDecode(response.body) as Map<String, dynamic>;
                    if (json['name'] != null && json['time'] != null) {
                      addToLogMessage(
                          msg:
                              'roonmatrix device found on ip: $ip, name: ${json['name']}');
                      if (kDebugMode) {
                        print(
                            'roonmatrix device found on ip: $ip, name: ${json['name']}, time: ${json['time']}');
                      }

                      devices.add(ip);
                      info[ip] = json;
                    }
                  }
                }
              } catch (e) {
                addToLogMessage(msg: 'error by access to $url: $e');
                if (kDebugMode) {
                  print('error by access to $url: $e');
                }
              }

              socket.destroy();
            }).catchError((error) {
              if (kDebugMode) {
                print("nothing found on ip: $ip");
              }
            });
          }

          add(LoadDevicesAndInfo(devices: devices, info: info));
        }

        isScanning = false;
      } catch (e) {
        if (logDebugMessage == true) {
          await Future.delayed(
              Duration(milliseconds: logTextDelayInMilliseconds));
          addToLogMessage(msg: 'general ip scan error: $e');
          await Future.delayed(
              Duration(milliseconds: logTextDelayInMilliseconds));
        }
        if (kDebugMode) {
          print('general ip scan error: $e');
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

  addToLogMessage({required String msg, bool clear = false}) {
    if (logDebugMessage == true) {
      String logMessage = state.logMessage;
      if (clear == true) {
        logMessage = '$msg\n';
      } else {
        logMessage += '$msg\n';
      }

      setLogMessage(msg: logMessage);
    }
  }

  setPollingTimer({required bool? stateBefore, required bool newState}) {
    if (stateBefore != true && newState == true) {
      if (kDebugMode) {
        print('enable polling');
      }
      timer = Timer.periodic(Duration(seconds: pollingIntervalInSeconds),
          (Timer timer) {
        searching();
      });
    }
    if (stateBefore != false && newState == false) {
      if (kDebugMode) {
        print('disable polling');
      }
      timer?.cancel();
    }
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void setIpRange({required String? ipStart, required String? ipEnd}) {
    add(SetIpRange(ipStart: ipStart, ipEnd: ipEnd));
  }

  void resetOptions() {
    add(ResetOptions());
  }

  void setLogMessage({required String msg}) {
    add(SetLogMessage(msg: msg));
  }

  void searching() {
    add(Searching());
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
      {required String ip, required String controlId, required String cmd}) {
    add(ZoneControl(ip: ip, controlId: controlId, cmd: cmd));
  }

  void setOptionsPolling({required bool polling}) {
    add(SetOptionsPolling(polling: polling));
  }

  void setOptions({required Options options}) {
    add(SetOptions(options: options));
  }

  void setSearchFilter({required String type, required String filter}) {
    add(SetSearchFilter(type: type, filter: filter));
  }

  @override
  Future<void> close() {
    timer?.cancel();
    return super.close();
  }
}
