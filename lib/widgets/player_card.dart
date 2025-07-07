import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/player.dart';

class PlayerCard extends StatelessWidget {
  final Player? player;
  final bool isCurrentPlayer;
  final String label;
  final bool isMe;

  const PlayerCard({
    super.key,
    required this.player,
    required this.isCurrentPlayer,
    required this.label,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return _buildEmptyCard(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isCurrentPlayer ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlayer 
              ? Colors.white.withOpacity(0.6)
              : Colors.white.withOpacity(0.2),
          width: isCurrentPlayer ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isMe 
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF8B5CF6),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              isCurrentPlayer ? Icons.person : Icons.person_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Name
          Text(
            player!.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Label
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Symbol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: player!.symbol == 'X' 
                  ? const Color(0xFF3B82F6).withOpacity(0.2)
                  : const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: player!.symbol == 'X' 
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFEF4444),
              ),
            ),
            child: Text(
              player!.symbol,
              style: TextStyle(
                color: player!.symbol == 'X' 
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFFEF4444),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          if (isCurrentPlayer) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Turn',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0))
        .then()
        .shimmer(
          duration: isCurrentPlayer ? 2000.ms : 0.ms,
          color: Colors.white.withOpacity(0.1),
        );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Colors.grey,
              size: 24,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Waiting...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 12,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }
}