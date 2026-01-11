import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
//import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  final String url;
  final int pingSecondsPeriodic = 15;
  final int pingSecondTimeout = 5;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Duration reconnectDelay = Duration(seconds: 3);
  Function(String message) onMessage;
  VoidCallback onPing;
  Function(bool connected) onConnect;

  WebSocketService(
    this.url, {
    required this.onMessage,
    required this.onPing,
    required this.onConnect,
  });

  void connect() async {
    if (kDebugMode) {
      debugPrint(
          "WebSocketService @ ${DateTime.now().toLocal()} => connect to $url");
    }
    final Uri wsUrl = Uri.parse(url);
    _channel = WebSocketChannel.connect(wsUrl);
    try {
      await _channel!.ready;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint(
            "WebSocketService @ ${DateTime.now().toLocal()} => connect error $e, url: $url");
      }
      return;
    } on WebSocketChannelException catch (e) {
      if (kDebugMode) {
        debugPrint(
            "WebSocketService @ ${DateTime.now().toLocal()} => connect error $e, url: $url");
      }
      return;
    }
    onConnect(true);

    DateTime lastPing = DateTime.now();

    Timer timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      DateTime afterPing = lastPing
          .add(Duration(seconds: pingSecondsPeriodic + pingSecondTimeout));
      bool timeout = DateTime.now().isAfter(afterPing);

      if (kDebugMode) {
        debugPrint(
            "WebSocketService @ ${DateTime.now().toLocal()} => timeout check: $timeout");
      }
      if (timeout) {
        onConnect(false);
        if (kDebugMode) {
          debugPrint(
              "WebSocketService @ ${DateTime.now().toLocal()} => => => timeout from $url");
        }
        timer.cancel();
        _reconnect();
      }
    });

    _subscription = _channel!.stream.listen(
      (dynamic message) {
        _channel!.sink.add('received');
        //_channel!.sink.close(status.goingAway, 'closed');
        lastPing = DateTime.now();

        if (message is String) {
          if (message.isNotEmpty &&
              message.startsWith('{') &&
              message.endsWith('}')) {
            if (kDebugMode) {
              debugPrint(
                  "WebSocketService @ ${DateTime.now().toLocal()} => received data from $url");
            }
            onMessage.call(message);
          } else {
            onPing();
            if (kDebugMode) {
              debugPrint(
                  "WebSocketService @ ${DateTime.now().toLocal()} => received message from $url: $message");
            }
          }
        }
      },
      onDone: () {
        onConnect(false);
        if (kDebugMode) {
          debugPrint(
              "WebSocketService @ ${DateTime.now().toLocal()} => disconnected from $url. try again to connect...");
        }
        timer.cancel();
        _reconnect();
      },
      onError: (error) {
        onConnect(false);
        if (kDebugMode) {
          debugPrint(
              "WebSocketService @ ${DateTime.now().toLocal()} => error for $url: ${error.toString()}");
        }
        timer.cancel();
        _reconnect();
      },
      cancelOnError: true,
    );
  }

  void _reconnect() {
    _subscription?.cancel();
    _channel = null;
    Future.delayed(reconnectDelay, connect);
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
  }
}
