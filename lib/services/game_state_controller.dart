import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/avatar.dart';
import '../models/chat_message.dart';
import '../models/draw_point.dart';
import '../models/game_room.dart';
import '../models/player.dart';
import 'bot_manager.dart';
import 'word_list.dart';
import 'firebase_game_service.dart';

class GameStateController extends ChangeNotifier {
  GameRoom _room = const GameRoom(id: 'local_room', hostId: 'player_1');
  List<Player> _players = [];
  List<DrawPoint> _drawingPoints = [];
  List<ChatMessage> _chatMessages = [];
  Player _localPlayer = Player(id: 'player_1', name: 'Player', avatar: Avatar.random(), isHost: true);

  Timer? _gameTimer;
  Timer? _botDrawTimer;
  int _currentDrawerIndex = 0;
  List<DrawPoint> _botPendingDrawing = [];
  int _botDrawIndex = 0;
  final Set<int> _revealedHintIndices = {};

  // For networking
  bool _isNetworkGame = false;
  bool _isServer = false;

  // Firebase integration
  bool _isFirebaseGame = false;
  bool _isHost = false;
  String? _roomCode;
  final FirebaseGameService _firebaseService = FirebaseGameService();

  StreamSubscription? _roomSubscription;
  StreamSubscription? _drawingPointsSubscription;
  StreamSubscription? _drawingPointsAddedSubscription;
  StreamSubscription? _guessesSubscription;
  StreamSubscription? _wordSelectionSubscription;

  GameStateController() {
    // Start with a default set of players including the local player and some bots
    _players = [_localPlayer];
    _addBotInternal('DaVinci (Bot)');
    _addBotInternal('Picasso (Bot)');
    _addBotInternal('Doodler (Bot)');
  }

  // Getters
  GameRoom get room => _room;
  List<Player> get players => _players;
  List<DrawPoint> get drawingPoints => _drawingPoints;
  List<ChatMessage> get chatMessages => _chatMessages;
  Player get localPlayer => _localPlayer;
  bool get isNetworkGame => _isNetworkGame;
  bool get isServer => _isServer;
  bool get isFirebaseGame => _isFirebaseGame;
  bool get isHost => _isHost;
  String? get roomCode => _roomCode;

  // Local actions
  void updateLocalPlayer(String name, Avatar avatar) {
    _localPlayer = _localPlayer.copyWith(name: name, avatar: avatar);
    final idx = _players.indexWhere((p) => p.id == _localPlayer.id);
    if (idx != -1) {
      _players[idx] = _players[idx].copyWith(name: name, avatar: avatar);
    }
    notifyListeners();
  }

  void setLobbySettings({int? rounds, int? drawTime, String? customWords}) {
    _room = _room.copyWith(
      rounds: rounds ?? _room.rounds,
      drawTime: drawTime ?? _room.drawTime,
      customWords: customWords ?? _room.customWords,
    );
    notifyListeners();
    _syncToFirebase();
  }

  void addBot() {
    if (_players.length >= 10) return;
    final bot = BotManager.createBot();
    _players.add(bot);
    addSystemMessage('${bot.name} joined the room.');
    notifyListeners();
  }

  void removeBot(String botId) {
    final idx = _players.indexWhere((p) => p.id == botId);
    if (idx != -1) {
      final name = _players[idx].name;
      _players.removeAt(idx);
      addSystemMessage('$name left the room.');
      notifyListeners();
    }
  }

  void _addBotInternal(String name) {
    final id = 'bot_${Random().nextInt(1000000)}';
    _players.add(Player(
      id: id,
      name: name,
      isBot: true,
      avatar: Avatar.random(),
    ));
  }

  // --- GAME LOOP LOGIC ---

  void startGame() {
    if (_players.length < 2) {
      addSystemMessage('Need at least 2 players to start.');
      return;
    }
    _room = _room.copyWith(
      status: GameStatus.choosing,
      currentRound: 1,
      timeRemaining: 15, // 15 seconds to choose a word
    );
    _currentDrawerIndex = 0;
    _startChoosingPhase();
  }

  void _startChoosingPhase() {
    _cancelTimers();
    _drawingPoints.clear();
    _revealedHintIndices.clear();

    // Reset player guessed status
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(
        isDrawing: false,
        hasGuessed: false,
        lastTurnScore: 0,
      );
    }

    final drawer = _players[_currentDrawerIndex % _players.length];
    final drawerIdx = _players.indexWhere((p) => p.id == drawer.id);
    _players[drawerIdx] = _players[drawerIdx].copyWith(isDrawing: true);

