
//////////////////////////////////////
//-------------------spelling games 
/////////////////////////////////////////
import 'dart:convert';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';


// /// MAIN SCREEN combining both games
// class SpellingGamesScreen extends StatefulWidget {
//   final String gameId; // ID for drag spelling game
//   final List<String> wordSearchWords; // Words for word search game

//   const SpellingGamesScreen({
//     required this.gameId,
//     required this.wordSearchWords,
//     super.key,
//   });

//   @override
//   State<SpellingGamesScreen> createState() => _SpellingGamesScreenState();
// }

// class _SpellingGamesScreenState extends State<SpellingGamesScreen> {
//   Map<String, dynamic>? game;
//   List<String> available = [];
//   List<String?> slots = [];
//   AudioPlayer audioPlayer = AudioPlayer();
//   bool loading = true;
//   String message = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadGame();
//   }

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     if (Platform.isIOS) return "http://localhost:3000";
//     return "http://localhost:3000";
//   }

//   Future<void> _loadGame() async {
//     final resp = await http.get(Uri.parse('${getBackendUrl()}/api/game/${widget.gameId}'));
//     if (resp.statusCode == 200) {
//       final data = jsonDecode(resp.body);
//       setState(() {
//         game = data;
//         available = List<String>.from(data['letters'] ?? []);
//         if (data['settings']?['shuffle'] ?? true) available.shuffle();
//         slots = List<String?>.filled((data['word'] as String).length, null);
//         loading = false;
//       });
//       if (game!['audio']?['wordAudio'] != null) _playUrl(game!['audio']['wordAudio']);
//     } else {
//       setState(() => message = 'Failed to load game');
//     }
//   }

//   Future<void> _playUrl(String url) async {
//     try {
//       await audioPlayer.stop();
//       await audioPlayer.play(UrlSource(url));
//     } catch (e) {}
//   }

//   void _onLetterDropped(String letter, int slotIndex) {
//     setState(() {
//       if (slots[slotIndex] == null) {
//         slots[slotIndex] = letter;
//         available.remove(letter);
//       }
//       final base = game?['audio']?['lettersAudioBase'];
//       if (base != null) _playUrl('$base/$letter.mp3');
//     });
//     if (!slots.contains(null)) _validateWord();
//   }

//   void _removeFromSlot(int index) {
//     setState(() {
//       final letter = slots[index];
//       if (letter != null) {
//         available.add(letter);
//         slots[index] = null;
//       }
//     });
//   }

//   void _validateWord() {
//     final formed = slots.map((s) => s ?? '').join();
//     if (formed.toLowerCase() == (game!['word'] as String).toLowerCase()) {
//       setState(() => message = 'Correct!');
//     } else {
//       setState(() => message = 'Try again');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) return Scaffold(body: Center(child: CircularProgressIndicator()));

//     final wordLen = (game!['word'] as String).length;

