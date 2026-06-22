import 'package:flutter/material.dart';
import '../services/game_service.dart';

class RoomScreen extends StatefulWidget {
  final String roomCode;
  final String roomKey;
  final String playerId;
  final String playerName;
  final bool isHost;

  const RoomScreen({
    super.key,
    required this.roomCode,
    required this.roomKey,
    required this.playerId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final GameService _gameService = GameService();
  Map<String, dynamic>? _roomData;

  @override
  void initState() {
    super.initState();
    _listenToRoom();
  }

  void _listenToRoom() {
    _gameService.listenToRoom(widget.roomKey).listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _roomData = Map<String, dynamic>.from(event.snapshot.value as Map);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomCode}'),
        backgroundColor: const Color(0xFF4A90E2),
        actions: [
          if (widget.isHost)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                await _gameService.deleteRoom(widget.roomKey);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: _roomData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: (_roomData!['players'] as Map?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final players = _roomData!['players'] as Map;
                      final pid = players.keys.elementAt(index);
                      final player = players[pid] as Map;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF4A90E2),
                            child: Text(
                              (player['name'] as String)[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            player['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            '${player['score']} pts',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF7ED321),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: const Border(
                      top: BorderSide(color: Colors.grey),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Players: ${(_roomData!['players'] as Map?)?.length ?? 0}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${_roomData!['gameState']}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _gameService.leaveRoom(widget.roomKey, widget.playerId);
    super.dispose();
  }
}
