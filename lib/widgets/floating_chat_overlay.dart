import 'dart:async';
import 'package:flutter/material.dart';
import '../models/floating_chat_message.dart';
import 'floating_chat_bubble.dart';

class FloatingChatOverlay extends StatefulWidget {
  final int maxVisibleMessages;
  final Duration defaultDuration;
  final Duration correctGuessDuration;
  final Duration systemMessageDuration;

  const FloatingChatOverlay({
    super.key,
    this.maxVisibleMessages = 3,
    this.defaultDuration = const Duration(seconds: 6),
    this.correctGuessDuration = const Duration(seconds: 8),
    this.systemMessageDuration = const Duration(seconds: 4),
  });

  @override
  State<FloatingChatOverlay> createState() => FloatingChatOverlayState();
}

class FloatingChatOverlayState extends State<FloatingChatOverlay> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<FloatingChatMessage> _messages = [];
  final Map<String, Timer> _dismissTimers = {};

  /// Adds a new chat message bubble to the overlay with slide-in animation and triggers auto-dismiss
  void addMessage(FloatingChatMessage message) {
    if (!mounted) return;

    // Spam filter: Ignore if the same sender sends a message within 200ms
    if (_messages.isNotEmpty) {
      final lastMsg = _messages.last;
      if (lastMsg.playerName == message.playerName &&
          message.timestamp.difference(lastMsg.timestamp).inMilliseconds < 200) {
        return; 
      }
    }

    final index = _messages.length;
    _messages.add(message);
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 300),
    );

    // Determine auto-dismiss duration
    Duration duration = widget.defaultDuration;
    if (message.isCorrectGuess) {
      duration = widget.correctGuessDuration;
    } else if (message.isSystemMessage) {
      duration = widget.systemMessageDuration;
    }

    // Schedule removal
    final timer = Timer(duration, () {
      _removeMessage(message.id);
    });
    _dismissTimers[message.id] = timer;

    // Enforce max visible queue count. If exceeds limit, remove oldest (index 0)
    if (_messages.length > widget.maxVisibleMessages) {
      final oldest = _messages.first;
      _removeMessage(oldest.id);
    }
  }

  void _removeMessage(String id) {
    if (!mounted) return;

    final index = _messages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    // Cancel timer
    _dismissTimers[id]?.cancel();
    _dismissTimers.remove(id);

    final removedMsg = _messages.removeAt(index);

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => FloatingChatBubble(
        message: removedMsg,
        animation: animation,
      ),
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    for (final timer in _dismissTimers.values) {
      timer.cancel();
    }
    _dismissTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no messages, render nothing to free layout resources
    if (_messages.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: true, // Allows touch events to pass through directly to drawing canvas underneath
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: AnimatedList(
          key: _listKey,
          initialItemCount: _messages.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index, animation) {
            // Guard index range out of bounds during async removals
            if (index >= _messages.length) return const SizedBox.shrink();
            return FloatingChatBubble(
              message: _messages[index],
              animation: animation,
            );
          },
        ),
      ),
    );
  }
}
