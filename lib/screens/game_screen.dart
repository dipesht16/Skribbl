import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/avatar.dart';
import '../models/draw_point.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../services/game_state_controller.dart';
import '../widgets/avatar_renderer.dart';
import '../widgets/chat_panel.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/player_list.dart';

class GameScreen extends StatefulWidget {
  final GameStateController controller;
  final bool isFirebaseJoiner;
  final String? roomCode;

  const GameScreen({
    super.key,
    required this.controller,
    this.isFirebaseJoiner = false,
    this.roomCode,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void dispose() {
    widget.controller.cleanupFirebase();
    super.dispose();
  }

  void _onPointAdded(DrawPoint point) {
    widget.controller.addDrawPoint(point);
  }

  void _onClear() {
    widget.controller.clearCanvas();
  }

  void _onGuessSubmitted(String text) {
    widget.controller.submitGuess(widget.controller.localPlayer.id, text);
  }

  void _onWordSelected(String word) {
    widget.controller.selectWord(word);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final room = widget.controller.room;
        final players = widget.controller.players;
        final chat = widget.controller.chatMessages;

        final isMyTurn = room.currentDrawerId == widget.controller.localPlayer.id;
        final hasGuessed = widget.controller.players.firstWhere((p) => p.id == widget.controller.localPlayer.id, orElse: () => widget.controller.localPlayer).hasGuessed;

        // Is guess input active
        final isInputActive = !isMyTurn && !hasGuessed && room.status == GameStatus.drawing;
        
        final mediaQuery = MediaQuery.of(context);
        final bool isPortrait = mediaQuery.size.width < 600;

        Widget mainLayout;

        if (isPortrait) {
          mainLayout = Column(
            children: [
              PlayerList(
                players: players,
                currentDrawerId: room.currentDrawerId,
                isHorizontal: true,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: DrawingCanvas(
                              points: widget.controller.drawingPoints,
                              isDrawingEnabled: isMyTurn && room.status == GameStatus.drawing,
                              onPointAdded: _onPointAdded,
                              onClear: _onClear,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            flex: 4,
                            child: ChatPanel(
                              messages: chat,
                              onMessageSubmitted: _onGuessSubmitted,
                              isInputEnabled: isInputActive,
                              placeholder: isMyTurn ? 'You are drawing! Type here to chat...' : 'Type your guess here...',
                            ),
                          ),
                        ],
                      ),
                      // Overlays inside the content area
                      if (room.status == GameStatus.choosing)
                        _buildWordSelectionOverlay(room, isMyTurn),
                      if (room.status == GameStatus.roundEnd)
                        _buildRoundEndOverlay(room),
                      if (room.status == GameStatus.gameEnd)
                        _buildGameEndPodium(players),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          // Horizontal side-by-side layout
          mainLayout = Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // LEFT SIDEBAR: Scores
                  Expanded(
                    flex: 3,
                    child: PlayerList(
                      players: players,
                      currentDrawerId: room.currentDrawerId,
                      isHorizontal: false,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // CENTER BOARD: Drawing canvas / Select Word overlay
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        DrawingCanvas(
                          points: widget.controller.drawingPoints,
                          isDrawingEnabled: isMyTurn && room.status == GameStatus.drawing,
                          onPointAdded: _onPointAdded,
                          onClear: _onClear,
                        ),
                        if (room.status == GameStatus.choosing)
                          _buildWordSelectionOverlay(room, isMyTurn),
                        if (room.status == GameStatus.roundEnd)
                          _buildRoundEndOverlay(room),
                        if (room.status == GameStatus.gameEnd)
                          _buildGameEndPodium(players),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // RIGHT SIDEBAR: Chat
                  Expanded(
                    flex: 4,
                    child: ChatPanel(
                      messages: chat,
                      onMessageSubmitted: _onGuessSubmitted,
                      isInputEnabled: isInputActive,
                      placeholder: isMyTurn ? 'You are drawing! Type here to chat...' : 'Type your guess here...',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1c2630), // Dark background for contrast
          body: SafeArea(
            child: Column(
              children: [
                // 1. TOP STATUS PANEL
                _buildTopBar(room, players, isMyTurn),

                // 2. MAIN LAYOUT
                if (isPortrait)
                  Expanded(child: mainLayout)
                else
                  mainLayout,
              ],
            ),
          ),
        );
      },
    );
  }

  // --- SUB-WIDGET BUILDERS ---

  Widget _buildTopBar(GameRoom room, List<Player> players, bool isMyTurn) {
    final drawer = players.firstWhere((p) => p.id == room.currentDrawerId, orElse: () => Player(id: '', name: 'Someone', avatar: Avatar.random()));
    
    String statusText = '';
    if (room.status == GameStatus.choosing) {
      statusText = isMyTurn ? 'CHOOSE A WORD!' : '${drawer.name} is choosing...';
    } else if (room.status == GameStatus.drawing) {
      statusText = isMyTurn ? 'DRAW THIS:' : '${drawer.name} is drawing...';
    } else if (room.status == GameStatus.roundEnd) {
      statusText = 'ROUND ENDED!';
    } else if (room.status == GameStatus.gameEnd) {
      statusText = 'GAME OVER!';
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 500;

    if (isSmall) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black, width: 3.0),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: room.timeRemaining <= 10 ? Colors.red.shade100 : Colors.blue.shade50,
                      border: Border.all(color: Colors.black, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${room.timeRemaining}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: room.timeRemaining <= 10 ? Colors.red.shade900 : Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'ROUND ${room.currentRound} OF ${room.rounds}',
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (room.status == GameStatus.drawing) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Text(
                    isMyTurn ? room.currentWord.toUpperCase() : room.currentHint,
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 2.0,
                      color: isMyTurn ? Colors.green.shade800 : Colors.black,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 4.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: room.timeRemaining <= 10 ? Colors.red.shade100 : Colors.blue.shade50,
                border: Border.all(color: Colors.black, width: 3),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${room.timeRemaining}',
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: room.timeRemaining <= 10 ? Colors.red.shade900 : Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ROUND ${room.currentRound} OF ${room.rounds}',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey.shade600),
                ),
                Text(
                  statusText,
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black),
                ),
              ],
            ),
            const Spacer(),
            if (room.status == GameStatus.drawing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2.5),
                ),
                child: Text(
                  isMyTurn ? room.currentWord.toUpperCase() : room.currentHint,
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 2.0,
                    color: isMyTurn ? Colors.green.shade800 : Colors.black,
                  ),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWordSelectionOverlay(GameRoom room, bool isMyTurn) {
    if (!isMyTurn) {
      return Container(
        color: Colors.black.withOpacity(0.6),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black, width: 4),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.amber),
                const SizedBox(height: 16),
                Text(
                  'Waiting for player to select a word...',
                  style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black.withOpacity(0.6),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              offset: Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CHOOSE A WORD',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.amber.shade900),
              ),
              const SizedBox(height: 20),
              ...room.wordChoices.map((word) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _onWordSelected(word),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2.5),
                        ),
                      ),
                      child: Text(
                        word.toUpperCase(),
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundEndOverlay(GameRoom room) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 4),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROUND OVER',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.blue.shade900),
              ),
              const SizedBox(height: 12),
              Text(
                'The word was:',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Text(
                room.currentWord.toUpperCase(),
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Colors.green.shade700,
                  letterSpacing: 1,
                ),
              ),
              const Divider(height: 24, thickness: 1.5),
              Text(
                'Next round starting in ${room.timeRemaining}s...',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade500),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameEndPodium(List<Player> players) {
    final topPlayers = [...players];
    topPlayers.sort((a, b) => b.score.compareTo(a.score));

    final Player? first = topPlayers.isNotEmpty ? topPlayers[0] : null;
    final Player? second = topPlayers.length > 1 ? topPlayers[1] : null;
    final Player? third = topPlayers.length > 2 ? topPlayers[2] : null;

    return Container(
      color: Colors.black.withOpacity(0.8),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 4),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CONGRATULATIONS!',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 24, color: Colors.orange.shade800),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 220,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (second != null)
                      _buildPodiumStep(
                        player: second,
                        rank: '2nd',
                        color: Colors.grey.shade300,
                        height: 100,
                      ),
                    const SizedBox(width: 8),
                    if (first != null)
                      _buildPodiumStep(
                        player: first,
                        rank: '1st',
                        color: const Color(0xFFFFD700),
                        height: 140,
                      ),
                    const SizedBox(width: 8),
                    if (third != null)
                      _buildPodiumStep(
                        player: third,
                        rank: '3rd',
                        color: const Color(0xFFCD7F32),
                        height: 70,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2.5),
                        ),
                      ),
                      child: Text(
                        'Exit Game',
                        style: GoogleFonts.fredoka(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  if (!widget.controller.isFirebaseGame || widget.controller.isHost) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.controller.restartGame();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00cc00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black, width: 2.5),
                          ),
                        ),
                        child: Text(
                          'Play Again',
                          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumStep({
    required Player player,
    required String rank,
    required Color color,
    required double height,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AvatarRenderer(avatar: player.avatar, size: 48),
        const SizedBox(height: 6),
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 12),
        ),
        Text(
          '${player.score} pts',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 6),
        Container(
          width: 90,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black, width: 3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            rank,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }
}
