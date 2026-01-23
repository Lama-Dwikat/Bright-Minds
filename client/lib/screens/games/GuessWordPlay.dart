



import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/screens/games/gameKids.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class GuessGameScreen extends StatefulWidget {
  final int initialLevel;
  final bool hasStarted;
  const GuessGameScreen({super.key, this.initialLevel = 1, this.hasStarted = false});

  @override
  State<GuessGameScreen> createState() => _GuessGameScreenState();
}

class _GuessGameScreenState extends State<GuessGameScreen> with SingleTickerProviderStateMixin {
  String? userId = "";
  final String gameName = "Guess The Word";

  Map<String, dynamic>? gameData;
  int currentQuestionIndex = 0;
  int currentLevel = 1;
  final int totalLevels = 2;

  num score = 0;
  String get scoreKey => "${gameName}_totalScore";
  int totalTrialsUsed = 0;
  bool hasStarted = false;
  bool isLoading = true;

  Timer? _timer;
  int remainingTime = 0;

  final TextEditingController answerController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String theme = " ";

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

  @override
  void initState() {
    super.initState();
    currentLevel = widget.initialLevel;
    loadScore();
    loadGame().then((_) {
      // Start at the correct level question
      _setQuestionIndexForLevel(currentLevel);
    });
    getUserId();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    answerController.dispose();
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
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

  void checkAnswer() {
    final question = gameData!['input'][currentQuestionIndex];
    final correctAnswers = List<String>.from(question['correctAnswer']);
    final userAnswer = answerController.text.trim().toLowerCase();

    if (correctAnswers.any((a) => a.toLowerCase() == userAnswer)) {
      score += gameData!['scorePerQuestion'];
      saveLocalScore(score);
      nextQuestion();
    } else {
      totalTrialsUsed++;
      if (totalTrialsUsed >= (gameData!['maxTrials'] ?? 3)) {
        _gameOver();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Try again")),
        );
        _startTimer();
      }
    }
  }

  Future<void> resetGameProgress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(scoreKey, 0);
    await prefs.setStringList("${gameName}_unlockedLevels", ["1"]);
  }

  void nextQuestion() {
    answerController.clear();

    if (currentQuestionIndex + 1 < gameData!['input'].length) {
      final nextIndex = currentQuestionIndex + 1;

      int currentQuestionLevel = gameData!['input'][currentQuestionIndex]['level'];
      int nextQuestionLevel = gameData!['input'][nextIndex]['level'];

      if (nextQuestionLevel > currentQuestionLevel) {
        currentLevel = nextQuestionLevel;
        _timer?.cancel();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLevelCompleteDialog();
        });
      } else {
        setState(() => currentQuestionIndex++);
        _startTimer();
      }
    } else {
      _showGameCompleteDialog();
    }
  }

  void _setQuestionIndexForLevel(int level) {
    if (gameData == null) return;
    for (int i = 0; i < gameData!['input'].length; i++) {
      if (gameData!['input'][i]['level'] == level) {
        setState(() {
          currentQuestionIndex = i;
          currentLevel = level;
        });
        break;
      }
    }
    _startTimer();
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
                Navigator.pop(context); // close dialog
                Navigator.pop(context, true); // notify level completed
              },
              child: const Text("Back to Levels"),
            ),
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
        backgroundColor: const Color.fromARGB(255, 245, 233, 126),
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

  Future<void> saveScore(String gameId, String userId, num score, {bool complete = false}) async {
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
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(design.bgImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Guess The Word Game",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 36,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  "You have ${gameData?['maxTrials'] ?? 3} trials",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Are You Ready To Start?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                    backgroundColor: Colors.green.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () async {
                    await resetGameProgress();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LevelSelectionScreen(
                          gameName: gameName,
                          totalLevels: totalLevels,
                            bgImage: design.bgImage,
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
      );
    }





   if (kIsWeb) {
//🌐 WEB DESIGN for GuessGameScreen
 return Scaffold(
  body: Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(design.bgImage),
        fit: BoxFit.cover,
      ),
    ),
    child: Stack(
      children: [
        // 🏠 HOME BUTTON
        Positioned(
          top: 24,
          left: 24,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.8),
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.green, size: 30),
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

        // ⭐ SCORE & ⏱ TIMER at top-center
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "⭐ Score: $score",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 5, 78, 7)),
              ),
              const SizedBox(width: 40),
              Text(
                "⏱ ${formatTime(remainingTime)}",
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 5, 78, 7)),
              ),
            ],
          ),
        ),

        // ✅ MAIN GAME BOX
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // transparent background
              border: Border.all(
                color: Colors.green.withOpacity(0.8),
                width: 3,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔹 Header: What is ? + icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "What is ?",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 27, 67, 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        design.icon,
                        color: Colors.brown,
                        size: 30,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 🔹 Clue box
                  if (question['clue'] != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.withOpacity(0.5), width: 2),
                      ),
                      child: Text(
                        question['clue'] ?? design.emoji,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // 🔹 Images row
                  if (images.isNotEmpty)
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: images.take(3).map((img) => Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 10),
                    //     child: imageBox(img),
                    //   )).toList(),

                      
                    // ),
if (images.isNotEmpty)
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // First image
      imageBox(images[0]),

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          "+",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),

      // Second image if exists
      if (images.length >= 2) imageBox(images[1]),

      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          "  =",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
      ),

      // Question mark image
      Image.asset(
        'assets/images/questionMark.png',
        height: 250,
        width: 250,
      ),
    ],
  ),

                  const SizedBox(height: 20),

                  // ✏️ ANSWER FIELD
                  TextField(
                    controller: answerController,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      prefixIcon: Icon(design.icon, color: Colors.brown),
                      hintText: "Your Answer",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ✅ SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.9),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
  }
