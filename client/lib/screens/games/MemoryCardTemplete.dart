


import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/games/gameSupervisor.dart';
import 'dart:io' show Platform;




// ================= PAGE =================
class MemoryTemplate extends StatefulWidget {
  const MemoryTemplate({super.key});

  @override
  State<MemoryTemplate> createState() => _MemoryTemplateState();
}

class _MemoryTemplateState extends State<MemoryTemplate> {
  List<dynamic> games = [];
  bool loading = true;
  String? userId;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    fetchGames();
  }

  // ================= FETCH GAMES =================
  Future<void> fetchGames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    userId = JwtDecoder.decode(token)['id'];

    final res = await http.get(
      Uri.parse('${getBackendUrl()}/api/game/getGameBySupervisor/$userId'),
    );

    if (res.statusCode == 200) {
      final List allGames = jsonDecode(res.body);

      setState(() {
        // ✅ show only Grid Words games
        games = allGames
            .where((g) => g['type'] == 'Memory' && g['name'] == 'Memory Cards')
            .toList();

        loading = false;
      });
    }
  }

  // ================= TOGGLE PUBLISH =================
  Future<void> togglePublish(int index) async {
    final game = games[index];
    final bool current = game['isPublished'] ?? false;
    final bool newStatus = !current;

    setState(() {
      games[index]['isPublished'] = newStatus; // Optimistic UI
    });

    try {
      final res = await http.put(
        Uri.parse('${getBackendUrl()}/api/game/publishGame/${game['_id']}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isPublished': newStatus}),
      );

      if (res.statusCode != 200) {
        // rollback
        setState(() {
          games[index]['isPublished'] = current;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update publish status")),
        );
      }
    } catch (e) {
      setState(() {
        games[index]['isPublished'] = current;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= DELETE GAME =================
  Future<void> deleteGame(int index) async {
    final game = games[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Game"),
        content: const Text("Are you sure you want to delete this game?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await http.delete(
        Uri.parse('${getBackendUrl()}/api/game/deleteGameById/${game['_id']}'),
      );

      if (res.statusCode == 200) {
        setState(() {
          games.removeAt(index); // remove from UI
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Game deleted successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete game")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= BUILD =================
//   @override
//   Widget build(BuildContext context) {
//  return Scaffold(
//   body: HomePage(
//     title: "Grid Words Games",
//     child: loading
//         ? const Center(child: CircularProgressIndicator())
//         : Stack(
//             children: [
//               _buildGrid(), // your grid view

//               // Add button slightly above bottom
//               Positioned(
//                 bottom: 20, // distance from bottom
//                 right: 16,  // distance from right
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color.fromARGB(255, 223, 159, 30),
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 20),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     elevation: 6,
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.add, size: 24, color:Colors.white),
//                       SizedBox(width: 6),
//                       Text("Create Game", style: TextStyle(fontSize: 16 , color:Colors.white)),
//                     ],
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const MemoryGameSetupScreen()),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//   ),
// );

//   }



@override
Widget build(BuildContext context) {
  bool isWebLayout = kIsWeb || MediaQuery.of(context).size.width > 800;

  return Scaffold(
    body: HomePage(
      title: "Memory Cards Games",
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : isWebLayout
              ? _buildWebBody() // Web layout
              : _buildMobileGrid(), // ⚡ Exact same mobile design
    ),
  );
}

// ================= MOBILE LAYOUT =================
// This stays exactly as your original mobile design
Widget _buildMobileGrid() {
  if (games.isEmpty) {
    return const Center(
      child: Text("No Memory Card Games Yet", style: TextStyle(fontSize: 18)),
    );
  }

  return Stack(
    children: [
      // Grid of games
      Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: games.length,
          itemBuilder: (context, i) {
            final g = games[i];
            final bool published = g['isPublished'] ?? false;
            return _gameCard(g, published, i);
          },
        ),
      ),

      // Create Game button at bottom
      Positioned(
        bottom: 16,
        right: 16,
        child: _buildCreateGameButton(),
      ),
    ],
  );
}


// ================= WEB LAYOUT =================
Widget _buildWebBody() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + instructions
        Text(
          "Memory Cards Games",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          "Select a game to play or create a new one",
          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
        ),
        const SizedBox(height: 24),

        // Create Game button on top right
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildCreateGameButton(),
          ],
        ),
        const SizedBox(height: 16),

        // Games grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              double totalWidth = constraints.maxWidth;
              int columns = 4; // 2 games per row
              double spacing = 24;
              double itemWidth = (totalWidth - (columns - 1) * spacing) / columns;
              double itemHeight = itemWidth * 0.8; // proportional for web

              return GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemCount: games.length,
                itemBuilder: (context, i) {
                  final g = games[i];
                  final bool published = g['isPublished'] ?? false;

                  return SizedBox(
                    height: itemHeight,
                    child: _gameCard(g, published, i),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

// ================= CREATE GAME BUTTON =================
Widget _buildCreateGameButton() {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 202, 139, 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.add, size: 24, color: Colors.white),
        SizedBox(width: 6),
        Text("Create Game", style: TextStyle(fontSize: 16, color: Colors.white)),
      ],
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MemoryGameSetupScreen()),
      );
    },
  );
}

  // ================= GRID VIEW =================
