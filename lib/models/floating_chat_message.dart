import 'package:flutter/material.dart';

class FloatingChatMessage {
  final String id;              // Unique identifier
  final String playerName;      // Sender name
  final String message;         // Message text
  final Color playerColor;      // Color for player name
  final bool isCorrectGuess;    // Green styling if true
  final bool isCorrectGuesserChat; // Green styling, no checkmark if true
  final bool isSystemMessage;   // Blue styling if true
  final bool isWarningMessage;  // Orange styling if true (for "Drawing too fast" warning)
  final bool isLike;            // Green text for thumbs up
  final bool isDislike;         // Red text for thumbs down
  final DateTime timestamp;     // For auto-dismiss

  const FloatingChatMessage({
    required this.id,
    required this.playerName,
    required this.message,
    required this.playerColor,
    this.isCorrectGuess = false,
    this.isCorrectGuesserChat = false,
    this.isSystemMessage = false,
    this.isWarningMessage = false,
    this.isLike = false,
    this.isDislike = false,
    required this.timestamp,
  });
}
