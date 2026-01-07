import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/rendering.dart';

class ChildDrawingCanvasScreen extends StatefulWidget {
  final String activityId;
  final String imageUrl;
  final String title;

  const ChildDrawingCanvasScreen({
    super.key,
    required this.activityId,
    required this.imageUrl,
    required this.title,
  });

  @override
  State<ChildDrawingCanvasScreen> createState() =>
      _ChildDrawingCanvasScreenState();
}

class _ChildDrawingCanvasScreenState extends State<ChildDrawingCanvasScreen> {
  final GlobalKey _repaintKey = GlobalKey();

  List<Stroke> strokes = [];
  List<Stroke> undoneStrokes = [];
  Stroke? currentStroke;
  Uint8List? _existingImageBytes; // 
  bool _isLoadingExisting = false;

  Color selectedColor = Colors.red;
  double selectedWidth = 4.0;

  bool isSaving = false;

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }
@override
void initState() {
  super.initState();
  _loadExistingDrawing();
}
Future<void> _loadExistingDrawing() async {
  try {
    setState(() {
      _isLoadingExisting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse(
      "${getBackendUrl()}/api/drawing/last/${widget.activityId}",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String base64Image = data["imageBase64"];
      setState(() {
        _existingImageBytes = base64Decode(base64Image);
      });
    } else if (response.statusCode == 404) {
      // ما في رسم سابق، عادي نتجاهل
      debugPrint("No existing drawing for this activity yet");
    } else {
      debugPrint("Failed to load existing drawing: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error loading existing drawing: $e");
  } finally {
    setState(() {
      _isLoadingExisting = false;
    });
  }
}


  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    final renderBox = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      undoneStrokes.clear();
      currentStroke = Stroke(
        points: [localPosition],
        color: selectedColor,
        width: selectedWidth,
      );
      strokes.add(currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final renderBox = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || currentStroke == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      currentStroke!.points.add(localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      currentStroke = null;
    });
  }

  void _clearCanvas() {
  setState(() {
    strokes.clear();
    undoneStrokes.clear();
    currentStroke = null;

    _existingImageBytes = null;
  });
}


void _undo() {
  if (strokes.isEmpty) return;
  setState(() {
    final lastStroke = strokes.removeLast();
    undoneStrokes.add(lastStroke);
  });
}

void _redo() {
  if (undoneStrokes.isEmpty) return;
  setState(() {
    final stroke = undoneStrokes.removeLast();
    strokes.add(stroke);
  });
}


Widget _buildBackgroundImage() {
  if (_existingImageBytes != null) {
    return Image.memory(
      _existingImageBytes!,
      fit: BoxFit.contain,
    );
  } else {
    return Image.network(
      widget.imageUrl,
      fit: BoxFit.contain,
    );
  }
}

  Future<void> _saveDrawing() async {
    try {
      setState(() {
        isSaving = true;
      });

      // أخذ صورة من الـ RepaintBoundary
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception("Failed to convert image");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();
      String base64Image = base64Encode(pngBytes);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final url = Uri.parse("${getBackendUrl()}/api/drawing/save");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "activityId": widget.activityId,
          "drawingImage": base64Image,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Drawing saved 🎉")),
        );
        Navigator.pop(context); // رجوع لقائمة الأنشطة
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Failed to save drawing (${response.statusCode}) ❌"),
          ),
        );
      }
    } catch (e) {
      debugPrint("Save drawing error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error while saving: $e")),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorOptions = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.black,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearCanvas,
            tooltip: "Clear",
          ),
          IconButton(
            icon: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: isSaving ? null : _saveDrawing,
            tooltip: "Save",
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas + صورة النشاط
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: (details) =>
                        _onPanStart(details, constraints),
                    onPanUpdate: (details) =>
                        _onPanUpdate(details, constraints),
                    onPanEnd: _onPanEnd,
                   child: RepaintBoundary(
  key: _repaintKey,
  child: Stack(
    fit: StackFit.expand,
    children: [
      _buildBackgroundImage(),

      // طبقة الرسم
      CustomPaint(
        painter: _DrawingPainter(strokes: strokes),
      ),
    ],
  ),
),

                  );
                },
              ),
            ),
          ),

          // لوحة الألوان
        Container(
  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
  color: Colors.white,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // الصف الأول: الألوان + Undo/Redo
      Row(
        children: [
          const Text("Color: "),
          const SizedBox(width: 8),
          ...colorOptions.map((c) {
            final isSelected = c == selectedColor;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = c;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 30 : 24,
                height: isSelected ? 30 : 24,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: "Undo",
            onPressed: strokes.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: "Redo",
            onPressed: undoneStrokes.isNotEmpty ? _redo : null,
          ),
        ],
      ),

      const SizedBox(height: 8),

      // الصف الثاني: حجم الفرشاة + سلايدر
      Row(
        children: [
          const Text("Size: "),
          Expanded(
            child: Slider(
              value: selectedWidth,
              min: 2,
              max: 12,
              onChanged: (v) {
                setState(() {
                  selectedWidth = v;
                });
              },
            ),
          ),
        ],
      ),
    ],
  ),
)

        ],
      ),
    );
  }
}



// ==================== MODEL + PAINTER ====================

class Stroke {
  List<Offset> points;
  Color color;
  double width;

  Stroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

   @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return true; 
  }

}
