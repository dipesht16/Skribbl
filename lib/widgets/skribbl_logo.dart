import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkribblLogo extends StatelessWidget {
  final double fontSize;

  const SkribblLogo({super.key, this.fontSize = 42.0});

  @override
  Widget build(BuildContext context) {
    final letters = [
      _LogoLetter(char: 's', color: const Color(0xFF1e90ff), rotation: -0.08),
      _LogoLetter(char: 'k', color: const Color(0xFF2ed573), rotation: 0.06),
      _LogoLetter(char: 'r', color: const Color(0xFFffa500), rotation: -0.05),
      _LogoLetter(char: 'i', color: const Color(0xFFff4757), rotation: 0.08),
      _LogoLetter(char: 'b', color: const Color(0xFF9b59b6), rotation: -0.04),
      _LogoLetter(char: 'b', color: const Color(0xFFff6b81), rotation: 0.05),
      _LogoLetter(char: 'l', color: const Color(0xFFeccc68), rotation: -0.07),
      _LogoLetter(char: '.', color: Colors.grey.shade800, rotation: 0.0, isDot: true),
      _LogoLetter(char: 'i', color: const Color(0xFF1e90ff), rotation: 0.04),
      _LogoLetter(char: 'o', color: const Color(0xFF2ed573), rotation: -0.06),
    ];

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: letters.map((l) => _buildLetterWidget(l)).toList(),
      ),
    );
  }

  Widget _buildLetterWidget(_LogoLetter letter) {
    if (letter.isDot) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.0),
        width: fontSize * 0.3,
        height: fontSize * 0.3,
        decoration: BoxDecoration(
          color: letter.color,
          border: Border.all(color: Colors.black, width: fontSize * 0.08),
          borderRadius: BorderRadius.circular(4.0),
        ),
      );
    }

    return Transform.rotate(
      angle: letter.rotation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
        padding: EdgeInsets.symmetric(horizontal: fontSize * 0.15, vertical: fontSize * 0.03),
        decoration: BoxDecoration(
          color: letter.color,
          border: Border.all(color: Colors.black, width: fontSize * 0.09),
          borderRadius: BorderRadius.circular(fontSize * 0.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          letter.char.toUpperCase(),
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  offset: Offset(1, 1),
                  blurRadius: 0,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoLetter {
  final String char;
  final Color color;
  final double rotation;
  final bool isDot;

  _LogoLetter({
    required this.char,
    required this.color,
    required this.rotation,
    this.isDot = false,
  });
}
