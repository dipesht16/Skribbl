import 'package:flutter/material.dart';
import '../models/avatar.dart';
import 'avatar_renderer.dart';

class PlayersPanel extends StatelessWidget {
  final Map<String, dynamic> players;
  final String currentPlayerId;

  const PlayersPanel({
    super.key,
    required this.players,
    required this.currentPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    final entries = players.entries.toList()
      ..sort((a, b) => (b.value['score'] as int? ?? 0)
          .compareTo(a.value['score'] as int? ?? 0));

    return Container(
      color: const Color(0xFF2C3E50),
      padding: const EdgeInsets.all(8),
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final playerId = entries[index].key;
          final player = entries[index].value as Map<String, dynamic>;
          final isYou = playerId == currentPlayerId;
          final name = player['name'] as String? ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isYou ? const Color(0xFF34495E) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '#${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF95A5A6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (player['avatar'] != null)
                  AvatarRenderer(
                    avatar: player['avatar'] as Avatar,
                    size: 32,
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getPlayerColor(index),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${player['score'] ?? 0} points',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF95A5A6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getPlayerColor(int index) {
    const colors = [
      Color(0xFFE74C3C),
      Color(0xFF3498DB),
      Color(0xFF2ECC71),
      Color(0xFFF39C12),
      Color(0xFF9B59B6),
      Color(0xFF1ABC9C),
    ];
    return colors[index % colors.length];
  }
}
