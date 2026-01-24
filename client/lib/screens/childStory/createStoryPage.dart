/*import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/widgets/DraggableTextWidget.dart';
import 'package:bright_minds/widgets/DraggableImageWidget.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:bright_minds/screens/childStory/loadingDragon.dart';

class CreateStoryPage extends StatefulWidget {
  final String? storyId;
  const CreateStoryPage({super.key, this.storyId});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  String storyTitle = "My Story";
  bool isDrawingMode = false;

  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;
  List<DrawPoint> drawingPoints = [];
  List<DrawPoint> redoStack = [];
  bool isGeneratingAI = false;

  int currentPageIndex = 0;
  List<List<Map<String, dynamic>>> pages = [[]]; // كل صفحة تحتوي عناصرها

  bool isRecording = false;
  final _audioRecorder = AudioRecorder();
  String? recordedFilePath;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = "";
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  // Main Brand Color
  final Color mainPurple = AppColors.pastelYellow;

  final List<String> storyImageAssets = [
    'assets/story_images/discussion.png',
    'assets/story_images/Drawing.png',
    'assets/story_images/energy.png',
    'assets/story_images/Games2.png',
    'assets/story_images/b.avif',
    'assets/story_images/a.jpg',
    'assets/story_images/c.jpg',
    'assets/story_images/d.webp',
  ];

  String? _storySessionId;
  DateTime? _lastPingAt;
  bool _timingStarted = false;
  bool _endingTiming = false;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // call when any activity happens
  Future<void> _markStoryActivity() async {
    final prefs = await SharedPreferences.getInstance();
    String? storyId = prefs.getString("currentStoryId");

    // لو ما في storyId (قصة جديدة)، لا نبدأ session إلا بعد ما تنعمل create story
    if (storyId == null) return;

    final token = await _getToken();
    if (token == null) return;

    // 1) start once
    if (!_timingStarted || _storySessionId == null) {
      final res = await http.post(
        Uri.parse("${getBackendUrl()}/api/storyTime/start"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"storyId": storyId}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _storySessionId = data["sessionId"];
        _timingStarted = true;
        _lastPingAt = DateTime.now();
      }
      return;
    }

    // 2) ping throttle (مثلاً كل 20 ثانية)
    final now = DateTime.now();
    if (_lastPingAt != null && now.difference(_lastPingAt!).inSeconds < 20) {
      return;
    }

    final res = await http.post(
      Uri.parse("${getBackendUrl()}/api/storyTime/ping"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"sessionId": _storySessionId}),
    );

    if (res.statusCode == 200) {
      _lastPingAt = now;
    }
  }

  Future<void> _endTiming(String reason) async {
    if (_endingTiming) return;
    if (_storySessionId == null) return;

    _endingTiming = true;

    try {
      final token = await _getToken();
      if (token == null) return;

      await http.post(
        Uri.parse("${getBackendUrl()}/api/storyTime/end"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({"sessionId": _storySessionId, "reason": reason}),
      );
    } catch (_) {
      // ignore
    } finally {
      _endingTiming = false;
      _storySessionId = null;
      _timingStarted = false;
    }
  }

  String getBackendUrl() {
    if (kIsWeb) {
      // return "http://192.168.1.63:3000";
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  // ===================== WEB RESPONSIVE HELPERS (UI ONLY) =====================
  double _maxContentWidth(double w) {
    if (w >= 900) return 1200; // وسّط المحتوى بالويب
    return w;
  }

  double _canvasWidthFor(double w) {
    // موبايل: 80% زي ما عندك
    if (w < 600) return w * 0.80;

    // ويب: نخليه ثابت/ألطف حسب العرض
    if (w < 900) return 680;
    if (w < 1200) return 820;
    return 920;
  }

  double _canvasHeightFor(double h) {
    // نفس منطقك تقريباً (60% من ارتفاع الشاشة)
    // بس على الويب بنقلّل شوي حتى ما يصير طويل زيادة
    if (h < 700) return h * 0.60;
    if (kIsWeb) return h * 0.62;
    return h * 0.60;
  }
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    if (widget.storyId != null) {
      _loadStoryData(widget.storyId!);

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('currentStoryId', widget.storyId!);
      });
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('currentStoryId');
      });
    }
  }

  @override
  void dispose() {
    _endTiming("exit");
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _endTiming("exit");
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 246, 228, 201),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              final contentMaxW = _maxContentWidth(screenW);
              final canvasW = _canvasWidthFor(screenW);
              final canvasH = _canvasHeightFor(screenH);

              return Stack(
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxW),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              _buildTitleBar(),
                              const SizedBox(height: 10),
                              _buildPageIndicator(),
                              const SizedBox(height: 10),

                              // ---------- CANVAS ----------
                              Expanded(
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Container(
                                    width: canvasW,
                                    height: canvasH,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.10),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // ========= DRAWING BACKGROUND =========
                                        Positioned.fill(
                                          child: AbsorbPointer(
                                            absorbing: !isDrawingMode,
                                            child: GestureDetector(
                                              behavior:
                                                  HitTestBehavior.translucent,
                                              onPanStart: (details) {
                                                _markStoryActivity();

                                                if (!isDrawingMode) return;
                                                setState(() {
                                                  redoStack.clear();
                                                  drawingPoints.add(DrawPoint(
                                                    position:
                                                        details.localPosition,
                                                    color: selectedColor,
                                                    width: strokeWidth,
                                                  ));
                                                });
                                              },
                                              onPanUpdate: (details) {
                                                if (!isDrawingMode) return;
                                                _markStoryActivity();

                                                setState(() {
                                                  drawingPoints.add(DrawPoint(
                                                    position:
                                                        details.localPosition,
                                                    color: selectedColor,
                                                    width: strokeWidth,
                                                  ));
                                                });
                                              },
                                              onPanEnd: (_) {
                                                if (!isDrawingMode) return;
                                                _markStoryActivity();
                                                setState(() {
                                                  drawingPoints.add(
                                                      DrawPoint(position: null));
                                                });
                                              },
                                              child: CustomPaint(
                                                painter:
                                                    DrawPainter(drawingPoints),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // ========= STORY ELEMENTS =========
                                        ...pages[currentPageIndex]
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          final item = entry.value;

                                          if (item["type"] == "text") {
                                            return DraggableTextWidget(
                                              key: item["key"],
                                              text: item["text"],
                                              color:
                                                  item["color"] ?? Colors.black,
                                              fontSize:
                                                  item["fontSize"] ?? 20.0,
                                              isBold: item["isBold"] ?? false,
                                              isItalic:
                                                  item["isItalic"] ?? false,
                                              isUnderlined: item["isUnderlined"] ??
                                                  false,
                                              x: item["x"] ?? 50.0,
                                              y: item["y"] ?? 50.0,
                                              onPositionChanged: (newX, newY) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["x"] = newX;
                                                  item["y"] = newY;
                                                });
                                              },
                                              onStyleChanged: (color, size, bold,
                                                  italic, underline) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["color"] = color;
                                                  item["fontSize"] = size;
                                                  item["isBold"] = bold;
                                                  item["isItalic"] = italic;
                                                  item["isUnderlined"] =
                                                      underline;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  pages[currentPageIndex]
                                                      .removeWhere((e) =>
                                                          e["key"] ==
                                                          item["key"]);
                                                });
                                                _markStoryActivity();
                                              },
                                            );
                                          }

                                          if (item["type"] == "image") {
                                            return DraggableImageWidget(
                                              key: item["key"],
                                              imagePath: item["imagePath"],
                                              x: item["x"] ?? 40.0,
                                              y: item["y"] ?? 40.0,
                                              width: item["width"] ?? 150.0,
                                              height: item["height"] ?? 150.0,
                                              onPositionChanged: (newX, newY) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["x"] = newX;
                                                  item["y"] = newY;
                                                });
                                              },
                                              onResize: (newW, newH) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["width"] = newW;
                                                  item["height"] = newH;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  pages[currentPageIndex]
                                                      .removeWhere((e) =>
                                                          e["key"] ==
                                                          item["key"]);
                                                });
                                                _markStoryActivity();
                                              },
                                            );
                                          }

                                          if (item["type"] == "drawn_image") {
                                            return DraggableImageWidget(
                                              key: item["key"],
                                              bytes: item["bytes"],
                                              x: item["x"] ?? 40.0,
                                              y: item["y"] ?? 40.0,
                                              width: item["width"] ?? 150.0,
                                              height: item["height"] ?? 150.0,
                                              onPositionChanged: (newX, newY) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["x"] = newX;
                                                  item["y"] = newY;
                                                });
                                              },
                                              onResize: (newW, newH) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["width"] = newW;
                                                  item["height"] = newH;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  pages[currentPageIndex]
                                                      .removeWhere((e) =>
                                                          e["key"] ==
                                                          item["key"]);
                                                });
                                                _markStoryActivity();
                                              },
                                            );
                                          }

                                          if (item["type"] == "uploaded_image") {
                                            return DraggableImageWidget(
                                              key: item["key"],
                                              networkUrl: item["networkUrl"],
                                              bytes: item["bytes"],
                                              x: item["x"] ?? 40.0,
                                              y: item["y"] ?? 40.0,
                                              width: item["width"] ?? 150.0,
                                              height: item["height"] ?? 150.0,
                                              onPositionChanged: (newX, newY) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["x"] = newX;
                                                  item["y"] = newY;
                                                });
                                              },
                                              onResize: (newW, newH) {
                                                _markStoryActivity();
                                                setState(() {
                                                  item["width"] = newW;
                                                  item["height"] = newH;
                                                });
                                              },
                                              onDelete: () {
                                                setState(() {
                                                  pages[currentPageIndex]
                                                      .removeWhere((e) =>
                                                          e["key"] ==
                                                          item["key"]);
                                                });
                                                _markStoryActivity();
                                              },
                                            );
                                          }

                                          // ===== AUDIO ELEMENT =====
                                          if (item["type"] == "audio") {
                                            return Positioned(
                                              left: item["x"] ?? 40.0,
                                              top: item["y"] ?? 40.0,
                                              child: Container(
                                                width: 200,
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFFFF5F5),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 4,
                                                    )
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.audiotrack,
                                                        color: Color.fromARGB(
                                                            255, 240, 169, 70)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Voice note",
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.play_arrow,
                                                        color: Color.fromARGB(
                                                            255, 240, 169, 70),
                                                      ),
                                                      onPressed: () async {
                                                        // ✅ لا نغيّر موبايل/دسكتوب
                                                        // ✅ فقط على الويب نمنع الكراش
                                                        if (kIsWeb) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  "Audio playback from local file is not supported on Web."),
                                                            ),
                                                          );
                                                          return;
                                                        }

                                                        final file =
                                                            File(item["path"]);
                                                        if (await file.exists()) {
                                                          await Process.run(
                                                            'start',
                                                            [file.path],
                                                            runInShell: true,
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    "File not found!")),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }

                                          return const SizedBox();
                                        }).toList(),

                                        if (pages[currentPageIndex].isEmpty)
                                          Center(
                                            child: Text(
                                              "Tap tools to add elements",
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),

                          // Bottom toolbar (fixed)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              ignoring: isDrawingMode,
                              child: _buildBottomToolbar(),
                            ),
                          ),

                          // drawing overlay
                          if (isDrawingMode) _drawingToolsOverlay(),
                          if (isGeneratingAI)
                            Container(
                              alignment: Alignment.center,
                              color: Colors.white.withOpacity(0.75),
                              child: const LoadingDragon(),
                            ),

                          // tools button
                          Positioned(
                            top: 80,
                            left: 10,
                            child: _buildToolsButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  //                          TITLE BAR
  // ============================================================
  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 237, 198, 145),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.edit, color: Color.fromARGB(255, 240, 169, 70)),
            const SizedBox(width: 10),

            Expanded(
              child: TextField(
                controller: _titleController,
                onChanged: (value) {
                  storyTitle = value;
                  _markStoryActivity();
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Story Title",
                ),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.save_rounded,
                  color: Color.fromARGB(255, 240, 169, 70), size: 28),
              tooltip: "Save your story",
              onPressed: () async {
                final choice = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.badgesButton,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: const [
                        Icon(Icons.save_rounded,
                            color: Color.fromARGB(255, 240, 169, 70), size: 30),
                        SizedBox(width: 10),
                        Text(
                          "Save Story",
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "Would you like to send your story to your supervisor or save it as a draft?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color.fromARGB(255, 240, 169, 70),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, "send"),
                        child: const Text("Send to Supervisor"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              const Color.fromARGB(255, 250, 202, 134),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, "draft"),
                        child: const Text("Save as Draft"),
                      ),
                    ],
                  ),
                );

                if (choice == "send") {
                  _saveStory(sendToSupervisor: true);
                } else if (choice == "draft") {
                  _saveStory(sendToSupervisor: false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //                      PAGE INDICATOR
  // ============================================================
  Widget _buildPageIndicator() {
    return Text(
      "Page ${currentPageIndex + 1} / ${pages.length}",
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color.fromARGB(255, 241, 164, 55),
      ),
    );
  }

  // ============================================================
  //                   BOTTOM CONTROL TOOLBAR
  // ============================================================
  Widget _buildBottomToolbar() {
    print("🧩 Building bottom toolbar...");

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.badgesButton,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // record story
          IconButton(
            icon: Icon(
              (_isListening || isRecording)
                  ? Icons.stop_circle_outlined
                  : Icons.mic,
              color: (_isListening || isRecording)
                  ? Color.fromARGB(255, 245, 168, 60)
                  : const Color.fromARGB(255, 251, 198, 122),
              size: 32,
            ),
            tooltip: "Add Voice or Speech",
            onPressed: () async {
              print(
                  "🎤 Button pressed | isListening=$_isListening | isRecording=$isRecording");

              if (_isListening) {
                print("🛑 Stopping speech recognition...");
                await _stopListening();
                setState(() => _isListening = false);
                return;
              }

              if (isRecording) {
                print("🛑 Stopping voice recording...");
                await _stopRecording();
                setState(() => isRecording = false);
                return;
              }

              print("📢 Opening choice dialog...");
              final choice = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.badgesButton,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text(
                    "Choose an action 🎙️",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Text(
                    "Would you like to record your voice or speak to write the story?",
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 240, 169, 70),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, "record"),
                      icon: const Icon(Icons.mic, color: Colors.white),
                      label: const Text("Record Voice",
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, "speech"),
                      icon: const Icon(Icons.record_voice_over,
                          color: Color.fromARGB(255, 240, 169, 70)),
                      label: const Text("Speak to Write",
                          style: TextStyle(
                              color: Color.fromARGB(255, 240, 169, 70))),
                    ),
                  ],
                ),
              );

              print("👉 User selected: $choice");

              if (choice == "record") {
                setState(() => isRecording = true);
                await _startRecording();
              } else if (choice == "speech") {
                setState(() => _isListening = true);
                await _startListening();
              }
            },
          ),

          IconButton(
            icon: const Icon(Icons.undo,
                color: Color.fromARGB(255, 240, 169, 70)),
            tooltip: "Previous Page",
            onPressed: currentPageIndex > 0
                ? () {
                    setState(() {
                      currentPageIndex--;
                    });
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo,
                color: Color.fromARGB(255, 240, 169, 70)),
            tooltip: "Next Page",
            onPressed: currentPageIndex < pages.length - 1
                ? () {
                    setState(() {
                      currentPageIndex++;
                    });
                  }
                : null,
          ),

          // delete page
          IconButton(
            icon: const Icon(Icons.delete,
                color: Color.fromARGB(255, 240, 169, 70)),
            tooltip: "Delete this page",
            onPressed: () async {
              if (pages.isEmpty) return;

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFFFFF8F9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Color.fromARGB(255, 240, 169, 70), size: 30),
                      SizedBox(width: 10),
                      Text(
                        "Delete Page?",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "Are you sure you want to delete this entire page and all its content? 😢",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color.fromARGB(255, 240, 169, 70),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() {
                  pages.removeAt(currentPageIndex);

                  if (currentPageIndex >= pages.length) {
                    currentPageIndex = pages.isEmpty ? 0 : pages.length - 1;
                  }

                  if (pages.isEmpty) {
                    pages.add([]);
                    currentPageIndex = 0;
                  }
                });
                _markStoryActivity();
              }
            },
          ),

          // add page
          IconButton(
            tooltip: "Add New Page",
            icon: const Icon(Icons.add_circle_rounded, color: Color.fromARGB(255, 240, 169, 70)),
            onPressed: () async {
              print("🟣 Add button pressed!");

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  print("🟢 Dialog opened!");
                  return AlertDialog(
                    backgroundColor: Color.fromARGB(255, 249, 234, 213),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: const [
                        Icon(Icons.add_circle_rounded,
                            color: Color.fromARGB(255, 240, 169, 70), size: 30),
                        SizedBox(width: 10),
                        Text(
                          "Add New Page?",
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "Do you want to add a new blank page for your story?",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color.fromARGB(255, 240, 169, 70),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Color.fromARGB(255, 240, 169, 70),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child:
                            const Text("Add", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                },
              );

              print("🟡 Dialog result: $confirm");

              if (confirm == true) {
                setState(() {
                  pages.add([]);
                  currentPageIndex = pages.length - 1;
                });
                _markStoryActivity();
                print(
                    "✅ Added new page — total: ${pages.length}, now at: $currentPageIndex");
              }
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  //                    LEFT TOOLS BUTTON
  // ============================================================
  Widget _buildToolsButton() {
    return GestureDetector(
      onTap: () => _openToolsDrawer(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 240, 169, 70),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.menu, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  // ============================================================
  //                        TOOLS DRAWER
  // ============================================================
  void _openToolsDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Tools",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Text(
                    "Tools",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 240, 169, 70),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _toolOption(Icons.text_fields, "Add Text", () {
                    Navigator.pop(context);
                    _showAddTextDialog();
                  }),
                  _toolOption(Icons.image, "Add Image", () {
                    Navigator.pop(context);
                    _showImageAssetsPicker();
                  }),
                  _toolOption(Icons.draw, "Draw", () {
                    Navigator.pop(context);
                    setState(() {
                      isDrawingMode = true;
                    });
                  }),
                  _toolOption(Icons.upload_file, "Upload Picture", () async {
                    Navigator.pop(context);

                    if (kIsWeb) {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );

                      if (result != null && result.files.isNotEmpty) {
                        final bytes = result.files.first.bytes!;
                        _addUploadedImageFromBytes(bytes);
                      }
                    } else {
                      final picker = ImagePicker();
                      final XFile? picked =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (picked != null) {
                        final file = File(picked.path);
                        final bytes = await file.readAsBytes();
                        _addUploadedImageFromBytes(bytes);
                      }
                    }
                  }),
                  _toolOption(Icons.auto_fix_high, "AI Generated Image", () {
                    Navigator.pop(context);
                    _openAIGenerateDialog();
                  }),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(animation),
          child: child,
        );
      },
    );
  }

  Widget _toolOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color.fromARGB(255, 240, 169, 70)),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 18)),
      onTap: onTap,
    );
  }

  // ============================================================
  //                    ADD TEXT DIALOG
  // ============================================================
  void _showAddTextDialog() {
    _textController.text = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Text"),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Type your text here...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 240, 169, 70),
              ),
              onPressed: () {
                final input = _textController.text.trim();
                if (input.isNotEmpty) {
                  _addDraggableText(input);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addDraggableText(String text) {
    final elementKey = UniqueKey();

    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "text",
        "text": text,
        "x": 50.0,
        "y": 50.0,
        "color": Colors.black,
        "fontSize": 20.0,
        "isBold": false,
        "isItalic": false,
        "isUnderlined": false,
      });
    });

    _markStoryActivity();
  }

  // ============================================================
  //                ADD IMAGE FROM ASSETS
  // ============================================================
  void _showImageAssetsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose an image",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: storyImageAssets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final assetPath = storyImageAssets[index];
                  return GestureDetector(
                    onTap: () {
                      _addImageElement(assetPath);
                      Navigator.pop(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addImageElement(String assetPath) {
    final elementKey = UniqueKey();

    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "image",
        "imagePath": assetPath,
        "x": 40.0,
        "y": 40.0,
        "width": 150.0,
        "height": 150.0,
      });
    });

    _markStoryActivity();
  }

  // ============================================================
  //          (من كودك الأصلي) IMAGE PICKER DRAWER الإضافي
  // ============================================================
  void _openImagePickerDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 340,
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _imageThumb("assets/story_images/forest.png"),
              _imageThumb("assets/story_images/castle.png"),
              _imageThumb("assets/story_images/space.png"),
              _imageThumb("assets/story_images/dragon.png"),
              _imageThumb("assets/story_images/b.avif"),
              _imageThumb("assets/story_images/a.jpg"),
              _imageThumb("assets/story_images/c.jpg"),
              _imageThumb("assets/story_images/d.webp"),
            ],
          ),
        );
      },
    );
  }

  Widget _imageThumb(String path) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _addImageElement(path);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }

  // ============================================================
  //                    DRAWING EXPORT / ADD
  // ============================================================
  void _addDrawnImage(Uint8List bytes) {
    final elementKey = UniqueKey();

    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "drawn_image",
        "bytes": bytes,
        "x": 40.0,
        "y": 40.0,
        "width": 150.0,
        "height": 150.0,
      });
    });

    _markStoryActivity();
  }

  Widget _drawingToolsOverlay() {
    return Positioned(
      top: 80,
      right: 10,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            _colorDot(Colors.black),
            _colorDot(Colors.red),
            _colorDot(Colors.blue),
            _colorDot(Colors.green),
            _colorDot(Colors.orange),
            const SizedBox(height: 10),

            const Text("Size", style: TextStyle(fontSize: 12)),
            Slider(
              value: strokeWidth,
              min: 2,
              max: 20,
              activeColor: Color.fromARGB(255, 240, 169, 70),
              onChanged: (v) => setState(() => strokeWidth = v),
            ),

            const SizedBox(height: 5),

            IconButton(
              tooltip: "Undo",
              icon: const Icon(Icons.undo,
                  color: Color.fromARGB(255, 240, 169, 70), size: 26),
              onPressed: _undoDraw,
            ),
            IconButton(
              tooltip: "Redo",
              icon: const Icon(Icons.redo,
                  color: Color.fromARGB(255, 240, 169, 70), size: 26),
              onPressed: _redoDraw,
            ),

            const Divider(
              color: Color.fromARGB(255, 246, 230, 208),
              thickness: 1,
              height: 15,
            ),

            IconButton(
              tooltip: "Done Drawing",
              icon: const Icon(Icons.check_circle_rounded,
                  color: Color.fromARGB(255, 240, 169, 70), size: 30),
              onPressed: () async {
                final pngBytes = await _exportDrawingAsImage();

                if (pngBytes != null) {
                  _addDrawnImage(pngBytes);

                  setState(() {
                    drawingPoints.clear();
                    redoStack.clear();
                    isDrawingMode = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(" Drawing added to your story!")),
                  );
                } else {
                  setState(() => isDrawingMode = false);
                }
              },
            ),

            const SizedBox(height: 8),

            IconButton(
              tooltip: "Delete Drawing",
              icon: const Icon(Icons.delete_forever_rounded,
                  color: Colors.redAccent, size: 30),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Color.fromARGB(255, 240, 169, 70),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            color: Color.fromARGB(255, 240, 169, 70), size: 30),
                        SizedBox(width: 10),
                        Text(
                          "Delete drawing?",
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      "Are you sure you want to clear your drawing? 😢",
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 16,
                      ),
                    ),
                    actionsAlignment: MainAxisAlignment.spaceEvenly,
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color.fromARGB(255, 240, 169, 70),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  setState(() {
                    drawingPoints.clear();
                    redoStack.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorDot(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  void _undoDraw() {
    if (drawingPoints.isEmpty) return;
    setState(() {
      int last = drawingPoints.lastIndexWhere((p) => p.position == null);
      redoStack.addAll(drawingPoints.sublist(last + 1));
      drawingPoints.removeRange(last + 1, drawingPoints.length);
      drawingPoints.removeLast();
    });
    _markStoryActivity();
  }

  void _redoDraw() {
    if (redoStack.isEmpty) return;
    setState(() {
      drawingPoints.addAll(redoStack);
      redoStack.clear();
    });
    _markStoryActivity();
  }

  // ============================================================
  //                    UPLOAD IMAGE
  // ============================================================
  void _addUploadedImageFromBytes(Uint8List bytes) {
    final elementKey = UniqueKey();
    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "uploaded_image",
        "bytes": bytes,
        "x": 40.0,
        "y": 40.0,
        "width": 150.0,
        "height": 150.0,
      });
    });
    _markStoryActivity();
  }

  // ============================================================
  //                    RECORDING / SPEECH
  // ============================================================
  Future<void> _startRecording() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Microphone permission denied")),
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/story_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(const RecordConfig(), path: filePath);
    setState(() {
      isRecording = true;
      recordedFilePath = filePath;
    });
    _markStoryActivity();
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    setState(() {
      isRecording = false;
      recordedFilePath = path;
    });

    if (path != null) {
      setState(() {
        pages[currentPageIndex].add({
          "type": "audio",
          "path": path,
          "x": 50.0,
          "y": 50.0,
          "key": UniqueKey(),
        });
      });

      _markStoryActivity();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎧 Voice recording added to your story!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("STATUS: $status"),
      onError: (error) => print("ERROR: $error"),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
          });
        },
        localeId: "ar_SA",
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Speech recognition not available")),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_spokenText.isNotEmpty) {
      setState(() {
        pages[currentPageIndex].add({
          "type": "text",
          "text": _spokenText,
          "x": 50.0,
          "y": 50.0,
          "key": UniqueKey(),
        });
      });

      _markStoryActivity();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📝 Text added from your voice!")),
      );
      _spokenText = "";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("😶 No speech detected! Try again.")),
      );
    }
  }

  // ============================================================
  //                    SAVE / LOAD / AI (AS-IS)
  // ============================================================
  Future<void> _saveStory({required bool sendToSupervisor}) async {
    // ⚠️ نفس دالتك — خليها كما عندك بالجزء السابق (أنتِ كاتبتها كاملة فوق)
    // أنا ما بغير عليها هون لأنه عندك موجودة بالأعلى.
  }

  Future<void> _submitStory(String storyId, String token) async {
    // ⚠️ نفس دالتك — موجودة بالأعلى عندك.
  }

  Future<void> _loadStoryData(String storyId) async {
    // ⚠️ نفس دالتك — موجودة بالأعلى عندك.
  }

  Future<Uint8List?> _exportDrawingAsImage() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final size = Size(
        _canvasWidthFor(MediaQuery.of(context).size.width),
        _canvasHeightFor(MediaQuery.of(context).size.height),
      );

      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

      final painter = DrawPainter(drawingPoints);
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
      return pngBytes?.buffer.asUint8List();
    } catch (e) {
      print("⚠️ Export drawing error: $e");
      return null;
    }
  }

  Future<void> _generateAIImage(String prompt) async {
    // ⚠️ نفس دالتك — موجودة بالأعلى عندك.
  }

  void _addAIImageToCanvas(String url) {
    final elementKey = UniqueKey();

    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "uploaded_image",
        "networkUrl": url,
        "x": 40.0,
        "y": 40.0,
        "width": 250.0,
        "height": 250.0,
      });
    });

    _markStoryActivity();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✨ AI Image Added!")),
    );
  }

  void _openAIGenerateDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 248, 237, 221),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Generate AI Image", style: TextStyle(fontSize: 20)),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: "Write your description..."),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 240, 169, 70)),
              child: const Text("Generate"),
              onPressed: () {
                final prompt = controller.text.trim();
                Navigator.pop(context);
                if (prompt.isNotEmpty) _generateAIImage(prompt);
              },
            )
          ],
        );
      },
    );
  }
}

// ============================================================
//                         DRAWING CLASSES
// ============================================================
class DrawPoint {
  final Offset? position;
  final Color? color;
  final double? width;

  DrawPoint({this.position, this.color, this.width});
}

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

*/








