import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player.dart';
import 'avatar_renderer.dart';

class PlayerList extends StatelessWidget {
  final List<Player> players;
  final String? currentDrawerId;
  final bool isHorizontal;

  const PlayerList({
    super.key,
    required this.players,
    required this.currentDrawerId,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    // Rank players based on score (descending)
    final sortedPlayers = [...players];
    sortedPlayers.sort((a, b) => b.score.compareTo(a.score));

    if (isHorizontal) {
      return Container(
        height: 68,
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: const BoxDecoration(
          color: Color(0xFF1E2833), // Dark charcoal-slate background
          border: Border(
            bottom: BorderSide(color: Colors.black, width: 3.0),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = sortedPlayers[index];
            final rank = index + 1;
            final isDrawing = player.id == currentDrawerId;
            final hasGuessed = player.hasGuessed;

            // Determine card background color
            Color cardBg = const Color(0xFF2C3E50); // Flat dark slate blue
            if (hasGuessed) {
              cardBg = const Color(0xFF2E7D32); // Flat green
            } else if (isDrawing) {
              cardBg = const Color(0xFF1F69C9); // Flat blue
            }

            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.black, width: 2.0),
              ),
              child: Row(
                children: [
                  // Avatar
                  AvatarRenderer(avatar: player.avatar, size: 28, drawBorder: false),
                  const SizedBox(width: 4),

                  // Player name and score
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '#$rank • ${player.score}',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 2),
                  // Score popups or status icon
                  if (player.lastTurnScore > 0)
                    Text(
                      '+${player.lastTurnScore}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        color: const Color(0xFF7ED321),
                      ),
                    )
                  else if (isDrawing)
                    const Icon(Icons.edit, size: 12, color: Colors.white)
                  else if (hasGuessed)
                    const Icon(Icons.check_circle, size: 12, color: Color(0xFF7ED321)),
                ],
              ),
            );
          },
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2833), // Dark charcoal-slate background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3.0),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = sortedPlayers[index];
          final rank = index + 1;
          final isDrawing = player.id == currentDrawerId;
          final hasGuessed = player.hasGuessed;

          // Determine card background color
          Color cardBg = const Color(0xFF2C3E50); // Flat dark slate blue
          if (hasGuessed) {
            cardBg = const Color(0xFF2E7D32); // Flat green
          } else if (isDrawing) {
            cardBg = const Color(0xFF1F69C9); // Flat blue
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 2.0),
            ),
            child: Row(
              children: [
                // Rank label
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text(
                    '#$rank',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),

                // Avatar
                AvatarRenderer(avatar: player.avatar, size: 36, drawBorder: false),
                const SizedBox(width: 8),

                // Player name and score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Points: ${player.score}',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),

                // Score popups or drawing pencil icon
                if (player.lastTurnScore > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      '+${player.lastTurnScore}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: const Color(0xFF7ED321),
                      ),
                    ),
                  ),

                if (isDrawing)
                  const Icon(Icons.edit, size: 18, color: Colors.white)
                else if (hasGuessed)
                  const Icon(Icons.check_circle, size: 18, color: Color(0xFF7ED321)),
              ],
            ),
          );
        },
      ),
    );
  }
}
