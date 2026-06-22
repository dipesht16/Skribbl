import 'avatar.dart';

class Player {
  final String id;
  final String name;
  final int score;
  final int lastTurnScore;
  final int streak;
  final bool isDrawing;
  final bool hasGuessed;
  final bool isHost;
  final bool isBot;
  final Avatar avatar;

  const Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.lastTurnScore = 0,
    this.streak = 0,
    this.isDrawing = false,
    this.hasGuessed = false,
    this.isHost = false,
    this.isBot = false,
    required this.avatar,
  });

  Player copyWith({
    String? id,
    String? name,
    int? score,
    int? lastTurnScore,
    int? streak,
    bool? isDrawing,
    bool? hasGuessed,
    bool? isHost,
    bool? isBot,
    Avatar? avatar,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      lastTurnScore: lastTurnScore ?? this.lastTurnScore,
      streak: streak ?? this.streak,
      isDrawing: isDrawing ?? this.isDrawing,
      hasGuessed: hasGuessed ?? this.hasGuessed,
      isHost: isHost ?? this.isHost,
      isBot: isBot ?? this.isBot,
      avatar: avatar ?? this.avatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'lastTurnScore': lastTurnScore,
      'streak': streak,
      'isDrawing': isDrawing,
      'hasGuessed': hasGuessed,
      'isHost': isHost,
      'isBot': isBot,
      'avatar': avatar.toJson(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Player',
      score: json['score'] as int? ?? 0,
      lastTurnScore: json['lastTurnScore'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      isDrawing: json['isDrawing'] as bool? ?? false,
      hasGuessed: json['hasGuessed'] as bool? ?? false,
      isHost: json['isHost'] as bool? ?? false,
      isBot: json['isBot'] as bool? ?? false,
      avatar: json['avatar'] != null
          ? Avatar.fromJson(Map<String, dynamic>.from(json['avatar'] as Map))
          : Avatar.random(),
    );
  }
}
