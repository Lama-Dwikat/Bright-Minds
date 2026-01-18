import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class LoadingDragon extends StatefulWidget {
  const LoadingDragon({super.key});

  @override
  State<LoadingDragon> createState() => _LoadingDragonState();
}

class _LoadingDragonState extends State<LoadingDragon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
      scale: Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✅ على الويب كمان بتشتغل عادي طالما asset موجود ومتعرف بالpubspec
          Image.asset(
            "assets/images/dragon.png",
            width: kIsWeb ? 170 : 150, // فرق بسيط بالويب (UI فقط)
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              // ✅ لو asset مش موجود أو ما نرفع صح على الويب
              return Icon(
                Icons.auto_awesome,
                size: kIsWeb ? 90 : 80,
                color: Colors.orange,
              );
            },
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










/*import 'package:flutter/material.dart';

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
*/