else return Scaffold(
  body: Container(
    width: double.infinity,
    height: double.infinity,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(design.bgImage),
        fit: BoxFit.cover,
      ),
    ),
    

    child: Stack(
      children: [
        // 🏠 HOME BUTTON
     Positioned(
      left:170,

       child:SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.8),
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.green, size: 30),
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
     ),
      
Align(
  alignment: Alignment.center,
  child: SingleChildScrollView(
    padding: const EdgeInsets.only(top: 120, bottom: 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // 🌿 QUESTION BOX

   Container(
  width: MediaQuery.of(context).size.width * 0.8,
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 204, 241, 122).withOpacity(0.7),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: const Color.fromARGB(255, 236, 251, 203).withOpacity(0.4),
      width: 4,
    ),
    boxShadow: const [
      BoxShadow(color: Colors.black26, blurRadius: 10)
    ],
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [

      // 🔹 HEADER: What is (centered) + icon on right
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 236, 251, 203).withOpacity(0.4),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Row(
          children: [
            const Spacer(),

            const Text(
              "What is ?",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 8, 59, 10),
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              design.icon,
              color: Colors.brown,
              size: 28,
            ),

            const Spacer(),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // 🔹 CLUE BOX (wrapped text)
if (question['clue'] != null)
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center, // <-- center the child inside the container
      child: Text(
        question['clue'] ?? design.emoji,
        textAlign: TextAlign.center, // <-- center text horizontally
        softWrap: true,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade900,
        ),
      ),
    ),
  ),


      const SizedBox(height: 16),



 if (images.isNotEmpty)
 Column(
  children: [
  Row( mainAxisAlignment: MainAxisAlignment.center, 
  children: [ if (images.length == 1)
   imageBox(images[0]), 
   if (images.length >= 2) ...[
     imageBox(images[0]),
      const Padding( padding: EdgeInsets.symmetric(horizontal: 10), 
      child: Text( "+",
       style: TextStyle( fontSize: 32,
        fontWeight: FontWeight.bold, 
        color: Colors.brown, ),
         ), ), imageBox(images[1]), ],
        
          ], 
          ),
          Text( "=",
       style: TextStyle( fontSize: 45,
        fontWeight: FontWeight.bold, 
        color: Colors.brown, )),
          ],
          ),

   

      Image.asset(
        'assets/images/questionMark.png',
        height: 200,
        width: 200,
      ),

      const SizedBox(height: 16),
      Row(
         mainAxisAlignment: MainAxisAlignment.center,

                      children:[  Text("⭐ Score: $score",
                      style: const TextStyle(fontSize: 22)),


                  const SizedBox(width: 20),

      // ⏱ TIMER
      Text(
        "⏱ ${formatTime(remainingTime)}",
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 6)],
        ),
      ),
                      ],
      ),
    ],
  ),
),

