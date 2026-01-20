
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:bright_minds/screens/games/gameKids.dart';





class RulerGameScreen extends StatefulWidget {
  final int initialLevel;
  final bool hasStarted;
  const RulerGameScreen({super.key, this.initialLevel = 1, this.hasStarted = false});

  @override
  State<RulerGameScreen> createState() => _RulerGameScreenState();
}

class _RulerGameScreenState extends State<RulerGameScreen> {
  int level = 1; 
  int questionCount = 0; 
  final int maxLevel = 3; 
  String userId = "";
  bool isLoading = true;
  final String gameName = "Ruler";
  Map<String, dynamic>? gameData;


  int currentQuestionIndex = 0;
  int currentLevel = 1;
  final int totalLevels = 2;

  num score = 0;
  String get scoreKey => "${gameName}_totalScore";
  int totalTrialsUsed = 0;
  bool hasStarted = false;


  Timer? _timer;
  int remainingTime = 0;

  final TextEditingController answerController = TextEditingController();



  String theme = " ";

  String? selectedValue;

  late double correctValue;
  late List<String> options; 

  final Random random = Random();

@override
void initState() {
  super.initState();
  _initGame();
}

Future<void> _initGame() async {
  await getUserId();       // fetch user id from token
  await loadGame();        // fetch game data (time, max trials, scorePerQuestion)
  _startTimer();           // start countdown for current question
  generateNewQuestion();   // generate the first ruler question
}


  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    setState(() {
      userId = decodedToken['id'];
    });
  }


Future<void> saveScore(String gameId, String userId, num score, {bool complete = false}) async {
  final url = Uri.parse('${getBackendUrl()}/api/game/saveUserScore');
  final response = await http.post(url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "gameId": gameId,
        "userId": userId,
        "score": score,
        "complete": complete,
      }));
  if (response.statusCode == 200) print("Score saved!");
  else print("Failed to save score: ${response.body}");
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
        }
      }
    } catch (e) {
      debugPrint("Error loading game: $e");
    } finally {
      setState(() => isLoading = false);
    }
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
  if (totalTrialsUsed >= (gameData?['maxTrials'] ?? 3)) {
    _gameOver();
  } else {
    generateNewQuestion(); // new ruler question
    _startTimer();         // restart timer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⏱ Time's up! Try the next one.")),
    );
  }
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


    void _showLevelCompleteDialog() {
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 245, 233, 126),
          title: const Text("👏 Level Complete!"),
          content: Text(
              "You finished level $currentLevel\nScore: $score\nGet ready for the next level!"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _goToNextLevel();
              },
              child: const Text("Next Level"),
            ),
          ],
        ),
      );
    });
  }

void _goToNextLevel() {

  
    _startTimer();
    setState(() {});

    _showGameCompleteDialog();
  
}


  void _showGameCompleteDialog() async {
    _timer?.cancel();
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
            onPressed: () => 
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => gamesKidScreen(),
            ),
          ),            child: const Text("Home"),
          )
        ],
      ),
    );
  }

   String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString()}:${s.toString().padLeft(2, '0')}";
  }

  void generateNewQuestion() {
    // Correct value
    if (level == 1) {
      correctValue = (1 + random.nextInt(7)).toDouble(); // whole numbers
    } else if (level == 2) {
      correctValue = (1 + random.nextInt(7)).toDouble();
      if (random.nextBool()) correctValue += 0.5; // halves
    } else {
      correctValue = (1 + random.nextInt(7)).toDouble();
      correctValue += random.nextInt(10) / 10; // decimals 0.1 step
      correctValue = double.parse(correctValue.toStringAsFixed(2));
    }

    // Generate 2 wrong answers
    Set<double> choicesSet = {correctValue};
    while (choicesSet.length < 3) {
      double wrong = 0;

      if (level == 1) {
        wrong = (1 + random.nextInt(7)).toDouble();
      } else if (level == 2) {
        wrong = (1 + random.nextInt(7)).toDouble();
        if (random.nextBool()) wrong += 0.5;
      } else {
        wrong = (1 + random.nextInt(7)) + random.nextInt(10) / 10;
        wrong = double.parse(wrong.toStringAsFixed(2));
      }

      // Avoid duplicate
      choicesSet.add(wrong);
        _startTimer();
    }

    options = choicesSet.map((e) => e.toString()).toList();
    options.shuffle();

    selectedValue = null;
    setState(() {});
  }

