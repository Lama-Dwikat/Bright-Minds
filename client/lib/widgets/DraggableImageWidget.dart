import 'dart:typed_data';
import 'package:flutter/material.dart';

class DraggableImageWidget extends StatefulWidget {
  final String? imagePath;        // asset image
  final String? networkUrl;       // cloudinary image
  final Uint8List? bytes;         // drawn / uploaded image

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

  // ================================
  // 🔥 CHOOSE IMAGE SOURCE
  // ================================
  Widget _buildImage() {
    if (widget.bytes != null) {
      return Image.memory(widget.bytes!, fit: BoxFit.cover);
    }

    if (widget.networkUrl != null && widget.networkUrl!.isNotEmpty) {
      return Image.network(
        widget.networkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, size: 40)),
      );
    }

    if (widget.imagePath != null) {
      return Image.asset(
        widget.imagePath!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, size: 40)),
      );
    }

    return const Center(child: Icon(Icons.image_not_supported, size: 40));
  }

  // ================================
  // 🔥 DELETE CONFIRMATION
  // ================================
  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF3F0FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
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
          "Are you sure you want to remove this image?",
          style: TextStyle(color: Color(0xFF3C2E7E), fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
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

  // ================================
  // 🔥 WIDGET BUILD
  // ================================
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () => _confirmDelete(),
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
            // IMAGE
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

            // RESIZE HANDLE
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
                      border: Border.all(color: Colors.purple, width: 2),
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
