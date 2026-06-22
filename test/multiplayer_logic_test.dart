import 'package:flutter_test/flutter_test.dart';
import 'package:skribble_io/models/game_room.dart';
import 'package:skribble_io/models/player.dart';
import 'package:skribble_io/models/avatar.dart';
import 'package:skribble_io/services/points_service.dart';
import 'package:skribble_io/services/word_list.dart';

void main() {
  group('Multiplayer Logic & Serialization Tests', () {
    test('GameRoom JSON Serialization/Deserialization', () {
      final room = GameRoom(
        id: 'test_room',
        hostId: 'host_123',
        status: GameStatus.choosing,
        currentRound: 2,
        rounds: 4,
        drawTime: 60,
        timeRemaining: 45,
        currentWord: 'flutter',
        currentHint: '_ _ _ _ _ _ _',
        wordChoices: const ['dart', 'flutter', 'widget'],
        currentDrawerId: 'drawer_1',
        customWords: 'test,words',
        drawerOrder: const ['drawer_1', 'drawer_2'],
      );

      final json = room.toJson();
      final parsed = GameRoom.fromJson(json);

      expect(parsed.id, 'test_room');
      expect(parsed.hostId, 'host_123');
      expect(parsed.status, GameStatus.choosing);
      expect(parsed.currentRound, 2);
      expect(parsed.rounds, 4);
      expect(parsed.drawTime, 60);
      expect(parsed.timeRemaining, 45);
      expect(parsed.currentWord, 'flutter');
      expect(parsed.currentHint, '_ _ _ _ _ _ _');
      expect(parsed.wordChoices, const ['dart', 'flutter', 'widget']);
      expect(parsed.currentDrawerId, 'drawer_1');
      expect(parsed.customWords, 'test,words');
      expect(parsed.drawerOrder, const ['drawer_1', 'drawer_2']);
    });

    test('Player JSON Serialization/Deserialization', () {
      final player = Player(
        id: 'player_abc',
        name: 'Gamer',
        score: 120,
        lastTurnScore: 40,
        streak: 3,
        isDrawing: true,
        hasGuessed: false,
        isHost: true,
        isBot: false,
        avatar: const Avatar(bodyColorIndex: 2, eyesIndex: 4, mouthIndex: 1),
      );

      final json = player.toJson();
      final parsed = Player.fromJson(json);

      expect(parsed.id, 'player_abc');
      expect(parsed.name, 'Gamer');
      expect(parsed.score, 120);
      expect(parsed.lastTurnScore, 40);
      expect(parsed.streak, 3);
      expect(parsed.isDrawing, true);
      expect(parsed.hasGuessed, false);
      expect(parsed.isHost, true);
      expect(parsed.isBot, false);
      expect(parsed.avatar.bodyColorIndex, 2);
      expect(parsed.avatar.eyesIndex, 4);
      expect(parsed.avatar.mouthIndex, 1);
    });

    test('Points Calculation Logic', () {
      // Guesser points
      final guessPointsStart = PointsService.calculateGuesserPoints(secondsElapsed: 0, totalSeconds: 60);
      final guessPointsMid = PointsService.calculateGuesserPoints(secondsElapsed: 30, totalSeconds: 60);
      final guessPointsEnd = PointsService.calculateGuesserPoints(secondsElapsed: 60, totalSeconds: 60);

      expect(guessPointsStart, 150); // 100 + (150-100)*1.0 = 150
      expect(guessPointsMid, 125);   // 100 + (150-100)*0.5 = 125
      expect(guessPointsEnd, 100);   // 100 + (150-100)*0.0 = 100

      // Streak bonus check
      final guessPointsWithStreak = PointsService.calculateGuesserPoints(secondsElapsed: 0, totalSeconds: 60, streak: 3);
      expect(guessPointsWithStreak, 175); // 150 + 25 = 175

      // Drawer points
      final drawerPointsNone = PointsService.calculateDrawerPoints(correctGuessers: 0, firstGuessTime: 5);
      final drawerPointsFew = PointsService.calculateDrawerPoints(correctGuessers: 2, firstGuessTime: 25, totalPlayers: 5);
      final drawerPointsPerfectSpeed = PointsService.calculateDrawerPoints(correctGuessers: 5, firstGuessTime: 10, totalPlayers: 5);

      expect(drawerPointsNone, 0);
      expect(drawerPointsFew, 20); // 2 * 10 = 20
      expect(drawerPointsPerfectSpeed, 100); // 5*10 + 20 (speed) + 30 (perfect) = 100 (capped)
    });

    test('Word Distance and Close Guess Detection', () {
      // Levenshtein distance
      expect(WordList.getLevenshteinDistance('apple', 'apple'), 0);
      expect(WordList.getLevenshteinDistance('apple', 'aple'), 1);
      expect(WordList.getLevenshteinDistance('apple', 'banana'), 5);

      // Typo/Close checks
      expect(WordList.isClose('aple', 'apple'), true);
      expect(WordList.isClose('apple', 'apple'), false); // Exact is not "close" (it is correct)
    });
  });
}
