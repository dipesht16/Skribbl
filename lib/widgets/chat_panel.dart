import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';

class ChatPanel extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onMessageSubmitted;
  final bool isInputEnabled;
  final String placeholder;

  const ChatPanel({
    super.key,
    required this.messages,
    required this.onMessageSubmitted,
    required this.isInputEnabled,
    this.placeholder = 'Type your guess here...',
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto scroll to bottom when new messages arrive
    if (oldWidget.messages.length != widget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onMessageSubmitted(text);
      _controller.clear();
      // Keep focus on the text field for rapid guessing
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3.0),
      ),
      child: Column(
        children: [
          // 1. MESSAGES LIST
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: widget.messages.length,
              itemBuilder: (context, index) {
                final message = widget.messages[index];
                return _buildMessageRow(message);
              },
            ),
          ),

          // 2. INPUT TEXTFIELD
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              border: const Border(
                top: BorderSide(color: Colors.black, width: 3.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.isInputEnabled,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSubmit(),
                      decoration: InputDecoration(
                        hintText: widget.isInputEnabled ? widget.placeholder : 'You cannot draw and guess!',
                        hintStyle: GoogleFonts.fredoka(color: Colors.grey.shade500, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: widget.isInputEnabled ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.black, width: 2.0),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: widget.isInputEnabled ? _handleSubmit : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message) {
    TextStyle textStyle;
    Color? rowBg;
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0);
    Border? border;

    switch (message.type) {
      case ChatMessageType.correct:
        textStyle = GoogleFonts.fredoka(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF155724),
          fontSize: 13,
        );
        rowBg = const Color(0xFFd4edda);
        border = Border.all(color: const Color(0xFFc3e6cb), width: 1.0);
        break;

      case ChatMessageType.close:
        textStyle = GoogleFonts.fredoka(
          fontWeight: FontWeight.w900,
          color: const Color(0xFF856404),
          fontSize: 13,
        );
        rowBg = const Color(0xFFfff3cd);
        border = Border.all(color: const Color(0xFFffeeba), width: 1.0);
        break;

      case ChatMessageType.system:
        textStyle = GoogleFonts.fredoka(
          fontWeight: FontWeight.w900,
          color: Colors.blue.shade900,
          fontSize: 13,
        );
        rowBg = Colors.blue.shade50;
        border = Border.all(color: Colors.blue.shade100, width: 1.0);
        break;

      case ChatMessageType.chat:
        textStyle = GoogleFonts.fredoka(
          fontWeight: FontWeight.w700,
          color: Colors.black,
          fontSize: 13,
        );
        break;
    }

    Widget content = RichText(
      text: TextSpan(
        style: textStyle,
        children: [
          if (message.type == ChatMessageType.chat) ...[
            TextSpan(
              text: '${message.senderName}: ',
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            TextSpan(text: message.text),
          ] else if (message.type == ChatMessageType.correct) ...[
            TextSpan(
              text: message.senderName,
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w900),
            ),
            const TextSpan(text: ' guessed the word!'),
          ] else if (message.type == ChatMessageType.close) ...[
            TextSpan(
              text: message.senderName,
              style: GoogleFonts.fredoka(fontWeight: FontWeight.w900),
            ),
            const TextSpan(text: ' is close!'),
          ] else ...[
            TextSpan(text: message.text),
          ],
        ],
      ),
    );

    if (rowBg != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6.0),
        padding: padding,
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(6.0),
          border: border,
        ),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
      child: content,
    );
  }
}