import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/widgets/DraggableTextWidget.dart';
import 'package:bright_minds/widgets/DraggableImageWidget.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert'; 
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:http_parser/http_parser.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:bright_minds/screens/childStory/loadingDragon.dart';







class CreateStoryPage extends StatefulWidget {
  final String? storyId;
  const CreateStoryPage({super.key, this.storyId});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  String storyTitle = "My Story";
  bool isDrawingMode = false;
  

Color selectedColor = Colors.black;
double strokeWidth = 4.0;
List<DrawPoint> drawingPoints = [];
List<DrawPoint> redoStack = [];
bool isGeneratingAI = false;



  // عناصر الكانفاس: نصوص + صور
  //List<Map<String, dynamic>> canvasElements = [];
  int currentPageIndex = 0;
  List<List<Map<String, dynamic>>> pages = [[]]; // كل صفحة تحتوي عناصرها

bool isRecording = false;

final _audioRecorder = AudioRecorder();
String? recordedFilePath;

late stt.SpeechToText _speech;
bool _isListening = false;
String _spokenText = "";
final TextEditingController _titleController = TextEditingController();



  final TextEditingController _textController = TextEditingController();

  // Main Brand Color
  final Color mainPurple = AppColors.pastelYellow;

  final List<String> storyImageAssets = [
    'assets/story_images/discussion.png',
    'assets/story_images/Drawing.png',
    'assets/story_images/energy.png',
    'assets/story_images/Games2.png',
    'assets/story_images/b.avif',
    'assets/story_images/a.jpg',
    'assets/story_images/c.jpg',
    'assets/story_images/d.webp',
  ];

String? _storySessionId;
DateTime? _lastPingAt;
bool _timingStarted = false;
bool _endingTiming = false;

Future<String?> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("token");
}