const SizedBox(height: 20),

// ✏️ ANSWER FIELD (left aligned + same icon)
SizedBox(
  width: MediaQuery.of(context).size.width * 0.9,
  child: TextField(
    controller: answerController,
    textAlign: TextAlign.left,
    decoration: InputDecoration(
      prefixIcon: Icon(
        design.icon,
        color: Colors.brown,
      ),
      hintText: "Your Answer",
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    ),
  ),
),


        const SizedBox(height: 16),

        // ✅ SUBMIT BUTTON
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: ElevatedButton(
            onPressed: checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color.fromARGB(255, 91, 159, 28).withOpacity(0.9),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              "Submit",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
      ],
    ),
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
        bgImage: "assets/images/animalGuess.png",
      );
    case "Fruits_Vegetables":
      return ThemeDesign(
        icon: Icons.apple,
        emoji: "🍎",
        bgImage: "assets/images/fruitGuess.png",
      );
    default:
      return ThemeDesign(
        icon: Icons.quiz,
        emoji: "❓",
        bgImage: "assets/images/generalGuess.png",
      );
  }
}

//////////////////////////////////////////////////////////////////
class LevelSelectionScreen extends StatefulWidget {
  final String gameName;
  final int totalLevels;
   final String bgImage;

  const LevelSelectionScreen({
    super.key,
    required this.gameName,
    required this.totalLevels,
     required this.bgImage,
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
    List<String> unlocked = prefs.getStringList(key) ?? ["1"];
    setState(() {
      unlockedLevels = List.generate(
        widget.totalLevels,
        (index) => unlocked.contains((index + 1).toString()),
      );
    });
  }

  Future<void> unlockNextLevel(int level) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> unlocked = prefs.getStringList("${widget.gameName}_unlockedLevels") ?? ["1"];
    if (level + 1 <= widget.totalLevels && !unlocked.contains((level + 1).toString())) {
      unlocked.add((level + 1).toString());
      await prefs.setStringList("${widget.gameName}_unlockedLevels", unlocked);
      setState(() {
        unlockedLevels[level] = true;
      });
    }
  }

  void startLevel(int level) async {
    final bool? completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuessGameScreen(
          initialLevel: level,
          hasStarted: true,
        ),
      ),
    );

    if (completed == true) {
      await unlockNextLevel(level);
    }
  }


    // Your full level selection UI code remains unchanged
   @override
Widget build(BuildContext context) {
  //final ThemeDesign design = getThemeDesign(" "); // default design

  return Scaffold(
    body: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(widget.bgImage),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // 🏠 HOME BUTTON (top center)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
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

            // 🌟 LEVEL SELECTION CONTENT CENTERED
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Choose Your Level",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 17, 74, 19),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    child: ListView.builder(
                      shrinkWrap: true, // important to avoid infinite height
                      physics: const NeverScrollableScrollPhysics(),
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
                                    ? const Color.fromARGB(255, 4, 156, 22)
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
                                  Text(
                                    unlocked ? "Level $level" : "Locked Level",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: unlocked
                                          ? Colors.white
                                          : Colors.black38,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

Widget imageBox(String imageUrl) { 
  return Container( 
    width: 150,
     height: 150, 
     decoration: BoxDecoration( 
      color: Colors.white, 
      borderRadius: BorderRadius.circular(20),
       border: Border.all( 
        color: const Color.fromARGB(255, 169, 238, 86),
        width: 7,),
        boxShadow: const [ BoxShadow(
          color: Colors.black26,
           blurRadius: 6, 
           offset: Offset(0, 4))],),
            child: ClipRRect(
               borderRadius: BorderRadius.circular(20), 
               child: Image.network(
                 imageUrl,
                 fit: BoxFit.contain,
                 ),
                  ), 
                  );
                   }