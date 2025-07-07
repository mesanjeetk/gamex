import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import '../models/room.dart';
import '../models/player.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../widgets/game_board.dart';
import '../widgets/player_card.dart';
import '../widgets/connection_status.dart';

class GameScreen extends StatefulWidget {
  final String playerName;

  const GameScreen({
    super.key,
    required this.playerName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  Room? _room;
  String? _currentPlayer;
  String? _winner;
  List<int>? _winPattern;
  bool _isWaiting = true;
  bool _gameStarted = false;
  bool _gameOver = false;
  String? _error;
  
  late AnimationController _pulseController;
  late AnimationController _celebrationController;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  void _setupSocketListeners() {
    // Room updates (waiting state)
    SocketService().roomStream.listen((room) {
      if (mounted) {
        setState(() {
          _room = room;
          _isWaiting = true;
          _gameStarted = false;
        });
      }
    });

    // Game start
    SocketService().gameStartStream.listen((room) {
      if (mounted) {
        setState(() {
          _room = room;
          _currentPlayer = room.currentPlayer;
          _isWaiting = false;
          _gameStarted = true;
          _gameOver = false;
        });
        _playHapticFeedback();
      }
    });

    // Move made
    SocketService().moveStream.listen((data) {
      if (mounted) {
        setState(() {
          _room = _room?.copyWith(
            board: (data['board'] as List<dynamic>)
                .map((e) => e as String?)
                .toList(),
          );
          _currentPlayer = data['currentPlayer'];
        });
        _playHapticFeedback();
      }
    });

    // Game over
    SocketService().gameOverStream.listen((data) {
      if (mounted) {
        setState(() {
          _room = _room?.copyWith(
            board: (data['board'] as List<dynamic>)
                .map((e) => e as String?)
                .toList(),
          );
          _winner = data['winner'];
          _winPattern = (data['winPattern'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList();
          _gameOver = true;
        });
        _celebrationController.forward();
        _playGameOverFeedback();
        _updateStats();
      }
    });

    // Game reset
    SocketService().gameResetStream.listen((data) {
      if (mounted) {
        setState(() {
          _room = _room?.copyWith(
            board: (data['board'] as List<dynamic>)
                .map((e) => e as String?)
                .toList(),
          );
          _currentPlayer = data['currentPlayer'];
          _winner = null;
          _winPattern = null;
          _gameOver = false;
        });
        _celebrationController.reset();
      }
    });

    // Opponent disconnected
    SocketService().opponentDisconnectedStream.listen((_) {
      if (mounted) {
        _showDisconnectionDialog();
      }
    });

    // Errors
    SocketService().errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _error = error;
        });
        _showErrorSnackBar(error);
      }
    });
  }

  Future<void> _playHapticFeedback() async {
    final vibrationEnabled = await StorageService.isVibrationEnabled();
    if (vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _playGameOverFeedback() async {
    final vibrationEnabled = await StorageService.isVibrationEnabled();
    if (vibrationEnabled) {
      if (_isWinner()) {
        HapticFeedback.heavyImpact();
        // Victory vibration pattern
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 200]);
        }
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }

  Future<void> _updateStats() async {
    await StorageService.incrementGamesPlayed();
    if (_isWinner()) {
      await StorageService.incrementGamesWon();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDisconnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Opponent Disconnected'),
        content: const Text('Your opponent has left the game.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Player? _getMyPlayer() {
    if (_room == null) return null;
    return _room!.players.firstWhere(
      (player) => player.name == widget.playerName,
      orElse: () => _room!.players.first,
    );
  }

  Player? _getOpponent() {
    if (_room == null || _room!.players.length < 2) return null;
    return _room!.players.firstWhere(
      (player) => player.name != widget.playerName,
    );
  }

  bool _isMyTurn() {
    final myPlayer = _getMyPlayer();
    return myPlayer != null && _currentPlayer == myPlayer.id;
  }

  bool _isWinner() {
    if (_winner == null || _winner == 'draw') return false;
    final myPlayer = _getMyPlayer();
    return myPlayer != null && _winner == myPlayer.symbol;
  }

  String _getGameStatusText() {
    if (_isWaiting) {
      if (_room?.isPrivate == true) {
        return 'Waiting for opponent to join...';
      }
      return 'Finding opponent...';
    }
    
    if (_gameOver) {
      if (_winner == 'draw') return "It's a draw!";
      return _isWinner() ? 'You won!' : 'You lost!';
    }
    
    return _isMyTurn() ? 'Your turn' : "Opponent's turn";
  }

  void _makeMove(int position) {
    if (_room != null && _isMyTurn() && !_gameOver) {
      SocketService().makeMove(_room!.id, position);
    }
  }

  void _playAgain() {
    if (_room != null) {
      SocketService().playAgain(_room!.id);
    }
  }

  void _copyRoomId() {
    if (_room != null) {
      Clipboard.setData(ClipboardData(text: _room!.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room ID copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFFA855F7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(child: ConnectionStatus()),
                    if (_room?.isPrivate == true)
                      IconButton(
                        onPressed: _copyRoomId,
                        icon: const Icon(
                          Icons.copy,
                          color: Colors.white,
                        ),
                        tooltip: 'Copy Room ID',
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Game title and status
                      Text(
                        _room?.isPrivate == true 
                            ? 'Private Room: ${_room!.name}'
                            : 'Quick Play',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (_room?.isPrivate == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Room ID: ${_room!.id}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Game status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getGameStatusText(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                          .animate(controller: _isMyTurn() && !_gameOver ? _pulseController : null)
                          .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05)),
                      
                      const SizedBox(height: 32),
                      
                      // Players
                      if (_room != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PlayerCard(
                                player: _getMyPlayer(),
                                isCurrentPlayer: _isMyTurn() && _gameStarted && !_gameOver,
                                label: 'You',
                                isMe: true,
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            Expanded(
                              child: PlayerCard(
                                player: _getOpponent(),
                                isCurrentPlayer: !_isMyTurn() && _gameStarted && !_gameOver,
                                label: 'Opponent',
                                isMe: false,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                      
                      // Game board
                      if (_room != null && _gameStarted)
                        GameBoard(
                          board: _room!.board,
                          onMove: _makeMove,
                          disabled: !_isMyTurn() || _gameOver,
                          winPattern: _winPattern,
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0)),
                      
                      // Waiting indicator
                      if (_isWaiting) ...[
                        const SizedBox(height: 32),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms),
                        const SizedBox(height: 16),
                        Text(
                          _room?.isPrivate == true
                              ? 'Share the room ID with your friend'
                              : 'Looking for an opponent...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate()
                            .fadeIn(delay: 300.ms, duration: 600.ms),
                      ],
                      
                      // Game over actions
                      if (_gameOver) ...[
                        const SizedBox(height: 32),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  _isWinner() 
                                      ? Icons.emoji_events
                                      : _winner == 'draw'
                                          ? Icons.handshake
                                          : Icons.sentiment_neutral,
                                  size: 48,
                                  color: _isWinner() 
                                      ? Colors.amber
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _getGameStatusText(),
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Back to Home'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _playAgain,
                                        child: const Text('Play Again'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(controller: _celebrationController)
                            .fadeIn(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0),
                              curve: Curves.elasticOut,
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}