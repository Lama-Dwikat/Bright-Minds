import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/widgets/DraggableTextWidget.dart';
import 'package:bright_minds/widgets/DraggableImageWidget.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  String storyTitle = "My Story";

  // بدل textWidgets → الآن عناصر عامة للكانفاس: نصوص + صور
  List<Widget> canvasElements = [];

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
                  child: Center(
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
                        children: [
                          ...canvasElements,
                          Center(
                            child: canvasElements.isEmpty
                                ? Text(
                                    "Tap tools to add elements",
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.grey[400],
                                    ),
                                  )
                                : const SizedBox(),
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
                  _toolOption(Icons.draw, "Draw", () {}),
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
          position: Tween(begin: const Offset(-1, 0), end: Offset.zero)
              .animate(animation),
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
    setState(() {
      canvasElements.add(
        DraggableTextWidget(
          text: text,
          color: Colors.black,
        ),
      );
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
                      _addDraggableImage(assetPath);
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

  void _addDraggableImage(String assetPath) {
    setState(() {
      canvasElements.add(
        DraggableImageWidget(
          assetPath: assetPath,
          width: 130,
          height: 130,
        ),
      );
    });
  }
}
