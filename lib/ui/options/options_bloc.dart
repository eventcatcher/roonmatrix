import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:roonmatrix/data/file_repository.dart';
import 'package:roonmatrix/model/options.dart';
import 'package:roonmatrix/ui/options/options_event.dart';
import 'package:roonmatrix/ui/options/options_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
//ignore:depend_on_referenced_packages
import 'package:http/http.dart' as http;

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
  final String startIp = '192.168.0.50'; // min: 1
  final String endIp = '192.168.0.59'; // max: 254
  final int port = 8000;
  final int timeoutInMilliseconds = 500;
  final int logTextDelayInMilliseconds = 500;
  http.Client client = http.Client();
  Timer? timer;
  bool isScanning = false;

  OptionsBloc({required this.fileRepository})
      : super(const OptionsStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<OptionsEvent>((event, emit) async {
      if (event is ResetOptions) {
        setPollingTimer(stateBefore: state.options?.polling, newState: false);
        Options options = Options((OptionsBuilder b) => b..polling = false);

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          options: options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
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
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          log: state.log,
          idle: state.idle,
          logMessage: logMessage,
        ));
      }

      if (event is LoadDevicesAndInfo) {
        emit(OptionsStateLoaded(
          update: DateTime.now(),
          options: state.options,
          searchFilter: state.searchFilter,
          devices: event.devices,
          info: event.info,
          config: state.config,
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
          options: options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
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
          options: options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
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
          options: state.options,
          searchFilter: searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          log: state.log,
          idle: state.idle,
          logMessage: state.logMessage,
        ));
      }

      if (event is Searching) {
        emit(OptionsStateLoaded(
          update: DateTime.now(),
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
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
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
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
                  options: state.options,
                  searchFilter: state.searchFilter,
                  devices: state.devices,
                  info: info,
                  config: state.config,
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
              options: state.options,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
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
            options: state.options,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
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
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
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

                emit(OptionsStateLoaded(
                  update: DateTime.now(),
                  options: state.options,
                  searchFilter: state.searchFilter,
                  devices: state.devices,
                  info: state.info,
                  config: json,
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
              options: state.options,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
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
            options: state.options,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
            log: state.log,
            idle: false,
            logMessage: state.logMessage,
          ));
        }
      }

      if (event is GetLog) {
        String ip = event.ip;

        emit(OptionsStateLoaded(
          update: DateTime.now(),
          options: state.options,
          searchFilter: state.searchFilter,
          devices: state.devices,
          info: state.info,
          config: state.config,
          log: '',
          idle: true,
          logMessage: state.logMessage,
        ));

        try {
          String url = 'http://$ip:$port/log/';
          Uri uri = Uri.parse(url);
          try {
            var response = await client.get(uri);
            if (response.statusCode == 200) {
              emit(OptionsStateLoaded(
                update: DateTime.now(),
                options: state.options,
                searchFilter: state.searchFilter,
                devices: state.devices,
                info: state.info,
                config: state.config,
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
              options: state.options,
              searchFilter: state.searchFilter,
              devices: state.devices,
              info: state.info,
              config: state.config,
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
            options: state.options,
            searchFilter: state.searchFilter,
            devices: state.devices,
            info: state.info,
            config: state.config,
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

        final int firstHostId = int.parse(startIp.split('.').last);
        final int lastHostId = int.parse(endIp.split('.').last);
        final String subnet = startIp.substring(0, startIp.lastIndexOf('.'));

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
        searchDevices();
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

  void getLog({required String ip}) {
    add(GetLog(ip: ip));
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
