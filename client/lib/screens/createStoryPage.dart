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
  final Color mainPurple = const Color(0xFF9182FA);

  final List<String> storyImageAssets = [
    'assets/story_images/discussion.png',
    'assets/story_images/Drawing.png',
    'assets/story_images/energy.png',
    'assets/story_images/Games2.png',
  ];



String getBackendUrl() {
  if (kIsWeb) {
    return "http://localhost:3000";
  } else if (Platform.isAndroid) {
    return "http://10.0.2.2:3000";
  } else {
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
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F0FF), // soft purple background
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
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onStyleChanged: (color, size, bold, italic, underline) {
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
            print("After delete: ${pages[currentPageIndex].length} elements");
          },
        );
      }

      // ===== IMAGE ELEMENT =====
      if (item["type"] == "image") {
        return DraggableImageWidget(
          key: item["key"],
          imagePath: item["imagePath"],
          x: item["x"] ?? 40.0,
          y: item["y"] ?? 40.0,
          width: item["width"] ?? 150.0,
          height: item["height"] ?? 150.0,
          onPositionChanged: (newX, newY) {
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onResize: (newW, newH) {
            setState(() {
              item["width"] = newW;
              item["height"] = newH;
            });
          },
          onDelete: () {
            setState(() {
              pages[currentPageIndex].removeWhere((e) => e["key"] == item["key"]);
            });
          },
        );
      }

      // ===== DRAWN IMAGE =====
      if (item["type"] == "drawn_image") {
        return DraggableImageWidget(
          key: item["key"],
          bytes: item["bytes"],
          x: item["x"] ?? 40.0,
          y: item["y"] ?? 40.0,
          width: item["width"] ?? 150.0,
          height: item["height"] ?? 150.0,
          onPositionChanged: (newX, newY) {
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onResize: (newW, newH) {
            setState(() {
              item["width"] = newW;
              item["height"] = newH;
            });
          },
          onDelete: () {
            setState(() {
              pages[currentPageIndex].removeWhere((e) => e["key"] == item["key"]);
            });
          },
        );
      }

      // ===== UPLOADED IMAGE =====
      if (item["type"] == "uploaded_image") {
        return DraggableImageWidget(
          key: item["key"],
          bytes: item["bytes"],
          x: item["x"] ?? 40.0,
          y: item["y"] ?? 40.0,
          width: item["width"] ?? 150.0,
          height: item["height"] ?? 150.0,
          onPositionChanged: (newX, newY) {
            setState(() {
              item["x"] = newX;
              item["y"] = newY;
            });
          },
          onResize: (newW, newH) {
            setState(() {
              item["width"] = newW;
              item["height"] = newH;
            });
          },
          onDelete: () {
            setState(() {
              pages[currentPageIndex].removeWhere((e) => e["key"] == item["key"]);
            });
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
        color: const Color(0xFFEEE9FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.audiotrack, color: Color(0xFF9182FA)),
          const SizedBox(width: 8),
          Text(
            "Voice note",
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Color(0xFF9182FA)),
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

            // ---------- LEFT SIDE TOOLS BUTTON ----------
            Positioned(
              top: 80,
              left: 10,
              child: _buildToolsButton(),
            ),
          ],
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
        color: const Color(0xFFE8E3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: mainPurple),
          const SizedBox(width: 10),

          // ---------- Editable Story Title ----------
         Expanded(
  child: TextField(
    controller: _titleController,    
    onChanged: (value) => storyTitle = value,
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
            icon: const Icon(Icons.save_rounded, color: Color(0xFF6C55F9), size: 28),
            tooltip: "Save your story",
            onPressed: () async {
              final choice = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFFF3F0FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: const [
                      Icon(Icons.save_rounded, color: Color(0xFF9182FA), size: 30),
                      SizedBox(width: 10),
                      Text(
                        "Save Story",
                        style: TextStyle(
                          color: Color(0xFF3C2E7E),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "Would you like to send your story to your supervisor or save it as a draft?",
                    style: TextStyle(
                      color: Color(0xFF3C2E7E),
                      fontSize: 16,
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9182FA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context, "send"),
                      child: const Text("Send to Supervisor"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF9182FA),
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
    color: mainPurple,
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
      color: const Color(0xFFE8E3FF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [

          // record story 
IconButton(
  icon: Icon(
    (_isListening || isRecording) ? Icons.stop_circle_outlined : Icons.mic,
    color: (_isListening || isRecording)
        ? Colors.redAccent
        : const Color(0xFF9182FA),
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
        backgroundColor: const Color(0xFFF3F0FF),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Choose an action 🎙️",
          style: TextStyle(
            color: Color(0xFF3C2E7E),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Would you like to record your voice or speak to write the story?",
          style: TextStyle(color: Color(0xFF3C2E7E)),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9182FA),
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
                color: Color(0xFF9182FA)),
            label: const Text("Speak to Write",
                style: TextStyle(color: Color(0xFF9182FA))),
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
  icon: const Icon(Icons.undo, color: Color(0xFF9182FA)),
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
  icon: const Icon(Icons.redo, color: Color(0xFF9182FA)),
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
  icon: const Icon(Icons.delete, color: Color(0xFF9182FA)),
  tooltip: "Delete this page",
  onPressed: () async {
    if (pages.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF3F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFF9182FA), size: 30),
            SizedBox(width: 10),
            Text(
              "Delete Page?",
              style: TextStyle(
                color: Color(0xFF3C2E7E),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to delete this entire page and all its content? 😢",
          style: TextStyle(
            color: Color(0xFF3C2E7E),
            fontSize: 16,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF9182FA),
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
    }
  },
),


         // icon + to add another pages 
IconButton(
  tooltip: "Add New Page",
  icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF7A6FF0)),
  onPressed: () async {
    print("🟣 Add button pressed!");

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        print("🟢 Dialog opened!");
        return AlertDialog(
          backgroundColor: const Color(0xFFF3F0FF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.add_circle_rounded, color: Color(0xFF9182FA), size: 30),
              SizedBox(width: 10),
              Text(
                "Add New Page?",
                style: TextStyle(
                  color: Color(0xFF3C2E7E),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            "Do you want to add a new blank page for your story?",
            style: TextStyle(
              color: Color(0xFF3C2E7E),
              fontSize: 16,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF9182FA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7A6FF0),
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
          color: mainPurple,
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
                      color: const Color(0xFF9182FA),
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
    //  الرفع من الهاتف (باستخدام image_picker)
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();
      _addUploadedImageFromBytes(bytes);
    }
  }
}),

                  _toolOption(Icons.auto_fix_high, "AI Generated Image", () {}),
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
      leading: Icon(icon, color: const Color(0xFF9182FA)),
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
                backgroundColor: const Color(0xFF9182FA),
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
            activeColor: const Color(0xFF9182FA),
            onChanged: (v) => setState(() => strokeWidth = v),
          ),

          const SizedBox(height: 5),

          // ↩️ Undo / Redo
          IconButton(
            tooltip: "Undo",
            icon: const Icon(Icons.undo, color: Color(0xFF7A6FF0), size: 26),
            onPressed: _undoDraw,
          ),
          IconButton(
            tooltip: "Redo",
            icon: const Icon(Icons.redo, color: Color(0xFF7A6FF0), size: 26),
            onPressed: _redoDraw,
          ),

          const Divider(
            color: Color(0xFFD3CCFA),
            thickness: 1,
            height: 15,
          ),

          // ✅ Done button
          IconButton(
            tooltip: "Done Drawing",
            icon: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF7A6FF0), size: 30),
            onPressed: () => setState(() => isDrawingMode = false),
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
                  backgroundColor: const Color(0xFFF3F0FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded,
                          color: Color(0xFF9182FA), size: 30),
                      SizedBox(width: 10),
                      Text(
                        "Delete drawing?",
                        style: TextStyle(
                          color: Color(0xFF3C2E7E),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    "Are you sure you want to clear your drawing? 😢",
                    style: TextStyle(
                      color: Color(0xFF3C2E7E),
                      fontSize: 16,
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceEvenly,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF9182FA),
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
}

void _redoDraw() {
  if (redoStack.isEmpty) return;
  setState(() {
    drawingPoints.addAll(redoStack);
    redoStack.clear();
  });
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

    // ============= 1) نبني الـ pages مع الميديا =============
    final List<Map<String, dynamic>> pagesJson = [];

    for (int pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final pageElements = <Map<String, dynamic>>[];
      final elements = pages[pageIndex];

      for (int i = 0; i < elements.length; i++) {
        final item = elements[i];
        final type = item["type"];

        // ---------- TEXT ----------
        if (type == "text") {
          pageElements.add({
            "type": "text",
            "content": item["text"] ?? "",
            "x": item["x"] ?? 50.0,
            "y": item["y"] ?? 50.0,
            "width": item["width"],
            "height": item["height"],
            "fontSize": item["fontSize"] ?? 20.0,
            "align": "left",
            "order": i,
          });
        }

        // ---------- IMAGE FROM ASSETS ----------
        else if (type == "image") {
          final String assetPath = item["imagePath"];

          pageElements.add({
            "type": "image",
            "content": "",
            "x": item["x"] ?? 40.0,
            "y": item["y"] ?? 40.0,
            "width": item["width"] ?? 150.0,
            "height": item["height"] ?? 150.0,
            "fontSize": null,
            "align": "left",
            "order": i,
            "media": {
              "mediaType": "image",
              "url": assetPath, // نخزن مسار الـ asset
              "page": pageIndex + 1,
              "elementOrder": i,
            },
          });
        }

        // ---------- UPLOADED IMAGE / DRAWN IMAGE ----------
        else if (type == "uploaded_image" || type == "drawn_image") {
          final Uint8List bytes = item["bytes"];
          final String fileName =
              "story_image_${DateTime.now().millisecondsSinceEpoch}.png";

          final url = await _uploadBytesToCloudinary(bytes, fileName);

          if (url == null) {
            print("⚠️ Failed to upload image, skipping element");
            continue;
          }

          pageElements.add({
            "type": "image",
            "content": "",
            "x": item["x"] ?? 40.0,
            "y": item["y"] ?? 40.0,
            "width": item["width"] ?? 150.0,
            "height": item["height"] ?? 150.0,
            "fontSize": null,
            "align": "left",
            "order": i,
            "media": {
              "mediaType": "image",
              "url": url,
              "page": pageIndex + 1,
              "elementOrder": i,
            },
          });
        }

        // ---------- AUDIO ----------
        else if (type == "audio") {
          final String path = item["path"];
          final String fileName =
              "story_audio_${DateTime.now().millisecondsSinceEpoch}.m4a";

          final url = await _uploadFilePathToCloudinary(path, fileName);

          if (url == null) {
            print("⚠️ Failed to upload audio, skipping element");
            continue;
          }

          pageElements.add({
            "type": "audio",
            "content": "",
            "x": item["x"] ?? 50.0,
            "y": item["y"] ?? 50.0,
            "width": null,
            "height": null,
            "fontSize": null,
            "align": "left",
            "order": i,
            "media": {
              "mediaType": "audio",
              "url": url,
              "page": pageIndex + 1,
              "elementOrder": i,
            },
          });
        }
      }

      pagesJson.add({
        "pageNumber": pageIndex + 1,
        "elements": pageElements,
      });
    }

    // ============= 2) نختار coverImage =============
    String? coverImage;
    for (final page in pagesJson) {
      for (final el in (page["elements"] as List)) {
        if (el["type"] == "image" && el["media"]?["url"] != null) {
          coverImage = el["media"]["url"];
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

    // ============= 3) CREATE لو ما في storyId =============
    http.Response response;

    if (storyId == null) {
      print("🆕 Creating new story...");

      response = await http.post(
        Uri.parse("${getBackendUrl()}/api/story/create"),
        headers: headers,
        body: jsonEncode({"title": storyTitle}),
      );

      print("📦 Server response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        storyId = data["storyId"] ?? data["_id"];

        if (storyId != null) {
          await prefs.setString('currentStoryId', storyId!);
          print("✅ New story saved with ID: $storyId");
        } else {
          print("⚠️ Story ID not found in create response.");
          return;
        }
      } else {
        print("❌ Error creating story: ${response.body}");
        return;
      }
    }

    // ============= 4) UPDATE PAGES =============
    print("✏️ Updating existing story: $storyId");

    final updateResponse = await http.put(
      Uri.parse("${getBackendUrl()}/api/story/update/$storyId"),
      headers: headers,
      body: jsonEncode(storyData),
    );

    print("📩 Update response: ${updateResponse.body}");

    if (updateResponse.statusCode != 200) {
      print("❌ Error updating story: ${updateResponse.body}");
      return;
    }

    // ============= 5) SUBMIT لو بده يرسل للسوبرفايزر =============
    if (sendToSupervisor) {
      await _submitStory(storyId!, token);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sendToSupervisor
            ? "📤 Story sent to supervisor!"
            : "💾 Story saved."),
        backgroundColor: const Color(0xFF9182FA),
      ),
    );
  } catch (e, stack) {
    print("⚠️ Exception while saving story: $e");
    print(stack);
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // -------- SET TITLE ----------
      storyTitle = data["title"] ?? "My Story";
      _titleController.text = storyTitle;       

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
            final String? mediaUrl = media?["url"];

            if (mediaUrl != null && mediaUrl.startsWith("assets/")) {
              // IMAGE FROM ASSETS
              pageElements.add({
                "key": UniqueKey(),
                "type": "image",
                "imagePath": mediaUrl,
                "x": x,
                "y": y,
                "width": width,
                "height": height,
              });
            } else if (mediaUrl != null && mediaUrl.startsWith("http")) {
              // IMAGE FROM CLOUDINARY
              pageElements.add({
                "key": UniqueKey(),
                "type": "uploaded_image",
                "networkUrl": mediaUrl,
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
    } 
    else {
      print("❌ Error loading story: ${response.statusCode} — ${response.body}");
    }
  } catch (e) {
    print("⚠️ Error: $e");
  }
}




Future<String?> _uploadBytesToCloudinary(Uint8List bytes, String fileName) async {
  try {
    final uri = Uri.parse("${getBackendUrl()}/api/upload/story-media");

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final request = http.MultipartRequest("POST", uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
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

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["url"];
    } else {
      print("❌ Cloudinary upload failed: ${response.body}");
      return null;
    }
  } catch (e) {
    print("⚠️ Upload error: $e");
    return null;
  }
}

Future<String?> _uploadFilePathToCloudinary(String filePath, String fileName) async {
  final file = File(filePath);
  if (!await file.exists()) return null;
  final bytes = await file.readAsBytes();
  return _uploadBytesToCloudinary(bytes, fileName);
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
