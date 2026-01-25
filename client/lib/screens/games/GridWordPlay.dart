


import 'package:bright_minds/screens/games/gameKids.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';

class GridGameScreen extends StatefulWidget {
  const GridGameScreen({super.key});

  @override
  State<GridGameScreen> createState() => _GridGameScreenState();
}

class _GridGameScreenState extends State<GridGameScreen>
    with SingleTickerProviderStateMixin {
  String userId = "";
  bool isLoading = true;
  Timer? _timer;
  int remainingTime = 0;
  Map<String, dynamic>? gameData;
  final String gameName = "Grid Words";
  num score = 0;
  int totalTrialsUsed = 0;

  int currentLevel = 1;
  List<String> currentLevelWords = [];
  Set<String> foundWordSet = {};

  int gridSize = 10;
  List<List<String>> grid = [];
  Set<String> lockedCells = {};
  List<Offset> selectedCells = [];
  String currentWord = "";
  Random random = Random();
  bool hasStarted = false;


  late List<int> levels;
  late Map<int, List<String>> levelWords;


  @override
  void initState() {
    super.initState();
    _initGame();
    //  _assignWordColors();

  }




  Future<void> _initGame() async {
    await getUserId();
    await loadGame();
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



void _prepareLevelWords() {
  if (gameData == null) return;

  levelWords = {};

  for (var question in gameData!['input']) {
    int lvl = question['level'] ?? 1;
    levelWords.putIfAbsent(lvl, () => []);
    levelWords[lvl]!.addAll(List<String>.from(question['correctAnswer']));
  }

  // Remove duplicates
  levelWords.updateAll((k, v) => v.toSet().toList());

  // Ensure levels are numeric and sorted
  levels = levelWords.keys
      .map((k) => k is int ? k : int.parse(k.toString()))
      .toList()
    ..sort();
    print("Levels available: $levels");

  // Set first level explicitly
  currentLevel = levels.isNotEmpty ? levels.first : 1;
  currentLevelWords = levelWords[currentLevel] ?? [];

  // Reset all selections
  foundWordSet.clear();
  lockedCells.clear();
  selectedCells.clear();
  currentWord = "";

  // Make sure the grid is generated for the correct level
  _generateGrid();
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
        // ✅ keep only published games
        final publishedGames =
            data.where((g) => g['isPublished'] == true).toList();

        if (publishedGames.isNotEmpty) {
          gameData = publishedGames.first; // or last if needed
          _prepareLevelWords();
          _startTimer();
        } else {
          debugPrint("No published game found");
        }
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
  totalTrialsUsed++; // increment trial counter

  if (totalTrialsUsed >= (gameData!['maxTrials'] ?? 3)) {
    _gameOver(); // game ends if trials exceeded
  } else {
    _restartCurrentLevel(); // start a new trial
  }
}


  void _restartCurrentLevel() {
  foundWordSet.clear();
  lockedCells.clear();
  selectedCells.clear();
  currentWord = "";

  _generateGrid(); // new grid = words must be found again
  _startTimer();

  setState(() {});
}


  void _checkLevelCompletion() {
    if (foundWordSet.length == currentLevelWords.length) {
      _timer?.cancel();
    score += gameData!['scorePerQuestion'] ?? 5;

      _showLevelCompleteDialog();
    }
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
  int index = levels.indexOf(currentLevel);

  if (index + 1 < levels.length) {
    currentLevel = levels[index + 1];
    currentLevelWords = levelWords[currentLevel]!;

    gridSize = (gridSize + 2).clamp(10, 20);

    foundWordSet.clear();
    selectedCells.clear();
    lockedCells.clear();
    currentWord = "";

    _generateGrid();
    _startTimer();
    setState(() {});
  } else {
    _showGameCompleteDialog();
  }
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

  void _gameOver() async {
    _timer?.cancel();
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
            MaterialPageRoute(
              builder: (_) => gamesKidScreen(),
            ),
          );
        },
        child: const Text("Home"),
      ),
    ],
  ),
);

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

  // ----------------- GRID LOGIC -----------------
  String cellKey(int r, int c) => "$r,$c";

  bool _isAdjacent(Offset last, Offset next) {
    int dx = (last.dx - next.dx).abs().toInt();
    int dy = (last.dy - next.dy).abs().toInt();
    return dx <= 1 && dy <= 1;
  }

  void _onCellTap(int row, int col) {
    final pos = Offset(row.toDouble(), col.toDouble());
    if (lockedCells.contains(cellKey(row, col))) return;

    if (selectedCells.isEmpty || _isAdjacent(selectedCells.last, pos)) {
      setState(() {
        selectedCells.add(pos);
        currentWord += grid[row][col];
      });

      final wordUpper = currentWord.toUpperCase();
      final reversed = wordUpper.split('').reversed.join();

      if (currentLevelWords
        .map((e) => e.toUpperCase())
        .contains(wordUpper) ||
    currentLevelWords.map((e) => e.toUpperCase()).contains(reversed)) {
  setState(() {
    foundWordSet.add(wordUpper);

    // ✅ Add this line to save positions for permanent color
    wordPositionsMap[wordUpper] = List.from(selectedCells);

    for (final p in selectedCells) {
      lockedCells.add(cellKey(p.dx.toInt(), p.dy.toInt()));
    }
    selectedCells.clear();
    currentWord = "";
    _checkLevelCompletion();
  });


      }
    }
  }

  void _onCancelSelection() {
    setState(() {
      selectedCells.clear();
      currentWord = "";
    });
  }

  void _generateGrid() {
    grid = List.generate(gridSize, (_) => List.filled(gridSize, ' '));

    for (String word in currentLevelWords) {
      bool placed = false;
      int attempts = 0;
      while (!placed && attempts < 100) {
        attempts++;
        int row = random.nextInt(gridSize);
        int col = random.nextInt(gridSize);
        int dir = random.nextInt(4);
        int dr = 0, dc = 0;
        switch (dir) {
          case 0:
            dr = 0;
            dc = 1;
            break;
          case 1:
            dr = 1;
            dc = 0;
            break;
          case 2:
            dr = 1;
            dc = 1;
            break;
          case 3:
            dr = -1;
            dc = 1;
            break;
        }

        int r = row, c = col;
        bool canPlace = true;
        for (int i = 0; i < word.length; i++) {
          if (r < 0 || r >= gridSize || c < 0 || c >= gridSize) {
            canPlace = false;
            break;
          }
          if (grid[r][c] != ' ' && grid[r][c] != word[i]) {
            canPlace = false;
            break;
          }
          r += dr;
          c += dc;
        }

        if (!canPlace) continue;

        r = row;
        c = col;
        for (int i = 0; i < word.length; i++) {
          grid[r][c] = word[i];
          r += dr;
          c += dc;
        }
        placed = true;
      }
    }

    // Fill empty cells
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        if (grid[r][c] == ' ') {
          grid[r][c] = String.fromCharCode(65 + random.nextInt(26));
        }
      }
    }

    foundWordSet.clear();
    lockedCells.clear();
    selectedCells.clear();
    currentWord = "";
    setState(() {});
  }

  String formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString()}:${s.toString().padLeft(2, '0')}";
  }


  Map<String, Color> wordColorMap = {}; // Word -> Color
  Map<String, List<Offset>> wordPositionsMap = {}; // Word -> list of positions

