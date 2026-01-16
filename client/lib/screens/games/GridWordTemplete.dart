


import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bright_minds/widgets/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/screens/gameSupervisor.dart';

// ================= ENUMS =================
enum GameTheme {
  Animals,
  Fruits_Vegetables,
  Furniture,
  Places_Locations,
  Actions_Verbs,
  Transportation,
  Sports_Games,
  Technology_Basics,
  Space_Astronomy,
  Occupations_Jobs,
  Body_Parts,
  Weather_Seasons
}

String themeName(GameTheme g) {
  switch (g) {
    case GameTheme.Animals:
      return "Animals";
    case GameTheme.Fruits_Vegetables:
      return "Fruits & Vegetables";
    case GameTheme.Furniture:
      return "Furniture";
    case GameTheme.Places_Locations:
      return "Places & Locations";
    case GameTheme.Actions_Verbs:
      return "Actions & Verbs";
    case GameTheme.Transportation:
      return "Transportation";
    case GameTheme.Sports_Games:
      return "Sports & Games";
    case GameTheme.Technology_Basics:
      return "Technology Basics";
    case GameTheme.Space_Astronomy:
      return "Space & Astronomy";
    case GameTheme.Occupations_Jobs:
      return "Occupations & Jobs";
    case GameTheme.Body_Parts:
      return "Body Parts";
    case GameTheme.Weather_Seasons:
      return "Weather & Seasons";
  }
}



// ================= PAGE =================
class GridWordTemplate extends StatefulWidget {
  const GridWordTemplate({super.key});

  @override
  State<GridWordTemplate> createState() => _GridWordTemplateState();
}

class _GridWordTemplateState extends State<GridWordTemplate> {
  List<dynamic> games = [];
  bool loading = true;
  String? userId;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
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
            .where((g) => g['type'] == 'Grid' && g['name'] == 'Grid Words')
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
  @override
  Widget build(BuildContext context) {
 return Scaffold(
  body: HomePage(
    title: "Grid Words Games",
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              _buildGrid(), // your grid view

              // Add button slightly above bottom
              Positioned(
                bottom: 20, // distance from bottom
                right: 16,  // distance from right
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bgBlushRoseDark,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 24),
                      SizedBox(width: 6),
                      Text("Create Game", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GridSetupScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
  ),
);

  }

  // ================= GRID VIEW =================
  Widget _buildGrid() {
    if (games.isEmpty) {
      return const Center(
        child: Text(
          "No Grid Games Yet",
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
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
    );
  }

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
            g['name'] ?? "Grid Words",
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
                    activeColor: AppColors.bgBlushRoseVeryDark,
                    onChanged: (_) => togglePublish(index),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteGame(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



class GridSetupScreen extends StatefulWidget {
  const GridSetupScreen({super.key});

  @override
  State<GridSetupScreen> createState() => _GridSetupScreenState();
}

class _GridSetupScreenState extends State<GridSetupScreen> {
  final levelsCtrl = TextEditingController(text: " ");
  final trailCtrl = TextEditingController(text: " ");
  final scoreCtrl = TextEditingController(text: " ");
  final timeCtrl = TextEditingController(text: " ");

  GameTheme selectedTheme =GameTheme.Animals;

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000"; // replace with your network IP
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }


@override
Widget build(BuildContext context) {
  return HomePage(
    title: "Game Setup",
    child: Padding(
      padding: const EdgeInsets.all(16),
     // child:Center(
      child: SingleChildScrollView(
        child:Center (
        child: Container(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🎮 Title
              Text(
                "🎮 Game Settings",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize:32,
                      color: AppColors.bgBlushRoseVeryDark,
                    ),
              ),

              const SizedBox(height: 8),

              Text(
                "Set up your word adventure!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600],
                fontSize: 16,
                  fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 37),



      


              // 🔢 Number of Levels
              TextFormField(
                controller: levelsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Number of Levels ",
                   labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,

                  ) ,
                  filled: true,
                  fillColor: Colors.orange.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      const Icon(Icons.layers, color: AppColors.bgBlushRoseDark),
                ),
              ),

              const SizedBox(height: 30),


              // 🎨 Theme Selector
              InputDecorator(
                decoration: InputDecoration(
                  labelText: "Choose Theme",
                    labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,

                  ) ,
                  filled: true,
                  fillColor: Colors.orange.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      const Icon(Icons.palette, color: AppColors.bgWarmPinkVeryDark),
                ),
             
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<GameTheme>(
                   menuMaxHeight: 300,
                    isExpanded: true,
                    value: selectedTheme,
                    items: GameTheme.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(themeName(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedTheme = v!),
                  ),
                ),
             
              ),




              const SizedBox(height: 30),

              TextFormField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Score Per Level",
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ) ,
                  filled: true,
                  fillColor: Colors.orange.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      const Icon(Icons.help_outline, color: AppColors.bgBlushRoseVeryDark),
                ),
              ),

              const SizedBox(height: 30),







             // ❓ Questions per Level
              TextFormField(
                controller: timeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Time Per Level",
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ) ,
                  filled: true,
                  fillColor: Colors.orange.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      const Icon(Icons.help_outline, color: AppColors.bgBlushRoseVeryDark),
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: trailCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Number of Trials Allowed",
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,

                  ) ,
                  filled: true,
                  fillColor: Colors.orange.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon:
                      const Icon(Icons.help_outline, color: AppColors.bgBlushRoseVeryDark),
                ),
              ),


              const SizedBox(height: 30),

              // ➜ Next Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgBlushRoseDark,
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
                  final int? levels = int.tryParse(levelsCtrl.text);

