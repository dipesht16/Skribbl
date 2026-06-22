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
import '../widgets/floating_chat_overlay.dart';
import '../models/floating_chat_message.dart';
import '../models/chat_message.dart';

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
  final GlobalKey<FloatingChatOverlayState> _floatingChatKey = GlobalKey<FloatingChatOverlayState>();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _lastMessageCount = widget.controller.chatMessages.length;
    widget.controller.addListener(_onControllerChangedInGame);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChangedInGame);
    widget.controller.cleanupFirebase();
    super.dispose();
  }

  void _onControllerChangedInGame() {
    if (!mounted) return;
    if (widget.controller.roomDeleted) {
      widget.controller.removeListener(_onControllerChangedInGame);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Host closed the game.')),
      );
      Navigator.of(context).pop();
      return;
    }
    final currentCount = widget.controller.chatMessages.length;
    if (currentCount > _lastMessageCount) {
      for (int i = _lastMessageCount; i < currentCount; i++) {
        final msg = widget.controller.chatMessages[i];
        
        final isCorrect = msg.type == ChatMessageType.correct;
        final isCorrectChat = msg.type == ChatMessageType.correctGuesserChat;
        final isSystem = msg.type == ChatMessageType.system;
        final isLike = msg.type == ChatMessageType.like;
        final isDislike = msg.type == ChatMessageType.dislike;
        final isWarning = msg.type == ChatMessageType.close;

        Color playerColor = Colors.black;
        final playerIdx = widget.controller.players.indexWhere((p) => p.name == msg.senderName);
        if (playerIdx != -1) {
          const colors = [
            Color(0xFFE74C3C),
            Color(0xFF3498DB),
            Color(0xFF2ECC71),
            Color(0xFFF39C12),
            Color(0xFF9B59B6),
            Color(0xFF1ABC9C),
          ];
          playerColor = colors[playerIdx % colors.length];
        }

        _floatingChatKey.currentState?.addMessage(
          FloatingChatMessage(
            id: msg.id,
            playerName: msg.senderName,
            message: msg.text,
            playerColor: playerColor,
            isCorrectGuess: isCorrect,
            isCorrectGuesserChat: isCorrectChat,
            isSystemMessage: isSystem,
            isLike: isLike,
            isDislike: isDislike,
            isWarningMessage: isWarning,
            timestamp: DateTime.now(),
          )
        );
      }
      _lastMessageCount = currentCount;
    } else if (currentCount < _lastMessageCount) {
      _lastMessageCount = currentCount;
    }
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
        final bool isPortrait = mediaQuery.size.width < mediaQuery.size.height;

        Widget mainLayout;

        if (isPortrait) {
          mainLayout = Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DrawingCanvas(
                                points: widget.controller.drawingPoints,
                                isDrawingEnabled: isMyTurn && room.status == GameStatus.drawing,
                                onPointAdded: _onPointAdded,
                                onClear: _onClear,
                                onReaction: !isMyTurn && room.status == GameStatus.drawing
                                    ? (isLike) => widget.controller.submitReaction(widget.controller.localPlayer.id, isLike)
                                    : null,
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FloatingChatOverlay(
                                key: _floatingChatKey,
                                maxVisibleMessages: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Expanded(
                              child: PlayerList(
                                players: players,
                                currentDrawerId: room.currentDrawerId,
                                isHorizontal: false,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ChatPanel(
                                messages: chat,
                                onSendMessage: _onGuessSubmitted,
                                isDrawing: !isInputActive,
                              ),
                            ),
                          ],
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
                        Positioned.fill(
                          child: DrawingCanvas(
                            points: widget.controller.drawingPoints,
                            isDrawingEnabled: isMyTurn && room.status == GameStatus.drawing,
                            onPointAdded: _onPointAdded,
                            onClear: _onClear,
                            onReaction: !isMyTurn && room.status == GameStatus.drawing
                                ? (isLike) => widget.controller.submitReaction(widget.controller.localPlayer.id, isLike)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FloatingChatOverlay(
                            key: _floatingChatKey,
                            maxVisibleMessages: 3,
                          ),
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
                      onSendMessage: _onGuessSubmitted,
                      isDrawing: !isInputActive,
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
            top: false,
            bottom: false,
            left: false,
            right: false,
            child: Column(
              children: [
                // 1. TOP STATUS PANEL
                _buildTopBar(room, players, isMyTurn),

                // 2. MAIN LAYOUT
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 3.0),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            // Left: Timer circle on top, Round text below
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF1c2630), width: 3),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${room.timeRemaining}',
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: room.timeRemaining <= 10 ? Colors.red.shade900 : const Color(0xFF1c2630),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Round ${room.currentRound} of ${room.rounds}',
                  style: GoogleFonts.fredoka(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            // Center: DRAW THIS / GUESS THIS instructions (wrapped in Expanded to prevent overflow)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    room.status == GameStatus.choosing
                        ? 'CHOOSING...'
                        : (isMyTurn ? 'DRAW THIS' : 'GUESS THIS'),
                    style: GoogleFonts.fredoka(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  if (room.status == GameStatus.drawing)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            isMyTurn ? room.currentWord.toUpperCase() : room.currentHint,
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              letterSpacing: 2.0,
                              color: isMyTurn ? const Color(0xFF7ED321) : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (!isMyTurn && room.currentWord.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${room.currentWord.length}',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    )
                  else if (room.status == GameStatus.choosing)
                    Text(
                      isMyTurn ? 'SELECT A WORD' : '${drawer.name.toUpperCase()} IS CHOOSING',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  else
                    Text(
                      statusText.toUpperCase(),
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            
            // Right offset of ~64px to account for the width of the timer column
            const SizedBox(width: 64),
          ],
        ),
      ),
    );
  }

  Widget _buildWordSelectionOverlay(GameRoom room, bool isMyTurn) {
    if (!isMyTurn) {
      return Container(
        color: Colors.black.withValues(alpha: 0.6),
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
      color: Colors.black.withValues(alpha: 0.6),
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
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFFD35400)),
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
                        backgroundColor: Colors.white,
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
    final roundPlayers = [...widget.controller.players];
    roundPlayers.sort((a, b) => b.lastTurnScore.compareTo(a.lastTurnScore));

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
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
              const Divider(height: 20, thickness: 1.5),
              Text(
                'POINTS THIS ROUND',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: roundPlayers.length,
                  itemBuilder: (context, index) {
                    final player = roundPlayers[index];
                    final pointsGained = player.lastTurnScore;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: pointsGained > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pointsGained > 0 ? const Color(0xFF81C784) : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          AvatarRenderer(avatar: player.avatar, size: 28, drawBorder: false),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              player.name,
                              style: GoogleFonts.fredoka(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '+$pointsGained',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: pointsGained > 0 ? Colors.green.shade800 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 20, thickness: 1.5),
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
      color: Colors.black.withValues(alpha: 0.8),
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
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