// ---------------- Assign Colors to Words ----------------
void _assignWordColors() {
  final List<Color> wordColors = [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.teal,
    Colors.pinkAccent,
    Colors.amber,
    Colors.cyanAccent,
    Colors.deepOrangeAccent,
  ];

  wordColorMap = {};
  for (int i = 0; i < currentLevelWords.length; i++) {
    final word = currentLevelWords[i].toUpperCase();
    wordColorMap[word] = wordColors[i % wordColors.length];
  }
}

// ---------------- Get Color for Word ----------------
Color getColorForWord(String word) {
  return wordColorMap[word.toUpperCase()] ?? Colors.grey;
}


Color getCellColor(int row, int col) {
  final pos = Offset(row.toDouble(), col.toDouble());

  // 1️⃣ Permanently found words
  for (String word in foundWordSet) {
    final positions = wordPositionsMap[word.toUpperCase()] ?? [];
    if (positions.contains(pos)) {
      return getColorForWord(word); // stays colored permanently
    }
  }

  // 2️⃣ Currently selecting letters (temporary highlight)
  if (selectedCells.contains(pos) && currentWord.isNotEmpty) {
    String? matchingWord;
    for (String word in currentLevelWords) {
      if (word.toUpperCase().startsWith(currentWord.toUpperCase()) ||
          word.toUpperCase() == currentWord.toUpperCase()) {
        matchingWord = word;
        break;
      }
    }
    return getColorForWord(matchingWord ?? currentWord);
  }

  // 3️⃣ Default color
  return Colors.orange.shade100;
}


