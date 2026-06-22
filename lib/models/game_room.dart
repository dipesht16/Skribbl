enum GameStatus {
  lobby,
  choosing, // Drawer choosing one of three words
  drawing,  // Game is active, drawer is drawing, others guessing
  roundEnd, // Turn ended, word is revealed, scores added
  gameEnd   // All rounds completed, podium displayed
}

class GameRoom {
  final String id;
  final String hostId;
  final int rounds;
  final int currentRound;
  final int drawTime;
  final int timeRemaining;
  final GameStatus status;
  final String currentWord;
  final String currentHint;
  final List<String> wordChoices;
  final String? currentDrawerId;
  final String customWords;
  final List<String> drawerOrder;

  const GameRoom({
    required this.id,
    required this.hostId,
    this.rounds = 2,
    this.currentRound = 1,
    this.drawTime = 80,
    this.timeRemaining = 80,
    this.status = GameStatus.lobby,
    this.currentWord = '',
    this.currentHint = '',
    this.wordChoices = const [],
    this.currentDrawerId,
    this.customWords = '',
    this.drawerOrder = const [],
  });

  GameRoom copyWith({
    String? id,
    String? hostId,
    int? rounds,
    int? currentRound,
    int? drawTime,
    int? timeRemaining,
    GameStatus? status,
    String? currentWord,
    String? currentHint,
    List<String>? wordChoices,
    String? currentDrawerId,
    String? customWords,
    List<String>? drawerOrder,
  }) {
    return GameRoom(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      rounds: rounds ?? this.rounds,
      currentRound: currentRound ?? this.currentRound,
      drawTime: drawTime ?? this.drawTime,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      status: status ?? this.status,
      currentWord: currentWord ?? this.currentWord,
      currentHint: currentHint ?? this.currentHint,
      wordChoices: wordChoices ?? this.wordChoices,
      currentDrawerId: currentDrawerId ?? this.currentDrawerId,
      customWords: customWords ?? this.customWords,
      drawerOrder: drawerOrder ?? this.drawerOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'rounds': rounds,
      'currentRound': currentRound,
      'drawTime': drawTime,
      'timeRemaining': timeRemaining,
      'status': status.name,
      'currentWord': currentWord,
      'currentHint': currentHint,
      'wordChoices': wordChoices,
      'currentDrawerId': currentDrawerId,
      'customWords': customWords,
      'drawerOrder': drawerOrder,
    };
  }

  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      rounds: json['rounds'] as int? ?? 2,
      currentRound: json['currentRound'] as int? ?? 1,
      drawTime: json['drawTime'] as int? ?? 80,
      timeRemaining: json['timeRemaining'] as int? ?? 80,
      status: GameStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameStatus.lobby,
      ),
      currentWord: json['currentWord'] as String? ?? '',
      currentHint: json['currentHint'] as String? ?? '',
      wordChoices: json['wordChoices'] != null ? List<String>.from(json['wordChoices'] as List) : const [],
      currentDrawerId: json['currentDrawerId'] as String?,
      customWords: json['customWords'] as String? ?? '',
      drawerOrder: json['drawerOrder'] != null ? List<String>.from(json['drawerOrder'] as List) : const [],
    );
  }
}
