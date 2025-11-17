import 'dart:typed_data';
import 'package:flutter/material.dart';

class DraggableImageWidget extends StatefulWidget {
  final String? imagePath;        // asset path
  final Uint8List? bytes;         // رسم الطفل
  final VoidCallback onDelete;

  final double x;
  final double y;
  final double width;
  final double height;

  final void Function(double x, double y)? onPositionChanged;
  final void Function(double width, double height)? onResize;

  DraggableImageWidget({
    super.key,
    this.imagePath,
    this.bytes,
    required this.onDelete,
    this.x = 40,
    this.y = 40,
    this.width = 150,
    this.height = 150,
    this.onPositionChanged,
    this.onResize,
  });

  @override
  State<DraggableImageWidget> createState() => _DraggableImageWidgetState();
}

class _DraggableImageWidgetState extends State<DraggableImageWidget> {
  late double x;
  late double y;

  late double width;
  late double height;

  bool showDelete = false;

  @override
  void initState() {
    super.initState();
    x = widget.x;
    y = widget.y;
    width = widget.width;
    height = widget.height;
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
          Icon(Icons.photo_rounded, color: Color(0xFF9182FA), size: 30),
          SizedBox(width: 10),
          Text(
            "Delete this image?",
            style: TextStyle(
              color: Color(0xFF3C2E7E),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: const Text(
        "Do you want to remove this image from your story? 🖼️",
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
    widget.onDelete(); // call the parent delete function
  }
},

        onPanUpdate: (details) {
          setState(() {
            x += details.delta.dx;
            y += details.delta.dy;
          });
          widget.onPositionChanged?.call(x, y);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ===== IMAGE (Asset or Memory) =====
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.bytes != null
                    ? Image.memory(widget.bytes!, fit: BoxFit.cover)
                    : Image.asset(widget.imagePath!, fit: BoxFit.cover),
              ),
            ),

           
            // ===== RESIZE HANDLE =====
            if (showDelete)
              Positioned(
                bottom: -15,
                right: -15,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: (details) {
                    setState(() {
                      width += details.delta.dx;
                      height += details.delta.dy;

                      if (width < 50) width = 50;
                      if (height < 50) height = 50;
                    });
                    widget.onResize?.call(width, height);
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purple,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 16,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