void _lockWordAtPositions(String word, List<Offset> positions) {
  final wordUpper = word.toUpperCase();
  if (!foundWordSet.contains(wordUpper)) {
    foundWordSet.add(wordUpper);
    wordPositionsMap[wordUpper] = List.from(positions); // permanent positions
    setState(() {}); // rebuild grid
  }
}


// ---------------- Lock Word ----------------
void _lockCurrentWord() {
  if (currentWord.isEmpty) return;

  final wordUpper = currentWord.toUpperCase();
  if (!foundWordSet.contains(wordUpper)) {
    foundWordSet.add(wordUpper);

    // Save positions of letters in grid
    wordPositionsMap[wordUpper] = List.from(selectedCells);

    // Clear selection
    selectedCells.clear();
    currentWord = "";

    setState(() {});
  }
}


// ---------------- Build Method ----------------
// @override
// Widget build(BuildContext context) {
//   if (isLoading) return const Center(child: CircularProgressIndicator());

//   _assignWordColors(); // Assign colors for this level


//   if (!hasStarted) {
// return Scaffold(
//   body: Stack(
//     children: [

//       Positioned.fill(
//         child: Image.asset(
//           'assets/images/test10.png',
//           fit: BoxFit.cover,
//         ),
//       ),


//       // 2️⃣ Friendly icons scattered

//       // 3️⃣ Centered content with semi-transparent box
//       Center(

//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Grid Word Game",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 36,
//                   color: Color.fromARGB(255, 4, 1, 8),
//                   shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "You have ${gameData?['maxTrials'] ?? 3} trials",
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                   shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 "Are You Ready To Start?",
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black87,
//                   shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 40),
//                ElevatedButton(
//   style: ElevatedButton.styleFrom(
//     padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
//     backgroundColor: Colors.green.withOpacity(0.8),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(24),
//     ),
//   ),
//   onPressed: () {
//     setState(() {
//       hasStarted = true;

//       // ✅ Start the game properly
//       currentLevel = levels.isNotEmpty ? levels.first : 1;
//       currentLevelWords = levelWords[currentLevel] ?? [];

//       // Clear all previous selections
//       foundWordSet.clear();
//       selectedCells.clear();
//       lockedCells.clear();
//       currentWord = "";

//       // Generate the grid for the first level
//       _generateGrid();

//       // Assign colors to words
//       _assignWordColors();

//       // Start the timer
//       _startTimer();
//     });
//   },
//   child: const Text(
//     "Play",
//     style: TextStyle(
//       fontSize: 28,
//       fontWeight: FontWeight.bold,
//       color: Colors.white,
//     ),
//   ),
// ),

//             ],
//           ),
//         ),
//     //  ),
//     ],
//   ),
// );

// }




//   return Scaffold(
//     backgroundColor: Colors.lightBlue.shade50,
//     body: SafeArea(
//       child: Column(
//         children: [
//           // ---------- Top Bar ----------
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.home, color: Colors.blue, size: 30),
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (_) => gamesKidScreen()),
//                     );
//                   },
//                 ),
//                 const Text(
//                   "🌟 Grid Words",
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(width: 40),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),

