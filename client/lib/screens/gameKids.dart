

import 'package:bright_minds/screens/games/GridWordPlay.dart';
import 'package:bright_minds/screens/games/ruler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/widgets/home.dart';
import 'dart:async';
import 'package:bright_minds/screens/games/clock.dart';
import 'package:bright_minds/screens/games/GuessWordPlay.dart';
import 'package:bright_minds/screens/games/Snake.dart';
import 'package:bright_minds/screens/games/MissLetterPlay.dart';
import 'package:bright_minds/screens/games/MemoryCardPlay.dart';



class gamesKidScreen extends StatefulWidget {
  const gamesKidScreen({super.key});

  @override
  State<gamesKidScreen> createState() => _gamesKidState();
}

class _gamesKidState extends State<gamesKidScreen> {
  List<dynamic> allGames = [];
  bool loading = true;
  String userId = "";
  String ageGroup = "";

  @override
  void initState() {
    super.initState();
    loadAllGames();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }




Timer? _gameTimer;
int _sessionSeconds = 0;

// Start a timer when a game starts
void _startGameTimer() {
  _sessionSeconds = 0;
  _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    _sessionSeconds++;
  });
}

// Stop timer and send elapsed minutes to backend
Future<void> _endGameTimerAndSave() async {
  _gameTimer?.cancel();
  final elapsedMinutes = _sessionSeconds / 60.0;

  final url = Uri.parse("${getBackendUrl()}/api/dailywatch/calculatePlay/$userId");
  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"minutes": elapsedMinutes}),
    );

    final data = jsonDecode(response.body);
    if (!data['allowed']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Daily game limit reached")),
      );
    }
  } catch (e) {
    debugPrint("❌ Error saving play time: $e");
  }
}

// Check if user can play before opening a game
Future<bool> _canPlay() async {
  final url = Uri.parse("${getBackendUrl()}/api/dailywatch/canPlay/$userId");
  try {
    final response = await http.get(url);
    final data = jsonDecode(response.body);
    return data['allowed'] ?? false;
  } catch (e) {
    debugPrint("❌ Error checking play permission: $e");
    return false;
  }
}

