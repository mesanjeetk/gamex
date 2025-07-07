import 'dart:async';
import 'dart:io';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/room.dart';
import '../models/player.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  
  // Event streams
  final StreamController<Room> _roomController = StreamController<Room>.broadcast();
  final StreamController<Room> _gameStartController = StreamController<Room>.broadcast();
  final StreamController<Map<String, dynamic>> _moveController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gameOverController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _gameResetController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<void> _opponentDisconnectedController = StreamController<void>.broadcast();

  // Getters for streams
  Stream<Room> get roomStream => _roomController.stream;
  Stream<Room> get gameStartStream => _gameStartController.stream;
  Stream<Map<String, dynamic>> get moveStream => _moveController.stream;
  Stream<Map<String, dynamic>> get gameOverStream => _gameOverController.stream;
  Stream<Map<String, dynamic>> get gameResetStream => _gameResetController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<void> get opponentDisconnectedStream => _opponentDisconnectedController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _isConnected) return;

    try {
      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No internet connection');
      }

      _socket = IO.io(
        'http://localhost:3001',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setTimeout(10000)
            .build(),
      );

      _setupEventListeners();
      
      // Wait for connection with timeout
      await _waitForConnection();
      
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _cancelReconnectTimer();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionController.add(false);
      _scheduleReconnect();
    });

    _socket!.onConnectError((error) {
      _handleConnectionError(error);
    });

    _socket!.onError((error) {
      _errorController.add('Socket error: $error');
    });

    // Game event listeners
    _socket!.on('waiting-for-opponent', (data) {
      final room = Room.fromJson(data['room']);
      _roomController.add(room);
    });

    _socket!.on('room-created', (data) {
      final room = Room.fromJson(data['room']);
      _roomController.add(room);
    });

    _socket!.on('game-start', (data) {
      final room = Room.fromJson(data['room']);
      _gameStartController.add(room);
    });

    _socket!.on('move-made', (data) {
      _moveController.add(data);
    });

    _socket!.on('game-over', (data) {
      _gameOverController.add(data);
    });

    _socket!.on('game-reset', (data) {
      _gameResetController.add(data);
    });

    _socket!.on('join-room-error', (data) {
      _errorController.add(data['error'] ?? 'Failed to join room');
    });

    _socket!.on('opponent-disconnected', (_) {
      _opponentDisconnectedController.add(null);
    });
  }

  Future<void> _waitForConnection() async {
    final completer = Completer<void>();
    Timer? timeoutTimer;

    void onConnect(_) {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.complete();
      }
    }

    void onError(error) {
      if (!completer.isCompleted) {
        timeoutTimer?.cancel();
        completer.completeError(error);
      }
    }

    _socket!.onConnect(onConnect);
    _socket!.onConnectError(onError);

    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        completer.completeError('Connection timeout');
      }
    });

    return completer.future;
  }

  void _handleConnectionError(dynamic error) {
    _isConnected = false;
    _connectionController.add(false);
    _errorController.add('Connection failed: $error');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      _errorController.add('Max reconnection attempts reached');
      return;
    }

    _cancelReconnectTimer();
    _reconnectTimer = Timer(
      Duration(seconds: 2 * (_reconnectAttempts + 1)),
      () {
        _reconnectAttempts++;
        connect();
      },
    );
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Game actions
  void joinPublicGame(String playerName) {
    if (!_isConnected) return;
    _socket!.emit('join-public-game', {'playerName': playerName});
  }

  void createPrivateRoom(String roomName, String playerName) {
    if (!_isConnected) return;
    _socket!.emit('create-private-room', {
      'roomName': roomName,
      'playerName': playerName,
    });
  }

  void joinPrivateRoom(String roomId, String playerName) {
    if (!_isConnected) return;
    _socket!.emit('join-private-room', {
      'roomId': roomId.toUpperCase(),
      'playerName': playerName,
    });
  }

  void makeMove(String roomId, int position) {
    if (!_isConnected) return;
    _socket!.emit('make-move', {
      'roomId': roomId,
      'position': position,
    });
  }

  void playAgain(String roomId) {
    if (!_isConnected) return;
    _socket!.emit('play-again', {'roomId': roomId});
  }

  void disconnect() {
    _cancelReconnectTimer();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    _roomController.close();
    _gameStartController.close();
    _moveController.close();
    _gameOverController.close();
    _gameResetController.close();
    _errorController.close();
    _connectionController.close();
    _opponentDisconnectedController.close();
  }
}