//           // ---------- Header Info ----------
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.purple.shade200, Colors.pink.shade200],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(20),
//               boxShadow: const [
//                 BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
//               ],
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _infoCard("⭐ Score", "$score", Colors.yellow),
//                 _infoCard("⏱ Time", "${formatTime(remainingTime)}", Colors.orange),
//                 _infoCard("🧩 Level", "$currentLevel", Colors.greenAccent),
//                 _infoCard("🎯 Trials",
//                     "$totalTrialsUsed/${gameData?['maxTrials'] ?? 3}", Colors.redAccent),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),


// // ---------- Word Grid ----------
// LayoutBuilder(
//   builder: (context, constraints) {
//     final double gridSizePx = constraints.maxWidth - 32;

//     return Center(
//       child: Container(
//         width: gridSizePx,
//         height: gridSizePx,
//         margin: const EdgeInsets.symmetric(horizontal: 16),
//         padding: const EdgeInsets.all(6),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 4,
//               offset: Offset(2, 2),
//             )
//           ],
//         ),
//         child: GridView.builder(
//           physics: const NeverScrollableScrollPhysics(), // IMPORTANT
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: gridSize,
//             mainAxisSpacing: 4,
//             crossAxisSpacing: 4,
//             childAspectRatio: 1, // 🔥 square cells
//           ),
//           itemCount: gridSize * gridSize,
//           itemBuilder: (_, index) {
//             final row = index ~/ gridSize;
//             final col = index % gridSize;

//             return GestureDetector(
//               onTap: () => _onCellTap(row, col),
//               onDoubleTap: _lockCurrentWord,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 150),
//                 decoration: BoxDecoration(
//                   color: getCellColor(row, col),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: SizedBox.expand(
//                   child: FittedBox(
//                     fit: BoxFit.scaleDown,
//                     child: Text(
//                       grid[row][col],
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         height: 1,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   },
// ),


//           const SizedBox(height: 12),

