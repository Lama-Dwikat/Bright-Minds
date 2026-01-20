
import 'package:bright_minds/screens/games/gameKids.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';

class MemoryPlayScreen extends StatefulWidget {
  const MemoryPlayScreen({super.key});

  @override
  State<MemoryPlayScreen> createState() => _MemoryPlayScreenState();
}

class _MemoryPlayScreenState extends State<MemoryPlayScreen> {
  int currentLevel = 0;
  int score = 0;
  int trialsLeft = 0;
  int timeLeft = 0; // Timer in seconds
  Timer? levelTimer;
  bool hasStarted=false;

  List<String> colorsToMatch = [];
  List<bool> revealed = [];
  List<bool> matched = [];
  int? firstSelectedIndex;
  int? secondSelectedIndex;

  String userId = "";
  bool isLoading = true;
  Map<String, dynamic>? gameData;
  final String gameName = "Memory Cards";

  Random random = Random();

  @override
  void initState() {
    super.initState();
    _initGame();
  }

 Future<void> _initGame() async {
  await getUserId();
  await loadGame();

  if (gameData != null) {
    trialsLeft = gameData?['maxTrials'] ?? 3; // ✅ set ONCE
    _startLevel();
  }
}

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    if (token.isNotEmpty) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      setState(() {
        userId = decodedToken['id'];
      });
    }
  }

  Future<void> loadGame() async {
    try {
      final encodedName = Uri.encodeComponent(gameName);
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/game/getGameByName/$encodedName'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          setState(() {
            gameData = data[0];
            isLoading = false;
          });
          print("Game data loaded: $gameData");
        } else {
          setState(() => isLoading = false);
          debugPrint("Game not found or empty response");
        }
      } else {
        setState(() => isLoading = false);
        debugPrint("Failed to load game. Status code: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error loading game: $e");
    }
  }

  void _startLevel() {
    if (gameData == null || gameData!['input'] == null) return;

    final levelData = gameData!['input'][currentLevel];
    List<String> originalColors = List<String>.from(levelData['correctAnswer'] ?? []);

    // Create pairs of colors
    colorsToMatch = [];
    for (var color in originalColors) {
      colorsToMatch.add(color);
      colorsToMatch.add(color);
    }
    colorsToMatch.shuffle();

    revealed = List.generate(colorsToMatch.length, (_) => true);
    matched = List.generate(colorsToMatch.length, (_) => false);
    firstSelectedIndex = null;
    secondSelectedIndex = null;

    //trialsLeft = gameData?['maxTrials'] ?? 3;
    timeLeft = (gameData?['timePerQuestionMin'] ?? 1) * 60;

    setState(() {});

    // Hide cards after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        revealed = List.generate(colorsToMatch.length, (_) => false);
      });
      _startTimer();
    });
  }

  void _startTimer() {
    levelTimer?.cancel();
    levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
          _levelFailed();
        }
      });
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> saveScore(String gameId, String userId, num score,
      {bool complete = false}) async {
    final url = Uri.parse('${getBackendUrl()}/api/game/saveUserScore');
    await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "gameId": gameId,
          "userId": userId,
          "score": score,
          "complete": complete,
        }));
  }

    void _levelFailed() {
      if (trialsLeft > 1) {
     trialsLeft--;
      _startLevel();
     } else {
       _gameOver();
     }
     }


  void _gameOver() async {
    levelTimer?.cancel();
    if (userId.isNotEmpty && gameData != null) {
      await saveScore(gameData!['_id'], userId, score, complete: false);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("🎮 Game Over"),
        content: Text("Final Score: $score"),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => gamesKidScreen()),
              );
            },
            child: const Text("Home"),
          ),
        ],
      ),
    );
  }

  void _showGameCompleteDialog() async {
    levelTimer?.cancel();
    if (userId.isNotEmpty && gameData != null) {
      await saveScore(gameData!['_id'], userId, score, complete: true);
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 245, 233, 126),
        title: const Text("🏆 Game Complete!", textAlign: TextAlign.center),
        content: Text(
          "Final Score: $score",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => gamesKidScreen()),
            ),
            child: const Text("Home"),
          )
        ],
      ),
    );
  }

  void _cardTapped(int index) {
    if (revealed[index] || matched[index]) return;

    setState(() {
      revealed[index] = true;

      if (firstSelectedIndex == null) {
        firstSelectedIndex = index;
      } else if (secondSelectedIndex == null) {
        secondSelectedIndex = index;

        if (colorsToMatch[firstSelectedIndex!] ==
            colorsToMatch[secondSelectedIndex!]) {
          matched[firstSelectedIndex!] = true;
          matched[secondSelectedIndex!] = true;
          _resetSelection();

          if (matched.every((m) => m)) {
            // Add score per level (not per card)
            score += (gameData?['scorePerQuestion'] ?? 5) as int;

            levelTimer?.cancel();

            if (currentLevel + 1 < (gameData?['input']?.length ?? 0)) {
              _nextLevel();
            } else {
              _showGameCompleteDialog();
            }
          }
        } else {
          Future.delayed(const Duration(seconds: 1), () {
            setState(() {
              revealed[firstSelectedIndex!] = false;
              revealed[secondSelectedIndex!] = false;
              _resetSelection();
            });
          });
        }
      }
    });
  }

  void _resetSelection() {
    firstSelectedIndex = null;
    secondSelectedIndex = null;
  }

  void _nextLevel() {
    currentLevel++;
    _startLevel();
  }

  Color _getColor(String name) {
    switch (name.toLowerCase()) {
      case "red":
        return Colors.red;
      case "green":
        return Colors.green;
      case "blue":
        return Colors.blue;
      case "yellow":
        return Colors.yellow;
      case "orange":
        return Colors.orange;
      case "purple":
        return Colors.purple;
      case "pink":
        return Colors.pink;
      case "cyan":
        return Colors.cyan;
      case "brown":
        return Colors.brown;
      case "gray":
        return Colors.grey;
      case "black":
        return Colors.black;
      case "white":
        return Colors.white;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    levelTimer?.cancel();
    super.dispose();
  }





 void _startGame() {
    setState(() => hasStarted = true);
   loadGame();
    _startTimer();
  }

@override
Widget build(BuildContext context) {
  if (isLoading || gameData == null) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
   if (!hasStarted) {
      
  return Scaffold(

    body:Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/memoryBg.png',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.90),
          ),
        ),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Memoty Cards Game",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8),
                  ],
                ),
                child: Text(
                  "🎯 You have ${gameData?['maxTrials'] ?? 3} tries",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  elevation: 10,
                ),
                child: const Text(
                  "▶ PLAY",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    ),
  
);

    }


    if (!kIsWeb) {

  return Scaffold(
    body: Stack(
      children: [
        // Background image
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/memoryBg.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Main content
        Column(
          children: [
   SizedBox(height:20),      
Container(
  width: double.infinity,
  height:90,
  padding: const EdgeInsets.symmetric(vertical: 16),
  color: Colors.blue.withOpacity(0.5), // semi-transparent blue
  alignment: Alignment.center,
  child: Text(
    "Level ${currentLevel + 1}",
    style: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Colors.white, // white text on blue
      shadows: [
        Shadow(color: Colors.black45, blurRadius: 3),
      ],
    ),
  ),
),


            const SizedBox(height: 40),

            // Clouds for Score, Trials, Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CloudWidget(
                    icon: Icons.star,
                    label: "SCORE",
                    value: score.toString()),
                CloudWidget(
                    icon: Icons.favorite,
                    label: "TRIALS",
                    value: trialsLeft.toString()),
                CloudWidget(
                    icon: Icons.timer,
                    label: "TIME",
                    value: _formatTime(timeLeft)),
              ],
            ),

            const SizedBox(height: 30),

       Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      // Estimate grid height
      final crossAxisCount = min(4, colorsToMatch.length);
      final spacing = 12.0;
      final itemWidth = (constraints.maxWidth - 40 - spacing * (crossAxisCount - 1)) / crossAxisCount;
      final rowCount = (colorsToMatch.length / crossAxisCount).ceil();
      final itemHeight = itemWidth; // square cards
      final gridHeight = rowCount * itemHeight + (rowCount - 1) * spacing;

      final shouldScroll = gridHeight > constraints.maxHeight;

      Widget grid = GridView.builder(
        physics: shouldScroll
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: colorsToMatch.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: 1,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _cardTapped(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: revealed[index] || matched[index]
                    ? _getColor(colorsToMatch[index])
                    : const Color(0xFF9AD0EC),
                gradient: revealed[index] || matched[index]
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF9AD0EC),
                          Color(0xFFB4E4FF),
                        ],
                      ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: revealed[index] || matched[index]
                    ? Container(
                        width: 55,
                        height: 55,
                        decoration: BoxDecoration(
                          color: _getColor(colorsToMatch[index]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      )
                    : const Text(
                        "?",
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
              ),
            ),
          );
        },
      );

      // Center grid if small, scroll if large
      if (shouldScroll) {
        return SingleChildScrollView(child: grid);
      } else {
        return Center(child: grid);
      }
    },
  ),
),


            // Home button at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _roundButton(
                icon: Icons.home,
                label: "HOME",
                color: Colors.blue,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => gamesKidScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
    }

  else {

 return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/memoryBg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Header with home, score, time
          _webHeader(context),

          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.6,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0),
              //  borderRadius: BorderRadius.circular(36),
               // border: Border.all(
               //   color: Colors.blueAccent.withOpacity(0.8),
                //  width: 3,
             //   ),
              //  boxShadow: const [
               //   BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
               // ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clouds row: Score, Trials, Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CloudWidget(icon: Icons.star, label: "SCORE", value: score.toString()),
                      CloudWidget(icon: Icons.favorite, label: "TRIALS", value: trialsLeft.toString()),
                      CloudWidget(icon: Icons.timer, label: "TIME", value: _formatTime(timeLeft)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Memory card grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = min(4, colorsToMatch.length);
                      final spacing = 12.0;
                      final itemWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                      final rowCount = (colorsToMatch.length / crossAxisCount).ceil();
                      final itemHeight = itemWidth;
                      final gridHeight = rowCount * itemHeight + (rowCount - 1) * spacing;

                      final shouldScroll = gridHeight > constraints.maxHeight;

                      Widget grid = GridView.builder(
                        physics: shouldScroll
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: colorsToMatch.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing,
                          crossAxisSpacing: spacing,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _cardTapped(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: revealed[index] || matched[index]
                                    ? _getColor(colorsToMatch[index])
                                    : const Color(0xFF9AD0EC),
                                gradient: revealed[index] || matched[index]
                                    ? null
                                    : const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF9AD0EC),
                                          Color(0xFFB4E4FF),
                                        ],
                                      ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: revealed[index] || matched[index]
                                    ? Container(
                                        width: 55,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: _getColor(colorsToMatch[index]),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      )
                                    : const Text(
                                        "?",
                                        style: TextStyle(
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(color: Colors.black45, blurRadius: 4),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          );
                        },
                      );

                      return shouldScroll ? SingleChildScrollView(child: grid) : Center(child: grid);
                    },
                  ),

                  const SizedBox(height: 30),

                  // Home button
                  _roundButton(
                    icon: Icons.home,
                    label: "HOME",
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => gamesKidScreen()),
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



Widget _webHeader(BuildContext context) {
  return Container(
    height: 70,
    padding: const EdgeInsets.symmetric(horizontal: 40),
    color: Colors.blue.withOpacity(0.6),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.home, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => gamesKidScreen()),
            );
          },
        ),

        Expanded(
          child: Center(
            child: Text(
              "Level ${currentLevel + 1}",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

     
      ],
    ),
  );
}
}

Widget _roundButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, color: Colors.white),
    label: Text(label),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 6,
    ),
  );
}
class CloudWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const CloudWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CloudPainter(),
      child: Container(
        width: 140,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.orange, size: 24),
            const SizedBox(width: 6),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4); // soft edges

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Draw cloud using circles
    path.addOval(Rect.fromCircle(center: Offset(w * 0.2, h * 0.5), radius: h * 0.4));
    path.addOval(Rect.fromCircle(center: Offset(w * 0.5, h * 0.3), radius: h * 0.5));
    path.addOval(Rect.fromCircle(center: Offset(w * 0.8, h * 0.5), radius: h * 0.4));

    canvas.drawPath(path, paint);

    // Optional: Add subtle shadow
    final shadowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path.shift(const Offset(2, 2)), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
