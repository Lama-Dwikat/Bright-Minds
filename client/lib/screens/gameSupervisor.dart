


import 'package:bright_minds/screens/games/GuessWordTemplete.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:bright_minds/screens/games/GridWordTemplete.dart';
import 'package:bright_minds/screens/games/MissLetterTemplete.dart';
import 'package:bright_minds/screens/games/MemoryCardTemplete.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';






// class _Bubble extends StatelessWidget {
//   final double size;

//   const _Bubble({required this.size});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,

//         // Transparent bubble body
//         color: Colors.white.withOpacity(0.05),

//         // Soft white border
//         border: Border.all(
//           color: Colors.white.withOpacity(0.3),
//           width: 1.5,
//         ),

//         // Glow effect
//         boxShadow: [
//           BoxShadow(
//             color: Colors.white.withOpacity(0.15),
//             blurRadius: 6,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//     );
//   }
// }







// class SoftWaveClipper extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     final path = Path();

//     path.lineTo(0, size.height - 10); // left edge DOWN

//     path.quadraticBezierTo(
//       size.width * 0.5,
//       size.height - 50, // middle UP
//       size.width,
//       size.height - 10, // right edge DOWN
//     );

//     path.lineTo(size.width, 0);
//     path.close();

//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) => false;
// }



// Widget _gameButton({
//   required String title,
//   String? imagePath,
//   Color? color,
//   required VoidCallback? onTap,
// }) {
//   return InkWell(
//     onTap: onTap,
//     borderRadius: BorderRadius.circular(30),
//     child: Container(
//       decoration: BoxDecoration(
//         color: color ?? Colors.blue,
//         borderRadius: BorderRadius.circular(30),
//         boxShadow: [
//           BoxShadow(
//             color: (color ?? Colors.blue).withOpacity(0.4),
//             blurRadius: 12,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // 🖼️ Image (if provided)
//           (imagePath != null
//               ? 
//        Image.asset(imagePath, width: 60, height: 60)
//                   : const SizedBox()),
//           const SizedBox(height: 12),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }


// Widget _gameCard({
//   required String title,
//   required String imagePath,
//   required VoidCallback onTap,
// }) {
//   return InkWell(
//     borderRadius: BorderRadius.circular(26),
//     onTap: onTap,
//     child: Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(26),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 14,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.all(14),
//               child: Image.asset(
//                 imagePath,
//                 fit: BoxFit.contain,
//               ),
//             ),
//           ),

//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 246, 231, 215),
//               borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(26),
//               ),
//             ),
//             child: Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.brown,
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }



// class GamesHomePage extends StatefulWidget {
//   const GamesHomePage({super.key});

//   @override
//   State<GamesHomePage> createState() => _GamesHomePageState();
// }

// class _GamesHomePageState extends State<GamesHomePage> {
//   String? role;
//   String? ageGroup;

//   @override
//   void initState() {
//     super.initState();
//     _decodeToken();
//   }

//   Future<void> _decodeToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token") ?? "";
//     if (token.isNotEmpty) {
//       final decoded = JwtDecoder.decode(token);
//       setState(() {
//         role = decoded['role'];
//         ageGroup = decoded['ageGroup']; // e.g., "5-8" or "9-12"
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return HomePage(
//       title: "Games",
//       child: ageGroup == null
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // 🌈 Header
// CustomPaint(
//   painter: SoftWaveBorderPainter(
//     clipper: SoftWaveClipper(),
//     color: const Color.fromARGB(255, 155, 98, 5).withOpacity(0.35),
//     strokeWidth: 2,
//   ),
//   child: ClipPath(
//     clipper: SoftWaveClipper(),
//     child: Container(
//       height: 120,
//       width: double.infinity,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             const Color.fromARGB(255, 228, 165, 62).withOpacity(0.50),
//             const Color.fromARGB(255, 227, 170, 12).withOpacity(0.50),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Stack(
//         children: [
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 Text(
//                   "Let’s Design Games 🎮",
//                   style: TextStyle(
//                     fontSize: 26,
//                     fontWeight: FontWeight.w800,
//                     color: Colors.brown,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   "Create fun games for kids 🌈",
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: Colors.brown,
//                     fontWeight: FontWeight.bold
//                   ),
//                 ),
//                        SizedBox(height: 3),

//               ],
//             ),
//           ),

//           // bubbles
//           Positioned(top: 25, left: 20, child: _Bubble(size: 35)),
//           Positioned(top: 60, right: 30, child: _Bubble(size: 18)),
//           Positioned(bottom: 40, left: 60, child: _Bubble(size: 28)),
//           Positioned(bottom: 15, right: 20, child: _Bubble(size: 70)),
//         ],
//       ),
//     ),
//   ),
// ),


//                 const SizedBox(height: 20),

//                 // 🎮 Games Grid
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: GridView.count(
//                       crossAxisCount: 2,
//                       mainAxisSpacing: 20,
//                       crossAxisSpacing: 20,
//                       childAspectRatio: 0.75,
//                       children: [
//                           if (ageGroup == '9-12')...[
//                         _gameCard(
//                           title: "Guess The Word",
//                           imagePath: "assets/images/guessWord.png",
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => GuessTemplate()),
//                             );
//                           },
//                         ),
//                         _gameCard(
//                           title: "Grid Words",
//                           imagePath: "assets/images/grid.png",
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => GridWordTemplate()),
//                             );
//                           },
//                         ),
//                         _gameCard(
//                           title: "Miss Letters",
//                           imagePath: "assets/images/missLetter.png",
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (_) => MissLetterTemplate()),
//                             );
//                           },
//                         ), ],