// call when any activity happens
Future<void> _markStoryActivity() async {
  // لازم يكون في storyId
  final prefs = await SharedPreferences.getInstance();
  String? storyId = prefs.getString("currentStoryId");

  // لو ما في storyId (قصة جديدة)، لا نبدأ session إلا بعد ما تنعمل create story
  if (storyId == null) return;

  final token = await _getToken();
  if (token == null) return;

  // 1) start once
  if (!_timingStarted || _storySessionId == null) {
    final res = await http.post(
      Uri.parse("${getBackendUrl()}/api/storyTime/start"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"storyId": storyId}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      _storySessionId = data["sessionId"];
      _timingStarted = true;
      _lastPingAt = DateTime.now();
    }
    return;
  }

  // 2) ping throttle (مثلاً كل 20 ثانية)
  final now = DateTime.now();
  if (_lastPingAt != null && now.difference(_lastPingAt!).inSeconds < 20) return;

  final res = await http.post(
    Uri.parse("${getBackendUrl()}/api/storyTime/ping"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    },
    body: jsonEncode({"sessionId": _storySessionId}),
  );

  if (res.statusCode == 200) {
    _lastPingAt = now;
  }
}

Future<void> _endTiming(String reason) async {
  if (_endingTiming) return;
  if (_storySessionId == null) return;

  _endingTiming = true;

  try {
    final token = await _getToken();
    if (token == null) return;

    await http.post(
      Uri.parse("${getBackendUrl()}/api/storyTime/end"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
      body: jsonEncode({"sessionId": _storySessionId, "reason": reason}),
    );
  } catch (_) {
    // ignore
  } finally {
    _endingTiming = false;
    _storySessionId = null;
    _timingStarted = false;
  }
}

String getBackendUrl() {
  if (kIsWeb) {
   // return "http://192.168.1.63:3000";
 return "http://localhost:3000";
  } else if (Platform.isAndroid) {
    // Android emulator
    return "http://10.0.2.2:3000";
  } else if (Platform.isIOS) {
    // iOS emulator
    return "http://localhost:3000";
  } else {
    // fallback
    return "http://localhost:3000";
  }
}


 @override
void initState() {
  super.initState();
  _speech = stt.SpeechToText();

  if (widget.storyId != null) {
    _loadStoryData(widget.storyId!);

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('currentStoryId', widget.storyId!);
    });

  } else {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('currentStoryId');
    });
  }
}






  @override
  /*void dispose() {
    _textController.dispose();
    super.dispose();
  }*/
  @override