//     return DefaultTabController(
//       length: 2,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Spelling Games'),
//           bottom: TabBar(
//             tabs: [
//               Tab(text: 'Drag Letters'),
//               Tab(text: 'Word Search'),
//             ],
//           ),
//         ),
//         body: TabBarView(
//           children: [
//             // ---- Drag-and-drop spelling game ----
//             SingleChildScrollView(
//               padding: EdgeInsets.all(12),
//               child: Column(
//                 children: [
//                   if (game!['clueImage'] != null)
//                     Image.network(game!['clueImage'], height: 120),
//                   SizedBox(height: 8),
//                   Text('Drag letters into boxes to spell the word',
//                       style: TextStyle(fontSize: 16)),
//                   SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(wordLen, (i) {
//                       return Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 6),
//                         child: DragTarget<String>(
//                           builder: (context, candidate, rejected) {
//                             final l = slots[i];
//                             return GestureDetector(
//                               onTap: () => _removeFromSlot(i),
//                               child: Container(
//                                 width: 48,
//                                 height: 64,
//                                 alignment: Alignment.center,
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: Colors.blue),
//                                   color: l == null ? Colors.white : Colors.blue.shade100,
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Text(l ?? '',
//                                     style: TextStyle(
//                                         fontSize: 24, fontWeight: FontWeight.bold)),
//                               ),
//                             );
//                           },
//                           onWillAccept: (data) => true,
//                           onAccept: (data) => _onLetterDropped(data, i),
//                         ),
//                       );
//                     }),
//                   ),
//                   SizedBox(height: 24),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: available.map((letter) {
//                       return Draggable<String>(
//                         data: letter,
//                         feedback: Material(
//                           color: Colors.transparent,
//                           child: _letterTile(letter, opacity: 0.8),
//                         ),
//                         childWhenDragging: _letterTile(letter, opacity: 0.3),
//                         child: _letterTile(letter),
//                       );
//                     }).toList(),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (game!['audio']?['wordAudio'] != null)
//                         _playUrl(game!['audio']['wordAudio']);
//                     },
//                     child: Text('Play word'),
//                   ),
//                   SizedBox(height: 12),
//                   Text(message,
//                       style: TextStyle(
//                           fontSize: 18,
//                           color: message == 'Correct!' ? Colors.green : Colors.red)),
//                 ],
//               ),
//             ),

//             // ---- Word search game ----
//             WordSearchGame(words: widget.wordSearchWords),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _letterTile(String letter, {double opacity = 1}) {
//     return Opacity(
//       opacity: opacity,
//       child: Container(
//         width: 56,
//         height: 56,
//         alignment: Alignment.center,
//         decoration: BoxDecoration(
//           color: Colors.orange.shade100,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.orange.shade700),
//         ),
//         child: Text(letter.toUpperCase(),
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//       ),
//     );
//   }
// }

// /// Interactive Word Search Game
// class WordSearchGame extends StatefulWidget {
//   final List<String> words;
//   const WordSearchGame({required this.words, super.key});

//   @override
//   State<WordSearchGame> createState() => _WordSearchGameState();
// }

// class _WordSearchGameState extends State<WordSearchGame> {
//   late List<List<String>> grid;
//   final int gridSize = 10;
//   late List<List<bool>> selected; // letters of found words
//   Set<String> foundWords = {};
//   Set<String> currentSelection = {};

//   @override
//   void initState() {
//     super.initState();
//     _generateGrid();
//   }

//   String _posKey(int row, int col) => '$row-$col';

//   void _generateGrid() {
//     grid = List.generate(gridSize, (_) => List.generate(gridSize, (_) => ''));
//     selected = List.generate(gridSize, (_) => List.generate(gridSize, (_) => false));

//     final random = Random();

//     for (var word in widget.words.map((w) => w.toUpperCase())) {
//       bool placed = false;
//       int attempts = 0;

//       while (!placed && attempts < 100) {
//         attempts++;
//         int dir = random.nextInt(3); // 0=horizontal,1=vertical,2=diagonal
//         int row = random.nextInt(gridSize);
//         int col = random.nextInt(gridSize);

//         if (_canPlace(word, row, col, dir)) {
//           _placeWord(word, row, col, dir);
//           placed = true;
//         }
//       }
//     }

//     const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
//     for (int i = 0; i < gridSize; i++) {
//       for (int j = 0; j < gridSize; j++) {
//         if (grid[i][j] == '') grid[i][j] = letters[Random().nextInt(26)];
//       }
//     }
//   }

//   bool _canPlace(String word, int row, int col, int dir) {
//     if (dir == 0 && col + word.length > gridSize) return false;
//     if (dir == 1 && row + word.length > gridSize) return false;
//     if (dir == 2 && (row + word.length > gridSize || col + word.length > gridSize)) return false;
//     return true;
//   }

//   void _placeWord(String word, int row, int col, int dir) {
//     for (int i = 0; i < word.length; i++) {
//       if (dir == 0) grid[row][col + i] = word[i];
//       if (dir == 1) grid[row + i][col] = word[i];
//       if (dir == 2) grid[row + i][col + i] = word[i];
//     }
//   }

//   void _startSelection(int row, int col) {
//     setState(() {
//       currentSelection = {_posKey(row, col)};
//     });
//   }

//   void _updateSelection(int row, int col) {
//     String key = _posKey(row, col);
//     setState(() {
//       currentSelection.add(key);
//     });
//   }

//   void _endSelection() {
//     String formed = currentSelection.map((key) {
//       var parts = key.split('-');
//       int r = int.parse(parts[0]);
//       int c = int.parse(parts[1]);
//       return grid[r][c];
//     }).join();

//     String revFormed = formed.split('').reversed.join();

//     bool wordFound = false;

//     for (var word in widget.words.map((w) => w.toUpperCase())) {
//       if (word == formed || word == revFormed) {
//         foundWords.add(word);
//         wordFound = true;

//         // mark letters as permanently selected
//         for (var key in currentSelection) {
//           var parts = key.split('-');
//           int r = int.parse(parts[0]);
//           int c = int.parse(parts[1]);
//           selected[r][c] = true;
//         }
//       }
//     }

//     // clear current selection (temporary)
//     setState(() {
//       currentSelection.clear();
//     });

//     // Check win condition
//     if (foundWords.length == widget.words.length) {
//       Future.delayed(Duration(milliseconds: 200), () {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('You Win!'),
//             content: Text('Congratulations, you found all words!'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: Text('OK'),
//               ),
//             ],
//           ),
//         );
//       });
//     }
//   }

//   void _handlePan(Offset localPosition, double cellWidth, double cellHeight) {
//     int row = (localPosition.dy ~/ (cellHeight + 2)).clamp(0, gridSize - 1);
//     int col = (localPosition.dx ~/ (cellWidth + 2)).clamp(0, gridSize - 1);
//     _updateSelection(row, col);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Wrap(
//           spacing: 8,
//           children: widget.words.map((w) {
//             bool found = foundWords.contains(w.toUpperCase());
//             return Text(
//               w,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 decoration: found ? TextDecoration.lineThrough : TextDecoration.none,
//                 color: found ? Colors.green : Colors.black,
//               ),
//             );
//           }).toList(),
//         ),
//         SizedBox(height: 8),
//         Expanded(
//           child: LayoutBuilder(
//             builder: (context, constraints) {
//               double cellWidth = (constraints.maxWidth - 2 * (gridSize - 1) * 2) / gridSize;
//               double cellHeight = (constraints.maxHeight - 2 * (gridSize - 1) * 2) / gridSize;

//               return GestureDetector(
//                 onPanStart: (details) => _handlePan(details.localPosition, cellWidth, cellHeight),
//                 onPanUpdate: (details) => _handlePan(details.localPosition, cellWidth, cellHeight),
//                 onPanEnd: (_) => _endSelection(),
//                 child: GridView.builder(
//                   physics: NeverScrollableScrollPhysics(),
//                   padding: EdgeInsets.all(0),
//                   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: gridSize,
//                     childAspectRatio: 1,
//                     crossAxisSpacing: 2,
//                     mainAxisSpacing: 2,
//                   ),
//                   itemCount: gridSize * gridSize,
//                   itemBuilder: (context, index) {
//                     int row = index ~/ gridSize;
//                     int col = index % gridSize;
//                     String key = _posKey(row, col);

//                     return Container(
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         border: Border.all(color: Colors.black12),
//                         color: selected[row][col] || currentSelection.contains(key)
//                             ? Colors.orange.shade300
//                             : Colors.yellow.shade100,
//                       ),
//                       child: Text(
//                         grid[row][col],
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }




