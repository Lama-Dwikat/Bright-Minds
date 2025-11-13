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
        onTap: () {
          setState(() {
            showDelete = !showDelete;
          });
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

            // ===== DELETE BUTTON =====
            if (showDelete)
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
