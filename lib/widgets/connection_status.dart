import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/socket_service.dart';

class ConnectionStatus extends StatefulWidget {
  const ConnectionStatus({super.key});

  @override
  State<ConnectionStatus> createState() => _ConnectionStatusState();
}

class _ConnectionStatusState extends State<ConnectionStatus> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _isConnected = SocketService().isConnected;
    
    SocketService().connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        )
            .animate()
            .fadeIn(duration: 300.ms)
            .then()
            .shimmer(
              duration: 2000.ms,
              color: _isConnected ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
            ),
        
        const SizedBox(width: 8),
        
        Text(
          _isConnected ? 'Connected' : 'Disconnected',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}