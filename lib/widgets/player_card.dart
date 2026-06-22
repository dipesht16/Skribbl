import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String playerName;
  final int score;
  final bool isDrawing;
  final bool isYou;
  final int rank;

  const PlayerCard({
    super.key,
    required this.playerName,
    required this.score,
    required this.isDrawing,
    required this.isYou,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isDrawing ? const Color(0xFF7ED321) : const Color(0xFFDDE1E3),
          width: isDrawing ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getPlayerColor(rank),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: isDrawing
                  ? const Icon(Icons.brush, color: Colors.white, size: 20)
                  : Text(
                      playerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isYou ? '$playerName (You)' : playerName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isYou ? const Color(0xFF4A90E2) : const Color(0xFF2C3E50),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(
            '#$rank • $score',
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlayerColor(int rank) {
    const colors = [
      Color(0xFFE74C3C),
      Color(0xFF3498DB),
      Color(0xFF2ECC71),
      Color(0xFFF39C12),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
      Color(0xFFE67E22),
      Color(0xFF34495E),
    ];
    return colors[(rank - 1) % colors.length];
  }
}
