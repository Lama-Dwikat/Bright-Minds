import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bright_minds/screens/gameKids.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'dart:convert';






class SnakeGameScreen extends StatefulWidget {
  const SnakeGameScreen({ super.key}); 
  @override
  _SnakeGameScreenState createState() => _SnakeGameScreenState();
}



class _SnakeGameScreenState extends State<SnakeGameScreen> {
  static const int rowCount = 28;
  static const int columnCount = 20;

  List<Point<int>> snake = [];
  Point<int> food = Point(5, 5);
  String direction = 'right';
  bool isgameOver = false;
  num score = 0;
  String userId = "";

  final String gameName = "Snake";

  Map<String, dynamic>? gameData;
  int currentQuestionIndex = 0;

 static const Duration tickDuration = Duration(milliseconds: 300);

  bool hasStarted = false;
  bool isLoading = true;
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    resetGame();
    getUserId();    
    loadGame();    
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    setState(() {
      userId = decodedToken['id'];
    });
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


  void gameOver() async {
  
    if (userId != null ) {
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


void resetGame() {
  snake = [Point(rowCount ~/ 2, columnCount ~/ 2)];
  spawnFood();
  direction = 'right';
  score = 0;
  isgameOver = false;

  // Cancel any existing timer
  gameTimer?.cancel();

  // Start the game loop
  gameTimer = Timer.periodic(tickDuration, (_) {
    if (!isgameOver) {
      updateGame();
    } else {
      gameTimer?.cancel();
    }
  });
}

  void spawnFood() {
    final random = Random();
    while (true) {
      final newFood = Point(random.nextInt(columnCount), random.nextInt(rowCount));
      if (!snake.contains(newFood)) {
        food = newFood;
        break;
      }
    }
  }

  void updateGame() {

    setState(() {
      final head = snake.last;
      Point<int> newHead;

      switch (direction) {
        case 'up':
          newHead = Point(head.x, head.y - 1);
          break;
        case 'down':
          newHead = Point(head.x, head.y + 1);
          break;
        case 'left':
          newHead = Point(head.x - 1, head.y);
          break;
        case 'right':
        default:
          newHead = Point(head.x + 1, head.y);
      }

      if (newHead.x < 0 ||
          newHead.x >= columnCount ||
          newHead.y < 0 ||
          newHead.y >= rowCount ||
          snake.contains(newHead)) {
        isgameOver = true;
           gameOver();
        return;
      }

      snake.add(newHead);

      if (newHead == food) {
        score++;
        spawnFood();
      } else {
        snake.removeAt(0);
      }
    });
  
    }

  void changeDirection(String newDirection) {
    if ((direction == 'up' && newDirection == 'down') ||
        (direction == 'down' && newDirection == 'up') ||
        (direction == 'left' && newDirection == 'right') ||
        (direction == 'right' && newDirection == 'left')) {
      return;
    }
    direction = newDirection;
  }
  

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

// @override
// Widget build(BuildContext context) {
//   final gridSize = MediaQuery.of(context).size.width * 2; // square grid

//   return Scaffold(
//     backgroundColor: const Color.fromARGB(255, 208, 207, 207), // background outside the game area
//     body: SafeArea(
//       child: Column(
//         children: [
//           // Top row: Home button + Score
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // Home button
//                 CircleAvatar(
//                   radius: 28,
//                   backgroundColor: Colors.white.withOpacity(0.8),
//                   child: IconButton(
//                     icon: const Icon(Icons.home, color: Color.fromARGB(255, 170, 2, 2), size: 30),
//                     onPressed: () {
//                       Navigator.pushAndRemoveUntil(
//                         context,
//                         MaterialPageRoute(builder: (_) => gamesKidScreen()),
//                         (_) => false,
//                       );
//                     },
//                   ),
//                 ),
         
//                 Row(
//   children: [
//     Icon(Icons.emoji_events, color: const Color.fromARGB(255, 203, 43, 43), size: 28),
//     SizedBox(width: 8),
//     Text('Score: $score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
//   ],
// )

//               ],
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Game area
//           Expanded(
//             child: Center(
//               child: Container(
//                 width: gridSize,
//                 height: gridSize,
//                 padding: const EdgeInsets.all(5),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[850], // game background color
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: GridView.builder(
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: columnCount,
//                   ),
//                   itemCount: rowCount * columnCount,
//                   itemBuilder: (context, index) {
//                     final x = index % columnCount;
//                     final y = index ~/ columnCount;
//                     final point = Point(x, y);

//                     Color color;
//                     if (snake.contains(point)) {
//                       color = Colors.green;
//                     } else if (point == food) {
//                       color = Colors.red;
//                     } else {
//                       color = Colors.grey[700]!;
//                     }

//                     return Container(
//                       margin: const EdgeInsets.all(1),
//                       decoration: BoxDecoration(
//                         color: color,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ),

//           const SizedBox(height: 20),

//           // Direction buttons
//           Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   DirectionButton(
//                       icon: Icons.arrow_upward,
//                       onPressed: () => changeDirection('up')),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   DirectionButton(
//                       icon: Icons.arrow_back,
//                       onPressed: () => changeDirection('left')),
//                   const SizedBox(width: 20),
//                   DirectionButton(
//                       icon: Icons.arrow_forward,
//                       onPressed: () => changeDirection('right')),
//                 ],
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   DirectionButton(
//                       icon: Icons.arrow_downward,
//                       onPressed: () => changeDirection('down')),
//                 ],
//               ),
//             ],
//           ),

    
//         ],
//       ),
//     ),
//   );
// }
// }
@override
Widget build(BuildContext context) {
  // Use different layout for web
  if (kIsWeb && MediaQuery.of(context).size.width > 800) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Make grid smaller for wide screens but keep square
    final gridSize = min(screenWidth * 0.7, screenHeight * 0.7);

    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top Row: Home + Score
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Home button
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.8),
                          child: IconButton(
                            icon: const Icon(Icons.home, color: Colors.red, size: 30),
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => gamesKidScreen()),
                                (_) => false,
                              );
                            },
                          ),
                        ),
                        // Score
                        Row(
                          children: [
                            const Icon(Icons.emoji_events, color: Colors.red, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'Score: $score',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Game area
                  Container(
                    width: gridSize,
                    height: gridSize,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                      ),
                      itemCount: rowCount * columnCount,
                      itemBuilder: (context, index) {
                        final x = index % columnCount;
                        final y = index ~/ columnCount;
                        final point = Point(x, y);

                        Color color;
                        if (snake.contains(point)) {
                          color = Colors.green;
                        } else if (point == food) {
                          color = Colors.red;
                        } else {
                          color = Colors.grey[700]!;
                        }

                        return Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Direction buttons (optional for web, can hide if using keyboard)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      DirectionButton(
                          icon: Icons.arrow_upward,
                          onPressed: () => changeDirection('up')),
                      DirectionButton(
                          icon: Icons.arrow_back,
                          onPressed: () => changeDirection('left')),
                      DirectionButton(
                          icon: Icons.arrow_forward,
                          onPressed: () => changeDirection('right')),
                      DirectionButton(
                          icon: Icons.arrow_downward,
                          onPressed: () => changeDirection('down')),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= MOBILE LAYOUT (keep your existing) =================
  final gridSize = MediaQuery.of(context).size.width * 2; // square grid
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 208, 207, 207),
    body: SafeArea(
      child: Column(
        children: [
          // Top row: Home button + Score
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.home,
                        color: Color.fromARGB(255, 170, 2, 2), size: 30),
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => gamesKidScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        color: const Color.fromARGB(255, 203, 43, 43), size: 28),
                    const SizedBox(width: 8),
                    Text('Score: $score',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Game area
          Expanded(
            child: Center(
              child: Container(
                width: gridSize,
                height: gridSize,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                  ),
                  itemCount: rowCount * columnCount,
                  itemBuilder: (context, index) {
                    final x = index % columnCount;
                    final y = index ~/ columnCount;
                    final point = Point(x, y);

                    Color color;
                    if (snake.contains(point)) {
                      color = Colors.green;
                    } else if (point == food) {
                      color = Colors.red;
                    } else {
                      color = Colors.grey[700]!;
                    }

                    return Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Direction buttons
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DirectionButton(
                      icon: Icons.arrow_upward,
                      onPressed: () => changeDirection('up')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DirectionButton(
                      icon: Icons.arrow_back,
                      onPressed: () => changeDirection('left')),
                  const SizedBox(width: 20),
                  DirectionButton(
                      icon: Icons.arrow_forward,
                      onPressed: () => changeDirection('right')),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DirectionButton(
                      icon: Icons.arrow_downward,
                      onPressed: () => changeDirection('down')),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}


class DirectionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const DirectionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(60, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Icon(icon, size: 30),
    );
  }
}