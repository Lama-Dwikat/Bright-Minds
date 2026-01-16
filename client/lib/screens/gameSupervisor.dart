


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




// class GamesHomePage extends StatelessWidget {
//   const GamesHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return HomePage(
//       title: "Games",
//       child: Column(
//         children: [
//           // 🌈 Header
//           ClipPath(
//             clipper: SoftWaveClipper(),
//             child: Container(
//               height: 200,
//               width: double.infinity,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.bgBlushRoseVeryDark,
//                     AppColors.bgBlushRoseDark,
//                   ],
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                 ),
//               ),
//               child: Stack(
//                 children: const [
//                   Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           "Let’s Design Games 🎨🎮",
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         SizedBox(height: 6),
//                         Text(
//                           "Create fun games for kids 🌟",
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // bubbles
//                   Positioned(top: 20, left: 30, child: _Bubble(size: 40)),
//                   Positioned(top: 50, right: 40, child: _Bubble(size: 15)),
//                   Positioned(bottom: 30, left: 70, child: _Bubble(size: 35)),
//                   Positioned(bottom: 20, right: 10, child: _Bubble(size: 85)),
//                 ],
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // 🎮 Games Grid (6 games)
//   Expanded(
//   child: Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 20),
//     child: GridView.count(
//       crossAxisCount: 2,
//       mainAxisSpacing: 20,
//       crossAxisSpacing: 20,
//       childAspectRatio: 0.75, // better for image + title
//       children: [
//         _gameCard(
//           title: "Guss The Word",
//           imagePath: "assets/images/guessWord.png",
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => GuessTemplate()),
//             );
//           },
//         ),
//         _gameCard(
//           title: "Grid Words",
//           imagePath: "assets/images/grid.png",
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => GridWordTemplate()),
//             );
//           },
//         ),
//         _gameCard(
//           title: "Miss Letters ",
//           imagePath: "assets/images/missLetter.png",
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => MissLetterTemplate()),
//             );
//           },
//         ),
 
//            _gameCard(
//           title: "Snake Game",
//           imagePath: "assets/images/memory.png",
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => MemoryTemplate()),
//             );
//           },
//         ),
//       ],
//     ),
//   ),
// ),
//         ],
//       ),
//     );
//   }
// }




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

        // Transparent bubble body
        color: Colors.white.withOpacity(0.05),

        // Soft white border
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),

        // Glow effect
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

    path.lineTo(0, size.height - 10); // left edge DOWN

    path.quadraticBezierTo(
      size.width * 0.5,
      size.height - 50, // middle UP
      size.width,
      size.height - 10, // right edge DOWN
    );

    path.lineTo(size.width, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}



Widget _gameButton({
  required String title,
  String? imagePath,
  Color? color,
  required VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(30),
    child: Container(
      decoration: BoxDecoration(
        color: color ?? Colors.blue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blue).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🖼️ Image (if provided)
          (imagePath != null
              ? 
       Image.asset(imagePath, width: 60, height: 60)
                  : const SizedBox()),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _gameCard({
  required String title,
  required String imagePath,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🖼️ Game Image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 📝 Game Title
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Games",
      child: ageGroup == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🌈 Header
                ClipPath(
                  clipper: SoftWaveClipper(),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.bgBlushRoseVeryDark,
                          AppColors.bgBlushRoseDark,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Stack(
                      children: const [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Let’s Design Games 🎨🎮",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Create fun games for kids 🌟",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // bubbles
                        Positioned(top: 20, left: 30, child: _Bubble(size: 40)),
                        Positioned(top: 50, right: 40, child: _Bubble(size: 15)),
                        Positioned(bottom: 30, left: 70, child: _Bubble(size: 35)),
                        Positioned(bottom: 20, right: 10, child: _Bubble(size: 85)),
                      ],
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
                          if (ageGroup == '9-12')...[
                        _gameCard(
                          title: "Guess The Word",
                          imagePath: "assets/images/guessWord.png",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GuessTemplate()),
                            );
                          },
                        ),
                        _gameCard(
                          title: "Grid Words",
                          imagePath: "assets/images/grid.png",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => GridWordTemplate()),
                            );
                          },
                        ),
                        _gameCard(
                          title: "Miss Letters",
                          imagePath: "assets/images/missLetter.png",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MissLetterTemplate()),
                            );
                          },
                        ), ],

                        // ✅ Memory Game only for ageGroup 5-8
                        if (ageGroup == '5-8')
                          _gameCard(
                            title: "Memory Game",
                            imagePath: "assets/images/memory.png",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => MemoryTemplate()),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
