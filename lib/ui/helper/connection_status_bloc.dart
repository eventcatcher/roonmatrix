import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/globals.dart';
import 'package:roonmatrix/ui/helper/connection_status_event.dart';
import 'package:roonmatrix/ui/helper/connection_status_state.dart';

class ConnectionStatusBloc
    extends Bloc<ConnectionStatusEvent, ConnectionStatusState> {
  final ConnectionNetworkType _connectionNetworkTypePlugin =
      ConnectionNetworkType();

  final int connectionTimeoutInSeconds = 5; // was 3 before in-app variant

  int connectivityCheckCounter = 0;
  int connectivityCheckCounterBackup = 0;
  bool actualConnectedStatus = true;
  bool isInitialized = false;

  DateTime? connectivityCheckUpdated;
  Connectivity? connectivity;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  StreamSubscription<NetworkStatus>? networkStatusSubscription;
  Timer? connectivityCheckTimer;
  Timer? connectivityCheckMasterTimer;
  Function? connectivityTimerControllerCallback;

  void init() async {
    if (isInitialized == false) {
      if (!Globals.isLinux()) {
        connectivity = Connectivity();
      }
      restartConnectivityCheck();

      isInitialized = true;
    }
  }

  ConnectionStatusBloc() : super(const ConnectionStatusStateInitial()) {
    // ====================== //
    // event to state handler //
    // ====================== //
    on<ConnectionStatusEvent>((event, emit) async {
      if (event is SetConnectionStatusStateLoadDefaults) {
        emit(ConnectionStatusStateLoaded(connected: actualConnectedStatus));

        if (actualConnectedStatus == true) {}
      }

      if (event is ConnectionStatusChanged) {
        bool connected = event.connected;
        actualConnectedStatus = connected;

        bool hasChanged = state.connected != connected;

        if (hasChanged == true) {
          if (kDebugMode) {
            debugPrint(
              'ConnectionStatusBloc/ConnectionStatusChanged -> hasChanged: $hasChanged, connected: $connected',
            );
          }
          emit(ConnectionStatusStateLoaded(connected: connected));
        }
      }
    });
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void loadDefaults() {
    add(SetConnectionStatusStateLoadDefaults());
  }

  void connectionStatusChanged({required bool connected}) {
    add(ConnectionStatusChanged(connected: connected));
  }

  // ============== //
  // public methods //
  // ============== //

  Future<List<ConnectivityResult>?> checkConnectivity() async {
    if (kDebugMode) {
      debugPrint(
        'ConnectionStatusBloc/checkConnectivity -> readConnectivityAndUpdateConnectionStatus',
      );
    }
    return await readConnectivityAndUpdateConnectionStatus();
  }

  Future<bool> checkInternetStatus() async {
    try {
      final HttpClient client = HttpClient()
        ..connectionTimeout = Duration(seconds: connectionTimeoutInSeconds);
      final HttpClientRequest request = await client.headUrl(
        Uri.parse('https://www.google.com'),
      );
      final HttpClientResponse response = await request.close();
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      log(e.toString(), name: 'ConnectionStatusBloc/checkInternetStatus/error');
      return false;
    }
  }

  Future<NetworkStatus> getNetworkStatus() async {
    late NetworkStatus networkStatus;

    try {
      networkStatus = await _connectionNetworkTypePlugin.currentNetworkStatus();
    } on PlatformException {
      networkStatus = NetworkStatus.unreachable;
    }

    return networkStatus;
  }

  // =============== //
  // private methods //
  // =============== //

  void restartConnectivityCheck() async {
    if (kDebugMode) {
      debugPrint(
        'ConnectionStatusBloc/restartConnectivityCheck @ ${DateTime.now().toLocal()}',
      );
    }

    if (!Globals.isLinux()) {
      await readConnectivityAndUpdateConnectionStatus();
      restartConnectivitySubscription();
    }

    restartConnectivityCheckTimer();
  }

  Timer initConnectivityMasterTimer({required Function callback}) {
    connectivityTimerControllerCallback = callback;
    connectivityCheckMasterTimer = Timer.periodic(
      const Duration(seconds: 60),
      (timer) => callback(),
    );

    return connectivityCheckMasterTimer!;
  }

  void restartConnectivityMasterTimer() {
    connectivityCheckMasterTimer?.cancel();
    initConnectivityMasterTimer(
      callback: connectivityTimerControllerCallback != null
          ? connectivityTimerControllerCallback!
          : connectivityMasterTimerCallback,
    );
  }

  void connectivityMasterTimerCallback() {
    if (connectivityCheckCounterBackup == connectivityCheckCounter) {
      if (kDebugMode) {
        debugPrint(
          'ConnectionStatusBloc/connectivityMasterTimerCallback is not running => restartConnectivityCheck',
        );
      }
      restartConnectivityCheck();
    }
    connectivityCheckCounterBackup = connectivityCheckCounter;
  }

  void restartConnectivityCheckTimer() {
    if (kDebugMode) {
      debugPrint('ConnectionStatusBloc/restartConnectivityCheckTimer');
    }
    connectivityCheckTimer?.cancel();
    connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => getConnectivityResultAndUpdateConnectionStatus(),
    );
  }

  Future<void> getConnectivityResultAndUpdateConnectionStatus() async {
    if (kDebugMode) {
      debugPrint(
        'ConnectionStatusBloc/getConnectivityResultAndUpdateConnectionStatus => running code @ ${DateTime.now().toLocal()}',
      );
    }
    if (Globals.isLinux()) {
      bool connected = await checkInternetStatus();
      connectionStatusChanged(connected: connected);
    } else {
      List<ConnectivityResult> result = await connectivity!.checkConnectivity();
      updateConnectionStatus(result, fromTimer: true);
    }

    connectivityCheckCounter++;
    connectivityCheckUpdated = DateTime.now();
  }

  Future<void> restartConnectivitySubscription() async {
    await connectivitySubscription?.cancel();
    connectivitySubscription = connectivity!.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        if (kDebugMode) {
          debugPrint(
            'ConnectionStatusBloc/restartConnectivitySubscription/onConnectivityChanged listener => change detected from onConnectivityChanged listener @ ${DateTime.now().toLocal()}',
          );
        }
        updateConnectionStatus(result);
      },
      onError: (Object e, StackTrace stack) {
        if (kDebugMode) {
          debugPrint(
            'ConnectionStatusBloc/restartConnectivitySubscription/onError => error: $e, stack: $stack',
          );
        }
      },
    );

    if (Globals.isMobileDevice()) {
      await networkStatusSubscription?.cancel();
      networkStatusSubscription = _connectionNetworkTypePlugin
          .onNetworkStateChanged
          .listen((NetworkStatus networkStatus) {
            if (kDebugMode) {
              debugPrint(
                'ConnectionStatusBloc/restartConnectivitySubscription/onNetworkStateChanged listener => change detected of ${networkStatus.name} from onNetworkStateChanged listener @ ${DateTime.now().toLocal()}',
              );
            }

            updateConnectionStatus([ConnectivityResult.mobile]);
          });
    }
  }

  Future<void> updateConnectionStatus(
    List<ConnectivityResult> result, {
    bool fromTimer = false,
  }) async {
    bool connected =
        result.contains(ConnectivityResult.ethernet) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.vpn);

    if (connected == true) {
      connected = false;

      if (Globals.isMobileDevice()) {
        NetworkStatus networkStatus = await getNetworkStatus();
        if (networkStatus == NetworkStatus.mobile2G) {
          if (kDebugMode) {
            debugPrint(
              'ConnectionStatusBloc/_updateConnectionStatus => network too slow: $networkStatus',
            );
          }
        } else {
          connected = await checkInternetStatus();
        }
      } else {
        connected = await checkInternetStatus();
      }
    }

    connectionStatusChanged(connected: connected);
  }

  Future<void> waitForConnection() async {
    await Future.delayed(Duration(seconds: 1));
    if (kDebugMode) {
      debugPrint(
        'ConnectionStatusBloc/waitForConnection, time: ${DateTime.now().toLocal()}',
      );
    }

    if (state.connected == false) {
      await waitForConnection();
    }
  }

  Future<List<ConnectivityResult>>
  readConnectivityAndUpdateConnectionStatus() async {
    List<ConnectivityResult> result = [];
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await connectivity!.checkConnectivity();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'ConnectionStatusBloc/readConnectivityAndUpdateConnectionStatus/catch, error: $e',
        );
      }

      return result;
    }

    updateConnectionStatus(result);
    return result;
  }

  // ============= //
  // close streams //
  // ============= //

  @override
  Future<void> close() async {
    connectivitySubscription?.cancel();
    networkStatusSubscription?.cancel();
    connectivityCheckTimer?.cancel();
    super.close();
  }
}
