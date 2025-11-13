import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawPage extends StatefulWidget {
  const DrawPage({super.key});

  @override
  State<DrawPage> createState() => _DrawPageState();
}

class _DrawPageState extends State<DrawPage> {
  List<DrawPoint> points = [];
  List<DrawPoint> redoStack = [];

  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;
  bool isEraser = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF),
      body: SafeArea(
        child: Row(
          children: [
            // ====================== TOOLS PANEL ======================
            Container(
              width: 80,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Colors
                  _colorDot(Colors.black),
                  _colorDot(Colors.red),
                  _colorDot(Colors.blue),
                  _colorDot(Colors.green),
                  _colorDot(Colors.orange),
                  _colorDot(Colors.purple),
                  _colorDot(Colors.brown),
                  _colorDot(Colors.yellow),

                  const SizedBox(height: 20),

                  // Brush Size
                  const Text("Size", style: TextStyle(fontSize: 12)),
                  Slider(
                    value: strokeWidth,
                    min: 2,
                    max: 20,
                    onChanged: (v) => setState(() => strokeWidth = v),
                  ),

                  const SizedBox(height: 10),

                  // Pen
                  IconButton(
                    icon: Icon(Icons.brush,
                        color: !isEraser ? Colors.black : Colors.grey),
                    onPressed: () {
                      setState(() => isEraser = false);
                    },
                  ),

                  // Eraser
                  IconButton(
                    icon: Icon(Icons.circle,
                        color: isEraser ? Colors.black : Colors.grey),
                    onPressed: () {
                      setState(() => isEraser = true);
                    },
                  ),

                  // Undo
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: _undo,
                  ),

                  // Redo
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: _redo,
                  ),

                  // Clear All
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    onPressed: () {
                      setState(() {
                        points.clear();
                        redoStack.clear();
                      });
                    },
                  ),

                  const Spacer(),

                  // Done
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9182FA),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final image = await _exportDrawing();
final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
Navigator.pop(context, bytes?.buffer.asUint8List());

                    },
                    child: const Text("Done"),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ====================== DRAW CANVAS ======================
            Expanded(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    redoStack.clear();
                    points.add(DrawPoint(
                      position: details.localPosition,
                      color: isEraser ? Colors.white : selectedColor,
                      width: strokeWidth,
                    ));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    points.add(DrawPoint(
                      position: details.localPosition,
                      color: isEraser ? Colors.white : selectedColor,
                      width: strokeWidth,
                    ));
                  });
                },
                onPanEnd: (_) {
                  setState(() {
                    points.add(DrawPoint(position: null)); // separator
                  });
                },
                child: CustomPaint(
                  painter: DrawPainter(points),
                  child: Container(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============== Helpers ==============

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          isEraser = false;
        });
      },
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  void _undo() {
    if (points.isEmpty) return;
    setState(() {
      int lastSeparator = points.lastIndexWhere((p) => p.position == null);
      redoStack.addAll(points.sublist(lastSeparator + 1));
      points.removeRange(lastSeparator + 1, points.length);
      points.removeLast(); // remove separator
    });
  }

  void _redo() {
    if (redoStack.isEmpty) return;
    setState(() {
      points.addAll(redoStack);
      points.add(DrawPoint(position: null));
      redoStack.clear();
    });
  }

  Future<ui.Image> _exportDrawing() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final painter = DrawPainter(points);
    painter.paint(canvas, const Size(800, 800));

    return recorder.endRecording().toImage(800, 800);
  }
}

// ============== Data Model ==============

class DrawPoint {
  final Offset? position;
  final Color? color;
  final double? width;

  DrawPoint({required this.position, this.color, this.width});
}

// ============== Painter ==============

class DrawPainter extends CustomPainter {
  final List<DrawPoint> points;

  DrawPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i].position != null && points[i + 1].position != null) {
        final paint = Paint()
          ..color = points[i].color!
          ..strokeWidth = points[i].width!
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(points[i].position!, points[i + 1].position!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawPainter oldDelegate) => true;

  
}
