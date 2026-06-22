import 'package:flutter/material.dart';
import '../models/floating_chat_message.dart';

class FloatingChatBubble extends StatelessWidget {
  final FloatingChatMessage message;
  final Animation<double> animation;

  const FloatingChatBubble({
    super.key,
    required this.message,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    Color nameColor = message.playerColor;
    if (message.isCorrectGuess || message.isCorrectGuesserChat || message.isLike) {
      nameColor = const Color(0xFF2E7D0F); // Darker green for readability
    } else if (message.isDislike) {
      nameColor = const Color(0xFFC62828); // Darker red for readability
    }

    // Truncate player name to 12 chars if needed
    String displayName = message.playerName;
    if (displayName.length > 12) {
      displayName = '${displayName.substring(0, 12)}...';
    }

    Widget contentText;
    if (message.isSystemMessage) {
      contentText = Text(
        message.message,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 13,
          fontStyle: FontStyle.italic,
          color: Color(0xFF1F69C9), // System blue
          decoration: TextDecoration.none,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (message.isWarningMessage) {
      contentText = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.warning, color: Color(0xFFD97D0D), size: 14), // Warning orange
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              message.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD97D0D), // Warning orange
                decoration: TextDecoration.none,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    } else {
      final bool isGreen = message.isCorrectGuess || message.isCorrectGuesserChat || message.isLike;
      final bool isRed = message.isDislike;
      final Color textColor = isGreen 
          ? const Color(0xFF2E7D0F) 
          : (isRed ? const Color(0xFFC62828) : Colors.black);

      contentText = RichText(
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(fontSize: 13, color: textColor),
          children: [
            TextSpan(
              text: '$displayName: ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: nameColor,
              ),
            ),
            TextSpan(
              text: message.message,
              style: TextStyle(
                fontWeight: (isGreen || isRed) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (message.isCorrectGuess)
              const TextSpan(
                text: ' ✓',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF2E7D0F), // Darker green checkmark
                ),
              ),
            if (message.isLike)
              const TextSpan(
                text: ' 👍',
                style: TextStyle(fontSize: 14),
              ),
            if (message.isDislike)
              const TextSpan(
                text: ' 👎',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
      );
    }

    // Animating the insertion and removal
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double value = animation.value;
        final bool isRemoving = animation.status == AnimationStatus.reverse || 
                                animation.status == AnimationStatus.dismissed;

        double opacity = value.clamp(0.0, 1.0);
        Widget animatedChild = child!;

        if (isRemoving) {
          // Fade-out + scale-down on removal
          final double scale = 0.95 + 0.05 * value;
          animatedChild = Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: animatedChild,
            ),
          );
        } else {
          // Slide-in + fade-in on insertion (using easeOutBack for bounce)
          final double curvedVal = Curves.easeOutBack.transform(value);
          final double translateY = 50.0 * (1.0 - curvedVal);
          animatedChild = Transform.translate(
            offset: Offset(0, translateY),
            child: Opacity(
              opacity: opacity,
              child: animatedChild,
            ),
          );
        }

        // Align right to prevent stretching and match bottom-right positioning
        return Align(
          alignment: Alignment.centerRight,
          child: animatedChild,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4.0),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        // No decoration (no background color, border radius or shadow)
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Colors.black,
            fontSize: 13.0,
            decoration: TextDecoration.none,
            fontWeight: FontWeight.normal,
          ),
          child: contentText,
        ),
      ),
    );
  }
}
