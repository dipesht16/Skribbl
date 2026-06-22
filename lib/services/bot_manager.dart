import 'dart:math';
import 'package:flutter/material.dart';
import '../models/draw_point.dart';
import '../models/player.dart';
import '../models/avatar.dart';
import 'word_list.dart';

class BotManager {
  static const List<String> botNames = [
    "Doodler", "SketchBot", "DaVinci", "Picasso", "ColorMaster",
    "DrawClassic", "ScribbleExpert", "ArtisticAI", "BrushKing", "CanvasQueen"
  ];

  static final Random _random = Random();

  /// Generates a random Bot Player
  static Player createBot() {
    final name = botNames[_random.nextInt(botNames.length)];
    final id = 'bot_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1000)}';
    return Player(
      id: id,
      name: '$name (Bot)',
      isBot: true,
      avatar: Avatar.random(),
    );
  }

  /// Decides if a bot makes a guess in this second tick.
  /// Returns null if no guess is made, otherwise returns the guess string.
  /// If it returns the correct word, the bot has guessed correctly.
  static String? generateBotGuess({
    required Player bot,
    required String targetWord,
    required Set<int> revealedIndices,
    required int timeRemaining,
    required int totalTime,
    required List<String> previousGuesses,
  }) {
    // Bots guess occasionally. Chance is higher if time is running out, or letters are revealed.
    final double baseChance = 0.05; // 5% chance per second
    final double timeFactor = (totalTime - timeRemaining) / totalTime * 0.1;
    final double revealFactor = revealedIndices.length / targetWord.length * 0.15;
    final double guessChance = baseChance + timeFactor + revealFactor;

    if (_random.nextDouble() > guessChance) {
      return null;
    }

    // Determine guess type: Correct (35%), Close (20%), or Random Incorrect (45%)
    final roll = _random.nextDouble();
    if (roll < 0.35) {
      // Correct guess!
      return targetWord;
    } else if (roll < 0.55) {
      // Close guess: target word with a typo (e.g. missing last letter or swap)
      if (targetWord.length > 3) {
        final chars = targetWord.split('');
        if (_random.nextBool()) {
          // Remove last character
          chars.removeLast();
        } else {
          // Swap two characters
          final idx = _random.nextInt(chars.length - 1);
          final tmp = chars[idx];
          chars[idx] = chars[idx + 1];
          chars[idx + 1] = tmp;
        }
        return chars.join('');
      }
      return targetWord; // Fallback
    } else {
      // Random incorrect word from word pool (excluding target)
      String randomWord;
      int iterations = 0;
      do {
        randomWord = WordList.defaultWords[_random.nextInt(WordList.defaultWords.length)];
        iterations++;
      } while (randomWord.toLowerCase() == targetWord.toLowerCase() && iterations < 10);
      return randomWord;
    }
  }