void checkAnswer() {
  if (selectedValue == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please drag a block first!")),
    );
    return;
  }

  double selectedDouble = double.tryParse(selectedValue!) ?? -1;

  if ((selectedDouble - correctValue).abs() < 0.01) {
    // Correct
    num points = gameData?['scorePerQuestion'] ?? 10;
    score += points;
    questionCount++;

    if (questionCount >= 3) {
      if (level < maxLevel) {
        level++;
        questionCount = 0;
        _showLevelCompleteDialog();
      } else {
        _showGameCompleteDialog();
      }
    } else {
      generateNewQuestion();
    }
  } else {
    totalTrialsUsed++;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("😅 Try again!")),
    );
    if (totalTrialsUsed >= (gameData?['maxTrials'] ?? 3)) {
      _gameOver();
    }
  }
}


  void _startGame() {
    setState(() => hasStarted = true);
    generateNewQuestion();
    _startTimer();
  }


//  @override
// Widget build(BuildContext context) {



//       if (!hasStarted) {


//   return Scaffold(
//   body: Container(
//     decoration: const BoxDecoration(
//       gradient: KidColors.bgGradient,
//     ),
//     child: Stack(
//       children: [
//         Positioned.fill(
//           child: Image.asset(
//             'assets/images/rulerGame.png',
//             fit: BoxFit.cover,
//             opacity: const AlwaysStoppedAnimation(0.90),
//           ),
//         ),

//         Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "📏 Ruler Game",
//                 style: TextStyle(
//                   fontSize: 42,
//                   fontWeight: FontWeight.bold,
//                   color: KidColors.purple,
//                 ),
//               ),

//               const SizedBox(height: 20),

//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(30),
//                   boxShadow: const [
//                     BoxShadow(color: Colors.black26, blurRadius: 8),
//                   ],
//                 ),
//                 child: Text(
//                   "🎯 You have ${gameData?['maxTrials'] ?? 3} tries",
//                   style: const TextStyle(
//                     fontSize: 22,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 40),

//               ElevatedButton(
//                 onPressed: _startGame,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: KidColors.purple,
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 40, vertical: 13),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(40),
//                   ),
//                   elevation: 10,
//                 ),
//                 child: const Text(
//                   "▶ PLAY",
//                   style: TextStyle(
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//               )
//             ],
//           ),
//         ),
//       ],
//     ),
//   ),
// );

//     }
  
//   return Scaffold(
//   appBar: AppBar(
//     backgroundColor: KidColors.purple,
//     elevation: 0,
//     leading: IconButton(
//       icon: const Icon(Icons.home, size: 34),
//       onPressed: () {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => gamesKidScreen()),
//           (_) => false,
//         );
//       },
//     ),
//     title: Text(
//       "🌟 Level $level",
//       style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//     ),
//     centerTitle: true,
//   ),

//   body: Container(
//     decoration: const BoxDecoration(
//       gradient: KidColors.bgGradient,
//     ),
//     child: SafeArea(
//       child: Column(
//         children: [

//           // ⭐ TIME + SCORE
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _infoBubble(Icons.timer, formatTime(remainingTime), Colors.blue),
//                 _infoBubble(Icons.star, score.toStringAsFixed(0), Colors.pink),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // 🐸 QUESTION
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(30),
//               boxShadow: const [
//                 BoxShadow(color: Colors.black12, blurRadius: 6),
//               ],
//             ),
//             child: const Text(
//               "🐸 How long is it?",
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//                 color: KidColors.purple,
//               ),
//             ),
//           ),

//           const SizedBox(height: 15),

//           // 📏 RULER
//           rulerWidget(correctValue),

//           const SizedBox(height: 20),

//           // 🎯 DROP ZONE
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               dropZone(),
//               const SizedBox(width: 8),
//               const Text(
//                 "cm",
//                 style: TextStyle(
//                   fontSize: 26,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 25),

//           // 🧱 OPTIONS
//           Wrap(
//             alignment: WrapAlignment.center,
//             children: options.map((v) => draggableBlock(v)).toList(),
//           ),

//           const Spacer(),

//           // ✅ CHECK BUTTON
//           ElevatedButton(
//             onPressed: checkAnswer,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: KidColors.yellow,
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               elevation: 8,
//             ),
//             child: const Text(
//               "CHECK ✅",
//               style: TextStyle(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black,
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),
//         ],
//       ),
//     ),
//   ),
// );

// }


