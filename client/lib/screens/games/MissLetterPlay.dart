


import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/screens/gameKids.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class MissLetterScreen extends StatefulWidget {
  final int initialLevel;
  final bool hasStarted;
  const MissLetterScreen({super.key, this.initialLevel = 1, this.hasStarted = false});
  @override
  State<MissLetterScreen> createState() => _MissLetterScreenState();
}

class _MissLetterScreenState extends State<MissLetterScreen>
    with SingleTickerProviderStateMixin {
  String? userId = "";
  final String gameName = "Miss Letters";

  Map<String, dynamic>? gameData;
  int currentQuestionIndex = 0;
  int currentLevel = 1;
  final int totalLevels = 3;

  int totalTrialsUsed = 0;
  bool isLoading = true;

  Timer? _timer;
  int remainingTime = 0;

num score = 0;
String get scoreKey => "${gameName}_totalScore";

  // 🔴 NEW: Miss Letters state
  late List<String?> userLetters;
  late List<String> lettersClue;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String theme = " ";
  

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    setState(() {
      userId = decodedToken['id'];
    });
  }

Future<void> loadScore() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setState(() {
    score = prefs.getInt(scoreKey) ?? 0;
  });
}

Future<void> saveLocalScore(num score) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt(scoreKey, score.toInt());
}


@override
void initState() {
  super.initState();

  currentLevel = widget.initialLevel; 

    loadScore(); 

  loadGame().then((_) {
    if (gameData != null) {
      // Find the first question of the current level
      currentQuestionIndex = gameData!['input']
          .indexWhere((q) => q['level'] == currentLevel);
      initMissLettersQuestion();
    }
  });

  getUserId();

  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  _fadeAnimation =
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
}



  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
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
          gameData = data[0];
          theme = gameData!['theme'] ?? " ";
        }
      }
    } catch (e) {
      debugPrint("Error loading game: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 🔴 NEW: Initialize question for Miss Letters
  void initMissLettersQuestion() {
    final question = gameData!['input'][currentQuestionIndex];
    final text = List<String>.from(question['text']);
    userLetters = List.generate(
      text.length,
      (i) => text[i] == "-" ? null : text[i],
    );
    lettersClue = List<String>.from(question['lettersClue']);
  }

  void _startTimer() {
    _timer?.cancel();
    remainingTime = ((gameData!['timePerQuestionMin'] ?? 1) * 60).toInt();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        timer.cancel();
        _onTimeOut();
      }
    });
  }

  void _onTimeOut() {
    totalTrialsUsed++;
    if (totalTrialsUsed >= (gameData!['maxTrials'] ?? 3)) {
      _gameOver();
    } else {
      _startTimer();
    }
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString()}:${s.toString().padLeft(2, '0')}";
  }

  // 🔴 NEW: When player taps a letter
  void onLetterTap(String letter) {
    setState(() {
      for (int i = 0; i < userLetters.length; i++) {
        if (userLetters[i] == null) {
          userLetters[i] = letter;
          break;
        }
      }
    });

    if (!userLetters.contains(null)) {
      checkMissLettersAnswer();
    }
  }

  // 🔴 NEW: Check Miss Letters Answer
  void checkMissLettersAnswer() {
    final correct =
        List<String?>.from(gameData!['input'][currentQuestionIndex]['correctAnswer']);

    bool isCorrect = true;
    for (int i = 0; i < correct.length; i++) {
      if (correct[i] != null && correct[i] != userLetters[i]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      score += gameData!['scorePerQuestion'];
        saveLocalScore(score);
       Future.delayed(const Duration(seconds: 1), () {
      nextQuestion();
    });

    } 
    else {
      totalTrialsUsed++;
      if (totalTrialsUsed >= (gameData!['maxTrials'] ?? 3)) {
        _gameOver();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Wrong letters")),
        );
      }
    }
  }

  Future<void> resetGameProgress() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt(scoreKey, 0);
  await prefs.setStringList("${gameName}_unlockedLevels", ["1"]);
}


  void nextQuestion() {
    _timer?.cancel();

    if (currentQuestionIndex + 1 < gameData!['input'].length) {
      final nextIndex = currentQuestionIndex + 1;

      int currentQuestionLevel =
          gameData!['input'][currentQuestionIndex]['level'];
      int nextQuestionLevel = gameData!['input'][nextIndex]['level'];

      if (nextQuestionLevel > currentQuestionLevel) {
        // Level completed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLevelCompleteDialog();
        });
      } else {
        setState(() {
          currentQuestionIndex = nextIndex;
          initMissLettersQuestion();
          _startTimer();
        });
      }
    } else {
      _showGameCompleteDialog();
    }
  }

  void _showLevelCompleteDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 245, 233, 126),
          title: const Text("👏 Congratulations!"),
          content: Text("You passed level $currentLevel\nScore: $score"),
          actions: [
            ElevatedButton(
              onPressed: () {
          //      Navigator.pop(context);


    Navigator.pop(context);      // close dialog
    Navigator.pop(context, true); // ✅ return success to LevelSelection
  },
  child: const Text("Back to Levels"),

            )
          ],
        ),
      );
    });
  }



  void _showGameCompleteDialog() async {
    _timer?.cancel();

    if (userId != null && gameData != null && userId!.isNotEmpty) {
      await saveScore(gameData!['_id'], userId!, score, complete: true);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 126, 199, 245),
        title: const Text(
          "🏆 You are a Champion!",
          textAlign: TextAlign.center,
        ),
        content: Text(
          "Congratulations! You finished the game.\nFinal Score: $score",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => gamesKidScreen()),
                (_) => false,
              );
            },
            child: const Text("Home"),
          )
        ],
      ),
    );
  }

  void _gameOver() async {
    _timer?.cancel();

    if (userId != null && gameData != null) {
      await saveScore(gameData!['_id'], userId!, score, complete: false);
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => gamesKidScreen()),
                (_) => false,
              );
            },
            child: const Text("Home"),
          )
        ],
      ),
    );
  }

  Future<void> saveScore(String gameId, String userId, num score,
      {bool complete = false}) async {
    final url = Uri.parse('${getBackendUrl()}/api/game/saveUserScore');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "gameId": gameId,
        "userId": userId,
        "score": score,
        "complete": complete,
      }),
    );

    if (response.statusCode == 200) {
      print("Score saved!");
    } else {
      print("Failed to save score: ${response.body}");
    }
  }

  // 🔴 NEW: Build letter slots