//   Widget _buildGrid() {
//     if (games.isEmpty) {
//       return const Center(
//         child: Text(
//           "No Memory Card Games Yet",
//           style: TextStyle(fontSize: 18),
//         ),
//       );
//     }

//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         childAspectRatio: 0.9,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//       ),
//       itemCount: games.length,
//       itemBuilder: (context, i) {
//         final g = games[i];
//         final bool published = g['isPublished'] ?? false;

//         return _gameCard(g, published, i);
//       },
//     );
//   }

//   // ================= GAME CARD =================
//   Widget _gameCard(Map<String, dynamic> g, bool published, int index) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             g['name'] ?? "Grid Words",
//             style: const TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             "Theme: ${g['theme']}",
//             style: TextStyle(color: Colors.grey[600]),
//           ),
//           const Spacer(),

    

//           const SizedBox(height: 8),

//           // Publish switch + Delete button
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   const Text("Published"),
//                   Switch(
//                     value: published,
//                     activeColor: const Color.fromARGB(255, 199, 140, 21),
//                     onChanged: (_) => togglePublish(index),
//                   ),
//                 ],
//               ),
//               IconButton(
//                 icon: const Icon(Icons.delete, color: Color.fromARGB(255, 200, 140, 19)),
//                 onPressed: () => deleteGame(index),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
  // ================= GRID VIEW =================
  // Widget _buildGrid() {
  //   if (games.isEmpty) {
  //     return const Center(
  //       child: Text(
  //         "No Grid Games Yet",
  //         style: TextStyle(fontSize: 18),
  //       ),
  //     );
  //   }

  //   return GridView.builder(
  //     padding: const EdgeInsets.all(16),
  //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //       crossAxisCount: 2,
  //       childAspectRatio: 0.9,
  //       crossAxisSpacing: 16,
  //       mainAxisSpacing: 16,
  //     ),
  //     itemCount: games.length,
  //     itemBuilder: (context, i) {
  //       final g = games[i];
  //       final bool published = g['isPublished'] ?? false;

  //       return _gameCard(g, published, i);
  //     },
  //   );
  // }

  // ================= GAME CARD =================
  Widget _gameCard(Map<String, dynamic> g, bool published, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            g['name'] ?? "Meomory Cardss",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Theme: ${g['theme']}",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Spacer(),

    

          const SizedBox(height: 8),

          // Publish switch + Delete button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Published"),
                  Switch(
                    value: published,
                    activeColor: const Color.fromARGB(255, 206, 149, 35),
                    onChanged: (_) => togglePublish(index),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color.fromARGB(255, 213, 149, 20)),
                onPressed: () => deleteGame(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MemoryGameSetupScreen extends StatefulWidget {
  const MemoryGameSetupScreen({super.key});

  @override
  State<MemoryGameSetupScreen> createState() => _MemoryGameSetupScreenState();
}

class _MemoryGameSetupScreenState extends State<MemoryGameSetupScreen> {
  final levelsCtrl = TextEditingController(text: "1");
  final trialCtrl = TextEditingController(text: "3");
  final scoreCtrl = TextEditingController(text: "10");
  final timeCtrl = TextEditingController(text: "5");

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Memory Game Setup",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "🎨 Memory Game Settings",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          color: const Color.fromARGB(255, 197, 137, 16),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Set up your color memory adventure!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 37),

                  // Levels
                  TextFormField(
                    controller: levelsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of Levels",
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.layers, color: Color.fromARGB(255, 206, 151, 41)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Trials
                  TextFormField(
                    controller: trialCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of Trials Allowed",
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.help_outline, color: Color.fromARGB(255, 216, 149, 16)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Score per Level
                  TextFormField(
                    controller: scoreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Score Per Match",
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.star, color: Color.fromARGB(255, 220, 153, 20)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Time per Level
                  TextFormField(
                    controller: timeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Time Per Level (Minutes)",
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.timer, color: Color.fromARGB(255, 218, 149, 12)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Next Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 231, 167, 39),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 6,
                    ),
                    child: const Text(
                      "Next ➜",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      final levels = int.tryParse(levelsCtrl.text) ?? 1;
                      final trials = int.tryParse(trialCtrl.text) ?? 3;
                      final score = int.tryParse(scoreCtrl.text) ?? 10;
                      final timePerLevel = int.tryParse(timeCtrl.text) ?? 5;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MemoryCreatorScreen(
                            levels: levels,
                            gameTrial: trials,
                            gameScore: score,
                            timePerLevel: timePerLevel,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= PAGE: CREATE MEMORY GAME =================
class MemoryCreatorScreen extends StatefulWidget {
  final int? gameTrial;
  final int? gameScore;
  final int levels;
  final int? timePerLevel;

  const MemoryCreatorScreen({
    super.key,
    required this.levels,
    this.gameTrial,
    this.gameScore,
    this.timePerLevel,
  });

  @override
  State<MemoryCreatorScreen> createState() => _MemoryCreatorScreenState();
}

class _MemoryCreatorScreenState extends State<MemoryCreatorScreen> {
  static const int maxColorsPerLevel = 10;

  List<Map<String, dynamic>> gameInputs = [];
  Map<int, List<TextEditingController>> levelColorCtrls = {};
  int currentLevel = 0;
  final TextEditingController colorCountCtrl = TextEditingController();

  List<String> suggestedColors = [
    "Red", "Green", "Blue", "Yellow", "Orange",
    "Purple", "Cyan", "Pink", "Brown", "Gray"
  ];

  String? userId;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Theme.of(context).platform == TargetPlatform.android) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    levelColorCtrls[currentLevel] = [];
  }

  void _updateColorCount(int count) {
    if (count > maxColorsPerLevel) {
      _error("Maximum $maxColorsPerLevel colors per level");
      return;
    }
    setState(() {
      final ctrls = levelColorCtrls[currentLevel]!;
      if (ctrls.length < count) {
        ctrls.addAll(List.generate(count - ctrls.length, (_) => TextEditingController()));
      } else if (ctrls.length > count) {
        levelColorCtrls[currentLevel] = ctrls.sublist(0, count);
      }
    });
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void saveLevel() {
    final ctrls = levelColorCtrls[currentLevel]!;
    if (ctrls.isEmpty) return _error("Enter number of colors");

    final colors = ctrls.map((c) => c.text.trim()).toList();
    if (colors.any((c) => c.isEmpty)) return _error("Please fill all color names");

    gameInputs.add({
      "level": currentLevel + 1,
      "correctAnswer": List<String>.from(colors),
      "text": [],
      "image": [],
      "lettersClue": [],
    });

    colorCountCtrl.clear();
    _updateColorCount(0);
  }

  Future<bool> submitGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    userId = JwtDecoder.decode(token)['id'];

    try {
      final response = await http.post(
        Uri.parse('${getBackendUrl()}/api/game/createGame'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": "Memory Cards",
          "type": "Memory",
          "ageGroup": "5-8",
          "theme": "Colors",
          "createdBy": userId,
          "input": gameInputs,
          "isPublished": false,
          "maxTrials": widget.gameTrial ?? 3,
          "timePerQuestionMin": widget.timePerLevel,
          "scorePerQuestion": widget.gameScore ?? 1,
          "Image": [],
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Game created successfully 🎉")));
        return true;
      } else {
        _error("Failed to create game");
        return false;
      }
    } catch (e) {
      _error("Error: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrls = levelColorCtrls.putIfAbsent(currentLevel, () => []);

    return HomePage(
      title: "Memory Game (Level ${currentLevel + 1})",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Suggested Colors:",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: suggestedColors.map((c) => ActionChip(
                      label: Text(c),
                      onPressed: () {
                        if (ctrls.isEmpty) return;
                        ctrls[0].text = c;
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: colorCountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of colors (max $maxColorsPerLevel)",
                      filled: true,
                      fillColor: Colors.orange.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                    onChanged: (v) {
                      final n = int.tryParse(v) ?? 0;
                      _updateColorCount(n);
                    },
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(ctrls.length, (i) {
                      return SizedBox(
                        width: 140,
                        child: TextField(
                          controller: ctrls[i],
                          decoration: InputDecoration(
                            labelText: "Color ${i + 1}",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentLevel == widget.levels - 1 ? const Color.fromARGB(255, 178, 125, 17) : const Color.fromARGB(255, 224, 162, 37),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 6,
                    ),
                    child: Text(
                      currentLevel == widget.levels - 1 ? "Create Game" : "Next",
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    onPressed: () async {
                      saveLevel();
                      if (currentLevel == widget.levels - 1) {
                        final success = await submitGame();
                        if (success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => GamesHomePage()),
                          );
                        }
                      } else {
                        setState(() {
                          currentLevel++;
                          levelColorCtrls.putIfAbsent(currentLevel, () => []);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
