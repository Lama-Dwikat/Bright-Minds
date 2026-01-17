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

/// =================== NEW: TOOLS / SHAPES / STICKERS ===================
enum ToolMode { draw, shape, sticker }

enum ShapeType { circle, square, triangle, star }

class CanvasShape {
  final Offset center;
  final ShapeType type;
  final double size;
  final Color color;

  CanvasShape({
    required this.center,
    required this.type,
    required this.size,
    required this.color,
  });
}

class CanvasSticker {
  final Offset center;
  final String emoji;
  final double size;

  CanvasSticker({
    required this.center,
    required this.emoji,
    required this.size,
  });
}

/// helpers للـ cos/sin بدون dart:math
class MathTrig {
  static double cos(double x) => _sin(x + 1.5707963267948966);
  static double sin(double x) => _sin(x);

  static double _sin(double x) {
    // Taylor approximation - good enough for UI shapes
    // normalize a bit to keep values stable
    while (x > 3.141592653589793) x -= 2 * 3.141592653589793;
    while (x < -3.141592653589793) x += 2 * 3.141592653589793;

    double term = x;
    double sum = x;
    for (int i = 1; i < 7; i++) {
      term *= -1 * x * x / ((2 * i) * (2 * i + 1));
      sum += term;
    }
    return sum;
  }
}

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

  Uint8List? _existingImageBytes;
  bool _isLoadingExisting = false;

  /// ✅ NEW: shapes + stickers
  ToolMode _mode = ToolMode.draw;
  List<CanvasShape> shapes = [];
  List<CanvasSticker> stickers = [];

  ShapeType selectedShape = ShapeType.circle;
  double selectedShapeSize = 60;

  String selectedSticker = "⭐";
  double selectedStickerSize = 44;

  /// ✅ Colors (more & consistent)
  Color selectedColor = const Color(0xFFEF4444);
  double selectedWidth = 4.0;

  bool isSaving = false;
  bool isSending = false;

  String? _activitySessionId; // timing session id
  String? _lastSavedDrawingId; // ✅ after save, we store drawingId

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    _loadExistingDrawing();
    _startActivityTiming();
  }

  @override
  void dispose() {
    _stopActivityTiming();
    super.dispose();
  }

  // ================= TIMING =================
  Future<void> _startActivityTiming() async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⛔ start timing: token is null");
        return;
      }

      final url = Uri.parse("${getBackendUrl()}/api/drawing/time/start");
      debugPrint("➡️ START TIMING URL: $url");

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "scope": "activity",
          "activityId": widget.activityId,
        }),
      );

      debugPrint("✅ START TIMING status: ${resp.statusCode}");
      debugPrint("✅ START TIMING body: ${resp.body}");

      if (resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        _activitySessionId = data["sessionId"];
        debugPrint("🟢 sessionId saved: $_activitySessionId");
      } else {
        debugPrint("🔴 start timing failed");
      }
    } catch (e) {
      debugPrint("❌ start activity timing error: $e");
    }
  }

  Future<void> _stopActivityTiming() async {
    if (_activitySessionId == null) {
      debugPrint("⚠️ stop timing: no sessionId");
      return;
    }

    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint("⛔ stop timing: token is null");
        return;
      }

      final url = Uri.parse("${getBackendUrl()}/api/drawing/time/stop");
      debugPrint("➡️ STOP TIMING URL: $url");
      debugPrint("➡️ STOP TIMING sessionId: $_activitySessionId");

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"sessionId": _activitySessionId}),
      );

      debugPrint("✅ STOP TIMING status: ${resp.statusCode}");
      debugPrint("✅ STOP TIMING body: ${resp.body}");

      if (resp.statusCode == 200) {
        _activitySessionId = null;
        debugPrint("🟢 session stopped & cleared");
      } else {
        debugPrint("🔴 stop timing failed");
      }
    } catch (e) {
      debugPrint("❌ stop activity timing error: $e");
    }
  }

  // ================= LOAD LAST DRAWING =================
  Future<void> _loadExistingDrawing() async {
    try {
      setState(() => _isLoadingExisting = true);

      final token = await _getToken();
      if (token == null) return;

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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String base64Image = data["imageBase64"];
        setState(() {
          _existingImageBytes = base64Decode(base64Image);
        });
      } else if (response.statusCode == 404) {
        debugPrint("No existing drawing for this activity yet");
      } else {
        debugPrint("Failed to load existing drawing: ${response.statusCode}");
        debugPrint("BODY: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error loading existing drawing: $e");
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  // ================= DRAWING EVENTS =================
  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_mode != ToolMode.draw) return;

    final renderBox =
        _repaintKey.currentContext?.findRenderObject() as RenderBox?;
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
    if (_mode != ToolMode.draw) return;

    final renderBox =
        _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || currentStroke == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      currentStroke!.points.add(localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_mode != ToolMode.draw) return;
    setState(() => currentStroke = null);
  }

  void _clearCanvas() {
    setState(() {
      strokes.clear();
      undoneStrokes.clear();
      currentStroke = null;

      shapes.clear();
      stickers.clear();

      _existingImageBytes = null;
      _lastSavedDrawingId = null; // reset saved id
    });
  }

  void _undo() {
    // Undo should affect current tool contents as well
    setState(() {
      if (_mode == ToolMode.draw) {
        if (strokes.isEmpty) return;
        final lastStroke = strokes.removeLast();
        undoneStrokes.add(lastStroke);
        return;
      }

      if (_mode == ToolMode.shape) {
        if (shapes.isEmpty) return;
        shapes.removeLast();
        return;
      }

      if (_mode == ToolMode.sticker) {
        if (stickers.isEmpty) return;
        stickers.removeLast();
        return;
      }
    });
  }

  void _redo() {
    // redo only for strokes (original behavior)
    if (_mode != ToolMode.draw) return;
    if (undoneStrokes.isEmpty) return;
    setState(() {
      final stroke = undoneStrokes.removeLast();
      strokes.add(stroke);
    });
  }

  Widget _buildBackgroundImage() {
    if (_isLoadingExisting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_existingImageBytes != null) {
      return Image.memory(_existingImageBytes!, fit: BoxFit.contain);
    }
    return Image.network(widget.imageUrl, fit: BoxFit.contain);
  }

  Future<Uint8List> _capturePngBytes() async {
    final boundary =
        _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception("Failed to convert image");
    return byteData.buffer.asUint8List();
  }

  // ================= SAVE (My Drawings) =================
  Future<void> _saveDrawingLocal() async {
    try {
      setState(() => isSaving = true);

      final pngBytes = await _capturePngBytes();
      final base64Image = base64Encode(pngBytes);

      final token = await _getToken();
      if (token == null) return;

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

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _lastSavedDrawingId = data["id"]; // ✅ store drawing id

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Saved to My Drawings ✅")),
        );
      } else {
        debugPrint("SAVE FAILED: ${response.statusCode} BODY: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed (${response.statusCode}) ❌")),
        );
      }
    } catch (e) {
      debugPrint("Save drawing error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error while saving: $e")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  // ================= SUBMIT (Send to Supervisor) =================
  Future<void> _sendToSupervisor() async {
    if (_lastSavedDrawingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please Save first before sending ✋")),
      );
      return;
    }

    try {
      setState(() => isSending = true);

      final token = await _getToken();
      if (token == null) return;

      // ✅ NOTE: submit by drawingId (no duplicate drawings)
      final url = Uri.parse(
        "${getBackendUrl()}/api/drawing/submit/$_lastSavedDrawingId",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sent to supervisor ✅")),
        );
      } else {
        debugPrint(
            "SUBMIT FAILED: ${response.statusCode} BODY: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Send failed (${response.statusCode}) ❌")),
        );
      }
    } catch (e) {
      debugPrint("Send error: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error while sending: $e")),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  /// ================= UI HELPERS =================
  Widget _toolChip(String text, IconData icon, ToolMode mode) {
    final active = _mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _mode = mode),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.bgWarmPink.withOpacity(0.35)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? Colors.black87 : Colors.grey.shade300,
              width: active ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shapePicker() {
    final items = [
      (ShapeType.circle, Icons.circle),
      (ShapeType.square, Icons.crop_square),
      (ShapeType.triangle, Icons.change_history),
      (ShapeType.star, Icons.star),
    ];

    return Row(
      children: items.map((it) {
        final type = it.$1;
        final icon = it.$2;
        final active = selectedShape == type;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => selectedShape = type),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? Colors.black.withOpacity(0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? Colors.black : Colors.grey.shade300,
                ),
              ),
              child: Icon(icon),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _stickerPicker() {
    final emojis = ["⭐", "❤️", "🌸", "🦋", "😄", "🍭", "🎈", "🐱", "🐶", "👑"];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: emojis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = emojis[i];
          final active = selectedSticker == e;

          return GestureDetector(
            onTap: () => setState(() => selectedSticker = e),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.bgWarmPink.withOpacity(0.3)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? Colors.black : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(e, style: const TextStyle(fontSize: 24)),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorOptions = [
      const Color(0xFFEF4444), // red
      const Color(0xFFF97316), // orange
      const Color(0xFFF59E0B), // amber
      const Color(0xFF22C55E), // green
      const Color(0xFF06B6D4), // cyan
      const Color(0xFF3B82F6), // blue
      const Color(0xFF6366F1), // indigo
      const Color(0xFFA855F7), // purple
      const Color(0xFFEC4899), // pink
      const Color(0xFF111827), // near black
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.warmHoneyYellow,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearCanvas,
            tooltip: "Clear",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onTapDown: (details) {
                      final renderBox =
                          _repaintKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      if (renderBox == null) return;

                      final local =
                          renderBox.globalToLocal(details.globalPosition);

                      setState(() {
                        if (_mode == ToolMode.shape) {
                          shapes.add(CanvasShape(
                            center: local,
                            type: selectedShape,
                            size: selectedShapeSize,
                            color: selectedColor,
                          ));
                        } else if (_mode == ToolMode.sticker) {
                          stickers.add(CanvasSticker(
                            center: local,
                            emoji: selectedSticker,
                            size: selectedStickerSize,
                          ));
                        }
                      });
                    },
                    onPanStart: (details) => _onPanStart(details, constraints),
                    onPanUpdate: (details) => _onPanUpdate(details, constraints),
                    onPanEnd: _onPanEnd,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildBackgroundImage(),
                          CustomPaint(
                            painter: _DrawingPainter(
                              strokes: strokes,
                              shapes: shapes,
                              stickers: stickers,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ✅ Buttons: Save + Send (unchanged)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _saveDrawingLocal,
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text("Save"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSending ? null : _sendToSupervisor,
                    icon: isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text("Send to Supervisor"),
                  ),
                ),
              ],
            ),
          ),

          // Tools + Colors + Undo/Redo + Size + Shape/Sticker panels
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Tool selector
                Row(
                  children: [
                    _toolChip("Draw", Icons.edit, ToolMode.draw),
                    const SizedBox(width: 8),
                    _toolChip("Shape", Icons.category, ToolMode.shape),
                    const SizedBox(width: 8),
                    _toolChip("Sticker", Icons.emoji_emotions, ToolMode.sticker),
                  ],
                ),
                const SizedBox(height: 10),

                // Colors + Undo/Redo
                Row(
                  children: [
                    const Text("Color: "),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: colorOptions.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final c = colorOptions[i];
                            final isSelected = c == selectedColor;
                            return GestureDetector(
                              onTap: () => setState(() => selectedColor = c),
                              child: Container(
                                width: isSelected ? 34 : 28,
                                height: isSelected ? 34 : 28,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.black
                                        : Colors.grey.shade400,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.undo),
                      tooltip: "Undo",
                      onPressed: () {
                        final canUndo = (_mode == ToolMode.draw && strokes.isNotEmpty) ||
                            (_mode == ToolMode.shape && shapes.isNotEmpty) ||
                            (_mode == ToolMode.sticker && stickers.isNotEmpty);
                        if (canUndo) _undo();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      tooltip: "Redo",
                      onPressed: (_mode == ToolMode.draw && undoneStrokes.isNotEmpty)
                          ? _redo
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Size slider for draw
                if (_mode == ToolMode.draw)
                  Row(
                    children: [
                      const Text("Brush size: "),
                      Expanded(
                        child: Slider(
                          value: selectedWidth,
                          min: 2,
                          max: 12,
                          onChanged: (v) => setState(() => selectedWidth = v),
                        ),
                      ),
                    ],
                  ),

                // Shape controls
                if (_mode == ToolMode.shape) ...[
                  _shapePicker(),
                  Row(
                    children: [
                      const Text("Shape size: "),
                      Expanded(
                        child: Slider(
                          value: selectedShapeSize,
                          min: 30,
                          max: 120,
                          onChanged: (v) =>
                              setState(() => selectedShapeSize = v),
                        ),
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Tip: Tap on the canvas to place the shape ✨",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],

                // Sticker controls
                if (_mode == ToolMode.sticker) ...[
                  _stickerPicker(),
                  Row(
                    children: [
                      const Text("Sticker size: "),
                      Expanded(
                        child: Slider(
                          value: selectedStickerSize,
                          min: 28,
                          max: 90,
                          onChanged: (v) =>
                              setState(() => selectedStickerSize = v),
                        ),
                      ),
                    ],
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Tip: Tap on the canvas to place the sticker 😍",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
  final List<CanvasShape> shapes;
  final List<CanvasSticker> stickers;

  _DrawingPainter({
    required this.strokes,
    required this.shapes,
    required this.stickers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1) shapes
    for (final s in shapes) {
      final paint = Paint()
        ..color = s.color.withOpacity(0.9)
        ..style = PaintingStyle.fill;

      switch (s.type) {
        case ShapeType.circle:
          canvas.drawCircle(s.center, s.size / 2, paint);
          break;

        case ShapeType.square:
          final rect = Rect.fromCenter(
            center: s.center,
            width: s.size,
            height: s.size,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(12)),
            paint,
          );
          break;

        case ShapeType.triangle:
          final path = Path()
            ..moveTo(s.center.dx, s.center.dy - s.size / 2)
            ..lineTo(s.center.dx - s.size / 2, s.center.dy + s.size / 2)
            ..lineTo(s.center.dx + s.size / 2, s.center.dy + s.size / 2)
            ..close();
          canvas.drawPath(path, paint);
          break;

        case ShapeType.star:
          final path = Path();
          final rOuter = s.size / 2;
          final rInner = rOuter * 0.45;

          for (int i = 0; i < 10; i++) {
            final isOuter = i.isEven;
            final r = isOuter ? rOuter : rInner;
            final angle = (i * 36.0 - 90.0) * 3.141592653589793 / 180.0;

            final x = s.center.dx + r * MathTrig.cos(angle);
            final y = s.center.dy + r * MathTrig.sin(angle);

            if (i == 0) {
              path.moveTo(x, y);
            } else {
              path.lineTo(x, y);
            }
          }
          path.close();
          canvas.drawPath(path, paint);
          break;
      }
    }

    // 2) stickers (Emoji)
    for (final st in stickers) {
      final tp = TextPainter(
        text: TextSpan(
          text: st.emoji,
          style: TextStyle(fontSize: st.size),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(st.center.dx - tp.width / 2, st.center.dy - tp.height / 2),
      );
    }

    // 3) strokes (original)
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