Widget buildWordSlots() {
  return Center(
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 8, // horizontal space between slots
      runSpacing: 8, // vertical space between lines
      children: List.generate(userLetters.length, (index) {
        return DragTarget<String>(
          onWillAccept: (data) => true,
          onAccept: (data) {
            setState(() {
              userLetters[index] = data; // place letter
              lettersClue.remove(data);   // remove from pool
            });
            if (!userLetters.contains(null)) {
              checkMissLettersAnswer(); // check if word is complete
            }
          },
          builder: (context, candidateData, rejectedData) {
            Color slotColor;

            if (userLetters[index] != null) {
              slotColor = Colors.green.shade200; // filled slot
            } else if (candidateData.isNotEmpty) {
              slotColor = Colors.yellow.shade200; // dragging over
            } else {
              slotColor = Colors.white; // empty
            }

            return Container(
              // width: 55,
              // height: 65,
              width: 70,
              height: 70,
              alignment: Alignment.center,
          
            decoration: bubbleDecoration(
            borderColor: userLetters[index] != null
              ? Colors.blue
                : Colors.white,
                  ),


              child: Text(
                userLetters[index] ?? "",
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      }),
    ),
  );
}




  // 🔴 NEW: Build letters clue buttons
Widget buildLetterChoices() {
  return Wrap(
    spacing: 14,
    runSpacing: 14,
    alignment: WrapAlignment.center,
    children: lettersClue.map((letter) {
      return Draggable<String>(
        data: letter,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            // width: 60,
            // height: 60,
            width: 56,
            height: 65,

            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.orange.shade400,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),



            child: Text(
              letter.toUpperCase(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        childWhenDragging: Container(
          width: 65,
          height: 65,
          alignment: Alignment.center,

      
          decoration: bubbleDecoration(
  borderColor: Colors.grey,
),

          child: const SizedBox.shrink(),
        ),
        child: Container(
          width: 65,
          height: 65,
          alignment: Alignment.center,
       decoration: BoxDecoration(
  color: const Color.fromARGB(255, 234, 227, 215),
  shape: BoxShape.circle,
  boxShadow: const [
    BoxShadow(color: Colors.black26, blurRadius: 4),
  ],
),
         
          child: Text(
            letter.toUpperCase(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList(),
  );
}

List<Widget> _buildFriendlyBackgroundIcons() {
  final icons = [
    Icons.pets, Icons.emoji_nature, Icons.eco,        // Animals / nature
    Icons.apple, Icons.local_pizza, Icons.icecream,  // Fruits / food
    Icons.chair, Icons.bed, Icons.table_bar,         // Furniture
    Icons.sports_esports, Icons.toys, Icons.casino, // Games / toys
    Icons.restaurant, Icons.local_dining,           // Vegetables / dining
  ];

  final colors = [
    Colors.red.shade400,
    Colors.orange.shade400,
    Colors.yellow.shade400,
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.purple.shade400,
    Colors.pink.shade400,
  ];

  // Static positions spread across edges and corners
  final positions = [
    const Alignment(-0.9, -0.85), // top-left
    const Alignment(0.9, -0.85),  // top-right
    const Alignment(-0.9, 0.85),  // bottom-left
    const Alignment(0.9, 0.85),   // bottom-right
    const Alignment(-0.8, 0.0),   // left-middle
    const Alignment(0.8, 0.0),    // right-middle
    const Alignment(0.0, -0.8),   // top-middle
    const Alignment(0.0, 0.8),    // bottom-middle
    const Alignment(-0.6, -0.5),  // upper-left inner
    const Alignment(0.6, -0.5),   // upper-right inner
    const Alignment(-0.6, 0.5),   // lower-left inner
    const Alignment(0.6, 0.5),    // lower-right inner
    const Alignment(-0.3, -0.7),  // top-left smaller
    const Alignment(0.3, -0.7),   // top-right smaller
  ];

  return List.generate(positions.length, (i) {
    return Align(
      alignment: positions[i],
      child: Transform.rotate(
        angle: (i % 5) * 0.2, // slight playful rotation
        child: Icon(
          icons[i % icons.length],
          size: 50 + (i % 3) * 15.0, // variety in size
          color: colors[i % colors.length].withOpacity(0.7),
        ),
      ),
    );
  });
}




BoxDecoration bubbleDecoration({Color borderColor = Colors.white}) {
  return BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      center: const Alignment(-0.4, -0.4),
      radius: 0.9,
      colors: [
        Colors.white.withOpacity(0.35),
        Colors.white.withOpacity(0.15),
        Colors.transparent,
      ],
    ),
    border: Border.all(
      color: borderColor.withOpacity(0.6),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withOpacity(0.4),
        blurRadius: 10,
        spreadRadius: 1,
      ),
    ],
  );
}


  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return HomePage(
        title: gameName,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (gameData == null) {
      return HomePage(
        title: gameName,
        child: const Center(child: Text("Game not found")),
      );
    }

    final ThemeDesign design = getThemeDesign(theme);

    final question = gameData!['input'][currentQuestionIndex];
    final images = (question['image'] as List?) ?? [];


  if (!widget.hasStarted) {
return Scaffold(
  body: Stack(
    children: [
      // 1️⃣ Gradient background
      Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF89CFF0),
              Color(0xFFFFF1A8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      // 2️⃣ Friendly icons scattered
      ..._buildFriendlyBackgroundIcons(),

      // 3️⃣ Centered content with semi-transparent box
      Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7), // transparent box
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Miss Letters Game",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: Colors.deepPurple,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                "You have ${gameData?['maxTrials'] ?? 3} trials",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Are You Ready To Start?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  backgroundColor: Colors.blue.withOpacity(0.85),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: () async {
                  await resetGameProgress();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelSelectionScreen(
                        gameName: gameName,
                        totalLevels: totalLevels,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Play",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);

}



    // ✅ NEW GAME SCREEN (IMAGE-BASED DESIGN)
return Scaffold(
  body: Stack(
    children: [
      // 🌊 BACKGROUND IMAGE
Container(
  width: double.infinity,
  height: double.infinity,
  child: Image.asset(
    "assets/images/missLetters6.png",
    width: MediaQuery.of(context).size.width,
    height: MediaQuery.of(context).size.height,
    fit: BoxFit.cover,
  ),
),



      // 🏠 HOME BUTTON
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.85),
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.lightBlueAccent),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => gamesKidScreen()),
                  (_) => false,
                );
              },
            ),
          ),
        ),
      ),

      // 🫧 WORD LETTERS (TOP)
      Positioned(
        top: 370,
        left: 0,
        right: 0,
        child: buildWordSlots(),
      ),


      // 💬 "WHAT'S MISSING?" (chat bubble shape)

Positioned(
  bottom:400, // adjust vertical position
  right: 70, // adjust horizontal
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      // Bubble
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6),
          ],
        ),
        child: const Text(
          "What’s missing?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Tail (bottom-left)
      Positioned(
        bottom: -15, // tail below bubble
        left: 20, // move tail to left
        child: CustomPaint(
          size: const Size(20, 15), // width, height of tail
          painter: TailPainter(color: Colors.white.withOpacity(0.85)),
        ),
      ),
    ],
  ),
),




      // 🫧 LETTER CHOICES (BOTTOM)
      Positioned(
        bottom: 70,
        left: 0,
        right: 0,
        child: buildLetterChoices(),
      ),

      // ⭐ SCORE + ⏱ TIMER
      Positioned(
        top: 80,
        left: 0,
        right: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "⭐ $score",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 20),
            Text(
              "⏱ ${formatTime(remainingTime)}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);

  }
}

