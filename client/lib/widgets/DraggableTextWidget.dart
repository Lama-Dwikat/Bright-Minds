import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DraggableTextWidget extends StatefulWidget {
  String text;
  Color color;
  double fontSize;
  bool isBold;
  bool isItalic;
  bool isUnderlined;
  final VoidCallback onDelete;

  final double x;
  final double y;
  final void Function(double x, double y)? onPositionChanged;

  /// لما تتغير خصائص النص من الـ bottom sheet
  final void Function(
    Color color,
    double fontSize,
    bool isBold,
    bool isItalic,
    bool isUnderlined,
  )? onStyleChanged;

  DraggableTextWidget({
    super.key,
    required this.text,
    this.color = Colors.black,
    required this.onDelete,
    this.fontSize = 20,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
    this.x = 50,
    this.y = 50,
    this.onPositionChanged,
    this.onStyleChanged,
  });

  @override
  State<DraggableTextWidget> createState() => _DraggableTextWidgetState();
}

class _DraggableTextWidgetState extends State<DraggableTextWidget> {
  late double x;
  late double y;

  bool showDeleteButton = false;

  @override
  void initState() {
    super.initState();
    x = widget.x;
    y = widget.y;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
       onTap: () async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFF3F0FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.delete_forever_rounded, color: Color(0xFF9182FA), size: 30),
          SizedBox(width: 10),
          Text(
            "Delete this text?",
            style: TextStyle(
              color: Color(0xFF3C2E7E),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: const Text(
        "Are you sure you want to delete this text from your story? 😢",
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
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes, Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm == true) {
    widget.onDelete();
  }
},

        onPanUpdate: (details) {
          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
          widget.onPositionChanged?.call(x, y);
        },
        onLongPress: () => _openTextFormattingMenu(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ===================== THE TEXT ITSELF =====================
            Text(
              widget.text,
              style: GoogleFonts.poppins(
                color: widget.color,
                fontSize: widget.fontSize,
                fontWeight: widget.isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle:
                    widget.isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: widget.isUnderlined
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),

            // ===================== DELETE BUTTON =====================
          /*  if (showDeleteButton)
              Positioned(
                top: -20,
                right: -20,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onDelete,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
              */
 

          ],
        ),
      ),
    );
  }

  // ===================== TEXT FORMAT MENU =====================
  void _openTextFormattingMenu(BuildContext context) {
    TextEditingController controller =
        TextEditingController(text: widget.text);

    bool tempBold = widget.isBold;
    bool tempItalic = widget.isItalic;
    bool tempUnderlined = widget.isUnderlined;
    double tempFontSize = widget.fontSize;
    Color tempColor = widget.color;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, bottomSetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ---------------- TEXT EDIT ----------------
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Edit Text",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // ---------------- TOOLS ROW ----------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _formatButton(
                          icon: Icons.format_bold,
                          active: tempBold,
                          onTap: () {
                            bottomSetState(() {
                              tempBold = !tempBold;
                            });
                          },
                        ),
                        _formatButton(
                          icon: Icons.format_italic,
                          active: tempItalic,
                          onTap: () {
                            bottomSetState(() {
                              tempItalic = !tempItalic;
                            });
                          },
                        ),
                        _formatButton(
                          icon: Icons.format_underline,
                          active: tempUnderlined,
                          onTap: () {
                            bottomSetState(() {
                              tempUnderlined = !tempUnderlined;
                            });
                          },
                        ),
                        _colorButton(
                          currentColor: tempColor,
                          onColorChanged: (c) {
                            bottomSetState(() {
                              tempColor = c;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ---------------- FONT SIZE SLIDER ----------------
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Font Size"),
                        Slider(
                          value: tempFontSize,
                          min: 12,
                          max: 60,
                          onChanged: (value) {
                            bottomSetState(() {
                              tempFontSize = value;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ---------------- SAVE BUTTON ----------------
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9182FA),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        setState(() {
                          widget.text = controller.text;
                          widget.isBold = tempBold;
                          widget.isItalic = tempItalic;
                          widget.isUnderlined = tempUnderlined;
                          widget.fontSize = tempFontSize;
                          widget.color = tempColor;
                        });

                        widget.onStyleChanged?.call(
                          widget.color,
                          widget.fontSize,
                          widget.isBold,
                          widget.isItalic,
                          widget.isUnderlined,
                        );

                        Navigator.pop(context);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== SMALL UI HELPERS =====================

  Widget _formatButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor:
            active ? const Color(0xFF9182FA) : Colors.grey[300],
        child: Icon(icon, color: active ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _colorButton({
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    return GestureDetector(
      onTap: () => _openColorPicker(onColorChanged),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: currentColor,
        child: const Icon(Icons.color_lens, color: Colors.white),
      ),
    );
  }

  void _openColorPicker(ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick Color"),
          content: Wrap(
            spacing: 10,
            children: [
              _colorChoice(Colors.black, onColorChanged),
              _colorChoice(Colors.red, onColorChanged),
              _colorChoice(Colors.blue, onColorChanged),
              _colorChoice(Colors.green, onColorChanged),
              _colorChoice(Colors.purple, onColorChanged),
              _colorChoice(Colors.orange, onColorChanged),
            ],
          ),
        );
      },
    );
  }

  Widget _colorChoice(Color color, ValueChanged<Color> onColorChanged) {
    return GestureDetector(
      onTap: () {
        onColorChanged(color);
        Navigator.pop(context);
      },
      child: CircleAvatar(
        backgroundColor: color,
        radius: 18,
      ),
    );
  }
}
