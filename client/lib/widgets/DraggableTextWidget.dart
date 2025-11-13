import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DraggableTextWidget extends StatefulWidget {
  String text;
  Color color;
  double fontSize;
  bool isBold;
  bool isItalic;
  bool isUnderlined;

  DraggableTextWidget({
    super.key,
    required this.text,
    this.color = Colors.black,
    this.fontSize = 20,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderlined = false,
  });

  @override
  State<DraggableTextWidget> createState() => _DraggableTextWidgetState();
}

class _DraggableTextWidgetState extends State<DraggableTextWidget> {
  double x = 50;
  double y = 50;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
        },

        onTap: () => _openTextFormattingMenu(context),

        child: Text(
          widget.text,
          style: GoogleFonts.poppins(
            color: widget.color,
            fontSize: widget.fontSize,
            fontWeight: widget.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: widget.isItalic ? FontStyle.italic : FontStyle.normal,
            decoration:
                widget.isUnderlined ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  // ===================== TEXT FORMAT MENU =====================
  void _openTextFormattingMenu(BuildContext context) {
    TextEditingController controller =
        TextEditingController(text: widget.text);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
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
                      active: widget.isBold,
                      onTap: () {
                        setState(() => widget.isBold = !widget.isBold);
                      },
                    ),
                    _formatButton(
                      icon: Icons.format_italic,
                      active: widget.isItalic,
                      onTap: () {
                        setState(() => widget.isItalic = !widget.isItalic);
                      },
                    ),
                    _formatButton(
                      icon: Icons.format_underline,
                      active: widget.isUnderlined,
                      onTap: () {
                        setState(() => widget.isUnderlined = !widget.isUnderlined);
                      },
                    ),
                    _colorButton(),
                  ],
                ),

                const SizedBox(height: 20),

                // ---------------- FONT SIZE SLIDER ----------------
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Font Size"),
                    Slider(
                      value: widget.fontSize,
                      min: 12,
                      max: 60,
                      onChanged: (value) {
                        setState(() => widget.fontSize = value);
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
                    });
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
  }

  // ===================== SMALL UI HELPERS =====================

  Widget _formatButton({required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: active ? const Color(0xFF9182FA) : Colors.grey[300],
        child: Icon(icon, color: active ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _colorButton() {
    return GestureDetector(
      onTap: () => _openColorPicker(),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: widget.color,
        child: const Icon(Icons.color_lens, color: Colors.white),
      ),
    );
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Pick Color"),
          content: Wrap(
            spacing: 10,
            children: [
              _colorChoice(Colors.black),
              _colorChoice(Colors.red),
              _colorChoice(Colors.blue),
              _colorChoice(Colors.green),
              _colorChoice(Colors.purple),
              _colorChoice(Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _colorChoice(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => widget.color = color);
        Navigator.pop(context);
      },
      child: CircleAvatar(
        backgroundColor: color,
        radius: 18,
      ),
    );
  }
}