//                         // ✅ Memory Game only for ageGroup 5-8
//                         if (ageGroup == '5-8')
//                           _gameCard(
//                             title: "Memory Game",
//                             imagePath: "assets/images/memory.png",
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => MemoryTemplate()),
//                               );
//                             },
//                           ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }
// class SoftWaveBorderPainter extends CustomPainter {
//   final CustomClipper<Path> clipper;
//   final Color color;
//   final double strokeWidth;

//   SoftWaveBorderPainter({
//     required this.clipper,
//     required this.color,
//     this.strokeWidth = 2,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final path = clipper.getClip(size);
//     final paint = Paint()
//       ..color = color
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = strokeWidth;

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
import 'package:bright_minds/screens/games/GuessWordTemplete.dart';
import 'package:bright_minds/screens/games/GridWordTemplete.dart';
import 'package:bright_minds/screens/games/MissLetterTemplete.dart';
import 'package:bright_minds/screens/games/MemoryCardTemplete.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class _Bubble extends StatelessWidget {
  final double size;
  const _Bubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class SoftWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 10);
    path.quadraticBezierTo(size.width * 0.5, size.height - 50, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

Widget _gameCard({required String title, required String imagePath, required VoidCallback onTap}) {
  return InkWell(
    borderRadius: BorderRadius.circular(26),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 246, 231, 215),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.brown),
            ),
          ),
        ],
      ),
    ),
  );
}

class GamesHomePage extends StatefulWidget {
  const GamesHomePage({super.key});

  @override
  State<GamesHomePage> createState() => _GamesHomePageState();
}

class _GamesHomePageState extends State<GamesHomePage> {
  String? role;
  String? ageGroup;

  @override
  void initState() {
    super.initState();
    _decodeToken();
  }