//           // ---------- Current Word ----------
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.orange.shade200, Colors.orange.shade400],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: const [
//                 BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
//               ],
//             ),
//             child: Text(
//               "💬 Current Word: $currentWord",
//               style: const TextStyle(
//                   fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
//             ),
//           ),
//           const SizedBox(height: 12),

//           // ---------- Word Chips ----------
//           Wrap(
//             spacing: 8,
//             runSpacing: 8,
//             children: currentLevelWords.map((word) {
//               final found = foundWordSet.contains(word.toUpperCase());
//               return Chip(
//                 label: Text(
//                   word,
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     decoration: found ? TextDecoration.lineThrough : TextDecoration.none,
//                   ),
//                 ),
//                 backgroundColor: found ? getColorForWord(word) : Colors.pink.shade100,
//                 avatar: found
//                     ? const Icon(Icons.check_circle, size: 16, color: Colors.white)
//                     : null,
//               );
//             }).toList(),
//           ),

//           const SizedBox(height: 12),

//           // ---------- Cancel Selection ----------
//           ElevatedButton.icon(
//             onPressed: _onCancelSelection,
//             icon: const Icon(Icons.cancel),
//             label: const Text("Cancel Selection"),
//          style: ElevatedButton.styleFrom(
//   backgroundColor: Colors.redAccent,
//   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//   textStyle: const TextStyle(
//     fontSize: 16,
//     fontWeight: FontWeight.bold,
//     color: Colors.white, // ✅ text color
//   ),
//   foregroundColor: Colors.white, // ✅ icon + text color
// ),

//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     ),
//   );
// }

@override
Widget build(BuildContext context) {
  if (isLoading) return const Center(child: CircularProgressIndicator());

  _assignWordColors();

  if (!hasStarted) {
    return kIsWeb ? _buildWebStart() : _buildMobileStart();
  }

  return kIsWeb ? _buildWebGame(context) : _buildMobileGame(context);
}


Widget _buildMobileStart() {
return Scaffold(
  body: Stack(
    children: [

      Positioned.fill(
        child: Image.asset(
          'assets/images/test10.png',
          fit: BoxFit.cover,
        ),
      ),


      // 2️⃣ Friendly icons scattered

      // 3️⃣ Centered content with semi-transparent box
      Center(

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Grid Word Game",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  color: Color.fromARGB(255, 4, 1, 8),
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
    backgroundColor: Colors.green.withOpacity(0.8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
  ),
  onPressed: () {
    setState(() {
      hasStarted = true;

      // ✅ Start the game properly
      currentLevel = levels.isNotEmpty ? levels.first : 1;
      currentLevelWords = levelWords[currentLevel] ?? [];

      // Clear all previous selections
      foundWordSet.clear();
      selectedCells.clear();
      lockedCells.clear();
      currentWord = "";

      // Generate the grid for the first level
      _generateGrid();

      // Assign colors to words
      _assignWordColors();

      // Start the timer
      _startTimer();
    });
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
    //  ),
    ],
  ),
);

}



Widget _buildWebStart() {
  return Scaffold(
    body: Stack(
      children: [

        // ✅ Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/images/test10.png',
            fit: BoxFit.cover, // fills the entire page
          ),
        ),

        // ✅ Semi-transparent overlay for content
        Center(
          child: Container(
        width: 600,
        padding: const EdgeInsets.all(40),
        
        decoration: 
        BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 10),
          ],
        ),
        // image: DecorationImage(
        //   image: AssetImage("assets/images/test10.png"), // same as mobile
        //   fit: BoxFit.fill,
        // ),
      //  ),
       child: 
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Grid Word Game",
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Trials: ${gameData?['maxTrials'] ?? 3}",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 30),
           ElevatedButton(
  onPressed: () {
    setState(() {
      hasStarted = true;

      currentLevel = levels.isNotEmpty ? levels.first : 1;
      currentLevelWords = levelWords[currentLevel] ?? [];

      foundWordSet.clear();
      selectedCells.clear();
      lockedCells.clear();
      currentWord = "";

      _generateGrid();
      _assignWordColors();
      _startTimer();
    });
  },
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  ),
  child: const Text("Play", style: TextStyle(fontSize: 26)),
),

          ],
        ),
      ),
    ),
      ],
  ),
  );
}



Widget _buildMobileGame(BuildContext context) {
   return Scaffold(
    backgroundColor: Colors.lightBlue.shade50,
    body: SafeArea(
      child: Column(
        children: [
          // ---------- Top Bar ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, color: Colors.blue, size: 30),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => gamesKidScreen()),
                    );
                  },
                ),
                const Text(
                  "🌟 Grid Words",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ---------- Header Info ----------
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade200, Colors.pink.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoCard("⭐ Score", "$score", Colors.yellow,context),
                _infoCard("⏱ Time", "${formatTime(remainingTime)}", Colors.orange , context),
                _infoCard("🧩 Level", "$currentLevel", Colors.greenAccent,context,),
                _infoCard("🎯 Trials",
                    "$totalTrialsUsed/${gameData?['maxTrials'] ?? 3}", Colors.redAccent,context),
              ],
            ),
          ),
          const SizedBox(height: 12),