void dispose() {
  _endTiming("exit");
  _textController.dispose();
  _titleController.dispose();
  super.dispose();
}


  @override
  Widget build(BuildContext context) {

    return WillPopScope(
    onWillPop: () async {
      await _endTiming("exit");
      return true; // 
    },
    

    child: Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 228, 201), // soft purple background

      body: SafeArea(
        child: Stack(
          
          children: [
            Column(
              children: [
                // ---------- TITLE BAR ----------
                _buildTitleBar(),

                const SizedBox(height: 10),

                // ---------- PAGE INDICATOR ----------
                _buildPageIndicator(),

                const SizedBox(height: 10),

                // ---------- CANVAS ----------
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.80,
                      height: MediaQuery.of(context).size.height * 0.60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    child: Stack(
  clipBehavior: Clip.none, // مهم جداً
  children: [
    // ========= DRAWING BACKGROUND =========
    Positioned.fill(
      child: AbsorbPointer( // ✅ بدّلنا IgnorePointer بـ AbsorbPointer
        absorbing: !isDrawingMode, // يمنع الرسم فقط عندما لا نكون في وضع الرسم
        child: GestureDetector(
        behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            _markStoryActivity();

            if (!isDrawingMode) return;
            setState(() {
              redoStack.clear();
              drawingPoints.add(DrawPoint(
                position: details.localPosition,
                color: selectedColor,
                width: strokeWidth,
              ));
            });
          },
          onPanUpdate: (details) {
            if (!isDrawingMode) return;
            _markStoryActivity();

            setState(() {
              drawingPoints.add(DrawPoint(
                position: details.localPosition,
                color: selectedColor,
                width: strokeWidth,
              ));
            });
          },
          onPanEnd: (_) {
            if (!isDrawingMode) return;
             _markStoryActivity();
            setState(() {
              drawingPoints.add(DrawPoint(position: null));
            });
          },
          child: CustomPaint(
            painter: DrawPainter(drawingPoints),
          ),
        ),
      ),
    ),

    // ========= STORY ELEMENTS =========
    ...pages[currentPageIndex].asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      // ===== TEXT ELEMENT =====
      if (item["type"] == "text") {
        return DraggableTextWidget(
          key: item["key"],
          text: item["text"],
          color: item["color"] ?? Colors.black,
          fontSize: item["fontSize"] ?? 20.0,
          isBold: item["isBold"] ?? false,
          isItalic: item["isItalic"] ?? false,
          isUnderlined: item["isUnderlined"] ?? false,
          x: item["x"] ?? 50.0,
          y: item["y"] ?? 50.0,
          onPositionChanged: (newX, newY) {
            _markStoryActivity();

            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onStyleChanged: (color, size, bold, italic, underline) {
             _markStoryActivity();
            setState(() {
              item["color"] = color;
              item["fontSize"] = size;
              item["isBold"] = bold;
              item["isItalic"] = italic;
              item["isUnderlined"] = underline;
            });
          },
          onDelete: () {
            print("🗑️ onDelete pressed for item type: ${item["type"]}");
            print("Before delete: ${pages[currentPageIndex].length} elements");
            setState(() {
              pages[currentPageIndex].removeWhere((e) => e["key"] == item["key"]);
            });
            _markStoryActivity();
            print("After delete: ${pages[currentPageIndex].length} elements");
          },
        );
      }

      // ===== IMAGE ELEMENT =====
 // ===== IMAGE FROM ASSETS =====
      if (item["type"] == "image") {
        return DraggableImageWidget(
          key: item["key"],
          imagePath: item["imagePath"],
          x: item["x"] ?? 40.0,
          y: item["y"] ?? 40.0,
          width: item["width"] ?? 150.0,
          height: item["height"] ?? 150.0,
          onPositionChanged: (newX, newY) {
              _markStoryActivity();
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onResize: (newW, newH) {
            _markStoryActivity();
            setState(() {
              

              item["width"] = newW;
              item["height"] = newH;
            });
          },
          onDelete: () {
            setState(() {
              pages[currentPageIndex]
                  .removeWhere((e) => e["key"] == item["key"]);
            });
            _markStoryActivity();
          },
        );
      }

      // ===== DRAWN IMAGE (BYTES) =====
      if (item["type"] == "drawn_image") {
        return DraggableImageWidget(
          key: item["key"],
          bytes: item["bytes"],
          x: item["x"] ?? 40.0,
          y: item["y"] ?? 40.0,
          width: item["width"] ?? 150.0,
          height: item["height"] ?? 150.0,
          onPositionChanged: (newX, newY) {
              _markStoryActivity();
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onResize: (newW, newH) {
            _markStoryActivity();
            setState(() {
              item["width"] = newW;
              item["height"] = newH;
            });
          },
          onDelete: () {
            setState(() {
              pages[currentPageIndex]
                  .removeWhere((e) => e["key"] == item["key"]);
            });
            _markStoryActivity();
          },
        );
      }

      // ===== UPLOADED IMAGE (FROM CLOUDINARY OR LOCAL) =====
      if (item["type"] == "uploaded_image") {
        return DraggableImageWidget(
          key: item["key"],
          // لو رجعت من الباك:
          networkUrl: item["networkUrl"],
          // لو لسه جديدة ولسا ما اترفعت:
          bytes: item["bytes"],
          x: item["x"] ?? 40.0,
          y: item["y"] ?? 40.0,
          width: item["width"] ?? 150.0,
          height: item["height"] ?? 150.0,
          onPositionChanged: (newX, newY) {
              _markStoryActivity();
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onResize: (newW, newH) {
            _markStoryActivity();
            setState(() {
              item["width"] = newW;
              item["height"] = newH;
            });
          },
          onDelete: () {
            setState(() {
              pages[currentPageIndex]
                  .removeWhere((e) => e["key"] == item["key"]);
            });
            _markStoryActivity();
          },
        );
        
      }



      // ===== AUDIO ELEMENT =====
if (item["type"] == "audio") {
  return Positioned(
    left: item["x"] ?? 40.0,
    top: item["y"] ?? 40.0,
    child: Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack, color: Color.fromARGB(255, 240, 169, 70)),
          const SizedBox(width: 8),
          Text(
            "Voice note",
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color.fromARGB(255, 240, 169, 70)),
            onPressed: () async {
              // 🔊 شغّل الصوت
              final file = File(item["path"]);
              if (await file.exists()) {
                await Process.run('start', [file.path], runInShell: true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File not found!")),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}


      return const SizedBox();
    }).toList(),

    if (pages[currentPageIndex].isEmpty)
      Center(
        child: Text(
          "Tap tools to add elements",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ),
  ],
),

                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ---------- BOTTOM TOOLBAR ----------
                //_buildBottomToolbar(),
                // ---------- BOTTOM TOOLBAR ----------


              ],
            ),
            Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: IgnorePointer(
    ignoring: isDrawingMode, // عشان ما يغطي أثناء الرسم
    child: _buildBottomToolbar(),
  ),
),


            // ===== DRAWING TOOLS OVERLAY =====
if (isDrawingMode) _drawingToolsOverlay(),
if (isGeneratingAI)
  Container(
    alignment: Alignment.center,
    color: Colors.white.withOpacity(0.75),
    child: const LoadingDragon(),
  ),


            // ---------- LEFT SIDE TOOLS BUTTON ----------
            Positioned(
              top: 80,
              left: 10,
              child: _buildToolsButton(),
            ),
          ],
        ),
      ),
    ),
    );
  }

  // ============================================================
  //                          TITLE BAR
  // ============================================================
 Widget _buildTitleBar() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 237, 198, 145),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color:Color.fromARGB(255, 240, 169, 70) ),
          const SizedBox(width: 10),

          // ---------- Editable Story Title ----------
         Expanded(
  child: TextField(
    controller: _titleController,    
    //onChanged: (value) => storyTitle = value,
    onChanged: (value) {
  storyTitle = value;
  _markStoryActivity();
},

    decoration: const InputDecoration(
      border: InputBorder.none,
      hintText: "Story Title",
    ),
    style: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
),



          // ---------- Save Button ----------
          IconButton(
            icon: const Icon(Icons.save_rounded, color: Color.fromARGB(255, 240, 169, 70), size: 28),
            tooltip: "Save your story",
            onPressed: () async {
              final choice = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.badgesButton,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: const [
                      Icon(Icons.save_rounded, color: Color.fromARGB(255, 240, 169, 70), size: 30),
                      SizedBox(width: 10),
                      Text(
                        "Save Story",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "Would you like to send your story to your supervisor or save it as a draft?",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 240, 169, 70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, "send"),
                      child: const Text("Send to Supervisor"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 250, 202, 134), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, "draft"),
                      child: const Text("Save as Draft"),
                    ),
                  ],
                ),
              );

              if (choice == "send") {
                _saveStory(sendToSupervisor: true);
              } else if (choice == "draft") {
                _saveStory(sendToSupervisor: false);
              }
            },
          ),
        ],
      ),
    ),
  );
}

  // ============================================================
  //                      PAGE INDICATOR
  // ============================================================
  Widget _buildPageIndicator() {
    return Text(
  "Page ${currentPageIndex + 1} / ${pages.length}",
  style: GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color:Color.fromARGB(255, 241, 164, 55) ,
  ),
);

  }

  // ============================================================
  //                   BOTTOM CONTROL TOOLBAR
  // ============================================================
  Widget _buildBottomToolbar() {
    print("🧩 Building bottom toolbar...");

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.badgesButton,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          // record story 
IconButton(
  icon: Icon(
    (_isListening || isRecording) ? Icons.stop_circle_outlined : Icons.mic,
    color: (_isListening || isRecording)
        ? Color.fromARGB(255, 245, 168, 60)
        : const Color.fromARGB(255, 251, 198, 122),
    size: 32,
  ),
  tooltip: "Add Voice or Speech",
  onPressed: () async {
    print("🎤 Button pressed | isListening=$_isListening | isRecording=$isRecording");

    // لو فعلاً في تسجيل أو استماع حالي، أوقفه
    if (_isListening) {
      print("🛑 Stopping speech recognition...");
      await _stopListening();
      setState(() => _isListening = false);
      return;
    }

    if (isRecording) {
      print("🛑 Stopping voice recording...");
      await _stopRecording();
      setState(() => isRecording = false);
      return;
    }

    // ✅ إذا ما في أي عملية شغالة، اعرض الـ dialog
    print("📢 Opening choice dialog...");
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.badgesButton,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Choose an action 🎙️",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Would you like to record your voice or speak to write the story?",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 240, 169, 70),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, "record"),
            icon: const Icon(Icons.mic, color: Colors.white),
            label: const Text("Record Voice",
                style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, "speech"),
            icon: const Icon(Icons.record_voice_over,
                color: Color.fromARGB(255, 240, 169, 70)),
            label: const Text("Speak to Write",
                style: TextStyle(color: Color.fromARGB(255, 240, 169, 70))),
          ),
        ],
      ),
    );

    print("👉 User selected: $choice");

    // تنفيذ الخيار
    if (choice == "record") {
      setState(() => isRecording = true);
      await _startRecording();
    } else if (choice == "speech") {
      setState(() => _isListening = true);
      await _startListening();
    }
  },
),





       //   IconButton(icon: Icon(Icons.play_arrow, color: mainPurple), onPressed: () {}),
         
         // previous and next page 
         IconButton(
  icon: const Icon(Icons.undo, color: Color.fromARGB(255, 240, 169, 70)),
  tooltip: "Previous Page",
  onPressed: currentPageIndex > 0
      ? () {
          setState(() {
            currentPageIndex--;
          });
        }
      : null, 
),
IconButton(
  icon: const Icon(Icons.redo, color: Color.fromARGB(255, 240, 169, 70)),
  tooltip: "Next Page",
  onPressed: currentPageIndex < pages.length - 1
      ? () {
          setState(() {
            currentPageIndex++;
          });
        }
      : null, 
),


