import 'package:flutter/material.dart';

class DraggableImageWidget extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;

  const DraggableImageWidget({
    super.key,
    required this.assetPath,
    this.width = 120,
    this.height = 120,
  });

  @override
  State<DraggableImageWidget> createState() => _DraggableImageWidgetState();
}

class _DraggableImageWidgetState extends State<DraggableImageWidget> {
  double x = 60;
  double y = 60;

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
        child: Image.asset(
          widget.assetPath,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
