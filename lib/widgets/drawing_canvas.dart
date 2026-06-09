import 'package:flutter/material.dart';
import '../models/draw_point.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawPoint> points;
  final bool isDrawingEnabled;
  final Function(DrawPoint) onPointAdded;
  final VoidCallback onClear;

  const DrawingCanvas({
    super.key,
    required this.points,
    required this.isDrawingEnabled,
    required this.onPointAdded,
    required this.onClear,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Color _selectedColor = Colors.black;
  double _strokeWidth = 6.0;
  bool _isEraser = false;

  // Official skribbl.io 22-color palette
  static const List<Color> _palette = [
    Color(0xFFFFFFFF), // White
    Color(0xFFC1C1C1), // Light Grey
    Color(0xFFEF130B), // Red
    Color(0xFFFF7100), // Orange
    Color(0xFFFFE400), // Yellow
    Color(0xFF00CC00), // Green
    Color(0xFF00B2FF), // Light Blue
    Color(0xFF231FD3), // Blue
    Color(0xFFA300D3), // Violet
    Color(0xFFDF4498), // Pink
    Color(0xFFC2763F), // Light Brown
    
    Color(0xFF000000), // Black
    Color(0xFF4C4C4C), // Dark Grey
    Color(0xFF740B07), // Maroon
    Color(0xFFB13E00), // Rust
    Color(0xFFCC8E00), // Mustard
    Color(0xFF005600), // Forest Green
    Color(0xFF00569E), // Cyan
    Color(0xFF0E0862), // Navy
    Color(0xFF550069), // Purple
    Color(0xFF870047), // Rose
    Color(0xFF86512C), // Dark Brown
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. MAIN CANVAS AREA
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade400, width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: widget.isDrawingEnabled
                        ? (details) => _addPoint(details.localPosition, constraints.biggest, isStart: true)
                        : null,
                    onPanUpdate: widget.isDrawingEnabled
                        ? (details) => _addPoint(details.localPosition, constraints.biggest, isStart: false)
                        : null,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _CanvasPainter(points: widget.points),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 2. CANVAS CONTROLS (Only visible to active drawer)
        if (widget.isDrawingEnabled) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            color: Colors.grey.shade200,
            child: Column(
              children: [
                Row(
                  children: [
                    // Size selectors
                    _buildSizeButton(4.0, 'S'),
                    const SizedBox(width: 6),
                    _buildSizeButton(8.0, 'M'),
                    const SizedBox(width: 6),
                    _buildSizeButton(16.0, 'L'),
                    const SizedBox(width: 6),
                    _buildSizeButton(24.0, 'XL'),
                    const Spacer(),

                    // Eraser Toggle
                    IconButton(
                      icon: Icon(
                        _isEraser ? Icons.cleaning_services : Icons.brush,
                        color: _isEraser ? Colors.blue : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEraser = !_isEraser;
                        });
                      },
                    ),

                    // Clear Canvas
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onClear,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Palette grid (two rows)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double gridWidth = constraints.maxWidth;
                    final double cellWidth = (gridWidth - (10 * 4.0)) / 11;
                    final double cellHeight = (60.0 - 4.0) / 2; // 28.0
                    final double aspectRatio = cellWidth / cellHeight;

                    return SizedBox(
                      height: 60,
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 11,
                          crossAxisSpacing: 4.0,
                          mainAxisSpacing: 4.0,
                          childAspectRatio: aspectRatio > 0 ? aspectRatio : 1.0,
                        ),
                        itemCount: _palette.length,
                        itemBuilder: (context, index) {
                          final color = _palette[index];
                          final isSelected = !_isEraser && _selectedColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = color;
                                _isEraser = false; // Turn off eraser when color selected
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: isSelected ? Colors.blue.shade900 : Colors.black,
                                  width: isSelected ? 3.0 : 1.0,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ],
    );
  }

  Widget _buildSizeButton(double width, String label) {
    final isSelected = _strokeWidth == width;
    return GestureDetector(
      onTap: () {
        setState(() {
          _strokeWidth = width;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade400 : Colors.white,
          border: Border.all(color: Colors.black, width: isSelected ? 2.5 : 1.0),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: width * 0.7 + 2,
          height: width * 0.7 + 2,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  void _addPoint(Offset localPosition, Size canvasSize, {required bool isStart}) {
    if (localPosition.dx < 0 ||
        localPosition.dx > canvasSize.width ||
        localPosition.dy < 0 ||
        localPosition.dy > canvasSize.height) {
      return; // Clamp to canvas bounds
    }

    // Normalize coordinates (0.0 to 1.0)
    final double nx = localPosition.dx / canvasSize.width;
    final double ny = localPosition.dy / canvasSize.height;

    widget.onPointAdded(DrawPoint(
      x: nx,
      y: ny,
      colorValue: _selectedColor.value,
      strokeWidth: _strokeWidth,
      isEraser: _isEraser,
      isStart: isStart,
    ));
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawPoint> points;

  _CanvasPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw background grid pattern (authentic skribbl feel!)
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final offset = Offset(pt.x * w, pt.y * h);

      final paint = Paint()
        ..color = pt.isEraser ? Colors.white : Color(pt.colorValue)
        ..strokeWidth = pt.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (pt.isStart) {
        // Draw starting dot
        canvas.drawCircle(
          offset,
          pt.strokeWidth / 2,
          Paint()
            ..color = paint.color
            ..style = PaintingStyle.fill,
        );
      } else if (i > 0) {
        final prevPt = points[i - 1];
        if (!pt.isStart) {
          final prevOffset = Offset(prevPt.x * w, prevPt.y * h);
          canvas.drawLine(prevOffset, offset, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) {
    return oldDelegate.points.length != points.length;
  }
}