// delete the page 
  IconButton(
  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 240, 169, 70)),
  tooltip: "Delete this page",
  onPressed: () async {
    if (pages.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8F9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color.fromARGB(255, 240, 169, 70), size: 30),
            SizedBox(width: 10),
            Text(
              "Delete Page?",
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this entire page and all its content? 😢",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color.fromARGB(255, 240, 169, 70),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        pages.removeAt(currentPageIndex);

        // لو حذفنا آخر صفحة، نرجع لصفحة موجودة
        if (currentPageIndex >= pages.length) {
          currentPageIndex = pages.isEmpty ? 0 : pages.length - 1;
        }

        // لو ما ظل صفحات، نضيف صفحة فاضية
        if (pages.isEmpty) {
          pages.add([]);
          currentPageIndex = 0;
        }
      });
      _markStoryActivity();
    }
  },
),


         // icon + to add another pages 
IconButton(
  tooltip: "Add New Page",
  icon: const Icon(Icons.add_circle_rounded, color: Color.fromARGB(255, 240, 169, 70)),
  onPressed: () async {
    print("🟣 Add button pressed!");

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        print("🟢 Dialog opened!");
        return AlertDialog(
          backgroundColor: Color.fromARGB(255, 249, 234, 213),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.add_circle_rounded, color: Color.fromARGB(255, 240, 169, 70), size: 30),
              SizedBox(width: 10),
              Text(
                "Add New Page?",
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            "Do you want to add a new blank page for your story?",
            style: TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 16,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color.fromARGB(255, 240, 169, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 240, 169, 70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    print("🟡 Dialog result: $confirm");

    if (confirm == true) {
      setState(() {
        pages.add([]);
        currentPageIndex = pages.length - 1;
      });
        _markStoryActivity();
      print("✅ Added new page — total: ${pages.length}, now at: $currentPageIndex");
    }
  },
),



        ],
      ),
    );
  }

  // ============================================================
  //                    LEFT TOOLS BUTTON
  // ============================================================
  Widget _buildToolsButton() {
    return GestureDetector(
      onTap: () => _openToolsDrawer(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 240, 169, 70),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.menu, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  // ============================================================
  //                        TOOLS DRAWER
  // ============================================================
  void _openToolsDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Tools",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.65,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Text(
                    "Tools",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 240, 169, 70),
                    ),
                  ),
                  const SizedBox(height: 30),

                  _toolOption(Icons.text_fields, "Add Text", () {
                    Navigator.pop(context);
                    _showAddTextDialog();
                  }),
                  _toolOption(Icons.image, "Add Image", () {
                    Navigator.pop(context);
                    _showImageAssetsPicker();
                  }),
                 _toolOption(Icons.draw, "Draw", () {
  Navigator.pop(context);
  setState(() {
    isDrawingMode = true;
  });
}),

             _toolOption(Icons.upload_file, "Upload Picture", () async {
  Navigator.pop(context);

  if (kIsWeb) {
    //  الرفع من المتصفح
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.isNotEmpty) {
      final bytes = result.files.first.bytes!;
      _addUploadedImageFromBytes(bytes);
    }
  } else {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      _addUploadedImageFromBytes(bytes);
    }
  }
}),

                  _toolOption(Icons.auto_fix_high, "AI Generated Image", () {
  Navigator.pop(context);
  _openAIGenerateDialog();
}),

                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return SlideTransition(
          position:
              Tween(begin: const Offset(-1, 0), end: Offset.zero).animate(animation),
          child: child,
        );
      },
    );
  }

  Widget _toolOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color.fromARGB(255, 240, 169, 70)),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 18)),
      onTap: onTap,
    );
  }

  // ============================================================
  //                    ADD TEXT DIALOG
  // ============================================================
  void _showAddTextDialog() {
    _textController.text = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Text"),
          content: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Type your text here...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 240, 169, 70),
              ),
              onPressed: () {
                final input = _textController.text.trim();
                if (input.isNotEmpty) {
                  _addDraggableText(input);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void _addDraggableText(String text) {
    final elementKey = UniqueKey();

    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "text",
        "text": text,
        "x": 50.0,
        "y": 50.0,
        "color": Colors.black,
        "fontSize": 20.0,
        "isBold": false,
        "isItalic": false,
        "isUnderlined": false,
      });
    });
      _markStoryActivity(); // 

  }

  // ============================================================
  //                ADD IMAGE FROM ASSETS
  // ============================================================
  void _showImageAssetsPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Choose an image",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                itemCount: storyImageAssets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final assetPath = storyImageAssets[index];
                  return GestureDetector(
                    onTap: () {
                      _addImageElement(assetPath);
                      Navigator.pop(context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addImageElement(String assetPath) {
    final elementKey = UniqueKey();

    setState(() {
      pages[currentPageIndex].add({
        "key": elementKey,
        "type": "image",
        "imagePath": assetPath,
        "x": 40.0,
        "y": 40.0,
        "width": 150.0,
        "height": 150.0,
      });
    });
      _markStoryActivity();
  }

  // ============================================================
  //          (من كودك الأصلي) IMAGE PICKER DRAWER الإضافي
  // ============================================================
  void _openImagePickerDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: 340,
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 3,
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _imageThumb("assets/story_images/forest.png"),
              _imageThumb("assets/story_images/castle.png"),
              _imageThumb("assets/story_images/space.png"),
              _imageThumb("assets/story_images/dragon.png"),
               _imageThumb("assets/story_images/b.avif"),
              _imageThumb("assets/story_images/a.jpg"),
              _imageThumb("assets/story_images/c.jpg"),
              _imageThumb("assets/story_images/d.webp"),
            ],
          ),
        );
      },
    );
  }

  Widget _imageThumb(String path) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _addImageElement(path);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(path, fit: BoxFit.cover),
      ),
    );
  }


 void _addDrawnImage(Uint8List bytes) {
  final elementKey = UniqueKey();

  setState(() {
    pages[currentPageIndex].add({
      "key": elementKey,
      "type": "drawn_image",
      "bytes": bytes,
      "x": 40.0,
      "y": 40.0,
      "width": 150.0,
      "height": 150.0,
    });
  });
}


