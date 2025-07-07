import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/socket_service.dart';
import '../services/storage_service.dart';
import '../widgets/connection_status.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  final _roomNameController = TextEditingController();
  final _roomIdController = TextEditingController();
  
  String? _savedUsername;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedUsername();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomNameController.dispose();
    _roomIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedUsername() async {
    final username = await StorageService.getUsername();
    if (mounted) {
      setState(() {
        _savedUsername = username;
        if (username != null) {
          _nameController.text = username;
        }
      });
    }
  }

  void _setupSocketListeners() {
    SocketService().errorStream.listen((error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isLoading = false;
        });
        _showErrorSnackBar(error);
      }
    });
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

  Future<void> _saveUsername(String username) async {
    await StorageService.setUsername(username);
    setState(() {
      _savedUsername = username;
    });
  }

  void _joinPublicGame() async {
    final username = _nameController.text.trim();
    if (username.isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _saveUsername(username);
    SocketService().joinPublicGame(username);
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameScreen(playerName: username),
        ),
      );
    }
  }

  void _createPrivateRoom() async {
    final username = _nameController.text.trim();
    final roomName = _roomNameController.text.trim();
    
    if (username.isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return;
    }
    
    if (roomName.isEmpty) {
      _showErrorSnackBar('Please enter room name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _saveUsername(username);
    SocketService().createPrivateRoom(roomName, username);
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameScreen(playerName: username),
        ),
      );
    }
  }

  void _joinPrivateRoom() async {
    final username = _nameController.text.trim();
    final roomId = _roomIdController.text.trim().toUpperCase();
    
    if (username.isEmpty) {
      _showErrorSnackBar('Please enter your name');
      return;
    }
    
    if (roomId.isEmpty) {
      _showErrorSnackBar('Please enter room ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _saveUsername(username);
    SocketService().joinPrivateRoom(roomId, username);
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GameScreen(playerName: username),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ConnectionStatus(),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Logo and title
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.grid_3x3,
                          size: 50,
                          color: Colors.white,
                        ),
                      )
                          .animate()
                          .scale(duration: 600.ms, curve: Curves.elasticOut),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        'Tic Tac Toe',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Multiplayer Game',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 48),
                      
                      // Name input
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enter Your Name',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Your name',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                textCapitalization: TextCapitalization.words,
                                enabled: !_isLoading,
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Game mode buttons
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Game Mode',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Quick Play
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _joinPublicGame,
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Quick Play'),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Create Room
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading ? null : () => _showCreateRoomDialog(),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Private Room'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Join Room
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isLoading ? null : () => _showJoinRoomDialog(),
                                  icon: const Icon(Icons.login),
                                  label: const Text('Join Room by ID'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                    side: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 800.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                      
                      if (_isLoading) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Private Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomNameController,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                hintText: 'Enter room name',
                prefixIcon: Icon(Icons.meeting_room),
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createPrivateRoom();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Private Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomIdController,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID',
                prefixIcon: Icon(Icons.key),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _joinPrivateRoom();
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}