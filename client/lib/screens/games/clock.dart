





import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:bright_minds/screens/gameKids.dart';

class ClockGameScreen extends StatefulWidget {


  const ClockGameScreen({
    super.key,

  });

  @override
  State<ClockGameScreen> createState() => _ClockGameScreenState();
}

class _ClockGameScreenState extends State<ClockGameScreen> {
  int level = 1;
  int stars = 0;

  int hour = 3;
  int minute = 0;

  String userId = "";
  bool isLoading = true;

  final String gameName = "Clock";
  Map<String, dynamic>? gameData;

  num score = 0;
  int totalTrialsUsed = 0;

  Timer? _timer;
  int remainingTime = 0;

  String? droppedHour;
  String? droppedMinute;

  List<String> hourOptions = [];
  List<String> minuteOptions = [];
  
  bool hasStarted=false;

  final List<int> fullMinutes = [
    0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55
  ];

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    await getUserId();
    await loadGame();
    _startTimer();
    _generateQuestion();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    if (token.isEmpty) return;

    final decoded = JwtDecoder.decode(token);
    userId = decoded['id'];
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


  /// 🔹 TIMER
  void _startTimer() {
    _timer?.cancel();
    remainingTime =
        ((gameData?['timePerQuestionMin'] ?? 1) * 60).toInt();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime > 0) {
        setState(() => remainingTime--);
      } else {
        timer.cancel();
        _onTimeOut();
      }
    });
  }

  String _formatTime(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return "${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}";
  }


  void _onTimeOut() {
  totalTrialsUsed++;

  if (totalTrialsUsed >= (gameData?['maxTrials'] ?? 3)) {
    _gameOver();
  } else {
    // Start a new trial
    _generateQuestion();  // new question
    _startTimer();        // restart timer
    _showWrongAnswerDialog(); // optional: show a message
  }
}


void _gameOver() {
  _timer?.cancel();

  // Save score
  if (gameData != null && userId.isNotEmpty) {
    saveScore(gameData!['_id'], userId, score, complete: false);
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
        ),
      ],
    ),
  );
}


  void _showWrongAnswerDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("❌ Wrong Answer"),
        content: const Text("Try again!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("⭐ Level Completed"),
        content: Text(
          "You completed Level ${level - 1}!\n\n"
          "Score: $score\n\n"
          "Moving to Level $level",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateQuestion();
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

void _showGameCompletedDialog() {
  _timer?.cancel();

  // Save score
  if (gameData != null && userId.isNotEmpty) {
    saveScore(gameData!['_id'], userId, score, complete: true);
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text("🎉 Game Completed"),
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
        ),
      ],
    ),
  );
}


  void _generateQuestion() {
    final random = Random();
    hour = random.nextInt(12) + 1;

    if (level == 1) {
      minute = 0;
    } else if (level == 2) {
      minute = random.nextBool() ? 0 : 30;
    } else {
      minute = fullMinutes[random.nextInt(fullMinutes.length)];
    }

    droppedHour = null;
    droppedMinute = level == 1 ? "00" : null;

    hourOptions = {
      hour,
      random.nextInt(12) + 1,
      random.nextInt(12) + 1,
    }.map((e) => e.toString().padLeft(2, '0')).toList()
      ..shuffle();

    if (level > 1) {
      minuteOptions = {
        minute,
        level == 2 ? (minute == 0 ? 30 : 0) : fullMinutes[random.nextInt(fullMinutes.length)],
      }.map((e) => e.toString().padLeft(2, '0')).toList()
        ..shuffle();
    }

  _startTimer();
    setState(() {});
  }

