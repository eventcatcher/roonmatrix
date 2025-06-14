import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String url;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Duration reconnectDelay = Duration(seconds: 3);
  Function(String)? onMessage;

  WebSocketService(this.url, {this.onMessage});

  void connect() {
    debugPrint("zzzz WebSocketService => connect to $url");
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _subscription = _channel!.stream.listen(
      (jsonStr) {
        //debugPrint("zzzz WebSocketService => received data from $url");
        onMessage?.call(jsonStr);
      },
      onDone: () {
        debugPrint(
            "zzzz WebSocketService => disconnected from $url. try again to connect...");
        _reconnect();
      },
      onError: (error) {
        debugPrint("zzzz WebSocketService => error for $url: $error");
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
