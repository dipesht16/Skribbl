import 'dart:math';
import 'package:flutter/material.dart';
import '../models/avatar.dart';

class AvatarRenderer extends StatelessWidget {
  final Avatar avatar;
  final double size;
  final bool drawBorder;

  const AvatarRenderer({
    super.key,
    required this.avatar,
    this.size = 80.0,
    this.drawBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: drawBorder
          ? BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: max(2.0, size * 0.04)),
              borderRadius: BorderRadius.circular(size * 0.25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                )
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: CustomPaint(
          size: Size(size, size),
          painter: _AvatarPainter(avatar: avatar),
        ),
      ),
    );
  }
}

class _AvatarPainter extends CustomPainter {
  final Avatar avatar;

  _AvatarPainter({required this.avatar});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // Paints
    final bodyPaint = Paint()
      ..color = avatar.color
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = w * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final pinkPaint = Paint()
      ..color = const Color(0xFFff7675)
      ..style = PaintingStyle.fill;

    // 1. DRAW BODY (Rounded capsule/egg-shape)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.75),
      Radius.circular(w * 0.3),
    );
    canvas.drawRRect(bodyRect, bodyPaint);
    canvas.drawRRect(bodyRect, outlinePaint);

    // 2. DRAW EYES
    _drawEyes(canvas, w, h, cx, cy, whitePaint, blackPaint, outlinePaint);

    // 3. DRAW MOUTH
    _drawMouth(canvas, w, h, cx, cy, whitePaint, blackPaint, outlinePaint, pinkPaint);
  }

  void _drawEyes(Canvas canvas, double w, double h, double cx, double cy, Paint white, Paint black, Paint outline) {
    final eyeStyle = avatar.eyesIndex % 10;
    final double eyeY = h * 0.45;
    final double leftEyeX = cx - w * 0.16;
    final double rightEyeX = cx + w * 0.16;
    final double r = w * 0.10; // normal eye radius

    switch (eyeStyle) {
      case 0: // Normal open eyes
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, outline);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, outline);
        // Pupils
        canvas.drawCircle(Offset(leftEyeX + w * 0.02, eyeY), r * 0.4, black);
        canvas.drawCircle(Offset(rightEyeX + w * 0.02, eyeY), r * 0.4, black);
        break;

      case 1: // Sleepy eyes (half circles / tired lids)
        final pathLeft = Path()
          ..addArc(Rect.fromCircle(center: Offset(leftEyeX, eyeY), radius: r), 0, pi);
        final pathRight = Path()
          ..addArc(Rect.fromCircle(center: Offset(rightEyeX, eyeY), radius: r), 0, pi);
        canvas.drawPath(pathLeft, white);
        canvas.drawPath(pathLeft, outline);
        canvas.drawPath(pathRight, white);
        canvas.drawPath(pathRight, outline);
        // Pupils peeking
        canvas.drawCircle(Offset(leftEyeX, eyeY + r * 0.3), r * 0.35, black);
        canvas.drawCircle(Offset(rightEyeX, eyeY + r * 0.3), r * 0.35, black);
        break;

      case 2: // Angry eyes (slanted lids)
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, outline);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, outline);
        // Pupils
        canvas.drawCircle(Offset(leftEyeX, eyeY), r * 0.4, black);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r * 0.4, black);
        // Angry eyebrows (slanted lids)
        final browPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = w * 0.05
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(leftEyeX - r, eyeY - r * 0.8), Offset(leftEyeX + r * 0.8, eyeY - r * 0.2), browPaint);
        canvas.drawLine(Offset(rightEyeX + r, eyeY - r * 0.8), Offset(rightEyeX - r * 0.8, eyeY - r * 0.2), browPaint);
        break;

      case 3: // Wide/Stunned eyes (huge white circles, small black dots)
        final double hr = r * 1.3;
        canvas.drawCircle(Offset(leftEyeX, eyeY), hr, white);
        canvas.drawCircle(Offset(leftEyeX, eyeY), hr, outline);
        canvas.drawCircle(Offset(rightEyeX, eyeY), hr, white);
        canvas.drawCircle(Offset(rightEyeX, eyeY), hr, outline);
        canvas.drawCircle(Offset(leftEyeX, eyeY), hr * 0.2, black);
        canvas.drawCircle(Offset(rightEyeX, eyeY), hr * 0.2, black);
        break;

      case 4: // Cross eyes (Dead/Dizzy)
        final crossPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = w * 0.05
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        // Left Cross
        canvas.drawLine(Offset(leftEyeX - r * 0.7, eyeY - r * 0.7), Offset(leftEyeX + r * 0.7, eyeY + r * 0.7), crossPaint);
        canvas.drawLine(Offset(leftEyeX + r * 0.7, eyeY - r * 0.7), Offset(leftEyeX - r * 0.7, eyeY + r * 0.7), crossPaint);
        // Right Cross
        canvas.drawLine(Offset(rightEyeX - r * 0.7, eyeY - r * 0.7), Offset(rightEyeX + r * 0.7, eyeY + r * 0.7), crossPaint);
        canvas.drawLine(Offset(rightEyeX + r * 0.7, eyeY - r * 0.7), Offset(rightEyeX - r * 0.7, eyeY + r * 0.7), crossPaint);
        break;

      case 5: // Glasses
        // Draw normal eyes first
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, outline);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, outline);
        canvas.drawCircle(Offset(leftEyeX, eyeY), r * 0.4, black);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r * 0.4, black);
        // Draw Glasses frames (large black squares/circles around eyes)
        final framePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = w * 0.04
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(leftEyeX, eyeY), r * 1.4, framePaint);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r * 1.4, framePaint);
        // Bridge
        canvas.drawLine(Offset(leftEyeX + r * 1.4, eyeY), Offset(rightEyeX - r * 1.4, eyeY), outline);
        break;

      case 6: // Closed happy arches (^ ^)
        final archPaint = Paint()
          ..color = Colors.black
          ..strokeWidth = w * 0.06
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final leftPath = Path()..addArc(Rect.fromLTWH(leftEyeX - r, eyeY - r * 0.5, r * 2, r * 1.5), pi, pi);
        final rightPath = Path()..addArc(Rect.fromLTWH(rightEyeX - r, eyeY - r * 0.5, r * 2, r * 1.5), pi, pi);
        canvas.drawPath(leftPath, archPaint);
        canvas.drawPath(rightPath, archPaint);
        break;

      case 7: // Wink (Left eye open, right eye closed happy arch)
        // Left Eye (Open)
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, white);
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, outline);
        canvas.drawCircle(Offset(leftEyeX + w * 0.02, eyeY), r * 0.4, black);
        // Right Eye (Arch)
        final archPaint2 = Paint()
          ..color = Colors.black
          ..strokeWidth = w * 0.06
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final rightPath2 = Path()..addArc(Rect.fromLTWH(rightEyeX - r, eyeY - r * 0.5, r * 2, r * 1.5), pi, pi);
        canvas.drawPath(rightPath2, archPaint2);
        break;

      case 8: // Cute sparkle eyes
        canvas.drawCircle(Offset(leftEyeX, eyeY), r, black);
        canvas.drawCircle(Offset(rightEyeX, eyeY), r, black);
        // White reflection sparkles
        canvas.drawCircle(Offset(leftEyeX - r * 0.3, eyeY - r * 0.3), r * 0.35, white);
        canvas.drawCircle(Offset(leftEyeX + r * 0.3, eyeY + r * 0.3), r * 0.15, white);
        canvas.drawCircle(Offset(rightEyeX - r * 0.3, eyeY - r * 0.3), r * 0.35, white);
        canvas.drawCircle(Offset(rightEyeX + r * 0.3, eyeY + r * 0.3), r * 0.15, white);
        break;

      case 9: // Cool Sunglasses
        final sunPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        // Draw left lens (rhombus or squarish)
        final leftLens = RRect.fromRectAndRadius(
          Rect.fromLTWH(leftEyeX - r * 1.3, eyeY - r, r * 2.4, r * 1.8),
          Radius.circular(w * 0.03),
        );
        final rightLens = RRect.fromRectAndRadius(
          Rect.fromLTWH(rightEyeX - r * 1.1, eyeY - r, r * 2.4, r * 1.8),
          Radius.circular(w * 0.03),
        );
        canvas.drawRRect(leftLens, sunPaint);
        canvas.drawRRect(rightLens, sunPaint);
        // Bridge line
        final bridgePaint = Paint()
          ..color = Colors.black
          ..strokeWidth = w * 0.06
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(leftEyeX, eyeY - r * 0.6), Offset(rightEyeX, eyeY - r * 0.6), bridgePaint);
        break;
    }
  }

  void _drawMouth(Canvas canvas, double w, double h, double cx, double cy, Paint white, Paint black, Paint outline, Paint pink) {
    final mouthStyle = avatar.mouthIndex % 10;
    final double mouthY = h * 0.68;
    final double mouthW = w * 0.22;

    switch (mouthStyle) {
      case 0: // Simple smile (curved line)
        final path = Path();
        path.moveTo(cx - mouthW / 2, mouthY - h * 0.02);
        path.quadraticBezierTo(cx, mouthY + h * 0.07, cx + mouthW / 2, mouthY - h * 0.02);
        canvas.drawPath(path, outline);
        break;

      case 1: // Wide open mouth
        final path = Path();
        path.moveTo(cx - mouthW, mouthY - h * 0.02);
        path.quadraticBezierTo(cx, mouthY + h * 0.15, cx + mouthW, mouthY - h * 0.02);
        path.close();
        canvas.drawPath(path, black);
        canvas.drawPath(path, outline);

        // Tongue
        final tonguePath = Path();
        tonguePath.moveTo(cx - mouthW * 0.6, mouthY + h * 0.06);
        tonguePath.quadraticBezierTo(cx, mouthY + h * 0.01, cx + mouthW * 0.6, mouthY + h * 0.06);
        tonguePath.quadraticBezierTo(cx, mouthY + h * 0.14, cx - mouthW * 0.6, mouthY + h * 0.06);
        canvas.drawPath(tonguePath, pink);
        break;

      case 2: // Neutral flat line
        canvas.drawLine(Offset(cx - mouthW * 0.8, mouthY), Offset(cx + mouthW * 0.8, mouthY), outline);
        break;

      case 3: // Sad curve
        final path = Path();
        path.moveTo(cx - mouthW / 2, mouthY + h * 0.04);
        path.quadraticBezierTo(cx, mouthY - h * 0.04, cx + mouthW / 2, mouthY + h * 0.04);
        canvas.drawPath(path, outline);
        break;

      case 4: // Tongue out
        // Draw normal smile
        final pathSmile = Path()
          ..moveTo(cx - mouthW / 2, mouthY)
          ..quadraticBezierTo(cx, mouthY + h * 0.05, cx + mouthW / 2, mouthY);
        canvas.drawPath(pathSmile, outline);
        // Draw tongue hanging down
        final tongueRect = Rect.fromLTWH(cx - w * 0.04, mouthY + h * 0.01, w * 0.08, h * 0.08);
        canvas.drawRRect(RRect.fromRectAndRadius(tongueRect, Radius.circular(w * 0.03)), pink);
        canvas.drawRRect(RRect.fromRectAndRadius(tongueRect, Radius.circular(w * 0.03)), outline);
        break;

      case 5: // Teeth grill smile
        final rect = Rect.fromLTWH(cx - mouthW, mouthY - h * 0.03, mouthW * 2, h * 0.07);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(h * 0.03));
        canvas.drawRRect(rrect, white);
        canvas.drawRRect(rrect, outline);
        // Draw center division line
        canvas.drawLine(Offset(cx - mouthW, mouthY), Offset(cx + mouthW, mouthY), outline);
        // Vertical grid lines
        for (int i = 1; i <= 3; i++) {
          double xOffset = (mouthW * 2 / 4) * i;
          canvas.drawLine(Offset(rect.left + xOffset, rect.top), Offset(rect.left + xOffset, rect.bottom), outline);
        }
        break;

      case 6: // Shocked O-mouth
        canvas.drawCircle(Offset(cx, mouthY), w * 0.08, black);
        canvas.drawCircle(Offset(cx, mouthY), w * 0.08, outline);
        break;

      case 7: // Smirk (cocky smile side-aligned)
        final path = Path();
        path.moveTo(cx - mouthW * 0.4, mouthY);
        path.quadraticBezierTo(cx + mouthW * 0.2, mouthY + h * 0.05, cx + mouthW * 0.8, mouthY - h * 0.04);
        canvas.drawPath(path, outline);
        break;

      case 8: // Mustache
        final mustPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill;
        final mPath = Path();
        // Draw left side of mustache
        mPath.moveTo(cx, mouthY - h * 0.02);
        mPath.quadraticBezierTo(cx - mouthW * 0.5, mouthY - h * 0.05, cx - mouthW * 0.8, mouthY);
        mPath.quadraticBezierTo(cx - mouthW * 0.4, mouthY + h * 0.04, cx, mouthY - h * 0.01);
        // Draw right side of mustache
        mPath.quadraticBezierTo(cx + mouthW * 0.4, mouthY + h * 0.04, cx + mouthW * 0.8, mouthY);
        mPath.quadraticBezierTo(cx + mouthW * 0.5, mouthY - h * 0.05, cx, mouthY - h * 0.02);
        canvas.drawPath(mPath, mustPaint);
        canvas.drawPath(mPath, outline);
        break;

      case 9: // Screaming triangle mouth
        final triPath = Path()
          ..moveTo(cx - mouthW, mouthY - h * 0.03)
          ..lineTo(cx + mouthW, mouthY - h * 0.03)
          ..lineTo(cx, mouthY + h * 0.10)
          ..close();
        canvas.drawPath(triPath, black);
        canvas.drawPath(triPath, outline);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.avatar.bodyColorIndex != avatar.bodyColorIndex ||
        oldDelegate.avatar.eyesIndex != avatar.eyesIndex ||
        oldDelegate.avatar.mouthIndex != avatar.mouthIndex;
  }
}