/* ===================== THEME ===================== */
class ThemeDesign {
  final IconData icon;
  final String emoji;
  final String bgImage;

  const ThemeDesign({
    required this.icon,
    required this.emoji,
    required this.bgImage,
  });
}

ThemeDesign getThemeDesign(String theme) {
  switch (theme) {
    case "Animals":
      return ThemeDesign(
        icon: Icons.pets,
        emoji: "🐾",
        bgImage: "assets/images/missAnimal.png",
      );
    default:
      return ThemeDesign(
        icon: Icons.games,
        emoji: "🎮",
        bgImage: "assets/images/game_bg.jpg",
      );
  }
}


///////////////////////////////////////////////////////////////////////////
class TailPainter extends CustomPainter {
  final Color color;
  TailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    // Draw triangle pointing DOWN (tip at bottom)
    path.moveTo(0, 0);           // top-left of triangle
    path.lineTo(size.width, 0);   // top-right of triangle
    path.lineTo(size.width / 2, size.height); // tip pointing down
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

///////////////////////////////////////////////////////////////////////////
class LevelSelectionScreen extends StatefulWidget {
  final String gameName;
  final int totalLevels;

  const LevelSelectionScreen({
    super.key,
    required this.gameName,
    required this.totalLevels,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  late List<bool> unlockedLevels;

  @override
  void initState() {
    super.initState();
    loadUnlockedLevels();
  }

Future<void> loadUnlockedLevels() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  final key = "${widget.gameName}_unlockedLevels";

  // 🔴 FORCE RESET TO LEVEL 1 ONLY
  List<String> unlocked = ["1"];
  await prefs.setStringList(key, unlocked);

  setState(() {
    unlockedLevels = List.generate(
      widget.totalLevels,
      (index) => unlocked.contains((index + 1).toString()),
    );
  });
}



  Future<void> unlockNextLevel(int level) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> unlocked =
        prefs.getStringList("${widget.gameName}_unlockedLevels") ?? ["1"];
    if (level + 1 <= widget.totalLevels &&
        !unlocked.contains((level + 1).toString())) {
      unlocked.add((level + 1).toString());
      await prefs.setStringList("${widget.gameName}_unlockedLevels", unlocked);
      setState(() {
        unlockedLevels[level] = true; // unlock next level
      });
    }
  }

