import 'dart:math' as math;
import 'package:flutter/material.dart';

class TimerWidget extends StatelessWidget {
  final int timeLeft;
  final int maxTime;

  const TimerWidget({super.key, required this.timeLeft, this.maxTime = 80});

  @override
  Widget build(BuildContext context) {
    final progress = timeLeft / maxTime;
    final isLow = timeLeft <= 10;

    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(42, 42),
            painter: CircularTimerPainter(
              progress: progress,
              color: isLow ? const Color(0xFFE74C3C) : const Color(0xFF2C3E50),
            ),
          ),
          Text(
            timeLeft.toString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isLow ? const Color(0xFFE74C3C) : const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFFE9ECEF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius - 2, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
