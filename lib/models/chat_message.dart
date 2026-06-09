enum ChatMessageType {
  chat,
  correct,
  close,
  system
}

class ChatMessage {
  final String id;
  final String senderName;
  final String text;
  final ChatMessageType type;
  final DateTime timestamp;

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
      id: json['id'] as String,
      senderName: json['senderName'] as String,
      text: json['text'] as String,
      type: ChatMessageType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
