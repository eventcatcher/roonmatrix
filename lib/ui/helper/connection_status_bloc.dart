import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roonmatrix/ui/helper/connection_status_event.dart';
import 'package:roonmatrix/ui/helper/connection_status_state.dart';
import 'package:roonmatrix/ui/layout/shared_widgets.dart';

class ConnectionStatusBloc
    extends Bloc<ConnectionStatusEvent, ConnectionStatusState> {
  final Connectivity connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  StreamSubscription<NetworkStatus>? networkStatusSubscription;
  bool actualConnectedStatus = true;
  bool isInitialized = false;
  Timer? connectivityCheckTimer;
  Timer? connectivityCheckMasterTimer;
  Function? connectivityTimerControllerCallback;
  int connectivityCheckCounter = 0;
  int connectivityCheckCounterBackup = 0;
  DateTime? connectivityCheckUpdated;
  final ConnectionNetworkType _connectionNetworkTypePlugin =
      ConnectionNetworkType();

  void init() async {
    if (isInitialized == false) {
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
        emit(
          ConnectionStatusStateLoaded(
            connected: actualConnectedStatus,
          ),
        );

        if (actualConnectedStatus == true) {}
      }

      if (event is ConnectionStatusChanged) {
        bool connected = event.connected;
        actualConnectedStatus = connected;

        bool hasChanged = state.connected != connected;

        if (hasChanged == true) {
          debugPrint(
            'ConnectionStatusBloc/ConnectionStatusChanged -> hasChanged: $hasChanged, connected: $connected',
          );
          emit(
            ConnectionStatusStateLoaded(
              connected: connected,
            ),
          );
        }
      }
    });
  }

  // ==================== //
  // public event methods //
  // ==================== //

  void loadDefaults() {
    add(
      SetConnectionStatusStateLoadDefaults(),
    );
  }

  void connectionStatusChanged({required bool connected}) {
    add(ConnectionStatusChanged(connected: connected));
  }

  // ============== //
  // public methods //
  // ============== //

  Future<List<ConnectivityResult>?> checkConnectivity() async {
    debugPrint(
      'ConnectionStatusBloc/checkConnectivity -> _readConnectivityAndUpdateConnectionStatus',
    );
    return await _readConnectivityAndUpdateConnectionStatus();
  }

  Future<bool> checkInternetStatus() async {
    bool connected = false;
    List<InternetAddress> result = [];
    try {
      result = await InternetAddress.lookup('roonmatrix.com');
    } on SocketException catch (e) {
      log(
        e.toString(),
        name: 'ConnectionStatusBloc/checkInternetStatus/lookup/error',
      );
    }

    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      connected = true;
    }

    return connected;
  }

  void restartConnectivityCheck() async {
    debugPrint(
      'ConnectionStatusBloc/restartConnectivityCheck @ ${DateTime.now().toLocal()}',
    );

    await _readConnectivityAndUpdateConnectionStatus();
    _restartConnectivitySubscription();
    _restartConnectivityCheckTimer();
  }

  // =============== //
  // private methods //
  // =============== //

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

  connectivityMasterTimerCallback() {
    if (connectivityCheckCounterBackup == connectivityCheckCounter) {
      debugPrint(
        'connectivityCheckTimer is not running => restartConnectivityCheck',
      );
      restartConnectivityCheck();
    }
    connectivityCheckCounterBackup = connectivityCheckCounter;
  }

  void _restartConnectivityCheckTimer() {
    debugPrint(
      'ConnectionStatusBloc/restartConnectivityCheckTimer',
    );
    connectivityCheckTimer?.cancel();
    connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => getConnectivityResultAndUpdateConnectionStatus(),
    );
  }

  getConnectivityResultAndUpdateConnectionStatus() async {
    debugPrint(
      'ConnectionStatusBloc/getConnectivityResultAndUpdateConnectionStatus => running code @ ${DateTime.now().toLocal()}',
    );
    List<ConnectivityResult> result = await connectivity.checkConnectivity();
    _updateConnectionStatus(result, fromTimer: true);
    connectivityCheckCounter++;
    connectivityCheckUpdated = DateTime.now();
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

  void _restartConnectivitySubscription() async {
    await connectivitySubscription?.cancel();
    connectivitySubscription = connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        debugPrint(
          'ConnectionStatusBloc/_restartConnectivitySubscription/onConnectivityChanged listener => change detected from onConnectivityChanged listener @ ${DateTime.now().toLocal()}',
        );
        _updateConnectionStatus(result);
      },
      onError: (Object e, StackTrace stack) {
        debugPrint(
          'ConnectionStatusBloc/_restartConnectivitySubscription/onError => error: $e, stack: $stack',
        );
      },
    );

    if (SharedWidgets.isMobileDevice()) {
      await networkStatusSubscription?.cancel();
      networkStatusSubscription = _connectionNetworkTypePlugin
          .onNetworkStateChanged
          .listen((NetworkStatus networkStatus) {
        debugPrint(
          'ConnectionStatusBloc/_restartConnectivitySubscription/onNetworkStateChanged listener => change detected of ${networkStatus.name} from onNetworkStateChanged listener @ ${DateTime.now().toLocal()}',
        );

        _updateConnectionStatus([ConnectivityResult.mobile]);
      });
    }
  }

  void _updateConnectionStatus(
    List<ConnectivityResult> result, {
    bool fromTimer = false,
  }) async {
    bool connected = result.contains(ConnectivityResult.ethernet) ||
        result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.vpn);

    if (connected == true) {
      connected = false;

      if (SharedWidgets.isMobileDevice()) {
        NetworkStatus networkStatus = await getNetworkStatus();
        if (networkStatus == NetworkStatus.mobile2G) {
          debugPrint(
            'ConnectionStatusBloc/_updateConnectionStatus => network too slow: $networkStatus',
          );
        } else {
          connected = await checkInternetStatus();
        }
      } else {
        connected = await checkInternetStatus();
      }
    }

    connectionStatusChanged(connected: connected);
  }

  waitForConnection() async {
    await Future.delayed(Duration(seconds: 1));
    debugPrint(
      'ConnectionStatusBloc/waitForConnection, time: ${DateTime.now().toLocal()}',
    );

    if (state.connected == false) {
      await waitForConnection();
    }
  }

  Future<List<ConnectivityResult>>
      _readConnectivityAndUpdateConnectionStatus() async {
    List<ConnectivityResult> result = [];
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      debugPrint(
        'ConnectionStatusBloc/_readConnectivityAndUpdateConnectionStatus/catch, error: $e',
      );

      return result;
    }

    _updateConnectionStatus(result);
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