Widget _drawingToolsOverlay() {
  return Positioned(
    top: 80,
    right: 10,
    child: Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // 🎨 Colors
          _colorDot(Colors.black),
          _colorDot(Colors.red),
          _colorDot(Colors.blue),
          _colorDot(Colors.green),
          _colorDot(Colors.orange),
          const SizedBox(height: 10),

          // ✏️ Brush size
          const Text("Size", style: TextStyle(fontSize: 12)),
          Slider(
            value: strokeWidth,
            min: 2,
            max: 20,
            activeColor: Color.fromARGB(255, 240, 169, 70),
            onChanged: (v) => setState(() => strokeWidth = v),
          ),

          const SizedBox(height: 5),

          // ↩️ Undo / Redo
          IconButton(
            tooltip: "Undo",
            icon: const Icon(Icons.undo, color: Color.fromARGB(255, 240, 169, 70), size: 26),
            onPressed: _undoDraw,
          ),
          IconButton(
            tooltip: "Redo",
            icon: const Icon(Icons.redo, color: Color.fromARGB(255, 240, 169, 70), size: 26),
            onPressed: _redoDraw,
          ),
// BACK
          const Divider(
            color: Color.fromARGB(255, 246, 230, 208),
            thickness: 1,
            height: 15,
          ),

          // ✅ Done button
          IconButton(
            tooltip: "Done Drawing",
            icon: const Icon(Icons.check_circle_rounded,
                color: Color.fromARGB(255, 240, 169, 70), size: 30),
            onPressed: () async {
  // 1) حول الرسم لصورة PNG
  final pngBytes = await _exportDrawingAsImage();

  if (pngBytes != null) {
    // 2) أضف الصورة كعنصر في الصفحة
    _addDrawnImage(pngBytes);
     _markStoryActivity();
    // 3) امسح الرسم من الشاشة لأنه صار محفوظ
    setState(() {
      drawingPoints.clear();
      redoStack.clear();
      isDrawingMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(" Drawing added to your story!")),
    );
  } else {
    setState(() => isDrawingMode = false);
  }
},

          ),

          const SizedBox(height: 8),

          // 🗑️ Delete button
          IconButton(
            tooltip: "Delete Drawing",
            icon: const Icon(Icons.delete_forever_rounded,
                color: Colors.redAccent, size: 30),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Color.fromARGB(255, 240, 169, 70),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Color.fromARGB(255, 240, 169, 70), size: 30),
                      SizedBox(width: 10),
                      Text(
                        "Delete drawing?",
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "Are you sure you want to clear your drawing? 😢",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 16,
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color.fromARGB(255, 240, 169, 70),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() {
                  drawingPoints.clear();
                  redoStack.clear();
                });
              }
            },
          ),
        ],
      ),
    ),
  );
}



