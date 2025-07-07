import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  int _gamesPlayed = 0;
  int _gamesWon = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadStats();
    _loadAppInfo();
  }

  Future<void> _loadSettings() async {
    final sound = await StorageService.isSoundEnabled();
    final vibration = await StorageService.isVibrationEnabled();
    
    if (mounted) {
      setState(() {
        _soundEnabled = sound;
        _vibrationEnabled = vibration;
      });
    }
  }

  Future<void> _loadStats() async {
    final played = await StorageService.getGamesPlayed();
    final won = await StorageService.getGamesWon();
    
    if (mounted) {
      setState(() {
        _gamesPlayed = played;
        _gamesWon = won;
      });
    }
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = packageInfo.version;
      });
    }
  }

  Future<void> _toggleSound(bool value) async {
    await StorageService.setSoundEnabled(value);
    setState(() {
      _soundEnabled = value;
    });
  }

  Future<void> _toggleVibration(bool value) async {
    await StorageService.setVibrationEnabled(value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  Future<void> _clearUsername() async {
    await StorageService.clearUsername();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cleared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  double get _winRate {
    if (_gamesPlayed == 0) return 0.0;
    return (_gamesWon / _gamesPlayed) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Game Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game Settings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Sound Effects'),
                      subtitle: const Text('Enable game sound effects'),
                      value: _soundEnabled,
                      onChanged: _toggleSound,
                      secondary: const Icon(Icons.volume_up),
                    ),
                    
                    SwitchListTile(
                      title: const Text('Vibration'),
                      subtitle: const Text('Enable haptic feedback'),
                      value: _vibrationEnabled,
                      onChanged: _toggleVibration,
                      secondary: const Icon(Icons.vibration),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Games Played',
                            value: _gamesPlayed.toString(),
                            icon: Icons.games,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Games Won',
                            value: _gamesWon.toString(),
                            icon: Icons.emoji_events,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _StatCard(
                      title: 'Win Rate',
                      value: '${_winRate.toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Account
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.person_remove),
                      title: const Text('Clear Username'),
                      subtitle: const Text('Remove saved username'),
                      onTap: _clearUsername,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // About
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Version'),
                      subtitle: Text(_appVersion),
                    ),
                    
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('Tic Tac Toe Multiplayer'),
                      subtitle: const Text('Real-time multiplayer game'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}