import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

class GameService {
  late final DatabaseReference _database = FirebaseDatabase.instanceFor(app: Firebase.app(), databaseURL: 'https://scribble-7bcd4-default-rtdb.firebaseio.com/').ref();
  final Uuid _uuid = const Uuid();

  String _generateRoomCode() {
    return _uuid.v4().substring(0, 6).toUpperCase();
  }

  Future<Map<String, String>> createRoom(String playerName) async {
    final playerId = _uuid.v4();
    final roomCode = _generateRoomCode();
    final roomRef = _database.child('rooms').push();
    final roomKey = roomRef.key!;

    await roomRef.set({
      'roomCode': roomCode,
      'roomKey': roomKey,
      'hostId': playerId,
      'gameState': 'waiting',
      'currentWord': '',
      'currentDrawerId': '',
      'round': 0,
      'maxRounds': 3,
      'createdAt': ServerValue.timestamp,
      'players': {
        playerId: {
          'name': playerName,
          'score': 0,
          'isReady': false,
          'streak': 0,
          'hasGuessedCorrectly': false,
        }
      },
      'messages': {},
    });

    return {
      'roomCode': roomCode,
      'roomKey': roomKey,
      'playerId': playerId,
    };
  }

  Future<Map<String, String>?> joinRoom(String roomCode, String playerName) async {
    final snapshot = await _database
        .child('rooms')
        .orderByChild('roomCode')
        .equalTo(roomCode.toUpperCase())
        .get();

    if (!snapshot.exists) return null;

    final roomsMap = snapshot.value as Map<dynamic, dynamic>;
    final roomKey = roomsMap.keys.first;
    final roomData = roomsMap[roomKey] as Map<dynamic, dynamic>;

    final players = roomData['players'] as Map<dynamic, dynamic>? ?? {};
    if (players.length >= 8) {
      throw Exception('Room is full (max 8 players)');
    }

    final playerId = _uuid.v4();

    await _database.child('rooms/$roomKey/players/$playerId').set({
      'name': playerName,
      'score': 0,
      'isReady': false,
      'streak': 0,
      'hasGuessedCorrectly': false,
    });

    return {
      'roomCode': roomCode.toUpperCase(),
      'roomKey': roomKey,
      'playerId': playerId,
    };
  }

  Stream<DatabaseEvent> listenToRoom(String roomKey) {
    return _database.child('rooms/$roomKey').onValue;
  }

  Future<void> sendMessage(
    String roomKey,
    String playerId,
    String playerName,
    String message,
  ) async {
    await _database.child('rooms/$roomKey/messages').push().set({
      'playerId': playerId,
      'playerName': playerName,
      'message': message,
      'timestamp': ServerValue.timestamp,
      'isCorrectGuess': false,
    });
  }

  Stream<DatabaseEvent> listenToMessages(String roomKey) {
    return _database
        .child('rooms/$roomKey/messages')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue;
  }

  Future<void> leaveRoom(String roomKey, String playerId) async {
    await _database.child('rooms/$roomKey/players/$playerId').remove();
  }

  Future<void> deleteRoom(String roomKey) async {
    await _database.child('rooms/$roomKey').remove();
  }

  Future<bool> testConnection() async {
    final testRef = _database.child('rooms/_test_connection');
    await testRef.set({
      'timestamp': ServerValue.timestamp,
      'test': true,
    });
    final snapshot = await testRef.get();
    await testRef.remove();
    return snapshot.exists;
  }
}
