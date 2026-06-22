enum ChatMessageType {
  chat,
  correct,
  close,
  system,
  correctGuesserChat,
  like,
  dislike
}

class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;

  bool get isCorrectGuess => type == ChatMessageType.correct;

  ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderName': senderName,
      'text': text,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Someone',
      text: json['text'] as String? ?? '',
      type: ChatMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChatMessageType.chat,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
