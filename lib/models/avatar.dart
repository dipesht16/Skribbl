import 'dart:math';
import 'package:flutter/material.dart';

class Avatar {
  final int bodyColorIndex;
  final int eyesIndex;
  final int mouthIndex;

  const Avatar({
    required this.bodyColorIndex,
    required this.eyesIndex,
    required this.mouthIndex,
  });

  factory Avatar.random() {
    final random = Random();
    return Avatar(
      bodyColorIndex: random.nextInt(avatarColors.length),
      eyesIndex: random.nextInt(10), // 10 eyes styles
      mouthIndex: random.nextInt(10), // 10 mouth styles
    );
  }

  Avatar copyWith({
    int? bodyColorIndex,
    int? eyesIndex,
    int? mouthIndex,
  }) {
    return Avatar(
      bodyColorIndex: bodyColorIndex ?? this.bodyColorIndex,
      eyesIndex: eyesIndex ?? this.eyesIndex,
      mouthIndex: mouthIndex ?? this.mouthIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyColorIndex': bodyColorIndex,
      'eyesIndex': eyesIndex,
      'mouthIndex': mouthIndex,
    };
  }

  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      bodyColorIndex: json['bodyColorIndex'] as int,
      eyesIndex: json['eyesIndex'] as int,
      mouthIndex: json['mouthIndex'] as int,
    );
  }

  static const List<Color> avatarColors = [
    Color(0xFFff4757), // Red
    Color(0xFFff6b81), // Pinkish red
    Color(0xFFff8500), // Orange
    Color(0xFFeccc68), // Yellow
    Color(0xFF2ed573), // Green
    Color(0xFF1e90ff), // Blue
    Color(0xFF3742fa), // Dark Blue
    Color(0xFFa29bfe), // Lavender
    Color(0xFFfd79a8), // Pink
    Color(0xFFe84393), // Dark Pink
    Color(0xFF00b894), // Teal
    Color(0xFFffeaa7), // Pastel Yellow
    Color(0xFFfab1a0), // Pastel Orange
    Color(0xFFff7675), // Pastel Red
    Color(0xFF74b9ff), // Light Blue
    Color(0xFF81ecec), // Cyan
    Color(0xFF6c5ce7), // Purple
    Color(0xFFb2bec3), // Gray
  ];

  Color get color => avatarColors[bodyColorIndex % avatarColors.length];
}
