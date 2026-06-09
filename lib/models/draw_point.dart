class DrawPoint {
  final double x; // Normalized X-coordinate (0.0 to 1.0)
  final double y; // Normalized Y-coordinate (0.0 to 1.0)
  final int colorValue; // ARGB value
  final double strokeWidth;
  final bool isEraser;
  final bool isStart;

  const DrawPoint({
    required this.x,
    required this.y,
    required this.colorValue,
    required this.strokeWidth,
    required this.isEraser,
    this.isStart = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'isStart': isStart,
    };
  }

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    return DrawPoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      colorValue: json['colorValue'] as int,
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isEraser: json['isEraser'] as bool,
      isStart: json['isStart'] as bool? ?? false,
    );
  }
}