// ---------- Word Grid ----------
LayoutBuilder(
  builder: (context, constraints) {
    final double gridSizePx = constraints.maxWidth - 32;

    return Center(
      child: Container(
        width: gridSizePx,
        height: gridSizePx,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(2, 2),
            )
          ],
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // IMPORTANT
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1, // 🔥 square cells
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (_, index) {
            final row = index ~/ gridSize;
            final col = index % gridSize;

            return GestureDetector(
              onTap: () => _onCellTap(row, col),
              onDoubleTap: _lockCurrentWord,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: getCellColor(row, col),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      grid[row][col],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  },
),


          const SizedBox(height: 12),

          // ---------- Current Word ----------
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade200, Colors.orange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
              ],
            ),
            child: Text(
              "💬 Current Word: $currentWord",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 12),

          // ---------- Word Chips ----------
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currentLevelWords.map((word) {
              final found = foundWordSet.contains(word.toUpperCase());
              return Chip(
                label: Text(
                  word,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: found ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                backgroundColor: found ? getColorForWord(word) : Colors.pink.shade100,
                avatar: found
                    ? const Icon(Icons.check_circle, size: 16, color: Colors.white)
                    : null,
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // ---------- Cancel Selection ----------
          ElevatedButton.icon(
            onPressed: _onCancelSelection,
            icon: const Icon(Icons.cancel),
            label: const Text("Cancel Selection"),
         style: ElevatedButton.styleFrom(
  backgroundColor: Colors.redAccent,
  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  textStyle: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white, // ✅ text color
  ),
  foregroundColor: Colors.white, // ✅ icon + text color
),

          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}



// Widget _buildWebGame(BuildContext context) {
//   return Scaffold(
//     backgroundColor: Colors.grey.shade100,
//     body: SafeArea(
//             child: Column(
//         children: [

//           // ---------- Top Bar ----------
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.home, color: Colors.blue, size: 30),
//                   onPressed: () {
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(builder: (_) => gamesKidScreen()),
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   "🌟 Grid Words",
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 1),

//           // ---------- Main Content ----------
//           Expanded(
     
//       child: LayoutBuilder(
//         builder: (context, constraints) {

//           return Center(
//             child: Container(
//               width: constraints.maxWidth * 0.95,
//               constraints: const BoxConstraints(maxWidth: 1400),
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [

//                   // 🟦 LEFT — GRID
//                   Expanded(
//                     flex: 4,
//                     child: Column(
//                       children: [
//                         _buildGridWeb(),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(width: 24),

//                   // 🟨 RIGHT — INFO PANEL
//                 Expanded(
//   flex: 3,
//   child: SingleChildScrollView(
//     child: Column(
//       children: [
//         Align(
//           alignment: Alignment.center,
//           child: _infoCardWeb("⭐ Score", "$score", Colors.amber),
//         ),
//         const SizedBox(height: 14),
//         Align(
//           alignment: Alignment.center,
//           child: _infoCardWeb("⏱ Time", formatTime(remainingTime), Colors.orange),
//         ),
//         const SizedBox(height: 14),
//         Align(
//           alignment: Alignment.center,
//           child: _infoCardWeb("🧩 Level", "$currentLevel", Colors.green),
//         ),
//         const SizedBox(height: 14),
//         Align(
//           alignment: Alignment.center,
//           child: _infoCardWeb(
//             "🎯 Trials",
//             "$totalTrialsUsed / ${gameData?['maxTrials'] ?? 3}",
//             Colors.red,
//           ),
//         ),


//                           const SizedBox(height: 24),

//                           // 🔵 Current Word
//                           Container(
//                             padding: const EdgeInsets.all(30),
//                             decoration: BoxDecoration(
//                               color: Colors.blue.shade50,
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: const [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 6,
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 const Text(
//                                   "Current Word",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   currentWord.isEmpty ? "—" : currentWord,
//                                   style: const TextStyle(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     letterSpacing: 2,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           const SizedBox(height: 16),

//                           // 🔴 Cancel Button (UNDER current word)
//                           ElevatedButton.icon(
//                             onPressed: _onCancelSelection,
//                             icon: const Icon(Icons.cancel),
//                             label: const Text("Cancel Selection"),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.redAccent,
//                               foregroundColor: Colors.white,
//                               padding: const EdgeInsets.symmetric(
//                                 vertical: 20,
//                               horizontal: 20,

//                               ),
//                               textStyle: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                             ),
//                           ),

//                           const SizedBox(height: 24),

//                           // 🟣 Words List
//                           Wrap(
//                             spacing: 10,
//                             runSpacing: 10,
//                              alignment: WrapAlignment.center, // centers each row horizontally
//                              runAlignment: WrapAlignment.center, // centers rows vertically if multiple rows
//                             children: currentLevelWords.map((word) {
//                               final found =
//                                   foundWordSet.contains(word.toUpperCase());
//                               return Chip(
//                                 padding: const EdgeInsets.symmetric(
//                                     horizontal: 12, vertical: 8),
//                                 label: Text(
//                                   word,
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 backgroundColor: found
//                                     ? getColorForWord(word)
//                                     : Colors.grey.shade300,
//                               );
//                             }).toList(),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     )
//         ],
//     ),
//     ),
//   );
// }
Widget _buildWebGame(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey.shade100,
    body: SafeArea(

       
  


      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = min(constraints.maxWidth * 0.95, 1400);

          return Center(
            child: Container(
              width: maxWidth,
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // 🟦 LEFT — GRID
                  Expanded(
                    flex: 7,
                    child: LayoutBuilder(
                      builder: (context, gridConstraints) {
                        return _buildGridWeb();
                      },
                    ),
                  ),

                  const SizedBox(width: 24),
 
                  // 🟨 RIGHT — INFO PANEL
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                           const SizedBox(width: 20),
    Text(
      "🌟 Level $currentLevel",
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    ),
                              const SizedBox(height: 14),

                          _infoCardWeb("⭐ Score", "$score", Colors.amber),
                          const SizedBox(height: 14),
                          _infoCardWeb("⏱ Time", formatTime(remainingTime), Colors.orange),
                          const SizedBox(height: 14),
                          _infoCardWeb("🧩 Level", "$currentLevel", Colors.green),
                          const SizedBox(height: 14),
                          _infoCardWeb("🎯 Trials",
                              "$totalTrialsUsed / ${gameData?['maxTrials'] ?? 3}", Colors.red),
                          const SizedBox(height: 24),
                          // Current Word
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Current Word",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentWord.isEmpty ? "—" : currentWord,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _onCancelSelection,
                            icon: const Icon(Icons.cancel),
                            label: const Text("Cancel Selection"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 20),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Words List
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            runAlignment: WrapAlignment.center,
                            children: currentLevelWords.map((word) {
                              final found = foundWordSet.contains(word.toUpperCase());
                              return Chip(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                label: Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                backgroundColor: found
                                    ? getColorForWord(word)
                                    : Colors.grey.shade300,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
           Container(
  width: 60,
  height: 60,
  decoration: const BoxDecoration(
    color: Colors.white, // white circle
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 4,
        offset: Offset(2, 2),
      ),
    ],
  ),
  child: IconButton(
    icon: const Icon(Icons.home, color: Colors.blue, size: 30),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => gamesKidScreen()),
      );
    },
  ),
)

                ],
              ),
            ),
          );
        },
      ),
    
  ),
   
    );
}