Widget _colorDot(Color color) {
  return GestureDetector(
    onTap: () => setState(() => selectedColor = color),
    child: Container(
      width: 26,
      height: 26,
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    ),
  );
}


void _undoDraw() {
  if (drawingPoints.isEmpty) return;
  setState(() {
    int last = drawingPoints.lastIndexWhere((p) => p.position == null);
    redoStack.addAll(drawingPoints.sublist(last + 1));
    drawingPoints.removeRange(last + 1, drawingPoints.length);
    drawingPoints.removeLast();
  });
    _markStoryActivity();
}

void _redoDraw() {
  if (redoStack.isEmpty) return;
  setState(() {
    drawingPoints.addAll(redoStack);
    redoStack.clear();
  });
    _markStoryActivity();
}



void _addUploadedImage(File imageFile) async {
  final elementKey = UniqueKey();
  final bytes = await imageFile.readAsBytes(); 

  setState(() {
    pages[currentPageIndex].add({
      "key": elementKey,
      "type": "uploaded_image",
      "bytes": bytes, 
      "x": 40.0,
      "y": 40.0,
      "width": 150.0,
      "height": 150.0,
    });
  });
}


void _addUploadedImageFromBytes(Uint8List bytes) {
  final elementKey = UniqueKey();
  setState(() {
    pages[currentPageIndex].add({
      "key": elementKey,
      "type": "uploaded_image",
      "bytes": bytes,
      "x": 40.0,
      "y": 40.0,
      "width": 150.0,
      "height": 150.0,
    });
  });
  _markStoryActivity();
}



Future<void> _startRecording() async {
  final hasPermission = await _audioRecorder.hasPermission();
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Microphone permission denied")),
    );
    return;
  }

  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/story_record_${DateTime.now().millisecondsSinceEpoch}.m4a';

  await _audioRecorder.start(const RecordConfig(), path: filePath);
  setState(() {
    isRecording = true;
    recordedFilePath = filePath;
  });
  _markStoryActivity(); 
}

Future<void> _stopRecording() async {
  final path = await _audioRecorder.stop();
  setState(() {
    isRecording = false;
    recordedFilePath = path;
  });

  if (path != null) {
    // ✅ أضف تسجيل الصوت كعنصر في الصفحة
    setState(() {
      pages[currentPageIndex].add({
        "type": "audio",
        "path": path,
        "x": 50.0,
        "y": 50.0,
        "key": UniqueKey(),
      });
    });
_markStoryActivity();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🎧 Voice recording added to your story!"),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}



Future<void> _startListening() async {
  bool available = await _speech.initialize(
    onStatus: (status) => print("STATUS: $status"),
    onError: (error) => print("ERROR: $error"),
  );

  if (available) {
    setState(() => _isListening = true);
    _speech.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
        });
      },
      localeId: "ar_SA", // ✅ عربي
      listenMode: stt.ListenMode.confirmation,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Speech recognition not available")),
    );
  }
}

Future<void> _stopListening() async {
  await _speech.stop();
  setState(() => _isListening = false);

  if (_spokenText.isNotEmpty) {
    setState(() {
      pages[currentPageIndex].add({
        "type": "text",
        "text": _spokenText,
        "x": 50.0,
        "y": 50.0,
        "key": UniqueKey(),
      });
    });
    _markStoryActivity();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("📝 Text added from your voice!")),
    );
    _spokenText = "";
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("😶 No speech detected! Try again.")),
    );
  }
}



// 
Future<void> _saveStory({required bool sendToSupervisor}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    String? storyId = prefs.getString('currentStoryId');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please log in first")),
      );
      return;
    }

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    // ================================
    // 1) Build pages JSON
    // ================================
    final List<Map<String, dynamic>> pagesJson = [];

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final List<Map<String, dynamic>> pageElements = [];

      for (int i = 0; i < pages[pageIndex].length; i++) {
        final item = pages[pageIndex][i];
        final type = item["type"];

        // ---------- TEXT ELEMENT ----------
        if (type == "text") {
          pageElements.add({
            "type": "text",
            "content": item["text"] ?? "",
            "x": item["x"],
            "y": item["y"],
            "width": item["width"],
            "height": item["height"],
            "fontSize": item["fontSize"] ?? 20.0,
            "order": i,
          });
        }

        // ---------- IMAGE FROM ASSETS ----------
        else if (type == "image") {
          final String asset = item["imagePath"];

          // 🔥 إصلاح الشرط — التأكد أنه من الـ assets فقط
          if (asset.startsWith("assets/")) {
            pageElements.add({
              "type": "image",
              "content": "",
              "x": item["x"],
              "y": item["y"],
              "width": item["width"],
              "height": item["height"],
              "order": i,
              "media": {
                "mediaType": "image",
                "url": asset,
                "page": pageIndex + 1,
                "elementOrder": i,
              }
            });

            continue; // مهم جداً
          }
        }


        // ---------- AI or Network Image ----------
else if (type == "uploaded_image" && item["networkUrl"] != null) {
  pageElements.add({
    "type": "image",
    "content": "",
    "x": item["x"],
    "y": item["y"],
    "width": item["width"],
    "height": item["height"],
    "order": i,
    "media": {
      "mediaType": "image",
      "url": item["networkUrl"],   // 
      "page": pageIndex + 1,
      "elementOrder": i
    }
  });

  continue;
}


        // ---------- UPLOADED IMAGE (BYTES) ----------
       /* else if (type == "uploaded_image" || type == "drawn_image") {
          final Uint8List? bytes = item["bytes"];

          if (bytes == null) {
            print("⚠️ Skipping image because bytes == null");
            continue;
          }

          final url = await _uploadBytesToCloudinary(
            bytes,
            "story_image_${DateTime.now().millisecondsSinceEpoch}.png",
          );

          if (url == null) continue;

          pageElements.add({
            "type": "image",
            "content": "",
            "x": item["x"],
            "y": item["y"],
            "width": item["width"],
            "height": item["height"],
            "order": i,
            "media": {
              "mediaType": "image",
              "url": url,
              "page": pageIndex + 1,
              "elementOrder": i
            }
          });
        }*/

        // ---------- AUDIO ----------
        else if (type == "audio") {
          final path = item["path"];
          final url = await _uploadFilePathToCloudinary(
            path,
            "story_audio_${DateTime.now().millisecondsSinceEpoch}.m4a",
          );

          if (url == null) continue;

          pageElements.add({
            "type": "audio",
            "content": "",
            "x": item["x"],
            "y": item["y"],
            "order": i,
            "media": {
              "mediaType": "audio",
              "url": url,
              "page": pageIndex + 1,
              "elementOrder": i
            }
          });
        }
      }

      pagesJson.add({
        "pageNumber": pageIndex + 1,
        "elements": pageElements,
      });
    }

    // ================================
    // 2) COVER IMAGE
    // ================================
    String? coverImage;
    for (var page in pagesJson) {
      for (var e in (page["elements"] as List)) {
        if (e["type"] == "image") {
          coverImage = e["media"]["url"];
          break;
        }
      }
      if (coverImage != null) break;
    }

    final storyData = {
      "title": storyTitle,
      "coverImage": coverImage,
      "pages": pagesJson,
    };

    // ================================
    // 3) CREATE STORY (IF FIRST TIME)
    // ================================
    if (storyId == null) {
      final res = await http.post(
        Uri.parse("${getBackendUrl()}/api/story/create"),
        headers: headers,
        body: jsonEncode({"title": storyTitle}),
      );

      final data = jsonDecode(res.body);
      storyId = data["storyId"];

      await prefs.setString("currentStoryId", storyId!);
      //await prefs.setString("currentStoryId", storyId!);
await _markStoryActivity(); // 

    }

    // ================================
    // 4) UPDATE STORY
    // ================================
    await http.put(
      Uri.parse("${getBackendUrl()}/api/story/update/$storyId"),
      headers: headers,
      body: jsonEncode(storyData),
    );

    // ================================
    // 5) SUBMIT TO SUPERVISOR
    // ================================
    if (sendToSupervisor) {
      await _submitStory(storyId!, token);
    }
