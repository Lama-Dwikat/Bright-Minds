

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
    if (kIsWeb) return "http://192.168.1.63:3000";
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

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Games",
       child: Container(
      color: const Color.fromARGB(255, 249, 226, 250), 
      child: loading
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

                // -------------------------
                // Game Image
                // -------------------------
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
                   imagePath="assets/images/clock.png";
                  case 'Ruler':
                   imagePath="assets/images/ruler.png";
                  case 'Memory':
                   imagePath="assets/images/memory.png";
                  default:
                    imagePath = "assets/images/Games2.png";
                }

                final rotation = index.isEven ? -0.04 : 0.04;

                return Transform.rotate(
                  angle: rotation,
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(28),
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
           

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

                      child: Stack(
                        children: [
                          ClipPath(
                            clipper: WavyClipper(),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.primaries[
                                            index %
                                                Colors.primaries.length]
                                        .shade400,
                                    Colors.primaries[
                                            (index + 3) %
                                                Colors.primaries.length]
                                        .shade200,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      imagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    game['name'] ?? "No Title",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 4,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

       
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
       ),
    );
  }
}

// -------------------------
// Wavy Card Shape
// -------------------------
class WavyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.1);
    path.quadraticBezierTo(w * 0.2, 0, w * 0.5, h * 0.05);
    path.quadraticBezierTo(w * 0.8, h * 0.1, w, 0);
    path.lineTo(w, h);
    path.quadraticBezierTo(w * 0.8, h * 0.95, w * 0.5, h);
    path.quadraticBezierTo(w * 0.2, h * 0.95, 0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
        