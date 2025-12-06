import 'package:flutter/material.dart';

class LoadingDragon extends StatefulWidget {
  const LoadingDragon({super.key});

  @override
  _LoadingDragonState createState() => _LoadingDragonState();
}

class _LoadingDragonState extends State<LoadingDragon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            "assets/images/dragon.png", 
            width: 150,
          ),
          const SizedBox(height: 10),
          const Text(
            "Generating your magic ✨",
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
