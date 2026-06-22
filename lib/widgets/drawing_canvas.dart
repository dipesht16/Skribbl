import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/draw_point.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawPoint> points;
  final bool isDrawingEnabled;
  final Function(DrawPoint) onPointAdded;
  final VoidCallback onClear;
  final ValueChanged<bool>? onReaction;

  const DrawingCanvas({
    super.key,
    required this.points,
    required this.isDrawingEnabled,
    required this.onPointAdded,
    required this.onClear,
    this.onReaction,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Color _selectedColor = Colors.black;
  final double _strokeWidth = 6.0;
  bool _isEraser = false;
  bool _isFillMode = false;
  bool _showColorMenu = false;
  bool _isDrawerExpanded = false;
  final GridDrawingCache _gridCache = GridDrawingCache();

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

  Widget _buildToolButton({
    required IconData icon,
    bool isSelected = false,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade200 : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 1.5),
              blurRadius: 0,
            )
          ],
        ),
        child: Icon(icon, color: color ?? Colors.black, size: 20),
      ),
    );
  }

  Widget _buildReactionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 1.5),
              blurRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant DrawingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If drawing is enabled now but was not enabled before, reset tools to default
    if (widget.isDrawingEnabled && !oldWidget.isDrawingEnabled) {
      setState(() {
        _selectedColor = Colors.black;
        _isEraser = false;
        _isFillMode = false;
        _showColorMenu = false;
        _isDrawerExpanded = false;
      });
    }
    // If points are cleared, clear cache
    if (widget.points.isEmpty) {
      _gridCache.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. MAIN CANVAS AREA WITH FLOATING CONTROLS
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.black, width: 3.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Drawing surface
                      GestureDetector(
                        onPanStart: widget.isDrawingEnabled
                            ? (details) => _addPoint(details.localPosition, constraints.biggest, isStart: true)
                            : null,
                        onPanUpdate: widget.isDrawingEnabled
                            ? (details) => _addPoint(details.localPosition, constraints.biggest, isStart: false)
                            : null,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _CanvasPainter(
                              points: widget.points,
                              cache: _gridCache,
                            ),
                          ),
                        ),
                      ),

                      // Reaction buttons overlay (visible for spectators if onReaction is non-null)
                      if (widget.onReaction != null)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildReactionButton(
                                icon: Icons.thumb_up,
                                color: const Color(0xFF2ECC71),
                                onTap: () => widget.onReaction!(true),
                              ),
                              const SizedBox(width: 8),
                              _buildReactionButton(
                                icon: Icons.thumb_down,
                                color: const Color(0xFFE74C3C),
                                onTap: () => widget.onReaction!(false),
                              ),
                            ],
                          ),
                        ),
                      
                      // Floating Canvas Controls (Only visible to active drawer)
                      if (widget.isDrawingEnabled)
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Floating Color Picker Panel
                              if (_showColorMenu) ...[
                                Container(
                                  width: 250,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 4),
                                        blurRadius: 6,
                                      )
                                    ],
                                  ),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 6.0,
                                      mainAxisSpacing: 6.0,
                                    ),
                                    itemCount: _palette.length,
                                    itemBuilder: (context, index) {
                                      final color = _palette[index];
                                      final isSelected = !_isEraser && _selectedColor == color;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedColor = color;
                                            _isEraser = false;
                                            _showColorMenu = false;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.blue.shade900 : Colors.black,
                                              width: isSelected ? 2.5 : 1.0,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              if (!_isDrawerExpanded)
                                // Collapsed Single Tool Button (shows selected color & active tool icon)
                                GestureDetector(
                                  onTap: () => setState(() => _isDrawerExpanded = true),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _isEraser ? Colors.white : _selectedColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: Icon(
                                      _isEraser
                                          ? Icons.cleaning_services_rounded
                                          : (_isFillMode ? Icons.format_paint : Icons.edit),
                                      color: _isEraser
                                          ? Colors.black
                                          : (_selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                                      size: 22,
                                    ),
                                  ),
                                )
                              else
                                // Main Floating Expanded Toolbar
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.black, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Collapse button (shows current color with close icon)
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _isDrawerExpanded = false;
                                          _showColorMenu = false;
                                        }),
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _isEraser ? Colors.white : _selectedColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.black, width: 2.0),
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: _isEraser
                                                ? Colors.black
                                                : (_selectedColor.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      
                                      // Pencil Button
                                      _buildToolButton(
                                        icon: Icons.edit,
                                        isSelected: !_isFillMode && !_isEraser,
                                        onTap: () {
                                          setState(() {
                                            _isFillMode = false;
                                            _isEraser = false;
                                            _showColorMenu = false;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),

                                      // Eraser Button
                                      _buildToolButton(
                                        icon: Icons.cleaning_services_rounded,
                                        isSelected: _isEraser,
                                        onTap: () {
                                          setState(() {
                                            _isFillMode = false;
                                            _isEraser = true;
                                            _showColorMenu = false;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      
                                      // Paint Brush (Fill) Button
                                      _buildToolButton(
                                        icon: Icons.format_paint,
                                        isSelected: _isFillMode && !_isEraser,
                                        onTap: () {
                                          setState(() {
                                            _isFillMode = true;
                                            _isEraser = false;
                                            _showColorMenu = false;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      
                                      // Color Selector Button (showing current color, opens palette)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showColorMenu = !_showColorMenu;
                                          });
                                        },
                                        child: Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _selectedColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _showColorMenu ? Colors.blue.shade900 : Colors.black,
                                              width: _showColorMenu ? 2.5 : 2.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      
                                      // Clear Canvas Button
                                      _buildToolButton(
                                        icon: Icons.delete,
                                        color: Colors.red.shade700,
                                        onTap: () {
                                          widget.onClear();
                                          setState(() {
                                            _showColorMenu = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _addPoint(Offset localPosition, Size canvasSize, {required bool isStart}) {
    if (localPosition.dx < 0 ||
        localPosition.dx > canvasSize.width ||
        localPosition.dy < 0 ||
        localPosition.dy > canvasSize.height) {
      return;
    }

    if (_isFillMode) {
      // In fill mode, we only register a single point on start, ignoring dragging
      if (!isStart) return;
    }

    final double nx = localPosition.dx / canvasSize.width;
    final double ny = localPosition.dy / canvasSize.height;

    widget.onPointAdded(DrawPoint(
      x: nx,
      y: ny,
      colorValue: _selectedColor.toARGB32(),
      strokeWidth: _strokeWidth,
      isEraser: _isEraser,
      isStart: isStart,
      isFill: _isFillMode,
    ));
  }
}

class GridDrawingCache {
  List<int>? grid;
  int lastProcessedIndex = 0;
  bool hasFill = false;

  void clear() {
    grid = null;
    lastProcessedIndex = 0;
    hasFill = false;
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawPoint> points;
  final GridDrawingCache cache;

  _CanvasPainter({required this.points, required this.cache});

  void _floodFill(List<int> grid, int startX, int startY, int targetColor, int replacementColor) {
    if (targetColor == replacementColor) return;
    
    final queue = <int>[];
    queue.add(startY * 256 + startX);
    grid[startY * 256 + startX] = replacementColor;
    
    while (queue.isNotEmpty) {
      final pos = queue.removeLast();
      final cx = pos % 256;
      final cy = pos ~/ 256;
      
      if (cx > 0) {
        final idx = pos - 1;
        if (grid[idx] == targetColor) {
          grid[idx] = replacementColor;
          queue.add(idx);
        }
      }
      if (cx < 255) {
        final idx = pos + 1;
        if (grid[idx] == targetColor) {
          grid[idx] = replacementColor;
          queue.add(idx);
        }
      }
      if (cy > 0) {
        final idx = pos - 256;
        if (grid[idx] == targetColor) {
          grid[idx] = replacementColor;
          queue.add(idx);
        }
      }
      if (cy < 255) {
        final idx = pos + 256;
        if (grid[idx] == targetColor) {
          grid[idx] = replacementColor;
          queue.add(idx);
        }
      }
    }
  }

  void _drawGridCircle(List<int> grid, int cx, int cy, double r, int color) {
    final int rad = max(1, r.round());
    for (int y = -rad; y <= rad; y++) {
      for (int x = -rad; x <= rad; x++) {
        if (x * x + y * y <= rad * rad) {
          final int gx = cx + x;
          final int gy = cy + y;
          if (gx >= 0 && gx < 256 && gy >= 0 && gy < 256) {
            grid[gy * 256 + gx] = color;
          }
        }
      }
    }
  }

  void _drawGridLine(List<int> grid, int x0, int y0, int x1, int y1, double strokeWidth, int color) {
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;

    int cx = x0;
    int cy = y0;

    while (true) {
      _drawGridCircle(grid, cx, cy, strokeWidth / 2.0, color);
      if (cx == x1 && cy == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        cx += sx;
      }
      if (e2 < dx) {
        err += dx;
        cy += sy;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // 1. Draw solid background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    if (points.isEmpty) {
      cache.clear();
      return;
    }

    // Check if points were reset
    if (cache.grid == null || cache.lastProcessedIndex > points.length) {
      cache.grid = List<int>.filled(256 * 256, 0xFFFFFFFF);
      cache.lastProcessedIndex = 0;
      cache.hasFill = false;
    }

    // Check if any new points contain a fill
    bool foundNewFill = false;
    for (int i = cache.lastProcessedIndex; i < points.length; i++) {
      if (points[i].isFill) {
        foundNewFill = true;
        break;
      }
    }

    if (foundNewFill && !cache.hasFill) {
      // First time we encounter a fill, we must process the entire history to populate the grid.
      cache.grid = List<int>.filled(256 * 256, 0xFFFFFFFF);
      cache.lastProcessedIndex = 0;
      cache.hasFill = true;
    }

    final whiteVal = 0xFFFFFFFF;

    if (cache.hasFill) {
      final grid = cache.grid!;
      // Process only the new points incrementally
      for (int i = cache.lastProcessedIndex; i < points.length; i++) {
        final pt = points[i];
        final int color = pt.isEraser ? whiteVal : pt.colorValue;
        
        final int gx = (pt.x * 255.0).clamp(0.0, 255.0).round();
        final int gy = (pt.y * 255.0).clamp(0.0, 255.0).round();
        final double gridStrokeWidth = pt.strokeWidth * 256.0 / w;

        if (pt.isFill) {
          final targetColor = grid[gy * 256 + gx];
          _floodFill(grid, gx, gy, targetColor, color);
        } else {
          if (pt.isStart) {
            _drawGridCircle(grid, gx, gy, gridStrokeWidth / 2.0, color);
          } else if (i > 0) {
            final prevPt = points[i - 1];
            if (!pt.isStart) {
              final int pgx = (prevPt.x * 255.0).clamp(0.0, 255.0).round();
              final int pgy = (prevPt.y * 255.0).clamp(0.0, 255.0).round();
              _drawGridLine(grid, pgx, pgy, gx, gy, gridStrokeWidth, color);
            }
          }
        }
      }
      cache.lastProcessedIndex = points.length;

      // Draw filled color pixels from the grid in batches using drawPoints
      final pointsMap = <int, List<Offset>>{};
      final double xMultiplier = w / 256.0;
      final double yMultiplier = h / 256.0;

      for (int y = 0; y < 256; y++) {
        final int yOffset = y * 256;
        final double yPos = y * yMultiplier;
        for (int x = 0; x < 256; x++) {
          final color = grid[yOffset + x];
          if (color != whiteVal) {
            pointsMap.putIfAbsent(color, () => []).add(Offset(x * xMultiplier, yPos));
          }
        }
      }

      final cellW = w / 256.0;
      final pixelPaint = Paint()
        ..strokeCap = StrokeCap.square
        ..strokeWidth = cellW * 1.5 // Overlay pixels to avoid gaps
        ..style = PaintingStyle.stroke;

      for (final entry in pointsMap.entries) {
        pixelPaint.color = Color(entry.key);
        canvas.drawPoints(ui.PointMode.points, entry.value, pixelPaint);
      }
    } else {
      cache.lastProcessedIndex = points.length;
    }

    // 4. Draw high-res smooth vector strokes on top of filled pixels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      if (pt.isFill) continue; // Fills are already drawn via grid

      final offset = Offset(pt.x * w, pt.y * h);
      final paint = Paint()
        ..color = pt.isEraser ? Colors.white : Color(pt.colorValue)
        ..strokeWidth = pt.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (pt.isStart) {
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
