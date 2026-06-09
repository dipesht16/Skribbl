import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class FirebaseGameService {
  DatabaseReference get _database => FirebaseDatabase.instance.ref();

  // Generate a random 6-character room code (alphanumeric uppercase, excluding confusing characters)
  String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid I, O, 0, 1
    final rnd = Random();
    return List.generate(6, (index) => chars[rnd.nextInt(chars.length)]).join();
  }

  // Reference to a specific room
  DatabaseReference roomRef(String roomCode) {
    return _database.child('rooms').child(roomCode.toUpperCase());
  }

  // Create room
  Future<void> createRoom(String roomCode, Map<String, dynamic> initialData) async {
    await roomRef(roomCode).set(initialData);
  }

  // Check if room exists
  Future<bool> checkRoomExists(String roomCode) async {
    final snapshot = await roomRef(roomCode).get();
    return snapshot.exists;
  }

  // Update specific fields of a room
  Future<void> updateRoom(String roomCode, Map<String, dynamic> updates) async {
    await roomRef(roomCode).update(updates);
  }

  // Write a new point to the drawing list
  Future<void> addDrawingPoint(String roomCode, Map<String, dynamic> pointData) async {
    await roomRef(roomCode).child('drawingPoints').push().set(pointData);
  }

  // Clear drawing points
  Future<void> clearDrawingPoints(String roomCode) async {
    await roomRef(roomCode).child('drawingPoints').remove();
  }

  // Send a guess/chat message
  Future<void> sendChatMessage(String roomCode, Map<String, dynamic> messageData) async {
    await roomRef(roomCode).child('chatMessages').push().set(messageData);
  }

  // Select a word choice (Joiner selects, Host listens)
  Future<void> selectWord(String roomCode, String word) async {
    await roomRef(roomCode).update({
      'selectedWord': word,
    });
  }

  // Clear selected word trigger
  Future<void> clearSelectedWord(String roomCode) async {
    await roomRef(roomCode).child('selectedWord').remove();
  }

  // Join a room as player
  Future<void> joinPlayer(String roomCode, String playerId, Map<String, dynamic> playerData) async {
    await roomRef(roomCode).child('players').child(playerId).set(playerData);
  }

  // Remove a player (like removing bot, or client leaving)
  Future<void> removePlayer(String roomCode, String playerId) async {
    await roomRef(roomCode).child('players').child(playerId).remove();
  }
}
