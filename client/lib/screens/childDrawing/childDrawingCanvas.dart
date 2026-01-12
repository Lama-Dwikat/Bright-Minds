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

  Uint8List? _existingImageBytes;
  bool _isLoadingExisting = false;

  Color selectedColor = Colors.red;
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
    final renderBox =
        _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || currentStroke == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    setState(() {
      currentStroke!.points.add(localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => currentStroke = null);
  }

  void _clearCanvas() {
    setState(() {
      strokes.clear();
      undoneStrokes.clear();
      currentStroke = null;
      _existingImageBytes = null;
      _lastSavedDrawingId = null; // reset saved id
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
        debugPrint("SUBMIT FAILED: ${response.statusCode} BODY: ${response.body}");
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
                    onPanStart: (details) => _onPanStart(details, constraints),
                    onPanUpdate: (details) => _onPanUpdate(details, constraints),
                    onPanEnd: _onPanEnd,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildBackgroundImage(),
                          CustomPaint(painter: _DrawingPainter(strokes: strokes)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ✅ Buttons: Save + Send
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

          // Colors + Undo/Redo + Size
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text("Color: "),
                    const SizedBox(width: 8),
                    ...colorOptions.map((c) {
                      final isSelected = c == selectedColor;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = c),
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
                Row(
                  children: [
                    const Text("Size: "),
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
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
