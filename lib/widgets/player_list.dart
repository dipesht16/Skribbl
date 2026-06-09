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
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: const Border(
            bottom: BorderSide(color: Colors.black, width: 3.0),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final rank = sortedPlayers.indexWhere((p) => p.id == player.id) + 1;
            final isDrawing = player.id == currentDrawerId;
            final hasGuessed = player.hasGuessed;

            // Determine card background color
            Color cardBg = Colors.white;
            if (hasGuessed) {
              cardBg = const Color(0xFFd4edda); // Soft green
            } else if (isDrawing) {
              cardBg = const Color(0xFFd1ecf1); // Soft blue
            }

            // Determine border color
            Color borderColor = Colors.black;
            double borderW = 1.5;
            if (isDrawing) {
              borderColor = const Color(0xFF0c5460); // Darker blue
              borderW = 2.0;
            } else if (hasGuessed) {
              borderColor = const Color(0xFF155724); // Darker green
              borderW = 2.0;
            }

            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: borderColor, width: borderW),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(0, 1.5),
                    blurRadius: 0,
                  )
                ],
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
                            color: isDrawing ? Colors.blue.shade900 : Colors.black,
                          ),
                        ),
                        Text(
                          '#$rank • ${player.score}',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                            color: Colors.grey.shade600,
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
                        color: Colors.green.shade700,
                      ),
                    )
                  else if (isDrawing)
                    const Icon(Icons.edit, size: 14, color: Colors.blue)
                  else if (hasGuessed)
                    const Icon(Icons.thumb_up, size: 14, color: Colors.green),
                ],
              ),
            );
          },
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3.0),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          final rank = sortedPlayers.indexWhere((p) => p.id == player.id) + 1;
          final isDrawing = player.id == currentDrawerId;
          final hasGuessed = player.hasGuessed;

          // Determine card background color
          Color cardBg = Colors.white;
          if (hasGuessed) {
            cardBg = const Color(0xFFd4edda); // Soft green
          } else if (isDrawing) {
            cardBg = const Color(0xFFd1ecf1); // Soft blue
          }

          // Determine border color
          Color borderColor = Colors.black;
          double borderW = 2.0;
          if (isDrawing) {
            borderColor = const Color(0xFF0c5460); // Darker blue
            borderW = 3.0;
          } else if (hasGuessed) {
            borderColor = const Color(0xFF155724); // Darker green
            borderW = 3.0;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: borderColor, width: borderW),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 2),
                  blurRadius: 0,
                )
              ],
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
                      color: Colors.grey.shade700,
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
                          color: isDrawing ? Colors.blue.shade900 : Colors.black,
                        ),
                      ),
                      Text(
                        'Points: ${player.score}',
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Colors.grey.shade600,
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
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),

                if (isDrawing)
                  const Icon(Icons.edit, size: 18, color: Colors.blue)
                else if (hasGuessed)
                  const Icon(Icons.thumb_up, size: 18, color: Colors.green),
              ],
            ),
          );
        },
      ),
    );
  }
}