//////////////////////////////////////////////
//--------------math and clock games
/////////////////////////////////////////////
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'dart:math';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;


//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     if (Platform.isIOS) return "http://localhost:3000";
//     return "http://localhost:3000";
//   }



// class GameScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffc4f089),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Text(
//               "Learning Games",
//               style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),

//             _gameButton(
//               context,
//               "Clock Game",
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => ClockGameScreen()),
//               ),
//             ),

//             _gameButton(
//               context,
//               "Math Game",
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (_) => MathGameScreen()),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _gameButton(BuildContext context, String title, VoidCallback onTap) {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           width: 250,
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.green.shade700,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Center(
//             child: Text(
//               title,
//               style: const TextStyle(fontSize: 22, color: Colors.white),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


// class ClockGameScreen extends StatefulWidget {
//   @override
//   _ClockGameScreenState createState() => _ClockGameScreenState();
// }

// class _ClockGameScreenState extends State<ClockGameScreen> {
//   int? hour;
//   int? minute;
//   TimeOfDay? correctAnswer;
//   bool loading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadClock();
//   }

//   /// Generates a random time with minutes in multiples of 5
//   void generateRandomTime() {
//     final random = Random();
//     hour = random.nextInt(12) + 1; // 1-12
//     minute = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55][random.nextInt(12)];
//     correctAnswer = TimeOfDay(hour: hour!, minute: minute!);
//     loading = false;
//   }

//   Future<void> loadClock() async {
//     setState(() {
//       loading = true;
//     });


//     generateRandomTime();

//     setState(() {});
//   }

//   String formatTime(TimeOfDay time) {
//     final h = time.hour.toString().padLeft(2, '0');
//     final m = time.minute.toString().padLeft(2, '0');
//     return "$h:$m";
//   }

//   /// Generate multiple-choice options
//   List<Widget> generateOptions() {
//     if (correctAnswer == null) return [];

//     final random = Random();
//     List<TimeOfDay> options = [
//       correctAnswer!,
//       TimeOfDay(
//         hour: (correctAnswer!.hour % 12) + 1,
//         minute: correctAnswer!.minute,
//       ),
//       TimeOfDay(
//         hour: correctAnswer!.hour,
//         minute: [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55][random.nextInt(12)],
//       ),
//     ];

//     options.shuffle();
//     return options.map((t) => answerButton(t)).toList();
//   }

//   Widget answerButton(TimeOfDay value) {
//     return InkWell(
//       onTap: () {
//         bool correct = value == correctAnswer;

//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(correct ? "Correct! 🎉" : "Wrong ❌"),
//             content: Text(correct
//                 ? "Great job!"
//                 : "The correct time was ${formatTime(correctAnswer!)}"),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   loadClock();
//                 },
//                 child: const Text("Next"),
//               ),
//             ],
//           ),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: Colors.blue.shade300,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(
//           formatTime(value),
//           style: const TextStyle(fontSize: 22, color: Colors.white),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xffc4f089),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             const SizedBox(height: 40),
//             const Text(
//               "What time does the clock show?",
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             ClockWidget(hour: hour!, minute: minute!),
//             const SizedBox(height: 30),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: generateOptions(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ClockWidget extends StatelessWidget {
//   final int hour;
//   final int minute;
//   ClockWidget({required this.hour, required this.minute});

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       size: const Size(220, 220),
//       painter: ClockPainter(hour: hour, minute: minute),
//     );
//   }
// }

// class ClockPainter extends CustomPainter {
//   final int hour;
//   final int minute;

//   ClockPainter({required this.hour, required this.minute});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final center = Offset(size.width / 2, size.height / 2);
//     final radius = size.width / 2 - 10;

//     // Draw clock background
//     canvas.drawCircle(
//       center,
//       radius,
//       Paint()..color = Colors.white,
//     );

//     // Draw numbers 1-12
//     final textPainter = TextPainter(
//       textAlign: TextAlign.center,
//       textDirection: TextDirection.ltr,
//     );

//     for (int i = 1; i <= 12; i++) {
//       double angle = i * 30 * pi / 180;
//       final offset = Offset(
//         center.dx + (radius - 25) * sin(angle),
//         center.dy - (radius - 25) * cos(angle),
//       );

//       textPainter.text = TextSpan(
//         text: i.toString(),
//         style: const TextStyle(
//           fontSize: 18,
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//         ),
//       );

//       textPainter.layout();
//       final textOffset = offset - Offset(textPainter.width / 2, textPainter.height / 2);
//       textPainter.paint(canvas, textOffset);
//     }

//     // Draw hour hand
//     double hourAngle = ((hour % 12) + minute / 60) * 30 * pi / 180;
//     canvas.drawLine(
//       center,
//       Offset(center.dx + radius * 0.5 * sin(hourAngle),
//           center.dy - radius * 0.5 * cos(hourAngle)),
//       Paint()
//         ..strokeWidth = 5
//         ..color = Colors.black,
//     );

//     // Draw minute hand
//     double minuteAngle = minute * 6 * pi / 180;
//     canvas.drawLine(
//       center,
//       Offset(center.dx + radius * 0.8 * sin(minuteAngle),
//           center.dy - radius * 0.8 * cos(minuteAngle)),
//       Paint()
//         ..strokeWidth = 3
//         ..color = Colors.black,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
// }




// class MathGameScreen extends StatefulWidget {
//   @override
//   _MathGameScreenState createState() => _MathGameScreenState();
// }

// class _MathGameScreenState extends State<MathGameScreen> {
//   int? a, b, answer;
//   bool loading = true;
//   bool error = false;

//   @override
//   void initState() {
//     super.initState();
//     loadQuestion();
//   }

//   Future<void> loadQuestion() async {
//     setState(() {
//       loading = true;
//       error = false;
//     });

//     final url =
//         "${getBackendUrl()}/api/game/math/question?operation=add&min=1&max=10";

//     print("➡️ REQUEST → $url");

//     try {
//       final res = await http.get(Uri.parse(url));

//       print("⬅️ STATUS: ${res.statusCode}");
//       print("⬅️ BODY: ${res.body}");

//       if (res.statusCode != 200) {
//         print("❌ Backend error");
//         setState(() {
//           loading = false;
//           error = true;
//         });
//         return;
//       }

//       final data = jsonDecode(res.body);

//       /// Validate JSON
//       if (data["a"] == null || data["b"] == null || data["answer"] == null) {
//         print("❌ Missing fields from backend");
//         setState(() {
//           loading = false;
//           error = true;
//         });
//         return;
//       }

//    setState(() {
//   a = int.tryParse(data["a"].toString());
//   b = int.tryParse(data["b"].toString());
//   if (a != null && b != null) {
//     // Compute the correct answer
//     answer = a! + b!;
//   } else {
//     answer = null;
//   }
//   loading = false;
// });

//     } catch (e) {
//       print("❌ EXCEPTION: $e");
//       setState(() {
//         loading = false;
//         error = true;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (error || a == null || b == null || answer == null) {
//       return Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "⚠️ Couldn't load question",
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: loadQuestion,
//                 child: const Text("Retry"),
//               )
//             ],
//           ),
//         ),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.yellow.shade200,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "$a + $b = ?",
//               style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),

//             /// Randomized answer options
//             Wrap(
//               spacing: 20,
//               children: generateOptions(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Creates the 3 answer choices
//   List<Widget> generateOptions() {
//     List<int> options = [
//       answer!,
//       answer! + 2,
//       answer! - 2,
//     ];

//     options.shuffle();

//     return options.map((opt) => answerOption(opt)).toList();
//   }

//   Widget answerOption(int option) {
//     return InkWell(
//       onTap: () {
//         bool correct = option == answer;

//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text(correct ? "Correct! 🎉" : "Wrong ❌"),
//             content: Text(correct
//                 ? "Great job!"
//                 : "The right answer was $answer"),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   loadQuestion();
//                 },
//                 child: const Text("Next"),
//               )
//             ],
//           ),
//         );
//       },
//       child: Container(
//         padding: const EdgeInsets.all(18),
//         decoration: BoxDecoration(
//           color: Colors.blue.shade400,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Text(
//           option.toString(),
//           style: const TextStyle(fontSize: 30, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }
///////////////////////////////////////////////////
//---------------------------guess the game 
///////////////////////////////////////////////////
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;

// class GuessGameScreen extends StatefulWidget {
//   @override
//   _GuessGameScreenState createState() => _GuessGameScreenState();
// }

// class _GuessGameScreenState extends State<GuessGameScreen> {
//   final TextEditingController _controller = TextEditingController();
//   String message = "Press 'Start Game' to begin!";
//   String? gameId;
//   bool loading = false;

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     if (Platform.isIOS) return "http://localhost:3000";
//     return "http://localhost:3000";
//   }
//   Future<void> startGame() async {
//     setState(() {
//       loading = true;
//       message = "Starting game...";
//     });
//     try {
//       final res = await http.post(Uri.parse('${getBackendUrl()}/api/game/start'));
//           if (res.statusCode == 200) {

//       final data = jsonDecode(res.body);
//       gameId = data['_id'];
//       print("data: $data");
//       print("Game ID: $gameId");
//       setState(() {
//         message = "Game started! Enter your guess.";
//         loading = false;
//         _controller.text = '';
//       });}
//       else {
//         setState(() {
//           message = "Failed to start game.";
//           loading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         message = "Error starting game: $e";
//         loading = false;
//       });
//     }
//   }

//   Future<void> submitGuess() async {
//     if (_controller.text.isEmpty) return;
//     final guess = int.tryParse(_controller.text);
//     if (guess == null) return;

//     setState(() {
//       loading = true;
//     });

//     try {
//       final res = await http.post(
//         Uri.parse("${getBackendUrl()}/api/game/guess"),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'guess': guess}),
//       );

//       final data = jsonDecode(res.body);

//       setState(() {
//         message = "Your guess: $guess → ${data['result']}";
//         loading = false;
//         _controller.text = '';
//       });
//     } catch (e) {
//       setState(() {
//         message = "Error submitting guess: $e";
//         loading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Guess Game"),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               message,
//               style: const TextStyle(fontSize: 20),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             TextField(
//               controller: _controller,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 border: OutlineInputBorder(),
//                 labelText: 'Enter your guess',
//               ),
//               onSubmitted: (_) => submitGuess(),
//             ),
//             const SizedBox(height: 20),
//             loading
//                 ? const CircularProgressIndicator()
//                 : Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       ElevatedButton(
//                         onPressed: startGame,
//                         child: const Text("Start Game"),
//                       ),
//                       ElevatedButton(
//                         onPressed: submitGuess,
//                         child: const Text("Submit Guess"),
//                       ),
//                     ],
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//////////////////////////////////////////////////
//-----------------Snake Game 
/////////////////////////////////////////////////
// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';

// class SnakeGameApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Snake Game',
//       debugShowCheckedModeBanner: false,
//       home: SnakeGameScreen(),
//     );
//   }
// }

// class SnakeGameScreen extends StatefulWidget {
//   @override
//   _SnakeGameScreenState createState() => _SnakeGameScreenState();
// }

// class _SnakeGameScreenState extends State<SnakeGameScreen> {
//   static const int rowCount = 20;
//   static const int columnCount = 20;
//   static const Duration tickDuration = Duration(milliseconds: 300);

//   List<Point<int>> snake = [];
//   Point<int> food = Point(5, 5);
//   String direction = 'right';
//   Timer? timer;
//   bool gameOver = false;
//   int score = 0;

//   @override
//   void initState() {
//     super.initState();
//     resetGame();
//   }

//   void resetGame() {
//     snake = [Point(rowCount ~/ 2, columnCount ~/ 2)];
//     spawnFood();
//     direction = 'right';
//     score = 0;
//     gameOver = false;
//     timer?.cancel();
//     timer = Timer.periodic(tickDuration, (_) => updateGame());
//   }

//   void spawnFood() {
//     final random = Random();
//     while (true) {
//       final newFood = Point(random.nextInt(columnCount), random.nextInt(rowCount));
//       if (!snake.contains(newFood)) {
//         food = newFood;
//         break;
//       }
//     }
//   }

//   void updateGame() {
//     if (gameOver) return;

//     setState(() {
//       final head = snake.last;
//       Point<int> newHead;

//       switch (direction) {
//         case 'up':
//           newHead = Point(head.x, head.y - 1);
//           break;
//         case 'down':
//           newHead = Point(head.x, head.y + 1);
//           break;
//         case 'left':
//           newHead = Point(head.x - 1, head.y);
//           break;
//         case 'right':
//         default:
//           newHead = Point(head.x + 1, head.y);
//       }

//       // Check collisions
//       if (newHead.x < 0 ||
//           newHead.x >= columnCount ||
//           newHead.y < 0 ||
//           newHead.y >= rowCount ||
//           snake.contains(newHead)) {
//         gameOver = true;
//         timer?.cancel();
//         return;
//       }

//       snake.add(newHead);

//       // Check if food eaten
//       if (newHead == food) {
//         score++;
//         spawnFood();
//       } else {
//         snake.removeAt(0);
//       }
//     });
//   }

//   void changeDirection(String newDirection) {
//     if ((direction == 'up' && newDirection == 'down') ||
//         (direction == 'down' && newDirection == 'up') ||
//         (direction == 'left' && newDirection == 'right') ||
//         (direction == 'right' && newDirection == 'left')) {
//       return;
//     }
//     direction = newDirection;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: Text('Snake Game - Score: $score'),
//         backgroundColor: Colors.green,
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.all(5),
//               color: Colors.black,
//               child: GridView.builder(
//                 physics: NeverScrollableScrollPhysics(),
//                 gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: columnCount,
//                 ),
//                 itemCount: rowCount * columnCount,
//                 itemBuilder: (context, index) {
//                   final x = index % columnCount;
//                   final y = index ~/ columnCount;
//                   final point = Point(x, y);

//                   Color color;
//                   if (snake.contains(point)) {
//                     color = Colors.green;
//                   } else if (point == food) {
//                     color = Colors.red;
//                   } else {
//                     color = Colors.grey[900]!;
//                   }

//                   return Container(
//                     margin: EdgeInsets.all(1),
//                     decoration: BoxDecoration(
//                       color: color,
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           if (gameOver)
//             Padding(
//               padding: const EdgeInsets.all(10.0),
//               child: ElevatedButton(
//                 onPressed: resetGame,
//                 child: Text('Restart Game'),
//               ),
//             ),
//           // Direction buttons
//           Padding(
//             padding: const EdgeInsets.all(10.0),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     DirectionButton(
//                         icon: Icons.arrow_upward, onPressed: () => changeDirection('up')),
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     DirectionButton(
//                         icon: Icons.arrow_back, onPressed: () => changeDirection('left')),
//                     SizedBox(width: 20),
//                     DirectionButton(
//                         icon: Icons.arrow_forward, onPressed: () => changeDirection('right')),
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     DirectionButton(
//                         icon: Icons.arrow_downward, onPressed: () => changeDirection('down')),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DirectionButton extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onPressed;

//   const DirectionButton({required this.icon, required this.onPressed});

//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         minimumSize: Size(60, 60),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//       onPressed: onPressed,
//       child: Icon(icon, size: 30),
//     );
//   }
// }

//////////////////////////////////////////////
/// -------------------Maze Game
/////////////////////////////////////////////
// import 'dart:async';
// import 'dart:collection';
// import 'dart:math';
// import 'package:flutter/material.dart';

// void main() => runApp(MazeGameApp());

// class MazeGameApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Maze Game',
//       home: MazeGameScreen(),
//     );
//   }
// }

// class MazeGameScreen extends StatefulWidget {
//   @override
//   _MazeGameScreenState createState() => _MazeGameScreenState();
// }

// class _MazeGameScreenState extends State<MazeGameScreen> {
//   static const int rows = 10;
//   static const int columns = 10;

//   int currentLevel = 0;

//   // Maze levels: 1 = corridor (gray), 0 = wall (white)
//   final List<List<List<int>>> mazes = [
//     // Easy
//     [
//       [0,0,0,0,0,0,0,0,1,0],
//       [0,1,1,0,0,1,1,0,1,0],
//       [0,1,0,1,0,1,0,1,1,0],
//       [0,1,0,1,0,1,0,0,1,0],
//       [0,1,0,1,1,1,1,0,1,0],
//       [0,1,0,0,0,0,1,0,1,0],
//       [0,1,1,1,1,0,1,0,1,0],
//       [0,0,0,0,1,0,1,0,1,0],
//       [0,1,1,0,1,1,1,1,1,0],
//       [0,0,0,0,0,0,0,0,0,0],
//     ],
//     // Medium
//     [
//       [0,0,0,1,0,0,0,1,1,0],
//       [0,1,1,1,0,1,0,0,1,0],
//       [0,1,0,0,0,1,0,1,1,0],
//       [0,1,1,1,0,1,1,1,0,0],
//       [0,0,0,1,0,0,0,1,0,1],
//       [1,1,0,1,1,1,0,1,0,1],
//       [0,1,0,0,0,1,0,0,1,0],
//       [0,1,1,1,0,1,1,1,1,0],
//       [0,0,0,0,0,0,0,1,1,1],
//       [0,1,1,1,1,1,1,1,0,0],
//     ],
//     // Hard
//     [
//       [0,1,0,0,1,0,1,0,1,0],
//       [1,1,1,1,1,1,1,1,1,0],
//       [0,0,0,1,0,0,0,0,1,0],
//       [0,1,1,1,0,1,1,0,1,0],
//       [0,1,0,0,0,0,1,0,1,0],
//       [0,1,0,1,1,1,1,0,1,0],
//       [0,1,0,0,0,0,1,1,1,0],
//       [0,1,1,1,1,0,0,0,1,0],
//       [0,0,0,0,1,1,1,0,1,0],
//       [0,1,1,0,0,0,0,0,1,1],
//     ],
//   ];

//   // Start and goal positions for each level
//   final List<Point<int>> startPositions = [
//     Point(8, 0),
//     Point(3, 0),
//     Point(1, 0),
//   ];

//   final List<Point<int>> goalPositions = [
//     Point(8, 8),
//     Point(9, 8),
//     Point(9, 9),
//   ];

//   late List<List<int>> maze;
//   late Point<int> player;
//   late Point<int> goal;
//   bool gameOver = false;

//   @override
//   void initState() {
//     super.initState();
//     loadLevel(currentLevel);
//   }

//   void loadLevel(int level) {
//     setState(() {
//       maze = mazes[level];
//       player = startPositions[level];
//       goal = goalPositions[level];
//       gameOver = false;
//     });
//   }

//   // BFS to find solution strictly through gray squares
//   List<Point<int>> findSolution(Point<int> start, Point<int> end) {
//     List<List<bool>> visited =
//         List.generate(rows, (_) => List.generate(columns, (_) => false));
//     Map<Point<int>, Point<int>> parent = {};

//     Queue<Point<int>> queue = Queue();
//     queue.add(start);
//     visited[start.y][start.x] = true;

//     List<Point<int>> directions = [
//       Point(0, -1),
//       Point(0, 1),
//       Point(-1, 0),
//       Point(1, 0)
//     ];

//     while (queue.isNotEmpty) {
//       Point<int> current = queue.removeFirst();
//       if (current == end) break;

//       for (var d in directions) {
//         int nx = current.x + d.x;
//         int ny = current.y + d.y;

//         if (nx >= 0 &&
//             ny >= 0 &&
//             nx < columns &&
//             ny < rows &&
//             maze[ny][nx] == 1 &&
//             !visited[ny][nx]) {
//           visited[ny][nx] = true;
//           Point<int> next = Point(nx, ny);
//           parent[next] = current;
//           queue.add(next);
//         }
//       }
//     }

//     List<Point<int>> path = [];
//     Point<int>? step = end;
//     while (step != null && step != start) {
//       path.add(step);
//       step = parent[step];
//     }
//     if (step == start) {
//       path.add(start);
//       return path.reversed.toList();
//     }
//     return [];
//   }

//   void walkThroughSolution() async {
//     List<Point<int>> path = findSolution(player, goal);
//     if (path.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No valid path!')),
//       );
//       return;
//     }

//     for (var point in path.skip(1)) {
//       await Future.delayed(const Duration(milliseconds: 300));
//       setState(() => player = point);
//     }

//     if (player == goal) {
//       setState(() => gameOver = true);
//       await Future.delayed(const Duration(milliseconds: 500));
//       currentLevel++;
//       if (currentLevel >= mazes.length) {
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: const Text('Congratulations! 🎉'),
//             content: const Text('You completed all levels!'),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   currentLevel = 0;
//                   loadLevel(currentLevel);
//                 },
//                 child: const Text('Restart Game'),
//               ),
//             ],
//           ),
//         );
//       } else {
//         loadLevel(currentLevel);
//       }
//     }
//   }

//   void movePlayer(String direction) {
//     if (gameOver) return;
//     int x = player.x;
//     int y = player.y;

//     switch (direction) {
//       case 'up': y--; break;
//       case 'down': y++; break;
//       case 'left': x--; break;
//       case 'right': x++; break;
//     }

//     if (maze[y][x] == 1) {
//       setState(() => player = Point(x, y));
//       if (player == goal) walkThroughSolution();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Maze Game - Level ${currentLevel + 1}'),
//         backgroundColor: Colors.blueAccent,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               color: Colors.black,
//               child: GridView.builder(
//                 physics: const NeverScrollableScrollPhysics(),
//                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                   crossAxisCount: columns,
//                 ),
//                 itemCount: rows * columns,
//                 itemBuilder: (context, index) {
//                   final x = index % columns;
//                   final y = index ~/ columns;
//                   final point = Point(x, y);

//                   Widget content;
//                   if (point == player) {
//                     content = const Icon(Icons.star, color: Colors.yellow, size: 24);
//                   } else if (point == goal) {
//                     content = const Icon(Icons.flag, color: Colors.red, size: 24);
//                   } else if (maze[y][x] == 1) {
//                     content = Container(color: Colors.grey);
//                   } else {
//                     content = Container(color: Colors.white);
//                   }

//                   return Container(
//                     margin: const EdgeInsets.all(2),
//                     child: Center(child: content),
//                   );
//                 },
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () => movePlayer('up'),
//                       child: const Icon(Icons.arrow_upward),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     ElevatedButton(
//                       onPressed: () => movePlayer('left'),
//                       child: const Icon(Icons.arrow_back),
//                     ),
//                     const SizedBox(width: 20),
//                     ElevatedButton(
//                       onPressed: () => movePlayer('down'),
//                       child: const Icon(Icons.arrow_downward),
//                     ),
//                     const SizedBox(width: 20),
//                     ElevatedButton(
//                       onPressed: () => movePlayer('right'),
//                       child: const Icon(Icons.arrow_forward),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: walkThroughSolution,
//                   child: const Text('Auto Walk Solution'),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 10),
//         ],
//       ),
//     );
//   }
// }


// build castle 

// class CastleQuizApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Castle Quiz',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: CastleQuizScreen(),
//     );
//   }
// }

// class Question {
//   final String question;
//   final List<String> options;
//   final int correctIndex;

//   Question(this.question, this.options, this.correctIndex);
// }

// class CastleQuizScreen extends StatefulWidget {
//   @override
//   _CastleQuizScreenState createState() => _CastleQuizScreenState();
// }

// class _CastleQuizScreenState extends State<CastleQuizScreen> {
//   int stage = 0; // current stage of castle
//   int currentQuestion = 0;

//   final List<Question> questions = [
//     Question("What is 2 + 2?", ["3", "4", "5"], 1),
//     Question("What is the color of the sky?", ["Blue", "Green", "Red"], 0),
//     Question("Which animal barks?", ["Cat", "Dog", "Cow"], 1),
//     Question("What is 5 - 3?", ["1", "2", "3"], 1),
//     Question("What is the first letter of 'Apple'?", ["A", "B", "C"], 0),
//   ];

//   void answerQuestion(int index) {
//     if (index == questions[currentQuestion].correctIndex) {
//       setState(() {
//         if (stage < 5) stage++; // build next block
//       });
//     }

//     setState(() {
//       if (currentQuestion < questions.length - 1) {
//         currentQuestion++;
//       } else {
//         // All questions done
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text('Congratulations!'),
//             content: Text('You built the full castle!'),
//             actions: [
//               TextButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     setState(() {
//                       stage = 0;
//                       currentQuestion = 0;
//                     });
//                   },
//                   child: Text('Restart'))
//             ],
//           ),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Build the Castle!')),
//       body: Column(
//         children: [
//           // Castle display
// // Castle display
// Expanded(
//   child: Stack(
//     alignment: Alignment.bottomCenter,
//     children: [
//       // Foundation
//       if (stage >= 1)
//         Container(width: 200, height: 50, color: Colors.brown),
      
//       // Left wall
//       if (stage >= 2)
//         Positioned(
//           left: 30,
//           bottom: 50,
//           child: Container(width: 50, height: 100, color: Colors.grey),
//         ),
//       // Right wall
//       if (stage >= 3)
//         Positioned(
//           right: 30,
//           bottom: 50,
//           child: Container(width: 50, height: 100, color: Colors.grey),
//         ),
//       // Gate
//       if (stage >= 3)
//         Positioned(
//           bottom: 50,
//           child: Container(width: 60, height: 60, color: Colors.black),
//         ),
//       // Towers
//       if (stage >= 4)
//         Positioned(
//           left: 0,
//           bottom: 100,
//           child: Column(
//             children: [
//               Container(width: 50, height: 100, color: Colors.red),
//               Container(
//                 width: 50,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   border: Border.all(color: Colors.black, width: 2),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       if (stage >= 4)
//         Positioned(
//           right: 0,
//           bottom: 100,
//           child: Column(
//             children: [
//               Container(width: 50, height: 100, color: Colors.red),
//               Container(
//                 width: 50,
//                 height: 20,
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   border: Border.all(color: Colors.black, width: 2),
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       // Crenellations (battlements) on walls
//       if (stage >= 2)
//         Positioned(
//           left: 30,
//           bottom: 150,
//           child: Row(
//             children: List.generate(
//               5,
//               (i) => Container(
//                 width: 10,
//                 height: 10,
//                 margin: EdgeInsets.symmetric(horizontal: 2),
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ),
//       if (stage >= 3)
//         Positioned(
//           right: 30,
//           bottom: 150,
//           child: Row(
//             children: List.generate(
//               5,
//               (i) => Container(
//                 width: 10,
//                 height: 10,
//                 margin: EdgeInsets.symmetric(horizontal: 2),
//                 color: Colors.grey[800],
//               ),
//             ),
//           ),
//         ),
//       // Flag
//       if (stage >= 5)
//         Positioned(
//           bottom: 200,
//           child: Column(
//             children: [
//               Container(width: 5, height: 40, color: Colors.brown), // pole
//               Icon(Icons.flag, color: Colors.yellow, size: 30),
//             ],
//           ),
//         ),
//     ],
//   ),
// ),

//           Divider(),
//           // Question display
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               questions[currentQuestion].question,
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           ),
//           // Options
//           ...List.generate(questions[currentQuestion].options.length, (i) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               child: ElevatedButton(
//                 onPressed: () => answerQuestion(i),
//                 child: Text(questions[currentQuestion].options[i]),
//               ),
//             );
//           }),
//           SizedBox(height: 20),
//         ],
//       ),
//     );
//   }
// }




class GamesHomePage extends StatelessWidget {
  const GamesHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HomePage(
    title:"Games",
   
      child: SafeArea(
        child: Column(
          children: [
            // 🌈 Header
ClipPath(
  clipper: SoftWaveClipper(),
  child: Container(
    height: 200, // enough space for bubbles
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
      children: [
        // Header text
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                "Let’s Design Games 🎨🎮 ",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
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

        // Blue decorative bubbles
        Positioned(
          top: 20,
          left: 30,
child:const _Bubble(size: 40),
        ),
        Positioned(
          top: 50,
          right: 40,
          child: const _Bubble(size: 15),
        ),
        Positioned(
          bottom: 30,
          left: 70,
          child: const _Bubble(size: 35),
        ),
        Positioned(
          bottom: 20,
          right: 10,
          child: const _Bubble(size: 85),
        ),
      ],
    ),
  ),
),





            const SizedBox(height: 20),

            // 🎮 Floating Games
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: games.map((game) {
                    return GameBubble(game: game);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class GameBubble extends StatelessWidget {
  final Game game;
  const GameBubble({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to game
      },
      child: Container(
        width: 140,
        height: 160,
        decoration: BoxDecoration(
          color: game.color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: game.color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              game.icon,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              game.title,
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
}
class Game {
  final String title;
  final IconData icon;
  final Color color;

  Game({
    required this.title,
    required this.icon,
    required this.color,
  });
}

final List<Game> games = [
  Game(
    title: "Math Fun",
    icon: Icons.calculate,
    color: Color(0xFFFFB703),
  ),
  Game(
    title: "Puzzle",
    icon: Icons.extension,
    color: Color(0xFF8ECAE6),
  ),
  Game(
    title: "Memory",
    icon: Icons.psychology,
    color: Color(0xFFFFAFCC),
  ),
  Game(
    title: "Music",
    icon: Icons.music_note,
    color: Color(0xFF80ED99),
  ),
  Game(
    title: "Drawing",
    icon: Icons.brush,
    color: Color(0xFFFFD166),
  ),
  Game(
    title: "Logic",
    icon: Icons.lightbulb,
    color: Color(0xFFBDB2FF),
  ),
];
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