@override
Widget build(BuildContext context) {
  // If game hasn't started, show the start screen (same for both mobile & web)
  if (!hasStarted) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: KidColors.bgGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/rulerGame.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.90),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "📏 Ruler Game",
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: KidColors.purple,
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
                      backgroundColor: KidColors.purple,
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check if web or mobile
  if (kIsWeb && MediaQuery.of(context).size.width > 800) {
    // ===== WEB LAYOUT =====
// ===== WEB LAYOUT =====
return Scaffold(
  appBar: AppBar(
    backgroundColor: KidColors.purple,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.home, size: 34),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => gamesKidScreen()),
          (_) => false,
        );
      },
    ),
    title: Text(
      "🌟 Level $level",
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    ),
    centerTitle: true,
  ),
  body: Container(
    decoration: const BoxDecoration(gradient: KidColors.bgGradient),
     height: double.infinity,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // <-- Added scroll
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ⭐ SCORE & TIME
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoBubble(Icons.star, score.toStringAsFixed(0), Colors.pink), // Score left
                    _infoBubble(Icons.timer, formatTime(remainingTime), Colors.blue), // Time right
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 🐸 QUESTION (CENTERED)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: const Text(
                    "🐸 How long is it?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: KidColors.purple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 📏 RULER
              rulerWidget(correctValue),
              const SizedBox(height: 20),

              // 🎯 DROP ZONE (CENTERED)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  dropZone(),
                  const SizedBox(width: 8),
                  const Text(
                    "cm",
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 🧱 OPTIONS (UNDER RULER)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: options.map((v) => draggableBlock(v)).toList(),
              ),
              const SizedBox(height: 40),

              // ✅ CHECK BUTTON
              Center(
                child: ElevatedButton(
                  onPressed: checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KidColors.yellow,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    "CHECK ✅",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  // ===== MOBILE LAYOUT (original) =====
  return Scaffold(
    appBar: AppBar(
      backgroundColor: KidColors.purple,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.home, size: 34),
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => gamesKidScreen()),
            (_) => false,
          );
        },
      ),
      title: Text(
        "🌟 Level $level",
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: KidColors.bgGradient,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ⭐ TIME + SCORE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoBubble(Icons.timer, formatTime(remainingTime), Colors.blue),
                  _infoBubble(Icons.star, score.toStringAsFixed(0), Colors.pink),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🐸 QUESTION
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: const Text(
                "🐸 How long is it?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: KidColors.purple,
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 📏 RULER
            rulerWidget(correctValue),

            const SizedBox(height: 20),

            // 🎯 DROP ZONE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                dropZone(),
                const SizedBox(width: 8),
                const Text(
                  "cm",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // 🧱 OPTIONS
            Wrap(
              alignment: WrapAlignment.center,
              children: options.map((v) => draggableBlock(v)).toList(),
            ),

            const Spacer(),

            // ✅ CHECK BUTTON
            ElevatedButton(
              onPressed: checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: KidColors.yellow,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
              ),
              child: const Text(
                "CHECK ✅",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

Widget dropZone() {
  return DragTarget<String>(
    onAccept: (value) {
      setState(() => selectedValue = value);
    },
    builder: (_, __, ___) {
      return Container(
        width: 140,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: KidColors.purple, width: 4),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          selectedValue ?? "DROP",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: selectedValue == null
                ? Colors.grey
                : KidColors.purple,
          ),
        ),
      );
    },
  );
}


  Widget draggableBlock(String text) {
    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: valueBlock(text),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: valueBlock(text),
      ),
      child: valueBlock(text),
    );
  }

  Widget valueBlock(String text) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 90,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget rulerWidget(double value) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 220, 155, 201),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 80,
        child: CustomPaint(
          size: const Size(double.infinity, 80),
          painter: RulerPainter(value),
        ),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  final double value; // value to read (1 to 7)

  RulerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    int maxCm = 7; // ruler from 1 to 7
    double widthPerCm = size.width / maxCm;
    double widthPerStep = widthPerCm / 10; // 0.1 cm steps

    // Draw ruler ticks
    for (int i = 1; i <= maxCm; i++) {
      for (int j = 0; j <= 10; j++) {
        double x = (i - 1) * widthPerCm + j * widthPerStep;
        double lineHeight;

        if (j == 0) {
          lineHeight = 40; // full cm
        } else if (j == 5) {
          lineHeight = 30; // half cm
        } else {
          lineHeight = 20; // small tick
        }

        canvas.drawLine(Offset(x, 0), Offset(x, lineHeight), paint);

        // numbers only at full cm
        if (j == 0) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: "$i",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          textPainter.paint(canvas, Offset(x - 5, 45));
        }
      }
    }

    // Draw marker as vertical line on the ruler itself
    double markerX = (value - 1) * widthPerCm;
    final markerPaint = Paint()
      ..color = const Color.fromARGB(255, 202, 1, 212)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(markerX, 0),
      Offset(markerX, 50), // line goes through the ticks
      markerPaint,
    );

    // Optional: small circle at top of the line
    canvas.drawCircle(
      Offset(markerX, 0),
      6,
      Paint()..color = const Color.fromARGB(255, 202, 1, 212),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}







class KidColors {
  static const pink = Color(0xFFFFC1E3);
  static const blue = Color(0xFFB3E5FC);
  static const purple = Color(0xFF9C89FF);
  static const yellow = Color(0xFFFFF59D);
  static const green = Color(0xFFB9F6CA);
  static const bgGradient = LinearGradient(
    colors: [pink, blue],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
Widget valueBlock(String text) {
  return Container(
    margin: const EdgeInsets.all(8),
    width: 90,
    height: 60,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [KidColors.purple, Colors.deepPurple],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 6),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 26,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}


Widget _infoBubble(IconData icon, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
