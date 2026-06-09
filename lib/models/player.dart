import 'avatar.dart';

class Player {
  final String id;
  final String name;
  final int score;
  final int lastTurnScore;
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
      'isDrawing': isDrawing,
      'hasGuessed': hasGuessed,
      'isHost': isHost,
      'isBot': isBot,
      'avatar': avatar.toJson(),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      score: json['score'] as int,
      lastTurnScore: json['lastTurnScore'] as int,
      isDrawing: json['isDrawing'] as bool,
      hasGuessed: json['hasGuessed'] as bool,
      isHost: json['isHost'] as bool,
      isBot: json['isBot'] as bool,
      avatar: Avatar.fromJson(json['avatar'] as Map<String, dynamic>),
    );
  }
}
