import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import '../services/game_state_controller.dart';
import '../services/firebase_game_service.dart';
import '../widgets/avatar_renderer.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final GameStateController controller;
  final bool isFirebaseHost;
  final String roomCode;

  const LobbyScreen({
    super.key,
    required this.controller,
    required this.isFirebaseHost,
    required this.roomCode,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _customWordsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customWordsController.text = widget.controller.room.customWords;
    if (widget.isFirebaseHost) {
      _customWordsController.addListener(() {
        widget.controller.setLobbySettings(customWords: _customWordsController.text);
      });
    }

    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    if (widget.controller.room.status != GameStatus.lobby) {
      widget.controller.removeListener(_onControllerChanged);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GameScreen(
            controller: widget.controller,
            isFirebaseJoiner: !widget.isFirebaseHost,
            roomCode: widget.roomCode,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _customWordsController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    widget.controller.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.controller.room;
    final players = widget.controller.players;
    final inviteCode = widget.roomCode;
    final bool isPortrait = MediaQuery.of(context).size.width < 600;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF133c64),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                final controller = widget.controller;
                if (controller.isFirebaseGame) {
                  final code = widget.roomCode;
                  if (widget.isFirebaseHost) {
                    await FirebaseGameService().roomRef(code).remove();
                  } else {
                    await FirebaseGameService().removePlayer(code, controller.localPlayer.id);
                  }
                  controller.cleanupFirebase();
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Text(
              'PRIVATE ROOM LOBBY',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ),
          body: SafeArea(
            child: isPortrait
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPlayersCard(players),
                        const SizedBox(height: 16),
                        _buildSettingsCard(room, inviteCode),
                        const SizedBox(height: 16),
                        _buildStartButton(players),
                        const SizedBox(height: 24),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LEFT COLUMN: Players inside lobby
                        Expanded(
                          flex: 4,
                          child: _buildPlayersCard(players),
                        ),
                        const SizedBox(width: 16),

                        // RIGHT COLUMN: Settings & Launch Controls
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildSettingsCard(room, inviteCode),
                              ),
                              const SizedBox(height: 16),
                              _buildStartButton(players),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  // --- SUB-WIDGET BUILDERS ---

  Widget _buildPlayersCard(List<Player> players) {
    final bool isPortrait = MediaQuery.of(context).size.width < 600;
    return Container(
      height: isPortrait ? 280 : null,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black, width: 4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLAYERS (${players.length}/10)',
                style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              ElevatedButton.icon(
                onPressed: (widget.isFirebaseHost && players.length < 10) ? widget.controller.addBot : null,
                icon: const Icon(Icons.add, size: 16),
                label: Text('ADD BOT', style: GoogleFonts.fredoka(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black, thickness: 2.0, height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: Row(
                    children: [
                      AvatarRenderer(avatar: player.avatar, size: 36, drawBorder: false),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player.name + (player.isHost ? ' (Host)' : ''),
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (player.isBot && widget.isFirebaseHost)
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => widget.controller.removeBot(player.id),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(GameRoom room, String inviteCode) {
    final encodedCode = inviteCode;
    final inviteLink = 'http://skribbl-clone.app/join?code=$encodedCode';
    final bool isPortrait = MediaQuery.of(context).size.width < 600;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const Divider(color: Colors.black, thickness: 2.0, height: 24),

        // Room Code Display
        Text(
          'ROOM CODE / SHARE LINK',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                encodedCode,
                style: GoogleFonts.fredoka(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.blue.shade900,
                  letterSpacing: 1.0,
                ),
              ),
              Row(
                children: [
                  // Copy Room Code Button
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy Room Code',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: encodedCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Room Code copied to clipboard!')),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  // Copy Invite Link Button
                  IconButton(
                    icon: const Icon(Icons.share, size: 18),
                    tooltip: 'Copy Share Link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite share link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Round selection slider
        Text(
          'ROUNDS: ${room.rounds}',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        Slider(
          value: room.rounds.toDouble(),
          min: 2,
          max: 10,
          divisions: 8,
          activeColor: Colors.amber,
          inactiveColor: Colors.grey.shade300,
          onChanged: widget.isFirebaseHost ? (val) {
            widget.controller.setLobbySettings(rounds: val.toInt());
          } : null,
        ),
        const SizedBox(height: 12),

        // Draw time selection dropdown
        Text(
          'DRAW TIME (SECONDS)',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: room.drawTime,
              isExpanded: true,
              items: [30, 45, 60, 80, 90, 120, 180].map<DropdownMenuItem<int>>((int val) {
                return DropdownMenuItem<int>(
                  value: val,
                  child: Text('$val seconds'),
                );
              }).toList(),
              onChanged: widget.isFirebaseHost ? (val) {
                if (val != null) {
                  widget.controller.setLobbySettings(drawTime: val);
                }
              } : null,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Custom words text area
        Text(
          'CUSTOM WORDS (COMMA SEPARATED)',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 2.0),
          ),
          child: TextField(
            controller: _customWordsController,
            enabled: widget.isFirebaseHost,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. dart, flutter, widget, hot reload',
              hintStyle: GoogleFonts.fredoka(color: Colors.grey.shade500, fontSize: 12),
              contentPadding: const EdgeInsets.all(12),
              border: InputBorder.none,
            ),
            style: GoogleFonts.fredoka(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.black, width: 4.0),
      ),
      child: isPortrait ? content : SingleChildScrollView(child: content),
    );
  }

  Widget _buildStartButton(List<Player> players) {
    if (!widget.isFirebaseHost) {
      return Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black, width: 3.5),
        ),
        child: Text(
          'WAITING FOR HOST TO START...',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
        ),
      );
    }

    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: players.length >= 2 ? _onStartPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00cc00),
          disabledBackgroundColor: Colors.grey.shade400,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Colors.black, width: 3.5),
          ),
        ),
        child: Text(
          'START GAME',
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
