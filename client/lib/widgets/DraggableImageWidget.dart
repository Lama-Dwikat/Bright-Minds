import 'dart:typed_data';
import 'package:flutter/material.dart';

class DraggableImageWidget extends StatefulWidget {
  final String? imagePath;    // asset image
  final String? networkUrl;   // cloudinary image
  final Uint8List? bytes;     // drawn / uploaded (محلياً)

  final VoidCallback onDelete;

  final double x;
  final double y;
  final double width;
  final double height;

  final void Function(double x, double y)? onPositionChanged;
  final void Function(double width, double height)? onResize;

  const DraggableImageWidget({
    super.key,
    this.imagePath,
    this.networkUrl,
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

  bool showControls = true;

  @override
  void initState() {
    super.initState();
    x = widget.x;
    y = widget.y;
    width = widget.width;
    height = widget.height;
  }

  // 🔍 اختيار مصدر الصورة
  Widget _buildImage() {
    // 1) bytes لو موجودة
    if (widget.bytes != null) {
      return Image.memory(widget.bytes!, fit: BoxFit.cover);
    }

    // 2) networkUrl حقيقي
    if (widget.networkUrl != null &&
        widget.networkUrl!.startsWith("http")) {
      return Image.network(
        widget.networkUrl!,
        fit: BoxFit.cover,
      );
    }

    // 3) asset
    if (widget.imagePath != null &&
        !widget.imagePath!.startsWith("http")) {
      return Image.asset(
        widget.imagePath!,
        fit: BoxFit.cover,
      );
    }

    return const Icon(Icons.image_not_supported);
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 255, 248, 234),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded,
                color:  Color.fromARGB(255, 240, 169, 70), size: 28),
            SizedBox(width: 10),
            Text(
              "Delete this image?",
              style: TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: const Text(
          "Are you sure you want to remove this image?",
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: _confirmDelete,
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
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(),
              ),
            ),
            if (showControls)
              Positioned(
                bottom: -14,
                right: -14,
                child: GestureDetector(
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
                      border: Border.all(color:  Color.fromARGB(255, 240, 169, 70), width: 2),
                    ),
                    child: const Icon(
                      Icons.open_in_full,
                      size: 16,
                      color: Color.fromARGB(255, 240, 169, 70),
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