void _checkAnswer() {
  if (droppedHour == null || (level > 1 && droppedMinute == null)) return;

  final answer = "${droppedHour!}:${level == 1 ? '00' : droppedMinute!}";
  final correct =
      "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";

  if (answer == correct) {
    // Use scorePerQuestion from gameData
    num points = gameData?['scorePerQuestion'] ?? 10;
    score += points;
    stars++;

    if (stars % 5 == 0) {
      if (level < 3) {
        level++;
        _showLevelCompleteDialog();
      } else {
        _showGameCompletedDialog();
      }
    } else {
      _generateQuestion();
    }
  } else {
    totalTrialsUsed++;
    _showWrongAnswerDialog();
    if (totalTrialsUsed >= (gameData?['maxTrials'] ?? 3)) {
      _gameOver();
    }
  }

  setState(() {}); // update UI
}


  void _startGame() {
    setState(() => hasStarted = true);
    _generateQuestion();
    _startTimer();
  }


  @override
  Widget build(BuildContext context) {


    if (!hasStarted) {
      return Scaffold(
          body: Stack(
      children: [
         Positioned.fill(
          child: Image.asset(
            'assets/images/clockGame.png', // replace with your image path
            fit: BoxFit.cover,
         opacity: const AlwaysStoppedAnimation(0.90),

          ),
        ),
        // Center(
        Positioned(
          top:300,
          right:0,
          left:0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Clock Game",
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text(
                "You have ${gameData?['maxTrials'] ?? 3} trials",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), // horizontal and vertical padding
    textStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16), // optional: rounded corners
    ),
  ),
                onPressed: _startGame,
                child: const Text("Play", style: TextStyle(fontSize: 28)),
              ),
            ],
          ),
        ),
      ]
          )
      );
    }


    if (isLoading || gameData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 249, 186, 91), // strong orange,
        leading: IconButton(
          icon: const Icon(Icons.home),
             iconSize: 36,
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => gamesKidScreen()),
              (_) => false,
            );
          },
        ),
         title: Text(
      "    Level $level",
      style: const TextStyle(
        fontSize: 28, // make it bigger
        fontWeight: FontWeight.bold, // optional for emphasis
      ),
    ),
    centerTitle: true,
  ),
     body: Container(
decoration: const BoxDecoration(
  gradient: LinearGradient(
    colors: [
     Color.fromARGB(255, 249, 195, 113), // strong orange
  Color.fromARGB(255, 245, 218, 137), // amber
  Color.fromARGB(255, 250, 238, 135),// soft yellow
    Color.fromARGB(255, 246, 241, 197),// soft yellow

    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ),
),

    height:double.infinity,
   child: Stack(
    children: [
  const Positioned(top: 30, left: 20, child: Icon(Icons.access_time, size: 40, color: Colors.black)),
      const Positioned(top: 100, right: 10, child: Icon(Icons.access_time, size: 30, color: Colors.black)),
      const Positioned(bottom: 50, left: 50, child: Icon(Icons.access_time, size: 35, color: Colors.black)),
      const Positioned(bottom: 70, right: 30, child: Icon(Icons.access_time, size: 50, color: Colors.black)), SingleChildScrollView(
        child: Column(
          children: [
                 
            const SizedBox(height: 10),
            Text("⭐ Stars: $stars ",
                style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
            Text("⏱ ${_formatTime(remainingTime)}",
                style: const TextStyle(fontSize: 23)),
            const SizedBox(height: 10),

Column(
  children: [
    const SizedBox(height: 16),

    // House container for clock
    Stack(
      alignment: Alignment.center,
      children: [
        
        // House shape
        ClipPath(
          clipper: HouseClipper(),
          child: Container(
            width: 280,
            height: 220,
            color: Colors.orangeAccent[200],
          ),
        ),
        // Analog clock inside the house
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: KidsClockPainter(hour: hour, minute: minute),
          ),
        ),
      ],
    ),


Container(
  width: 280,
  height: 90,
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: Colors.orangeAccent.withOpacity(0.3), // semi-transparent orange
   // borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _dropZone("Hour", droppedHour, Colors.blue,
          (v) => setState(() => droppedHour = v)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text(":", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      ),
      level == 1
          ? _lockedMinute()
          : _dropZone("Minute", droppedMinute, Colors.green,
              (v) => setState(() => droppedMinute = v)),
    ],
  ),
),

   const SizedBox(height: 20),


Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Hours column
      Column(
        children: [
          const Text("Hours",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: hourOptions.map((v) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Draggable<String>(
                  data: v,
                  feedback: _block(v, Colors.blue),
                  childWhenDragging: _block(v, Colors.blue.withOpacity(0.4)),
                  child: _block(v, Colors.blue),
                ),
              )).toList(),
            ),
          ),
        ],
      ),

      const SizedBox(width: 20),

      // Minutes column
      if (level > 1)
        Column(
          children: [
            const Text("Minutes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: minuteOptions.map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Draggable<String>(
                    data: v,
                    feedback: _block(v, Colors.green),
                    childWhenDragging: _block(v, Colors.green.withOpacity(0.4)),
                    child: _block(v, Colors.green),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
    ],
  ),
),


    const SizedBox(height: 30),
    ElevatedButton(

      onPressed: _checkAnswer,
      child: const Text("Check",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    ),
  ],
),
        //    const SizedBox(height: 16),

  ],
            ),
  
        ),
    ],
     ),
       ),
    );

    
  }


  Widget _lockedMinute() => Container(
        width: 80,
        height: 70,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey, width: 3),
        ),
        child: const Text("00",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      );

  Widget _dropZone(
      String label, String? value, Color color, Function(String) onAccept) {
    return DragTarget<String>(
      onAccept: onAccept,
      builder: (_, candidate, __) {
        return Container(
          width: 80,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: candidate.isNotEmpty
                ? color.withOpacity(0.3)
                : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 3),
          ),
          child: Text(value ?? label,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _blockRow(List<String> values, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: values.map((v) {
        return Draggable<String>(
          data: v,
          feedback: _block(v, color),
          childWhenDragging: _block(v, color.withOpacity(0.4)),
          child: _block(v, color),
        );
      }).toList(),
    );
  }
// Updated label for Hours/Minutes


  Widget _block(String text, Color color) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 70,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      );

}