  void startLevel(int level) async {
    final bool? completed = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MissLetterScreen(
        initialLevel: level,
        hasStarted: true,
      ),
    ),
  );

  if (completed == true) {
    await unlockNextLevel(level);
  }
   }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF89CFF0),
            Color(0xFFFFF1A8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 🏠 HOME BUTTON (top-left)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color.fromARGB(255, 243, 242, 190),
                  child: IconButton(
                    icon: const Icon(Icons.home, color: Colors.blue),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => gamesKidScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🌟 CENTERED TITLE
            const Text(
              "🌟 Choose Your Level",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 30),

            // 📜 CENTERED LEVEL LIST
            Expanded(
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85, // 👈 center column
                  child: ListView.builder(
                    itemCount: widget.totalLevels,
                    itemBuilder: (context, index) {
                      bool unlocked = unlockedLevels[index];
                      int level = index + 1;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: GestureDetector(
                          onTap: unlocked ? () => startLevel(level) : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 90,
                            decoration: BoxDecoration(
                              color: unlocked
                                  ? Colors.orangeAccent
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: unlocked
                                  ? [
                                      const BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 4),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 🔢 LEVEL NUMBER
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    "$level",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: unlocked
                                          ? Colors.deepPurple
                                          : Colors.grey,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // 📝 LEVEL TEXT
                                Text(
                                  unlocked
                                      ? "Level $level"
                                      : "Locked Level",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: unlocked
                                        ? Colors.white
                                        : Colors.black38,
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // ▶ / 🔒 ICON
                                Icon(
                                  unlocked
                                      ? Icons.play_arrow_rounded
                                      : Icons.lock_rounded,
                                  size: 32,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}