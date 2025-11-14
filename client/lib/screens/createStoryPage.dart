import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/widgets/DraggableTextWidget.dart';
import 'package:bright_minds/widgets/DraggableImageWidget.dart';
import 'dart:typed_data';


class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

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
  List<Map<String, dynamic>> canvasElements = [];

  final TextEditingController _textController = TextEditingController();

  // Main Brand Color
  final Color mainPurple = const Color(0xFF9182FA);

  final List<String> storyImageAssets = [
    'assets/story_images/discussion.png',
    'assets/story_images/Drawing.png',
    'assets/story_images/energy.png',
    'assets/story_images/Games2.png',
  ];

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
  child: IgnorePointer(
    ignoring: !isDrawingMode,
    child: GestureDetector(
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

                          ...canvasElements.map((item) {
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
                                  setState(() {
                                    canvasElements.removeWhere(
                                      (e) => e["key"] == item["key"],
                                    );
                                  });
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
                                    canvasElements.removeWhere(
                                      (e) => e["key"] == item["key"],
                                    );
                                  });
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
        canvasElements.removeWhere((e) => e["key"] == item["key"]);
      });
    },
  );
}

                            return const SizedBox();
                          }).toList(),

                          if (canvasElements.isEmpty)
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
                _buildBottomToolbar(),
              ],
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
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => storyTitle = value),
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
      "Page 1 / 1",
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFE8E3FF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(icon: Icon(Icons.mic, color: mainPurple), onPressed: () {}),
          IconButton(icon: Icon(Icons.play_arrow, color: mainPurple), onPressed: () {}),
          IconButton(icon: Icon(Icons.undo, color: mainPurple), onPressed: () {}),
          IconButton(icon: Icon(Icons.redo, color: mainPurple), onPressed: () {}),
          IconButton(icon: Icon(Icons.delete, color: mainPurple), onPressed: () {}),
          IconButton(icon: Icon(Icons.add, color: mainPurple), onPressed: () {}),
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

                  _toolOption(Icons.upload_file, "Upload Picture", () {}),
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
      canvasElements.add({
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
      canvasElements.add({
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
    canvasElements.add({
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
          )
        ],
      ),
      child: Column(
        children: [
          // Colors
          _colorDot(Colors.black),
          _colorDot(Colors.red),
          _colorDot(Colors.blue),
          _colorDot(Colors.green),
          _colorDot(Colors.orange),
          SizedBox(height: 10),

          Text("Size", style: TextStyle(fontSize: 12)),
          Slider(
            value: strokeWidth,
            min: 2,
            max: 20,
            onChanged: (v) => setState(() => strokeWidth = v),
          ),

          IconButton(
            icon: Icon(Icons.undo),
            onPressed: _undoDraw,
          ),
          IconButton(
            icon: Icon(Icons.redo),
            onPressed: _redoDraw,
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9182FA),
            ),
            onPressed: () => setState(() => isDrawingMode = false),
            child: Text("Done"),
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
