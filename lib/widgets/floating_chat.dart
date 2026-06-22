import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';

class FloatingChat extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(String) onMessageSubmitted;
  final bool isInputEnabled;
  final String placeholder;
  final bool isDrawer; // true if the current user is the drawer, hide input

  const FloatingChat({
    super.key,
    required this.messages,
    required this.onMessageSubmitted,
    required this.isInputEnabled,
    this.placeholder = 'Type your guess here...',
    this.isDrawer = false,
  });

  @override
  State<FloatingChat> createState() => _FloatingChatState();
}

class _FloatingChatState extends State<FloatingChat> {
  bool _expanded = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant FloatingChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages.length != widget.messages.length) {
      // auto‑scroll when new messages appear
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

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      // focus the text field when expanded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onMessageSubmitted(text);
      _controller.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double width = 280;
    const double collapsedHeight = 50;
    const double expandedHeight = 350;

    return Positioned(
      bottom: 16,
      right: 16,
      child: AnimatedContainer(
        width: width,
        height: _expanded ? expandedHeight : collapsedHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          children: [
            // Header
            GestureDetector(
              onTap: _toggle,
              child: Container(
                height: 40,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Chat', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              // Message list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) => _buildMessageRow(widget.messages[index]),
                ),
              ),
              // Input (hidden for drawer)
              if (!widget.isDrawer)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.black, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.isInputEnabled,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _handleSubmit(),
                          decoration: InputDecoration(
                            hintText: widget.isInputEnabled ? widget.placeholder : 'You cannot draw and guess!',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: widget.isInputEnabled ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.black, width: 1),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message) {
    TextStyle textStyle;
    Color? rowBg;
    Border? border;
    switch (message.type) {
      case ChatMessageType.correct:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF155724), fontSize: 13);
        rowBg = const Color(0xFFd4edda);
        border = Border.all(color: const Color(0xFFc3e6cb), width: 1);
        break;
      case ChatMessageType.correctGuesserChat:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFF155724), fontSize: 13);
        rowBg = const Color(0xFFd4edda);
        border = Border.all(color: const Color(0xFFc3e6cb), width: 1);
        break;
      case ChatMessageType.close:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF856404), fontSize: 13);
        rowBg = const Color(0xFFfff3cd);
        border = Border.all(color: const Color(0xFFffeeba), width: 1);
        break;
      case ChatMessageType.system:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.blue.shade900, fontSize: 13);
        rowBg = Colors.blue.shade50;
        border = Border.all(color: Colors.blue.shade100, width: 1);
        break;
      case ChatMessageType.like:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFF2E7D32), fontSize: 13);
        rowBg = const Color(0xFFE8F5E9);
        border = Border.all(color: const Color(0xFFC8E6C9), width: 1);
        break;
      case ChatMessageType.dislike:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w900, color: const Color(0xFFC62828), fontSize: 13);
        rowBg = const Color(0xFFFFEBEE);
        border = Border.all(color: const Color(0xFFFFCDD2), width: 1);
        break;
      case ChatMessageType.chat:
        textStyle = GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.black, fontSize: 13);
        break;
    }

    Widget content = RichText(
      text: TextSpan(
        style: textStyle,
        children: [
          if (message.type == ChatMessageType.chat || message.type == ChatMessageType.correctGuesserChat) ...[
            TextSpan(text: '${message.senderName}: ', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: message.type == ChatMessageType.correctGuesserChat ? const Color(0xFF155724) : Colors.black87)),
            TextSpan(text: message.text),
          ] else if (message.type == ChatMessageType.correct) ...[
            TextSpan(text: message.senderName, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
            const TextSpan(text: ' guessed the word!'),
          ] else if (message.type == ChatMessageType.close) ...[
            TextSpan(text: message.senderName, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
            const TextSpan(text: ' is close!'),
          ] else if (message.type == ChatMessageType.like) ...[
            TextSpan(text: message.senderName, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
            const TextSpan(text: ' liked the drawing! 👍'),
          ] else if (message.type == ChatMessageType.dislike) ...[
            TextSpan(text: message.senderName, style: GoogleFonts.inter(fontWeight: FontWeight.w900)),
            const TextSpan(text: ' disliked the drawing! 👎'),
          ] else ...[TextSpan(text: message.text)],
        ],
      ),
    );

    if (rowBg != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(color: rowBg, borderRadius: BorderRadius.circular(6), border: border),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8, right: 8),
      child: content,
    );
  }
}
