class DrawPoint {
  final double x; // Normalized X-coordinate (0.0 to 1.0)
  final double y; // Normalized Y-coordinate (0.0 to 1.0)
  final int colorValue; // ARGB value
  final double strokeWidth;
  final bool isEraser;
  final bool isStart;
  final bool isFill; // Indicates if this point is a flood fill action

  const DrawPoint({
    required this.x,
    required this.y,
    required this.colorValue,
    required this.strokeWidth,
    required this.isEraser,
    this.isStart = false,
    this.isFill = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'colorValue': colorValue,
      'strokeWidth': strokeWidth,
      'isEraser': isEraser,
      'isStart': isStart,
      'isFill': isFill,
    };
  }

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    return DrawPoint(
      x: (json['x'] as num? ?? 0.0).toDouble(),
      y: (json['y'] as num? ?? 0.0).toDouble(),
      colorValue: json['colorValue'] as int? ?? 0,
      strokeWidth: (json['strokeWidth'] as num? ?? 4.0).toDouble(),
      isEraser: json['isEraser'] as bool? ?? false,
      isStart: json['isStart'] as bool? ?? false,
      isFill: json['isFill'] as bool? ?? false,
    );
  }
}
