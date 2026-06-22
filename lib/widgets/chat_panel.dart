import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatPanel extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onSendMessage;
  final bool isDrawing;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.onSendMessage,
    required this.isDrawing,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSendMessage(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF34495E),
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: widget.messages.length,
                itemBuilder: (context, index) {
                  final message = widget.messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          if (!widget.isDrawing) _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    Color bgColor;
    Color textColor;
    Color nameColor;

    if (message.isCorrectGuess || message.type == ChatMessageType.correctGuesserChat) {
      bgColor = const Color(0xFFD4EDDA);
      textColor = const Color(0xFF155724);
      nameColor = const Color(0xFF28A745);
    } else if (message.type == ChatMessageType.close) {
      bgColor = const Color(0xFFFFF3CD);
      textColor = const Color(0xFF856404);
      nameColor = const Color(0xFFD35400);
    } else if (message.type == ChatMessageType.system) {
      bgColor = const Color(0xFFD1ECF1);
      textColor = const Color(0xFF0C5460);
      nameColor = const Color(0xFF2980B9);
    } else if (message.type == ChatMessageType.like) {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      nameColor = const Color(0xFF4CAF50);
    } else if (message.type == ChatMessageType.dislike) {
      bgColor = const Color(0xFFFFEBEE);
      textColor = const Color(0xFFC62828);
      nameColor = const Color(0xFFF44336);
    } else {
      bgColor = const Color(0xFFF1F3F5);
      textColor = const Color(0xFF2C3E50);
      nameColor = const Color(0xFF4A90E2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${message.senderName}: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: nameColor,
              ),
            ),
            TextSpan(
              text: message.text,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontStyle: message.type == ChatMessageType.system ? FontStyle.italic : FontStyle.normal,
                fontWeight: (message.isCorrectGuess ||
                        message.type == ChatMessageType.correctGuesserChat ||
                        message.type == ChatMessageType.close ||
                        message.type == ChatMessageType.like ||
                        message.type == ChatMessageType.dislike)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (message.isCorrectGuess)
              const TextSpan(
                text: ' ✓',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF28A745),
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (message.type == ChatMessageType.like)
              const TextSpan(
                text: ' 👍',
                style: TextStyle(fontSize: 14),
              ),
            if (message.type == ChatMessageType.dislike)
              const TextSpan(
                text: ' 👎',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE9ECEF), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your guess...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF95A5A6)),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4A90E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
