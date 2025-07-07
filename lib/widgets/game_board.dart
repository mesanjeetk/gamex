import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GameBoard extends StatelessWidget {
  final List<String?> board;
  final Function(int) onMove;
  final bool disabled;
  final List<int>? winPattern;

  const GameBoard({
    super.key,
    required this.board,
    required this.onMove,
    required this.disabled,
    this.winPattern,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 9,
          itemBuilder: (context, index) {
            final isWinningCell = winPattern?.contains(index) ?? false;
            final cellValue = board[index];
            final isEmpty = cellValue == null;
            
            return GestureDetector(
              onTap: isEmpty && !disabled ? () => onMove(index) : null,
              child: Container(
                decoration: BoxDecoration(
                  color: isWinningCell 
                      ? Colors.green.withOpacity(0.3)
                      : Colors.white.withOpacity(isEmpty ? 0.1 : 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWinningCell 
                        ? Colors.green
                        : Colors.white.withOpacity(0.3),
                    width: isWinningCell ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: cellValue != null
                      ? _buildSymbol(cellValue, isWinningCell)
                      : null,
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
          },
        ),
      ),
    );
  }

  Widget _buildSymbol(String symbol, bool isWinning) {
    final color = symbol == 'X' 
        ? const Color(0xFF3B82F6) // Blue
        : const Color(0xFFEF4444); // Red
    
    Widget symbolWidget;
    
    if (symbol == 'X') {
      symbolWidget = CustomPaint(
        size: const Size(40, 40),
        painter: XPainter(color: color),
      );
    } else {
      symbolWidget = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 4,
          ),
        ),
      );
    }
    
    return symbolWidget
        .animate()
        .scale(
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .shimmer(
          duration: isWinning ? 1000.ms : 0.ms,
          color: Colors.white.withOpacity(0.5),
        );
  }
}

class XPainter extends CustomPainter {
  final Color color;

  XPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double padding = size.width * 0.2;
    
    // Draw X
    canvas.drawLine(
      Offset(padding, padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(padding, size.height - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}