class KidsClockPainter extends CustomPainter {
  final int hour;
  final int minute;

  KidsClockPainter({required this.hour, required this.minute});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    /// Clock face
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.yellow[300]!
          ..style = PaintingStyle.fill);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.orange
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke);

    /// Draw numbers 1–12
    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final textPainter = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final offset = center +
          Offset(cos(angle), sin(angle)) * (radius * 0.75) -
          Offset(textPainter.width / 2, textPainter.height / 2);

      textPainter.paint(canvas, offset);
    }

    /// Smile
    canvas.drawArc(
      Rect.fromCircle(center: center.translate(0, 15), radius: 40),
      0,
      pi,
      false,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    /// Hour hand
    final hourAngle = ((hour % 12) + minute / 60) * 30 * pi / 180;
    canvas.drawLine(
      center,
      center +
          Offset(cos(hourAngle - pi / 2), sin(hourAngle - pi / 2)) *
              radius *
              0.45,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    /// Minute hand
    final minuteAngle = minute * 6 * pi / 180;
    canvas.drawLine(
      center,
      center +
          Offset(cos(minuteAngle - pi / 2), sin(minuteAngle - pi / 2)) *
              radius *
              0.7,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    /// Center dot
    canvas.drawCircle(center, 6, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;


  
}


/// Custom clipper for house shape
class HouseClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    double w = size.width;
    double h = size.height;

    // Roof
    path.moveTo(0, h * 0.4);
    path.lineTo(w / 2, 0);
    path.lineTo(w, h * 0.4);

    // Walls
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}



class KidColors {
  static const pink = Color(0xFFFFC1E3);
  static const blue = Color(0xFFB3E5FC);
  static const purple = Color(0xFF9C89FF);
  static const yellow = Color(0xFFFFF59D);
}
