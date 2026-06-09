import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/avatar.dart';
import '../services/game_state_controller.dart';
import '../widgets/avatar_customizer.dart';
import '../widgets/skribbl_logo.dart';
import 'lobby_screen.dart';
import 'game_screen.dart';
import '../services/firebase_game_service.dart';

class LandingScreen extends StatefulWidget {
  final GameStateController controller;

  const LandingScreen({super.key, required this.controller});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  Avatar _selectedAvatar = Avatar.random();
  String _selectedLanguage = 'English';
  final FirebaseGameService _firebaseService = FirebaseGameService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.controller.localPlayer.name;
    _selectedAvatar = widget.controller.localPlayer.avatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  void _onPlayPressed() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    // Update local player state
    widget.controller.updateLocalPlayer(name, _selectedAvatar);
    widget.controller.restartGame(); // Reset any past matches
    
    // Auto-populate 3 bots
    widget.controller.startGame();

    // Navigate to Game Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameScreen(controller: widget.controller),
      ),
    );
  }

  void _onCreateRoomPressed() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.controller.updateLocalPlayer(name, _selectedAvatar);
    widget.controller.restartGame();

    final roomCode = _firebaseService.generateRoomCode();
    widget.controller.initializeFirebaseHost(roomCode);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LobbyScreen(
          controller: widget.controller,
          isFirebaseHost: true,
          roomCode: roomCode,
        ),
      ),
    );
  }

  void _onJoinRoomPressed() async {
    final name = _nameController.text.trim();
    final joinCode = _joinCodeController.text.trim().toUpperCase();
    if (name.isEmpty || joinCode.isEmpty) return;

    final exists = await _firebaseService.checkRoomExists(joinCode);
    if (!exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room code "$joinCode" not found!')),
        );
      }
      return;
    }

    widget.controller.updateLocalPlayer(name, _selectedAvatar);
    final localPlayer = widget.controller.localPlayer;
    await _firebaseService.joinPlayer(joinCode, localPlayer.id, localPlayer.toJson());

    widget.controller.initializeFirebaseJoiner(joinCode);

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LobbyScreen(
            controller: widget.controller,
            isFirebaseHost: false,
            roomCode: joinCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF133c64), // Dark blue sky background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF133c64),
              Color(0xFF071b30),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                
                // 1. Skribbl Logo
                const SkribblLogo(fontSize: 46),
                const SizedBox(height: 32),

                // 2. MAIN SETUP CARD
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.black, width: 4.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 6),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Name Input Box
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 3.0),
                        ),
                        child: TextField(
                          controller: _nameController,
                          maxLength: 14,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter your name',
                            hintStyle: GoogleFonts.fredoka(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Language Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black, width: 3.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            items: <String>['English', 'German', 'Spanish', 'French', 'Italian']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLanguage = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Avatar customization
                      AvatarCustomizer(
                        avatar: _selectedAvatar,
                        onChanged: (newAvatar) {
                          setState(() {
                            _selectedAvatar = newAvatar;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      // PLAY BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onPlayPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00cc00), // Vibrant green
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Colors.black, width: 3.5),
                            ),
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            'PLAY!',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // CREATE PRIVATE ROOM BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onCreateRoomPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7100), // Orange
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Colors.black, width: 3.5),
                            ),
                          ),
                          child: Text(
                            'Create Private Room',
                            style: GoogleFonts.fredoka(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // 3. JOIN LOBBY BY ROOM CODE CARD
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.black, width: 4.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        offset: Offset(0, 4),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black, width: 2.5),
                          ),
                          child: TextField(
                            controller: _joinCodeController,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Enter Room IP/Code',
                              hintStyle: GoogleFonts.fredoka(color: Colors.grey.shade500),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _onJoinRoomPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black, width: 2.5),
                          ),
                        ),
                        child: Text(
                          'JOIN LOBBY',
                          style: GoogleFonts.fredoka(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 4. HOW TO PLAY & INFO CARDS (Footer grid)
                Container(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: MediaQuery.of(context).size.width < 600
                      ? Column(
                          children: [
                            _buildInfoCard(
                              title: 'HOW TO PLAY',
                              color: const Color(0xFF00B2FF), // Cyan
                              content: 'When it is your turn to draw, choose a word from the choices and draw it on the whiteboard.\n\nWhen others are drawing, type your guesses in the chat box to gain points. The faster you guess, the more points you score!',
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              title: 'LATEST NEWS',
                              color: const Color(0xFFFFB200), // Gold
                              content: 'Welcome to Skribbl.io Flutter!\n\nThis app includes smart AI bots who draw and guess in the chat room. Play single player offline or host private rooms over local Wi-Fi to challenge your friends!',
                            ),
                          ],
                        )
                      : IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  title: 'HOW TO PLAY',
                                  color: const Color(0xFF00B2FF), // Cyan
                                  content: 'When it is your turn to draw, choose a word from the choices and draw it on the whiteboard.\n\nWhen others are drawing, type your guesses in the chat box to gain points. The faster you guess, the more points you score!',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoCard(
                                  title: 'LATEST NEWS',
                                  color: const Color(0xFFFFB200), // Gold
                                  content: 'Welcome to Skribbl.io Flutter!\n\nThis app includes smart AI bots who draw and guess in the chat room. Play single player offline or host private rooms over local Wi-Fi to challenge your friends!',
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildInfoCard({
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.black, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(0, 4),
            blurRadius: 0,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1.5, 1.5),
                  blurRadius: 0,
                )
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black.withOpacity(0.85),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