Future<void> _openGame(Widget Function() gameScreenBuilder) async {
  // 1️⃣ Check if user can play
  bool allowed = await _canPlay();
  if (!allowed) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have reached the daily 40-minute game limit.")),
    );
    return; // stop here
  }

  // 2️⃣ Start counting time
  _startGameTimer();

  // 3️⃣ Open the game screen
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => gameScreenBuilder()),
  );

  // 4️⃣ Stop timer and save play time to backend
  await _endGameTimerAndSave();
}


  // -------------------------
  // Load Games
  // -------------------------
  Future<void> loadAllGames() async {
    setState(() => loading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null) return;

      final decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];
      ageGroup = decodedToken['ageGroup'];

      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/game/getGamesByAgeGroup/$ageGroup"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = List<dynamic>.from(jsonDecode(response.body));
        decoded.sort(
          (a, b) => DateTime.parse(b['createdAt'])
              .compareTo(DateTime.parse(a['createdAt'])),
        );

        setState(() => allGames = decoded);
      }
    } catch (e) {
      debugPrint("❌ Error loading games: $e");
    } finally {
      setState(() => loading = false);
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     return HomePage(
//       title: "Games",
//       child: 
//       Center(
//         child:Container(
//         color: const Color(0xFFFFF0F5),
//         child: Stack(
//           children: [
//             // 🎈 Playful background
//             Positioned(
//               top: -50,
//               left: -30,
//               child: _backgroundCircle(80, Colors.yellow.withOpacity(0.3)),
//             ),
//             Positioned(
//               bottom: 100,
//               right: -30,
//               child: _backgroundCircle(120, const Color.fromARGB(255, 231, 190, 66).withOpacity(0.2)),
//             ),
//             Positioned(
//               top: 150,
//               right: -20,
//               child: _backgroundCircle(60, const Color.fromARGB(255, 240, 232, 113).withOpacity(0.2)),
//             ),
//             // 🕹️ Grid of games
//              Positioned(
//               top: 150,
//               right: -20,
//               child: _backgroundCircle(60, const Color.fromARGB(255, 235, 128, 7).withOpacity(0.2)),
//             ),
//               Positioned(
//               bottom: 150,
//               left: -20,
//               child: _backgroundCircle(60, const Color.fromARGB(255, 123, 83, 38).withOpacity(0.2)),
//             ),
//                Positioned(
//               bottom: -30,
//               left: 130,
//               child: _backgroundCircle(120, const Color.fromARGB(255, 225, 129, 20).withOpacity(0.2)),
//             ),
//             loading
//                 ? const Center(child: CircularProgressIndicator())
//                 : GridView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: allGames.length,
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 2,
//                       mainAxisSpacing: 20,
//                       crossAxisSpacing: 20,
//                       childAspectRatio: 3 / 4,
//                     ),
//                     itemBuilder: (context, index) {
//                       final game = allGames[index];

//                       // Determine game image
//                       String imagePath;
//                       switch (game['type']) {
//                         case 'Guessing':
//                           imagePath = "assets/images/guessWord.png";
//                           break;
//                         case 'Grid':
//                           imagePath = "assets/images/grid.png";
//                           break;
//                         case 'MissLetters':
//                           imagePath = "assets/images/missLetter.png";
//                           break;
//                         case 'Snake':
//                           imagePath = "assets/images/snake.png";
//                           break;
//                         case 'Clock':
//                           imagePath = "assets/images/clock.png";
//                           break;
//                         case 'Ruler':
//                           imagePath = "assets/images/ruler.png";
//                           break;
//                         case 'Memory':
//                           imagePath = "assets/images/memory.png";
//                           break;
//                         default:
//                           imagePath = "assets/images/Games2.png";
//                       }

//                       return _gameCard(
//                         title: game['name'] ?? "Game",
//                         imagePath: imagePath,
//                         onTap: () {
//                           switch (game['type']) {
//                             case 'Guessing':
//                               _openGame(() => GuessGameScreen());
//                               break;
//                             case 'Snake':
//                               _openGame(() => const SnakeGameScreen());
//                               break;
//                             case 'Grid':
//                               _openGame(() => GridGameScreen());
//                               break;
//                             case 'MissLetters':
//                               _openGame(() => MissLetterScreen());
//                               break;
//                             case 'Clock':
//                               _openGame(() => ClockGameScreen());
//                               break;
//                             case 'Ruler':
//                               _openGame(() => RulerGameScreen());
//                               break;
//                             case 'Memory':
//                               _openGame(() => MemoryPlayScreen());
//                               break;
//                             default:
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(content: Text("Game not available yet")),
//                               );
//                           }
//                         },
//                       );
//                     },
//                   ),
//           ],
//         ),
//       ),
//       ),
//     );
//   }

//   // 🔹 Game card widget
//   Widget _gameCard({
//     required String title,
//     required String imagePath,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(26),
//       onTap: onTap,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(26),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.06),
//               blurRadius: 14,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Image.asset(
//                   imagePath,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               decoration: BoxDecoration(
//                 color: const Color.fromARGB(255, 246, 231, 215),
//                 borderRadius: const BorderRadius.vertical(
//                   bottom: Radius.circular(26),
//                 ),
//               ),
//               child: Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.brown,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🔹 Playful background circle
//   Widget _backgroundCircle(double size, Color color) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: color,
//         shape: BoxShape.circle,
//       ),
//     );
//   }
// }

 // -------------------- MOBILE BODY --------------------
  Widget _buildMobileBody() {
    return Center(
      child: Container(
        color: const Color(0xFFFFF0F5),
        child: Stack(
          children: [
            // 🎈 Background Circles
            Positioned(top: -50, left: -30, child: _backgroundCircle(80, Colors.yellow.withOpacity(0.3))),
            Positioned(bottom: 100, right: -30, child: _backgroundCircle(120, const Color.fromARGB(255, 231, 190, 66).withOpacity(0.2))),
            Positioned(top: 150, right: -20, child: _backgroundCircle(60, const Color.fromARGB(255, 240, 232, 113).withOpacity(0.2))),
            Positioned(top: 150, right: -20, child: _backgroundCircle(60, const Color.fromARGB(255, 235, 128, 7).withOpacity(0.2))),
            Positioned(bottom: 150, left: -20, child: _backgroundCircle(60, const Color.fromARGB(255, 123, 83, 38).withOpacity(0.2))),
            Positioned(bottom: -30, left: 130, child: _backgroundCircle(120, const Color.fromARGB(255, 225, 129, 20).withOpacity(0.2))),
            // Grid of games
            loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allGames.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 20,
                      childAspectRatio: 3 / 4,
                    ),
                    itemBuilder: (context, index) {
                      final game = allGames[index];
                      String imagePath;
                      switch (game['type']) {
                        case 'Guessing':
                          imagePath = "assets/images/guessWord.png";
                          break;
                        case 'Grid':
                          imagePath = "assets/images/grid.png";
                          break;
                        case 'MissLetters':
                          imagePath = "assets/images/missLetter.png";
                          break;
                        case 'Snake':
                          imagePath = "assets/images/snake.png";
                          break;
                        case 'Clock':
                          imagePath = "assets/images/clock.png";
                          break;
                        case 'Ruler':
                          imagePath = "assets/images/ruler.png";
                          break;
                        case 'Memory':
                          imagePath = "assets/images/memory.png";
                          break;
                        default:
                          imagePath = "assets/images/Games2.png";
                      }
                      return _gameCard(
                        title: game['name'] ?? "Game",
                        imagePath: imagePath,
                        onTap: () {
                          switch (game['type']) {
                            case 'Guessing':
                              _openGame(() => GuessGameScreen());
                              break;
                            case 'Snake':
                              _openGame(() => const SnakeGameScreen());
                              break;
                            case 'Grid':
                              _openGame(() => GridGameScreen());
                              break;
                            case 'MissLetters':
                              _openGame(() => MissLetterScreen());
                              break;
                            case 'Clock':
                              _openGame(() => ClockGameScreen());
                              break;
                            case 'Ruler':
                              _openGame(() => RulerGameScreen());
                              break;
                            case 'Memory':
                              _openGame(() => MemoryPlayScreen());
                              break;
                            default:
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Game not available yet")),
                              );
                          }
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // -------------------- WEB BODY --------------------
  Widget _buildWebBody() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel for info
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(16)),
                  child: const Text(
                    "Welcome to the Games Section. Are you Ready To Start New Adventure?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(16)),
                  child: const Text("Select a game from the right panel", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
        // Right panel for games
   Expanded(
  flex: 5,
  child: Container(
    color: const Color(0xFFFFF0F5),
    padding: const EdgeInsets.all(24),
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              // Calculate item height for better fit
              double itemWidth = (constraints.maxWidth - 40) / 2; // 2 items per row, 20px spacing
              double itemHeight = itemWidth * 0.8; // Adjust ratio to 1.2 for compactness

              return GridView.builder(
                itemCount: allGames.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemBuilder: (context, index) {
                  final game = allGames[index];
                  String imagePath;
                  switch (game['type']) {
                    case 'Guessing':
                      imagePath = "assets/images/guessWord.png";
                      break;
                    case 'Grid':
                      imagePath = "assets/images/grid.png";
                      break;
                    case 'MissLetters':
                      imagePath = "assets/images/missLetter.png";
                      break;
                    case 'Snake':
                      imagePath = "assets/images/snake.png";
                      break;
                    case 'Clock':
                      imagePath = "assets/images/clock.png";
                      break;
                    case 'Ruler':
                      imagePath = "assets/images/ruler.png";
                      break;
                    case 'Memory':
                      imagePath = "assets/images/memory.png";
                      break;
                    default:
                      imagePath = "assets/images/Games2.png";
                  }
                  return _gameCard(
                    title: game['name'] ?? "Game",
                    imagePath: imagePath,
                    onTap: () {
                      switch (game['type']) {
                        case 'Guessing':
                          _openGame(() => GuessGameScreen());
                          break;
                        case 'Snake':
                          _openGame(() => const SnakeGameScreen());
                          break;
                        case 'Grid':
                          _openGame(() => GridGameScreen());
                          break;
                        case 'MissLetters':
                          _openGame(() => MissLetterScreen());
                          break;
                        case 'Clock':
                          _openGame(() => ClockGameScreen());
                          break;
                        case 'Ruler':
                          _openGame(() => RulerGameScreen());
                          break;
                        case 'Memory':
                          _openGame(() => MemoryPlayScreen());
                          break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Game not available yet")),
                          );
                      }
                    },
                  );
                },
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
    bool isWebLayout = kIsWeb || MediaQuery.of(context).size.width > 800;
    return HomePage(title: "Games", child: isWebLayout ? _buildWebBody() : _buildMobileBody());
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
              child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.brown)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backgroundCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}