                  if (levels == null || levels < 1 ) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("At least 1 question per level is required"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GridCreatorScreen(
                        levels: levels,
                        theme: selectedTheme,
                        gameTrial: int.tryParse(trailCtrl.text),
                        gameScore: int.tryParse(scoreCtrl.text),
                        timePerLevel: int.tryParse(timeCtrl.text),
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
     // ),
    ),
  );
}
}















// ================= PAGE: CREATE GRID GAME =================
class GridCreatorScreen extends StatefulWidget {
  final GameTheme theme;
  final int? gameTrial;
  final int? gameScore;
  final int levels;
  final int? timePerLevel;

  const GridCreatorScreen({
    super.key,
    required this.theme,
    required this.gameTrial,
    required this.gameScore,
    required this.levels,
    required this.timePerLevel,
  });

  @override
  State<GridCreatorScreen> createState() => _GridCreatorScreenState();
}




class _GridCreatorScreenState extends State<GridCreatorScreen> {


  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }


  static const int maxGridWords = 10;

  final TextEditingController gridCountCtrl = TextEditingController();
  int gridWordCount = 0;
  List<TextEditingController> gridWordCtrls = [];

  List<String> words = []; // suggested words from backend
  bool isFetchingWords = false;
  String? userId;

  // Store words separately for each level
  Map<int, List<TextEditingController>> levelWordCtrls = {};

  List<Map<String, dynamic>> gameInputs = [];

  int currentLevel = 0;

  @override
  void initState() {
    super.initState();
    // initialize controller list for level 0
    levelWordCtrls[0] = [];
    fetchWordsForCurrentLevel();
  }


  Future<void> fetchWordsForCurrentLevel() async {
    setState(() => isFetchingWords = true);
    final theme = widget.theme.name;
    final result = await fetchWordsSuggestion(theme, "9-12");
    if (result != null) {
      setState(() {
        words = result['words'] ?? [];
      });
    }
    setState(() => isFetchingWords = false);
  }


  void _updateGridWordCount(int count) {
    if (count > maxGridWords) {
      _error("Maximum $maxGridWords words allowed in word grid");
      return;
    }

    setState(() {
      gridWordCount = count;

      final ctrls = levelWordCtrls[currentLevel]!;
      if (ctrls.length < count) {
        ctrls.addAll(
          List.generate(count - ctrls.length, (_) => TextEditingController()),
        );
      } else if (ctrls.length > count) {
        levelWordCtrls[currentLevel] = ctrls.sublist(0, count);
      }
    });
  }


  void _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  
 void save() {
  final ctrls = levelWordCtrls[currentLevel]!;
  if (ctrls.isEmpty) {
    _error("Enter number of words");
    return;
  }

  // Save the current words as a separate list
  final gridWords = ctrls.map((c) => c.text.trim()).toList();

  if (gridWords.any((w) => w.isEmpty)) {
    _error("Please fill all grid words");
    return;
  }

  // Store a copy of the words for this level
  gameInputs.add({
    "level": currentLevel + 1, // optional, for clarity
    "correctAnswer": List<String>.from(gridWords),
  });

  // Clear only the input fields, not the controllers for previous levels
  gridCountCtrl.clear();
  gridWordCount = 0;

  setState(() {});
}


  Future<Map<String, dynamic>?> fetchWordsSuggestion(
      String theme, String ageGroup) async {
    try {
      final response = await http.post(
        Uri.parse('${getBackendUrl()}/api/game/generateThemeWords'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'theme': theme, 'ageGroup': ageGroup}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        words = List<String>.from(data['words'] ?? []);
        return {'words': words};
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching words: $e");
      return null;
    }
  }
  Future<bool> submitGameToBackend() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    userId = JwtDecoder.decode(token)['id'];

    try {
      final response = await http.post(
        Uri.parse('${getBackendUrl()}/api/game/createGame'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": "Grid Words",
          "type": "Grid",
          "ageGroup": "9-12",
          "theme": widget.theme.name,
          "createdBy": userId,
          "input": gameInputs,
          "isPublished": false,
          "maxTrials": widget.gameTrial ?? 3,
          "timePerQuestionMin": widget.timePerLevel,
          "scorePerQuestion": widget.gameScore ?? 1,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Game created successfully 🎉")),
        );
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
    final ctrls = levelWordCtrls.putIfAbsent(currentLevel, () => []);

    return HomePage(
      title: "Grid Words (Level ${currentLevel + 1})",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (words.isNotEmpty) ...[
                const Text(
                  "Suggested Words:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: words.map((w) {
                    return ActionChip(
                      label: Text(w),
                      onPressed: () {
                        if (ctrls.isEmpty) return;
                        ctrls[0].text = w;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              TextField(
                controller: gridCountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Number of words (max $maxGridWords)",
                  filled: true,
                  fillColor: Colors.white70,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) {
                  final n = int.tryParse(v) ?? 0;
                  _updateGridWordCount(n);
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
                        labelText: "Word ${i + 1}",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentLevel == widget.levels - 1
                      ? Colors.green
                      : AppColors.bgBlushRoseVeryDark,
                ),
                child: Text(
                  currentLevel == widget.levels - 1 ? "Create Game" : "Next",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                onPressed: () async {
                  save(); // save current level

                  if (currentLevel == widget.levels - 1) {
                    final success = await submitGameToBackend();
                    if (success && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GamesHomePage(),
                        ),
                      );
                    }
                  } else {
                    setState(() {
                      currentLevel++;
                      levelWordCtrls.putIfAbsent(currentLevel, () => []);
                      fetchWordsForCurrentLevel();
                    });
                  }
                },
              ),
              if (isFetchingWords)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