  Future<void> _decodeToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    if (token.isNotEmpty) {
      final decoded = JwtDecoder.decode(token);
      setState(() {
        role = decoded['role'];
        ageGroup = decoded['ageGroup']; // e.g., "5-8" or "9-12"
      });
    }
  }

  // -------------------- MOBILE BODY --------------------
  Widget _buildMobileBody() {
    return ageGroup == null
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // 🌈 Header
              CustomPaint(
                painter: SoftWaveBorderPainter(
                  clipper: SoftWaveClipper(),
                  color: const Color.fromARGB(255, 155, 98, 5).withOpacity(0.35),
                  strokeWidth: 2,
                ),
                child: ClipPath(
                  clipper: SoftWaveClipper(),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(255, 228, 165, 62).withOpacity(0.50),
                          const Color.fromARGB(255, 227, 170, 12).withOpacity(0.50),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                "Let’s Design Games 🎮",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.brown,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Create fun games for kids 🌈",
                                style: TextStyle(fontSize: 15, color: Colors.brown, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 3),
                            ],
                          ),
                        ),
                        Positioned(top: 25, left: 20, child: _Bubble(size: 35)),
                        Positioned(top: 60, right: 30, child: _Bubble(size: 18)),
                        Positioned(bottom: 40, left: 60, child: _Bubble(size: 28)),
                        Positioned(bottom: 15, right: 20, child: _Bubble(size: 70)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 🎮 Games Grid
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.75,
                    children: [
                      if (ageGroup == '9-12') ...[
                        _gameCard(
                          title: "Guess The Word",
                          imagePath: "assets/images/guessWord.png",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuessTemplate())),
                        ),
                        _gameCard(
                          title: "Grid Words",
                          imagePath: "assets/images/grid.png",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GridWordTemplate())),
                        ),
                        _gameCard(
                          title: "Miss Letters",
                          imagePath: "assets/images/missLetter.png",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MissLetterTemplate())),
                        ),
                      ],
                      if (ageGroup == '5-8')
                        _gameCard(
                          title: "Memory Game",
                          imagePath: "assets/images/memory.png",
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryTemplate())),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
  }

  // -------------------- WEB BODY --------------------
  Widget _buildWebBody() {
    return ageGroup == null
        ? const Center(child: CircularProgressIndicator())
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT SIDE: optional menu/info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 248, 217, 154),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Welcome to the Games Dashboard Including The Templetes!",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Additional menu or info can go here
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 248, 217, 154),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Select a game from the right panel",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // // RIGHT SIDE: Games Grid
              // Expanded(
              //   flex: 5,
              //   child: Padding(
              //     padding: const EdgeInsets.all(24.0),
              //     child: GridView.count(
              //       crossAxisCount: 4,
              //       mainAxisSpacing: 20,
              //       crossAxisSpacing: 20,
              //       childAspectRatio: 0.75,
              //       children: [
              //         if (ageGroup == '9-12') ...[
              //           _gameCard(
              //             title: "Guess The Word",
              //             imagePath: "assets/images/guessWord.png",
              //             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GuessTemplate())),
              //           ),
              //           _gameCard(
              //             title: "Grid Words",
              //             imagePath: "assets/images/grid.png",
              //             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GridWordTemplate())),
              //           ),
              //           _gameCard(
              //             title: "Miss Letters",
              //             imagePath: "assets/images/missLetter.png",
              //             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MissLetterTemplate())),
              //           ),
              //         ],
              //         if (ageGroup == '5-8')
              //           _gameCard(
              //             title: "Memory Game",
              //             imagePath: "assets/images/memory.png",
              //             onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MemoryTemplate())),
              //           ),
              //       ],
              //     ),
              //   ),
              // ),
              // RIGHT SIDE: Games Grid
Expanded(
  flex: 5,
  child: Padding(
    padding: const EdgeInsets.all(24.0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        // Total available width for GridView
        double totalWidth = constraints.maxWidth;

        int columns = 2; // 2 games per row
        double spacing = 20; // same as crossAxisSpacing
        double itemWidth = (totalWidth - (columns - 1) * spacing) / columns;

        double childAspectRatio = 1.3; // same as your GridView
        double itemHeight = itemWidth / childAspectRatio;

        print("Item width: $itemWidth, Item height: $itemHeight"); // 👈 here you detect height

        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
          children: [
            if (ageGroup == '9-12') ...[
              _gameCard(
                title: "Guess The Word",
                imagePath: "assets/images/guessWord.png",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GuessTemplate())),
              ),
              _gameCard(
                title: "Grid Words",
                imagePath: "assets/images/grid.png",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => GridWordTemplate())),
              ),
              _gameCard(
                title: "Miss Letters",
                imagePath: "assets/images/missLetter.png",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MissLetterTemplate())),
              ),
            ],
            if (ageGroup == '5-8')
              _gameCard(
                title: "Memory Game",
                imagePath: "assets/images/memory.png",
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MemoryTemplate())),
              ),
          ],
        );
      },
    ),
  ),
),


            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    // Detect web or large screen
    bool isWebLayout = kIsWeb || MediaQuery.of(context).size.width > 800;
    return HomePage(
      title: "Games",
      child: isWebLayout ? _buildWebBody() : _buildMobileBody(),
    );
  }
}

class SoftWaveBorderPainter extends CustomPainter {
  final CustomClipper<Path> clipper;
  final Color color;
  final double strokeWidth;
  SoftWaveBorderPainter({required this.clipper, required this.color, this.strokeWidth = 2});
  @override
  void paint(Canvas canvas, Size size) {
    final path = clipper.getClip(size);
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
