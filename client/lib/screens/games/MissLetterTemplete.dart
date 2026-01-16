

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

enum LevelType {
  oneMissing,
  twoMissing,
  allMissing,
}

String levelName(LevelType type) {
  switch (type) {
    case LevelType.oneMissing:
      return "One Missing Letter";
    case LevelType.twoMissing:
      return "Two Missing Letters";
    case LevelType.allMissing:
      return "All Letters Missing";
  }
}




String themeName(GameTheme g){
  switch(g){

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
class MissLetterTemplate extends StatefulWidget {
  const MissLetterTemplate({super.key});

  @override
  State<MissLetterTemplate> createState() => _MissLetterTemplateState();
}

class _MissLetterTemplateState extends State<MissLetterTemplate> {
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
            .where((g) => g['type'] == 'MissLetters' && g['name'] == 'Miss Letters')
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
                          builder: (_) => const MissLetterSetupScreen ()),
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

// ================= PAGE 1: GAME SETUP =================
class MissLetterSetupScreen extends StatefulWidget {
  const MissLetterSetupScreen({super.key});

  @override
  State<MissLetterSetupScreen> createState() => _MissLetterSetupScreenState();
}

class _MissLetterSetupScreenState extends State<MissLetterSetupScreen> {
  final levelsCtrl = TextEditingController(text: " ");
  final questionsCtrl = TextEditingController(text: " ");
  final trailCtrl = TextEditingController(text: " ");
  final scoreCtrl = TextEditingController(text: " ");


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

              // ❓ Questions per Level
              TextFormField(
                controller: questionsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Questions per Level",
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

              // ❓ Questions per Level
              TextFormField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Score Per Question",
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
                  final int? questions = int.tryParse(questionsCtrl.text);

                  if (levels == null || levels < 1 ) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("At least 1 question per level is required"),
                      ),
                    );
                    return;
                  }

                  if (questions == null || questions < 1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("At least 1 question per level is required"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LevelTypeScreen(
                        levels: levels,
                        questionsPerLevel: questions,
                        theme: selectedTheme,
                        gameTrial: int.tryParse(trailCtrl.text),
                        gameScore: int.tryParse(scoreCtrl.text),

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


// ================= PAGE 2: CHOOSE LEVEL TYPES =================
class LevelTypeScreen extends StatefulWidget {
  final int levels;
  final int questionsPerLevel;
  final GameTheme theme;
  final int? gameTrial;
  final int? gameScore;

  const LevelTypeScreen({
    super.key,
    required this.levels,
    required this.questionsPerLevel,
    required this.theme,
    required this.gameTrial,
    required this.gameScore,  
  });

  @override
  State<LevelTypeScreen> createState() => _LevelTypeScreenState();
}

class _LevelTypeScreenState extends State<LevelTypeScreen> {
  late List<LevelType> types;

  @override
  void initState() {
    super.initState();
    types = List.generate(widget.levels, (_) => LevelType.oneMissing);
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Choose Level Types",
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
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
              children: [
                // 🎯 Title
                Text(
                  "🧩 Levels Types",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: AppColors.bgBlushRoseVeryDark,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  "Choose how each level works",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // 📜 Levels list
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.levels,
                    itemBuilder: (_, i) {
                      return Card(
                        color:AppColors.bgWarmPinkVeryLight,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.bgBlushRoseVeryDark,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          title: Text(
                            "Level ${i + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: DropdownButton<LevelType>(
                            value: types[i],
                            underline: const SizedBox(),
                            items: LevelType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(levelName(t)),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => types[i] = v!),
                          ),
                        ),
                      );
                    },
                  ),
                ),

               

                // ⬅ ➡ Navigation arrows
                Row(
                  children: [
                    // ⬅ Back
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back ,  color:Colors.white , size:20),
                        label: const Text(
                          "Back",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.bgBlushRoseDark,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ➡ Next
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.bgBlushRoseDark,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MissLetterCreatorScreen(
                                levelTypes: types,
                                questionsPerLevel:  widget.questionsPerLevel,
                              theme: widget.theme,    
                              gameTrial: widget.gameTrial,
                              gameScore: widget.gameScore,
                              ),
                            ),
                          );
                        },

                      
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                           children: const [
                               Text(
                            "Next",
                            style: TextStyle(
                             fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                                ),
                             ),
                             SizedBox(width: 8),
                           Icon(
                           Icons.arrow_forward,
                         color: Colors.white,
                            size: 20,
                             ),
                             ],
                          ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}








// // ================= PAGE 3: CREATE QUESTIONS =================
class MissLetterCreatorScreen extends StatefulWidget {
  final List<LevelType> levelTypes;
  final int questionsPerLevel;
  final GameTheme theme ;
   final int? gameTrial;
  final int? gameScore;

  const MissLetterCreatorScreen({
    super.key,
    required this.levelTypes,
    required this.questionsPerLevel,
    required this.theme,
    required this.gameTrial,
    required this.gameScore,
  });

  @override
  State<MissLetterCreatorScreen> createState() => _GameCreatorScreenState();
}



class _GameCreatorScreenState extends State<MissLetterCreatorScreen> {
  final TextEditingController wordCtrl = TextEditingController();
  final TextEditingController clueCtrl = TextEditingController();
  final TextEditingController clueCtrl1 = TextEditingController(); // picture clue 1
  final TextEditingController clueCtrl2 = TextEditingController(); // picture clue 2
  
  bool isFetchingClue1Images = false;
  bool isFetchingClue2Images = false;
  List<String> clue1Images = [];
  List<String> clue2Images = [];
  String? selectedClue1Image;
  String? selectedClue2Image;
  static const int maxGridWords = 10;

int gridWordCount = 0;
final TextEditingController gridCountCtrl = TextEditingController();
List<TextEditingController> gridWordCtrls = [];

  final alphabet = List.generate(26, (i) => String.fromCharCode(97 + i));
  final List<int> missing = [];
  final List<String> choices = [];

  List<String> words = [];


  int currentLevel = 0;
  int currentQuestion = 0;
  bool isLoadingClue = false;
  bool isFetchingWords = false;

  List<Map<String, dynamic>> gameInputs = [];
    String? userId;


  @override
  void initState() {
    super.initState();
    fetchWordsForCurrentLevel();
    
  }



  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }








Future<Map<String, dynamic>?> fetchWordsSuggestion(String theme, String ageGroup) async {   
   try {
      final response = await http.post(
        Uri.parse('${getBackendUrl()}/api/game/generateThemeWords'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'theme': theme, 'ageGroup': ageGroup}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        words = List<String>.from(data['words']);
        print("words are : $words");


   
      return {
        'words': words,
   
      };
    } else {
   print("words are :  null");
      return null;
    }
  } catch (e) {
    print("Error fetching words: $e");
    return null;
  }
}



 
  Future<void> fetchWordsForCurrentLevel() async {
    setState(() => isFetchingWords = true);
    final theme = widget.theme.name; // assuming GameTheme has a name
    final result = await fetchWordsSuggestion(theme, "9-12");
    if (result != null) {
      setState(() {
        words = result['words'] ?? [];
      });
    }
    setState(() => isFetchingWords = false);
  }

  //// ================= Test =================
  List<String?> buildMaskedText(String word, List<int> missing) {
  return List.generate(word.length, (i) {
    return missing.contains(i) ? "-" : word[i];
  });
}

List<String?> buildMissingAnswers(String word, List<int> missing) {
  return List.generate(word.length, (i) {
    return missing.contains(i) ? word[i] : null;
  });
}


// ================= validate missing letters =================

bool validateAndFixMissingLetters(
  LevelType type,
  String word,
) {

  if (type == LevelType.oneMissing) {
    if (missing.length != 1) {
      _error("Please select exactly ONE missing letter");
      return false;
    }
  }

  // twoMissing → exactly 2
  if (type == LevelType.twoMissing) {
    if (missing.length != 2) {
      _error("Please select exactly TWO missing letters");
      return false;
    }
  }

  return true;
}



  // ================= SAVE QUESTION =================


void save() async {
  final word = wordCtrl.text.trim().toLowerCase();
  final type = widget.levelTypes[currentLevel];
  String? clueText = clueCtrl.text.trim().isEmpty ? null : clueCtrl.text.trim();
  List<String>? images;


    if (word.isEmpty) {
      _error("Enter a word");
      return;
    }
  



  // ---------------- Validate missing letters ----------------
  if (!validateAndFixMissingLetters(type, word)) {
    return;
  }

  final level = currentLevel + 1;

  Map<String, dynamic> question = {
    "level": level,
    "type": type.name,
  };

  if (type == LevelType.oneMissing ||
      type == LevelType.twoMissing ||
      type == LevelType.allMissing) {
    question.addAll({
      "text": buildMaskedText(word, missing),
      "correctAnswer": buildMissingAnswers(word, missing),
      "lettersClue": List.from(choices),
      "clue": null,
      "image": [],
    });
  }





  // ---------------- Save question ----------------
  gameInputs.add(question);

  // ---------------- Clear UI ----------------
  wordCtrl.clear();
  clueCtrl.clear();
  clueCtrl1.clear();
  clueCtrl2.clear();
  missing.clear();
  choices.clear();

  setState(() {}); // refresh UI
}


  // ================= Submit Game =================

Future<bool> submitGameToBackend() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String token = prefs.getString("token") ?? "";

  Map<String,dynamic> decodedToken = JwtDecoder.decode(token);
  userId = decodedToken['id'];

  try {
    final response = await http.post(
      Uri.parse('${getBackendUrl()}/api/game/createGame'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": "Guess The Word",
        "type": "Guessing",
        "ageGroup": "9-12",
        "theme": widget.theme.name,
        "createdBy": userId,
        "input": gameInputs,
        "isPublished": false,
        "maxTrials": widget.gameTrial ?? 3,
      "timePerLevelMin": 100000,
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

 // ================= auto-select letters =================

void autoSelectLettersIfNeeded(String word) {
  final type = widget.levelTypes[currentLevel];

  if (type == LevelType.allMissing) {

    setState(() {
      missing
        ..clear()
        ..addAll(List.generate(word.length, (i) => i));
    });
  }
}


bool showClueFirst = true; 

@override
Widget build(BuildContext context) {
  final word = wordCtrl.text;
  final type = widget.levelTypes[currentLevel];

  return HomePage(
    title: "${levelName(type)} (Q${currentQuestion + 1})",
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [



// ================= WORD INPUT =================
TextField(
  controller: wordCtrl,
  decoration: InputDecoration(
    labelText: "Word",
    hintText: "Enter the Word",
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
),
const SizedBox(height: 12),

// ================= WORD SUGGESTIONS (ALL LEVELS) =================
if (words.isNotEmpty ) ...[
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
          wordCtrl.text = w; // auto-fill word
        },
      );
    }).toList(),
  ),
  const SizedBox(height: 12),
],



        


            const SizedBox(height: 12),
            if (isLoadingClue || isFetchingWords)
              const Center(child: CircularProgressIndicator()),

            // ------------------ ALPHABET CHOICES ------------------
            // ✅ NOT SHOWN for grid
            if ( word.isNotEmpty   )
            const Text(
    "Select the missing letters",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  const SizedBox(height: 6),

              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(word.length, (i) {
                  return ChoiceChip(
                    label: Text(word[i]),
                    selected: missing.contains(i),
                    onSelected: (_) {
                      setState(() {
                        missing.contains(i)
                            ? missing.remove(i)
                            : missing.add(i);
                      });
                    },
                  );
                }),
              ),

       
             const Text(
    "Select letter choices",
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),
  const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: alphabet.map((l) {
                  return ChoiceChip(
                    label: Text(l),
                    selected: choices.contains(l),
                    onSelected: (_) {
                      setState(() {
                        choices.contains(l)
                            ? choices.remove(l)
                            : choices.add(l);
                      });
                    },
                  );
                }).toList(),
              ),
          
            const SizedBox(height: 16),
 


const SizedBox(height: 16),


   

// ------------------ NAVIGATION BUTTONS ------------------
if (currentLevel == widget.levelTypes.length - 1 &&
    currentQuestion + 1 == widget.questionsPerLevel)
  // Last question of last level → Create Game
  ElevatedButton(
    onPressed: () async {
      // Validate missing letters BEFORE saving
      final type = widget.levelTypes[currentLevel];
      final word = wordCtrl.text.trim();
      if (!validateAndFixMissingLetters(type, word)) return;

      save(); // save last question

      // Submit game
      final success = await submitGameToBackend();

      // Navigate only if submission was successful
      if (success && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GamesHomePage()),
        );
      }
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
    ),
    child: const Text("Create Game"),
  )
else
  // All other questions → Next
  ElevatedButton(
    onPressed: () async {
      // Validate missing letters BEFORE saving
      final type = widget.levelTypes[currentLevel];
      final word = wordCtrl.text.trim();
      if (!validateAndFixMissingLetters(type, word)) return;

      save(); // save current question

      // Go to next question
      setState(() {
        currentQuestion++;

        // Move to next level if last question of current level
        if (currentQuestion >= widget.questionsPerLevel) {
          currentQuestion = 0;
          currentLevel++;
          fetchWordsForCurrentLevel();
        }
      });
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.bgBlushRoseVeryDark,
    ),
    child: const Text("Next"),
  ),






          ],
        ),
      ),
    ),
  );
   }




}