await _markStoryActivity(); //
await _endTiming(sendToSupervisor ? "submit" : "save_draft");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sendToSupervisor ? "📤 Story sent to supervisor!" : "💾 Story saved.",
        ),
      ),
    );
  } catch (e) {
    print("SAVE ERROR: $e");
  }
}




/*Future<void> _updateStoryPages(String storyId, Map storyData, String token) async {
  final response = await http.put(
    Uri.parse("${getBackendUrl()}/api/story/update/$storyId"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
    body: jsonEncode(storyData),
  );

  print("📩 Update response: ${response.body}");

  if (response.statusCode != 200) {
    print("❌ Error updating story: ${response.body}");
  }
}
*/

Future<void> _submitStory(String storyId, String token) async {
  final response = await http.post(
    Uri.parse("${getBackendUrl()}/api/story/submit/$storyId/submit"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  print("📨 Submit response: ${response.body}");

  if (response.statusCode != 200) {
    print("❌ Error submitting story: ${response.body}");
  }
}


String? _getCoverImageFromPages() {
  if (pages.isEmpty) return null;

  final firstPage = pages.first;

  for (var element in firstPage) {
    if (element["type"] == "image") {
      return element["url"] ?? element["content"] ?? null;
    }
  }

  return null;
}

Future<void> _loadStoryData(String storyId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${getBackendUrl()}/api/story/getstorybyid/$storyId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("🟣 LOAD STORY RESPONSE: ${response.body}");

    if (response.statusCode != 200) {
      print("❌ Error loading story: ${response.statusCode} — ${response.body}");
      return;
    }

    final data = jsonDecode(response.body);

    // -------- SET TITLE ----------
    storyTitle = data["title"] ?? "My Story";
    _titleController.text = storyTitle;
    // -------- SET REVIEWS ----------
    List reviews = data["reviews"] ?? [];


    // -------- LOAD PAGES ----------
    final List<List<Map<String, dynamic>>> loadedPages = [];
    final pagesFromApi = data["pages"] as List? ?? [];

    for (final page in pagesFromApi) {
      final List<Map<String, dynamic>> pageElements = [];
      final elements = page["elements"] as List? ?? [];

      for (final el in elements) {
        final String type = el["type"] ?? "text";
        final media = el["media"];
        final double x = (el["x"] ?? 40).toDouble();
        final double y = (el["y"] ?? 40).toDouble();
        final double width =
            el["width"] != null ? (el["width"] as num).toDouble() : 150;
        final double height =
            el["height"] != null ? (el["height"] as num).toDouble() : 150;

        // ---------- TEXT ----------
        if (type == "text") {
          pageElements.add({
            "key": UniqueKey(),
            "type": "text",
            "text": el["content"] ?? "",
            "x": x,
            "y": y,
            "width": el["width"],
            "height": el["height"],
            "fontSize": el["fontSize"] != null
                ? (el["fontSize"] as num).toDouble()
                : 20.0,
          });
        }

        // ---------- IMAGE ----------
        else if (type == "image") {
          final String? url = media?["url"];
          if (url == null) continue;

          if (url.startsWith("assets/")) {
            // 🟣 Asset image
            pageElements.add({
              "key": UniqueKey(),
              "type": "image",           // مهم
              "imagePath": url,          // مهم لـ DraggableImageWidget
              "x": x,
              "y": y,
              "width": width,
              "height": height,
            });
          } else if (url.startsWith("http")) {
            // ☁️ Cloudinary image
            pageElements.add({
              "key": UniqueKey(),
              "type": "uploaded_image",
              "networkUrl": url,
              "x": x,
              "y": y,
              "width": width,
              "height": height,
            });
          }
        }

        // ---------- AUDIO ----------
        else if (type == "audio") {
          pageElements.add({
            "key": UniqueKey(),
            "type": "audio",
            "path": media?["url"] ?? "",
            "x": x,
            "y": y,
          });
        }
      }

      loadedPages.add(pageElements);
    }

    setState(() {
      pages = loadedPages.isEmpty ? [[]] : loadedPages;
      currentPageIndex = 0;
    });
  } catch (e) {
    print("⚠️ Error: $e");
  }
}






Future<String?> _uploadBytesToCloudinary(Uint8List bytes, String fileName) async {
  try {
    if (bytes.isEmpty) {
      print("⚠ Cannot upload empty bytes!");
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse("${getBackendUrl()}/api/upload/story-media");

    final request = http.MultipartRequest("POST", uri);

    if (token != null) {
      request.headers['Authorization'] = "Bearer $token";
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("🟣 Upload Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["url"];
    } else {
      print("❌ Cloudinary upload failed: ${response.body}");
      return null;
    }
  } catch (e) {
    print("⚠ Upload error: $e");
    return null;
  }
}





Future<String?> _uploadFilePathToCloudinary(String filePath, String fileName) async {
  final file = File(filePath);
  if (!await file.exists()) return null;
  final bytes = await file.readAsBytes();
  return _uploadBytesToCloudinary(bytes, fileName);
}



Future<Uint8List?> _exportDrawingAsImage() async {
  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final size = Size(
      MediaQuery.of(context).size.width * 0.80,
      MediaQuery.of(context).size.height * 0.60,
    );

    // White background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw all points
    final painter = DrawPainter(drawingPoints);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();

    final img = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return pngBytes?.buffer.asUint8List();
  } catch (e) {
    print("⚠️ Export drawing error: $e");
    return null;
  }
}


Future<void> _generateAIImage(String prompt) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please log in first")),
      );
      return;
    }

    // 🔵 ابدأ اللودينغ
    setState(() => isGeneratingAI = true);

    String? storyId = prefs.getString("currentStoryId");

    // ---------- ----------
    if (storyId == null) {
      final createRes = await http.post(
        Uri.parse("${getBackendUrl()}/api/story/create"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"title": storyTitle}),
      );

      final created = jsonDecode(createRes.body);
      storyId = created["storyId"];
      await prefs.setString("currentStoryId", storyId!);
      await _markStoryActivity();
    }

    // ---------- إرسال طلب إنشاء صورة ----------
    final body = {
      "prompt": prompt,
      "storyId": storyId,
      "pageNumber": currentPageIndex + 1,
      "style": "cartoon",
    };

    final response = await http.post(
      Uri.parse("${getBackendUrl()}/api/ai/generate-image"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("🟣 AI Response: ${response.body}");

    if (response.statusCode != 200) {
      setState(() => isGeneratingAI = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI Error: ${response.body}")),
      );
      return;
    }

    // ---------- إضافة الصورة إلى الكانفاس ----------
    final data = jsonDecode(response.body);
    final imageUrl = data["imageUrl"];

    _addAIImageToCanvas(imageUrl);

    // 🔵 أوقف اللودينغ
    setState(() => isGeneratingAI = false);

  } catch (e) {
    print("AI ERROR: $e");
    setState(() => isGeneratingAI = false); // 🔥 لازم في كل errors
  }
}
void _addAIImageToCanvas(String url) {
  final elementKey = UniqueKey();

  setState(() {
    pages[currentPageIndex].add({
      "key": elementKey,
      "type": "uploaded_image",
      "networkUrl": url,
      "x": 40.0,
      "y": 40.0,
      "width": 250.0,
      "height": 250.0,
    });
  });
_markStoryActivity();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("✨ AI Image Added!")),
  );
}


void _openAIGenerateDialog() {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Color.fromARGB(255, 248, 237, 221),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Generate AI Image", style: TextStyle(fontSize: 20)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Write your description..."),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 240, 169, 70)),
            child: Text("Generate"),
            onPressed: () {
              final prompt = controller.text.trim();
              Navigator.pop(context);
              if (prompt.isNotEmpty) _generateAIImage(prompt);
            },
          )
        ],
      );
    },
  );
}




















  








////////////////////////////////////////////////////////////

}

// for drawing 

class DrawPoint {
  final Offset? position;
  final Color? color;
  final double? width;

  DrawPoint({this.position, this.color, this.width});
}

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

