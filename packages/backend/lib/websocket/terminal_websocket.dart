import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../services/terminal_service_impl.dart';

/// WebSocket handler for real-time terminal output streaming
class TerminalWebSocket {
  final TerminalServiceImpl _terminal;
  final Set<WebSocketChannel> _clients = {};
  StreamSubscription<String>? _outputSubscription;

  TerminalWebSocket(this._terminal) {
    // Listen to terminal output and broadcast to all clients
    _outputSubscription = _terminal.outputStream.listen(_broadcast);
  }

  /// Get the WebSocket handler
  Handler get handler => webSocketHandler(_handleConnection);

  void _handleConnection(WebSocketChannel socket) {
    _clients.add(socket);

    // Handle incoming messages from client
    socket.stream.listen(
      (message) {
        _handleMessage(socket, message as String);
      },
      onDone: () {
        _clients.remove(socket);
      },
      onError: (error) {
        _clients.remove(socket);
      },
    );
  }

  void _handleMessage(WebSocketChannel socket, String message) {
    // Handle commands from client
    // For now, just forward to terminal stdin if needed
    switch (message) {
      case 'hot-reload':
        _terminal.hotReload();
        break;
      case 'hot-restart':
        _terminal.hotRestart();
        break;
      case 'stop':
        _terminal.stop();
        break;
    }
  }

  void _broadcast(String data) {
    final deadClients = <WebSocketChannel>[];

    for (final client in _clients) {
      try {
        client.sink.add(data);
      } catch (e) {
        deadClients.add(client);
      }
    }

    // Remove disconnected clients
    for (final client in deadClients) {
      _clients.remove(client);
    }
  }

  void dispose() {
    _outputSubscription?.cancel();
    for (final client in _clients) {
      client.sink.close();
    }
    _clients.clear();
  }
}