    final choices = WordList.getWordChoices(_room.customWords);
    _room = _room.copyWith(
      status: GameStatus.choosing,
      currentDrawerId: drawer.id,
      wordChoices: choices,
      currentWord: '',
      currentHint: '',
      timeRemaining: 15,
    );

    addSystemMessage('${drawer.name} is choosing a word...');
    notifyListeners();

    if (_isFirebaseGame && _isHost && _roomCode != null) {
      _firebaseService.clearDrawingPoints(_roomCode!);
      _firebaseService.roomRef(_roomCode!).child('guesses').remove();
    }
    _syncToFirebase();

    // Start 15s choosing timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_room.status != GameStatus.choosing) {
        timer.cancel();
        return;
      }

      int remaining = _room.timeRemaining - 1;
      if (remaining <= 0) {
        // Auto-select first word
        timer.cancel();
        final selected = _room.wordChoices.isNotEmpty ? _room.wordChoices[0] : 'apple';
        selectWord(selected);
      } else {
        _room = _room.copyWith(timeRemaining: remaining);
        notifyListeners();
        _syncToFirebase();
      }
    });

    // If bot is choosing, let it choose instantly (or after 2 seconds)
    if (drawer.isBot) {
      Timer(const Duration(seconds: 2), () {
        if (_room.status == GameStatus.choosing && _room.currentDrawerId == drawer.id) {
          final chosen = choices[Random().nextInt(choices.length)];
          selectWord(chosen);
        }
      });
    }
  }

  void selectWord(String word) {
    if (_isFirebaseGame && !_isHost && _roomCode != null) {
      _firebaseService.selectWord(_roomCode!, word);
      return;
    }

    _cancelTimers();
    final drawer = _players[_currentDrawerIndex % _players.length];

    _room = _room.copyWith(
      status: GameStatus.drawing,
      currentWord: word.toLowerCase(),
      currentHint: WordList.getHint(word, _revealedHintIndices),
      timeRemaining: _room.drawTime,
    );

    addSystemMessage('${drawer.name} is drawing now!');
    notifyListeners();
    _syncToFirebase();

    // Setup bot drawing path if the drawer is a bot
    if (drawer.isBot) {
      _botPendingDrawing = BotManager.generateBotDrawing(word);
      _botDrawIndex = 0;
      final int totalTicks = _room.drawTime * 5; // 5 drawing ticks per second
      final int pointsPerTick = (_botPendingDrawing.length / (totalTicks * 0.75)).ceil().clamp(1, 15);

      _botDrawTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (_room.status != GameStatus.drawing) {
          timer.cancel();
          return;
        }

        if (_botDrawIndex < _botPendingDrawing.length) {
          final List<DrawPoint> nextPoints = [];
          for (int i = 0; i < pointsPerTick && _botDrawIndex < _botPendingDrawing.length; i++) {
            nextPoints.add(_botPendingDrawing[_botDrawIndex]);
            _botDrawIndex++;
          }
          _drawingPoints.addAll(nextPoints);
          notifyListeners();

          if (_isFirebaseGame && _roomCode != null) {
            for (final pt in nextPoints) {
              _firebaseService.addDrawingPoint(_roomCode!, pt.toJson());
            }
          }
        } else {
          timer.cancel();
        }
      });
    }

    // Start 1s game loop timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_room.status != GameStatus.drawing) {
        timer.cancel();
        return;
      }

      int remaining = _room.timeRemaining - 1;
      _room = _room.copyWith(timeRemaining: remaining);

      // Bot guesses simulation
      _simulateBotGuesses(remaining);

      // Periodically reveal letters
      _checkHintReveal(remaining);

      // Check if turn should end early (all guessers guessed)
      final activeGuessers = _players.where((p) => p.id != _room.currentDrawerId);
      final allGuessed = activeGuessers.isNotEmpty && activeGuessers.every((p) => p.hasGuessed);

      if (remaining <= 0 || allGuessed) {
        _endTurn();
      } else {
        notifyListeners();
        _syncToFirebase();
      }
    });
  }

  void _checkHintReveal(int remaining) {
    final word = _room.currentWord;
    if (word.isEmpty) return;

    // Total time divided into segments
    final total = _room.drawTime;
    final int revealInterval = (total / 3).round();

    // Reveal one letter at 2/3 time and another at 1/3 time
    if (remaining == (revealInterval * 2) && _revealedHintIndices.length < (word.length * 0.3).ceil()) {
      _revealRandomLetter();
    } else if (remaining == revealInterval && _revealedHintIndices.length < (word.length * 0.6).ceil()) {
      _revealRandomLetter();
    }
  }

  void _revealRandomLetter() {
    final word = _room.currentWord;
    final List<int> hiddenIndices = [];
    for (int i = 0; i < word.length; i++) {
      if (word[i] != ' ' && !_revealedHintIndices.contains(i)) {
        hiddenIndices.add(i);
      }
    }

    if (hiddenIndices.isNotEmpty) {
      final index = hiddenIndices[Random().nextInt(hiddenIndices.length)];
      _revealedHintIndices.add(index);
      _room = _room.copyWith(
        currentHint: WordList.getHint(word, _revealedHintIndices),
      );
    }
  }

  void _simulateBotGuesses(int remaining) {
    final drawerId = _room.currentDrawerId;
    final target = _room.currentWord;

    for (var bot in _players) {
      if (!bot.isBot || bot.id == drawerId || bot.hasGuessed) continue;

      // Check if bot makes a guess
      final guess = BotManager.generateBotGuess(
        bot: bot,
        targetWord: target,
        revealedIndices: _revealedHintIndices,
        timeRemaining: remaining,
        totalTime: _room.drawTime,
        previousGuesses: [],
      );

      if (guess != null) {
        submitGuess(bot.id, guess);
      }
    }
  }

  void _endTurn() {
    _cancelTimers();
    _room = _room.copyWith(
      status: GameStatus.roundEnd,
      timeRemaining: 6, // 6 seconds review phase
    );

    // Score calculations
    final drawerId = _room.currentDrawerId;
    final guessers = _players.where((p) => p.id != drawerId && p.hasGuessed).toList();
    final totalGuessers = _players.where((p) => p.id != drawerId).length;

    // 1. Award Drawer points
    if (drawerId != null && guessers.isNotEmpty) {
      final drawerIdx = _players.indexWhere((p) => p.id == drawerId);
      if (drawerIdx != -1) {
        // Drawer gets points proportional to % of players who guessed
        final drawerPoints = (200 * (guessers.length / totalGuessers)).round();
        final p = _players[drawerIdx];
        _players[drawerIdx] = p.copyWith(
          score: p.score + drawerPoints,
          lastTurnScore: drawerPoints,
        );
      }
    }

    addSystemMessage('The word was: ${_room.currentWord.toUpperCase()}');
    notifyListeners();
    _syncToFirebase();

    // Start 6s round review timer
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_room.status != GameStatus.roundEnd) {
        timer.cancel();
        return;
      }

      int remaining = _room.timeRemaining - 1;
      if (remaining <= 0) {
        _nextTurn();
      } else {
        _room = _room.copyWith(timeRemaining: remaining);
        notifyListeners();
        _syncToFirebase();
      }
    });
  }

  void _nextTurn() {
    _currentDrawerIndex++;

    // Check if round is finished (everyone has drawn)
    if (_currentDrawerIndex >= _players.length) {
      _currentDrawerIndex = 0;
      final nextRound = _room.currentRound + 1;
      if (nextRound > _room.rounds) {
        // Game Over! Show podium
        _endGame();
        return;
      } else {
        _room = _room.copyWith(currentRound: nextRound);
        addSystemMessage('--- ROUND $nextRound ---');
      }
    }

    _startChoosingPhase();
  }

  void _endGame() {
    _cancelTimers();
    // Sort players by final score
    _players.sort((a, b) => b.score.compareTo(a.score));
    _room = _room.copyWith(
      status: GameStatus.gameEnd,
      timeRemaining: 0,
    );
    addSystemMessage('The game has ended! Congratulations to the winners!');
    notifyListeners();
  }

  void restartGame() {
    _cancelTimers();
    _drawingPoints.clear();
    _chatMessages.clear();
    _revealedHintIndices.clear();

    // Reset scores
    for (int i = 0; i < _players.length; i++) {
      _players[i] = _players[i].copyWith(
        score: 0,
        lastTurnScore: 0,
        isDrawing: false,
        hasGuessed: false,
      );
    }

    _room = _room.copyWith(
      status: GameStatus.lobby,
      currentRound: 1,
      currentWord: '',
      currentHint: '',
      wordChoices: const [],
      currentDrawerId: null,
    );

    addSystemMessage('Welcome back to the lobby!');
    notifyListeners();

    if (_isFirebaseGame && _isHost && _roomCode != null) {
      _firebaseService.clearDrawingPoints(_roomCode!);
      _firebaseService.roomRef(_roomCode!).child('guesses').remove();
    }
    _syncToFirebase();
  }

  // --- ACTIONS ---

  void addDrawPoint(DrawPoint point) {
    if (_room.status != GameStatus.drawing) return;
    if (_room.currentDrawerId != _localPlayer.id) return; // Only drawer can draw

    if (_isFirebaseGame && _roomCode != null) {
      _firebaseService.addDrawingPoint(_roomCode!, point.toJson());
      _drawingPoints.add(point);
      notifyListeners();
      return;
    }

    _drawingPoints.add(point);
    notifyListeners();
  }

  void clearCanvas() {
    if (_room.status != GameStatus.drawing) return;
    if (_room.currentDrawerId != _localPlayer.id) return;

    if (_isFirebaseGame && _roomCode != null) {
      _firebaseService.clearDrawingPoints(_roomCode!);
      _drawingPoints.clear();
      notifyListeners();
      return;
    }

    _drawingPoints.clear();
    notifyListeners();
  }

  void submitGuess(String playerId, String guessText) {
    if (_room.status != GameStatus.drawing) return;

    if (_isFirebaseGame && !_isHost && _roomCode != null) {
      // Joiners send guesses to Host via Firebaseguesses queue
      _firebaseService.roomRef(_roomCode!).child('guesses').push().set({
        'playerId': playerId,
        'text': guessText,
      });
      return;
    }

    final playerIdx = _players.indexWhere((p) => p.id == playerId);
    if (playerIdx == -1) return;
    final player = _players[playerIdx];

    if (playerId == _room.currentDrawerId) {
      // Drawer can't guess! It's just a normal message
      addChatMessage(player.name, guessText, ChatMessageType.chat);
      return;
    }

    if (player.hasGuessed) {
      // Already guessed correctly, any text is standard chat
      addChatMessage(player.name, guessText, ChatMessageType.chat);
      return;
    }

    final String cleanGuess = guessText.trim().toLowerCase();
    final String cleanTarget = _room.currentWord.trim().toLowerCase();

    if (cleanGuess == cleanTarget) {
      // CORRECT GUESS!
      // Calculate guess speed bonus points
      final alreadyGuessedCount = _players.where((p) => p.hasGuessed).length;
      int guessPoints = 100; // Base score
      if (alreadyGuessedCount == 0) guessPoints = 300; // 1st
      else if (alreadyGuessedCount == 1) guessPoints = 250; // 2nd
      else if (alreadyGuessedCount == 2) guessPoints = 200; // 3rd
      else if (alreadyGuessedCount == 3) guessPoints = 150; // 4th

      _players[playerIdx] = player.copyWith(
        hasGuessed: true,
        score: player.score + guessPoints,
        lastTurnScore: guessPoints,
      );

      // System shows: "X has guessed the word!"
      addChatMessage(player.name, 'guessed the word!', ChatMessageType.correct);
      notifyListeners();
      _syncToFirebase();
    } else if (WordList.isClose(cleanGuess, cleanTarget)) {
      // CLOSE GUESS!
      // Private message to that player, or system warning visible to that player
      addChatMessage(player.name, guessText, ChatMessageType.chat);
      // System notification: "X is close!" (visible to all, standard skribbl behavior)
      addChatMessage(player.name, 'is close!', ChatMessageType.close);
      notifyListeners();
      _syncToFirebase();
    } else {
      // INCORRECT GUESS - normal chat message
      addChatMessage(player.name, guessText, ChatMessageType.chat);
    }
  }

  void addChatMessage(String sender, String text, ChatMessageType type) {
    _chatMessages.add(ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      senderName: sender,
      text: text,
      type: type,
    ));
    // Limit chat size
    if (_chatMessages.length > 50) {
      _chatMessages.removeAt(0);
    }
    notifyListeners();
    _syncToFirebase();
  }

  void addSystemMessage(String text) {
    addChatMessage('System', text, ChatMessageType.system);
  }

  void loadServerState(GameRoom serverRoom, List<Player> serverPlayers, List<ChatMessage> serverChat) {
    _room = serverRoom;
    _players = serverPlayers;
    _chatMessages = serverChat;
    notifyListeners();
  }

  void addDrawPointFromNetwork(DrawPoint point) {
    _drawingPoints.add(point);
    notifyListeners();
  }

  void clearCanvasFromNetwork() {
    _drawingPoints.clear();
    notifyListeners();
  }

  void _syncToFirebase() {
    if (!_isFirebaseGame || !_isHost || _roomCode == null) return;

    final Map<String, dynamic> playersMap = {};
    for (final p in _players) {
      playersMap[p.id] = p.toJson();
    }

    final Map<String, dynamic> chatMap = {};
    for (int i = 0; i < _chatMessages.length; i++) {
      final msg = _chatMessages[i];
      chatMap['msg_$i'] = msg.toJson();
    }

    _firebaseService.updateRoom(_roomCode!, {
      'room': _room.toJson(),
      'players': playersMap,
      'chatMessages': chatMap,
    });
  }

  void initializeFirebaseHost(String code) {
    cleanupFirebase();
    _isNetworkGame = true;
    _isFirebaseGame = true;
    _isHost = true;
    _roomCode = code;

    _players = [_localPlayer.copyWith(isHost: true)];
    _chatMessages = [];
    _drawingPoints = [];

    _firebaseService.roomRef(code).remove().then((_) {
      _syncToFirebase();
      addSystemMessage('Room created. Share code: $code');

      _guessesSubscription = _firebaseService.roomRef(code)
          .child('guesses')
          .onChildAdded
          .listen((event) {
            final val = event.snapshot.value;
            if (val != null) {
              final map = Map<String, dynamic>.from(val as Map);
              final playerId = map['playerId'] as String;
              final text = map['text'] as String;
              submitGuess(playerId, text);
            }
          });

      _wordSelectionSubscription = _firebaseService.roomRef(code)
          .child('selectedWord')
          .onValue
          .listen((event) {
            final val = event.snapshot.value;
            if (val != null && val is String && val.isNotEmpty) {
              selectWord(val);
              _firebaseService.clearSelectedWord(code);
            }
          });

      _roomSubscription = _firebaseService.roomRef(code)
          .child('players')
          .onChildAdded
          .listen((event) {
            final val = event.snapshot.value;
            if (val != null) {
              final newPlayer = Player.fromJson(Map<String, dynamic>.from(val as Map));
              if (!_players.any((p) => p.id == newPlayer.id)) {
                _players.add(newPlayer);
                addSystemMessage('${newPlayer.name} joined the lobby.');
                _syncToFirebase();
              }
            }
          });
    });
  }

  void initializeFirebaseJoiner(String code) {
    cleanupFirebase();
    _isNetworkGame = true;
    _isFirebaseGame = true;
    _isHost = false;
    _roomCode = code;

    _players = [];
    _chatMessages = [];
    _drawingPoints = [];

    _roomSubscription = _firebaseService.roomRef(code)
        .onValue
        .listen((event) {
          final val = event.snapshot.value;
          if (val != null) {
            final map = Map<String, dynamic>.from(val as Map);

            if (map.containsKey('room')) {
              _room = GameRoom.fromJson(Map<String, dynamic>.from(map['room'] as Map));
            }

            if (map.containsKey('players')) {
              final playersMap = Map<String, dynamic>.from(map['players'] as Map);
              _players = playersMap.values.map((p) {
                return Player.fromJson(Map<String, dynamic>.from(p as Map));
              }).toList();
            }

            if (map.containsKey('chatMessages')) {
              final chatMap = Map<String, dynamic>.from(map['chatMessages'] as Map);
              final List<ChatMessage> syncedChat = [];
              final sortedKeys = chatMap.keys.toList()..sort();
              for (final k in sortedKeys) {
                syncedChat.add(ChatMessage.fromJson(Map<String, dynamic>.from(chatMap[k] as Map)));
              }
              _chatMessages = syncedChat;
            }

            notifyListeners();
          }
        });

    _drawingPointsSubscription = _firebaseService.roomRef(code)
        .child('drawingPoints')
        .onValue
        .listen((event) {
          if (event.snapshot.value == null) {
            _drawingPoints.clear();
            notifyListeners();
          }
        });

    _drawingPointsAddedSubscription = _firebaseService.roomRef(code)
        .child('drawingPoints')
        .onChildAdded
        .listen((event) {
          if (_room.currentDrawerId == _localPlayer.id) {
            return;
          }
          final val = event.snapshot.value;
          if (val != null) {
            final point = DrawPoint.fromJson(Map<String, dynamic>.from(val as Map));
            _drawingPoints.add(point);
            notifyListeners();
          }
        });
  }

  void cleanupFirebase() {
    _cancelTimers();
    _roomSubscription?.cancel();
    _drawingPointsSubscription?.cancel();
    _drawingPointsAddedSubscription?.cancel();
    _guessesSubscription?.cancel();
    _wordSelectionSubscription?.cancel();

    _isFirebaseGame = false;
    _isHost = false;
    _isNetworkGame = false;
    _roomCode = null;
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _botDrawTimer?.cancel();
  }

  @override
  void dispose() {
    cleanupFirebase();
    super.dispose();
  }
}