  /// Generates lists of DrawPoints representing actual sketches of the chosen word
  static List<DrawPoint> generateBotDrawing(String word, {Color? customColor}) {
    final String cleanWord = word.trim().toLowerCase();
    final List<DrawPoint> points = [];

    void addLine(List<Offset> pathPoints, int argbColor, double strokeWidth, {bool isEraser = false}) {
      if (pathPoints.isEmpty) return;
      points.add(DrawPoint(
        x: pathPoints.first.dx,
        y: pathPoints.first.dy,
        colorValue: argbColor,
        strokeWidth: strokeWidth,
        isEraser: isEraser,
        isStart: true,
      ));
      for (int i = 1; i < pathPoints.length; i++) {
        points.add(DrawPoint(
          x: pathPoints[i].dx,
          y: pathPoints[i].dy,
          colorValue: argbColor,
          strokeWidth: strokeWidth,
          isEraser: isEraser,
          isStart: false,
        ));
      }
    }

    // DRAWING PRESETS
    if (cleanWord == 'house') {
      // 1. Square base (black)
      final wallColor = Colors.black.toARGB32();
      addLine([
        Offset(0.3, 0.7),
        Offset(0.7, 0.7),
        Offset(0.7, 0.4),
        Offset(0.3, 0.4),
        Offset(0.3, 0.7),
      ], wallColor, 4.0);

      // 2. Roof triangle (red)
      addLine([
        Offset(0.3, 0.4),
        Offset(0.5, 0.2),
        Offset(0.7, 0.4),
      ], Colors.red.toARGB32(), 4.0);

      // 3. Door (brown)
      addLine([
        Offset(0.46, 0.7),
        Offset(0.46, 0.55),
        Offset(0.54, 0.55),
        Offset(0.54, 0.7),
      ], Colors.brown.toARGB32(), 4.0);

      // 4. Window (blue)
      addLine([
        Offset(0.35, 0.46),
        Offset(0.43, 0.46),
        Offset(0.43, 0.52),
        Offset(0.35, 0.52),
        Offset(0.35, 0.46),
      ], Colors.blue.toARGB32(), 3.0);
    } 
    else if (cleanWord == 'sun') {
      final yellow = Colors.orangeAccent.toARGB32();
      // 1. Center Circle
      final List<Offset> circle = [];
      const double cx = 0.5;
      const double cy = 0.4;
      const double r = 0.12;
      for (int i = 0; i <= 20; i++) {
        double angle = (i * 2 * pi) / 20;
        circle.add(Offset(cx + r * cos(angle), cy + r * sin(angle)));
      }
      addLine(circle, yellow, 5.0);

      // 2. Rays
      for (int i = 0; i < 8; i++) {
        double angle = (i * 2 * pi) / 8;
        addLine([
          Offset(cx + (r + 0.02) * cos(angle), cy + (r + 0.02) * sin(angle)),
          Offset(cx + (r + 0.08) * cos(angle), cy + (r + 0.08) * sin(angle)),
        ], yellow, 3.0);
      }
    } 
    else if (cleanWord == 'car') {
      final blue = Colors.blue.toARGB32();
      final black = Colors.black.toARGB32();
      // 1. Lower Body
      addLine([
        Offset(0.2, 0.6),
        Offset(0.8, 0.6),
        Offset(0.75, 0.7),
        Offset(0.25, 0.7),
        Offset(0.2, 0.6),
      ], blue, 4.0);

      // 2. Cabin
      addLine([
        Offset(0.3, 0.6),
        Offset(0.38, 0.48),
        Offset(0.62, 0.48),
        Offset(0.7, 0.6),
      ], blue, 4.0);

      // 3. Wheels
      final List<Offset> w1 = [];
      final List<Offset> w2 = [];
      for (int i = 0; i <= 12; i++) {
        double angle = (i * 2 * pi) / 12;
        w1.add(Offset(0.35 + 0.06 * cos(angle), 0.7 + 0.06 * sin(angle)));
        w2.add(Offset(0.65 + 0.06 * cos(angle), 0.7 + 0.06 * sin(angle)));
      }
      addLine(w1, black, 5.0);
      addLine(w2, black, 5.0);
    } 
    else if (cleanWord == 'tree') {
      // 1. Brown Trunk
      addLine([
        Offset(0.48, 0.75),
        Offset(0.52, 0.75),
        Offset(0.52, 0.5),
        Offset(0.48, 0.5),
        Offset(0.48, 0.75),
      ], Colors.brown.toARGB32(), 6.0);

      // 2. Green Foliage (cloud shape)
      final green = Colors.green.toARGB32();
      addLine([
        Offset(0.5, 0.25),
        Offset(0.42, 0.3),
        Offset(0.38, 0.38),
        Offset(0.42, 0.48),
        Offset(0.5, 0.52),
        Offset(0.58, 0.48),
        Offset(0.62, 0.38),
        Offset(0.58, 0.3),
        Offset(0.5, 0.25),
      ], green, 6.0);
    } 
    else if (cleanWord == 'smiley') {
      final yellow = Colors.orange.toARGB32();
      final black = Colors.black.toARGB32();
      // Face circle
      final List<Offset> circle = [];
      for (int i = 0; i <= 24; i++) {
        double angle = (i * 2 * pi) / 24;
        circle.add(Offset(0.5 + 0.2 * cos(angle), 0.5 + 0.2 * sin(angle)));
      }
      addLine(circle, yellow, 4.0);

      // Left eye
      addLine([Offset(0.42, 0.43), Offset(0.42, 0.47)], black, 5.0);
      // Right eye
      addLine([Offset(0.58, 0.43), Offset(0.58, 0.47)], black, 5.0);

      // Smile
      final List<Offset> smile = [];
      for (int i = 0; i <= 10; i++) {
        double angle = pi + (i * pi) / 10;
        smile.add(Offset(0.5 + 0.1 * cos(angle), 0.53 - 0.07 * sin(angle)));
      }
      addLine(smile, black, 4.0);
    } 
    else if (cleanWord == 'cloud') {
      final gray = Colors.grey.shade400.toARGB32();
      addLine([
        Offset(0.35, 0.5),
        Offset(0.3, 0.44),
        Offset(0.35, 0.38),
        Offset(0.44, 0.36),
        Offset(0.5, 0.32),
        Offset(0.58, 0.36),
        Offset(0.65, 0.38),
        Offset(0.7, 0.44),
        Offset(0.65, 0.5),
        Offset(0.35, 0.5),
      ], gray, 5.0);
    }
    else if (cleanWord == 'star') {
      final gold = Colors.amber.toARGB32();
      addLine([
        Offset(0.5, 0.2),
        Offset(0.58, 0.38),
        Offset(0.78, 0.38),
        Offset(0.62, 0.5),
        Offset(0.68, 0.7),
        Offset(0.5, 0.58),
        Offset(0.32, 0.7),
        Offset(0.38, 0.5),
        Offset(0.22, 0.38),
        Offset(0.42, 0.38),
        Offset(0.5, 0.2),
      ], gold, 4.0);
    }
    else if (cleanWord == 'umbrella') {
      final purple = Colors.purple.toARGB32();
      final black = Colors.black.toARGB32();
      // Canopy arch
      final List<Offset> canopy = [];
      for (int i = 0; i <= 12; i++) {
        double angle = pi + (i * pi) / 12;
        canopy.add(Offset(0.5 + 0.22 * cos(angle), 0.5 - 0.15 * sin(angle)));
      }
      addLine(canopy, purple, 5.0);
      addLine([Offset(0.28, 0.5), Offset(0.72, 0.5)], purple, 4.0);

      // Handle shaft
      addLine([Offset(0.5, 0.5), Offset(0.5, 0.72)], black, 4.0);
      // Hook
      addLine([
        Offset(0.5, 0.72),
        Offset(0.47, 0.75),
        Offset(0.44, 0.72),
      ], black, 4.0);
    }
    else if (cleanWord == 'balloon') {
      final red = Colors.red.toARGB32();
      // Balloon body oval
      final List<Offset> oval = [];
      for (int i = 0; i <= 20; i++) {
        double angle = (i * 2 * pi) / 20;
        oval.add(Offset(0.5 + 0.12 * cos(angle), 0.4 + 0.16 * sin(angle)));
      }
      addLine(oval, red, 4.0);
      // Knot
      addLine([Offset(0.5, 0.56), Offset(0.48, 0.59), Offset(0.52, 0.59), Offset(0.5, 0.56)], red, 3.0);
      // String
      addLine([
        Offset(0.5, 0.59),
        Offset(0.48, 0.65),
        Offset(0.52, 0.71),
        Offset(0.5, 0.78),
      ], Colors.grey.toARGB32(), 2.0);
    }
    else {
      // PROCEDURAL SCRIBBLING FOR GENERIC WORDS (Draws a spiral/doodle so it feels active!)
      final List<Offset> doodle = [];
      final center = Offset(0.5, 0.45);
      final double maxRadius = 0.22;
      final int steps = 60;
      final color = Colors.deepPurple.toARGB32();

      for (int i = 0; i < steps; i++) {
        double theta = (i * 6 * pi) / steps;
        double r = (i * maxRadius) / steps;
        // Add tiny noise
        double nx = 0.015 * sin(theta * 5);
        double ny = 0.015 * cos(theta * 3);
        doodle.add(Offset(center.dx + r * cos(theta) + nx, center.dy + r * sin(theta) + ny));
      }
      addLine(doodle, color, 4.0);
    }

    return points;
  }
}