Widget _infoCard(String title, String value, Color color, BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;

  return Container(
    width: width * 0.17,   // responsive width
    height: height * 0.07, // responsive height
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.white, blurRadius: 3, offset: Offset(1, 1))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center, // centers text horizontally
      children: [
        Text(title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _buildGridWeb() {
 // final double gridWidth = min(600, MediaQuery.of(context).size.width * 0.9);
 // final double gridHeight = maxHeight ?? gridWidth;
  final double cellPadding = 3;

  return Container(
   color:Colors.white,
   child:Expanded(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        mainAxisSpacing: cellPadding,
        crossAxisSpacing: cellPadding,
        childAspectRatio: 1,
      ),
      itemCount: gridSize * gridSize,
      itemBuilder: (_, index) {
        final row = index ~/ gridSize;
        final col = index % gridSize;
        return GestureDetector(
          onTap: () => _onCellTap(row, col),
          onDoubleTap: _lockCurrentWord,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: getCellColor(row, col),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                grid[row][col],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
            ),
          ),
        );
      },
    ),
  ),
   ),
  );
}






Widget _infoCardWeb(String title, String value, Color color) {
  return Container(
    width: 300, // fixed width for web
    height: 80, // fixed height for web
    alignment: Alignment.center, // centers the Column inside container
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, // vertical centering
      crossAxisAlignment: CrossAxisAlignment.center, // horizontal centering
      children: [
        Text(
          title,
          textAlign: TextAlign.center, // center text
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center, // center text
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}







    }