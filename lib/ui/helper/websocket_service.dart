import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String ip;
  final int port;
  final Function(String message) onInfoMessage;
  final VoidCallback onPing;
  final Function(String message) onNotification;
  final Function(bool connected) onConnect;

  WebSocketService({
    required this.ip,
    required this.port,
    required this.onInfoMessage,
    required this.onPing,
    required this.onNotification,
    required this.onConnect,
  });

  final int pingSecondsPeriodic = 15;
  final int pingSecondTimeout = 5;

  String get url => 'ws://$ip:$port/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  Future<void> connect() async {
    String url = 'ws://$ip:$port/ws';
    if (kDebugMode) {
      debugPrint(
        "ws123 WebSocketService @ ${DateTime.now().toLocal()} => connect to $url",
      );
    }
    final Uri wsUrl = Uri.parse(url);
    _channel = WebSocketChannel.connect(wsUrl);
    try {
      await _channel!.ready;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint(
          "ws123 WebSocketService @ ${DateTime.now().toLocal()} => SocketException => connect error $e, url: $url",
        );
      }

      onConnect(false);
      return;
    } on WebSocketChannelException catch (e) {
      if (kDebugMode) {
        debugPrint(
          "ws123 WebSocketService @ ${DateTime.now().toLocal()} => WebSocketChannelException => connect error $e, url: $url",
        );
      }

      onConnect(false);
      return;
    }
    onConnect(true);

    DateTime lastPing = DateTime.now();

    Timer timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      DateTime afterPing = lastPing.add(
        Duration(seconds: pingSecondsPeriodic + pingSecondTimeout),
      );
      bool timeout = DateTime.now().isAfter(afterPing);

      if (kDebugMode) {
        debugPrint(
          "WebSocketService @ ${DateTime.now().toLocal()} => timeout check: $timeout",
        );
      }
      if (timeout) {
        timer.cancel();
        if (kDebugMode) {
          debugPrint(
            "WebSocketService @ ${DateTime.now().toLocal()} => => => timeout from $url",
          );
        }
        onConnect(false);
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
                "WebSocketService @ ${DateTime.now().toLocal()} => received data from $url",
              );
            }
            onInfoMessage.call(message);
          } else {
            if (kDebugMode) {
              debugPrint('WebSocketService received notification: $message');
            }
            if (message == 'roon-activation-alert') {
              onNotification.call(message);
            }
            onPing();
            if (kDebugMode) {
              debugPrint(
                "WebSocketService @ ${DateTime.now().toLocal()} => received message from $url: $message",
              );
            }
          }
        }
      },
      onDone: () {
        timer.cancel();
        if (kDebugMode) {
          debugPrint(
            "ws123 WebSocketService @ ${DateTime.now().toLocal()} => disconnected from $url. try again to connect...",
          );
        }
        onConnect(false);
      },
      onError: (error) {
        timer.cancel();
        if (kDebugMode) {
          debugPrint(
            "WebSocketService @ ${DateTime.now().toLocal()} => error for $url: ${error.toString()}",
          );
        }
        onConnect(false);
      },
      cancelOnError: true,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}
