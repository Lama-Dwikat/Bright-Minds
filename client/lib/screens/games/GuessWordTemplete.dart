

import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bright_minds/widgets/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/screens/games/gameSupervisor.dart';


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
  textClues,
  pictureClues,
}

String levelName(LevelType type) {
  switch (type) {

    case LevelType.textClues:
      return "Text Clue ";
    case LevelType.pictureClues:
      return "Picture Clues";
   
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
class GuessTemplate extends StatefulWidget {
  const GuessTemplate({super.key});

  @override
  State<GuessTemplate> createState() => _GuessTemplateState();
}

class _GuessTemplateState extends State<GuessTemplate> {
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
            .where((g) => g['type'] == 'Guessing' && g['name'] == 'Guess The Word')
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
//                     backgroundColor: const Color.fromARGB(255, 190, 133, 21),
//                     padding: const EdgeInsets.symmetric(
//                         vertical: 14, horizontal: 20),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     elevation: 6,
//                   ),
//                   child: const Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(Icons.add, size: 24 , color:Colors.white),
//                       SizedBox(width: 6),
//                       Text("Create Game", style: TextStyle(fontSize: 16 ,color:Colors.white)),
//                     ],
//                   ),
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const GuessSetupScreen()),
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
      title: "Gruess Words Games",
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
      child: Text("No Guess  Words Games Yet", style: TextStyle(fontSize: 18)),
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
          "Guess Words Games",
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
        MaterialPageRoute(builder: (_) => const GuessSetupScreen()),
      );
    },
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
                    activeColor: const Color.fromARGB(255, 199, 140, 21),
                    onChanged: (_) => togglePublish(index),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color.fromARGB(255, 200, 140, 19)),
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
class GuessSetupScreen extends StatefulWidget {
  const GuessSetupScreen({super.key});

  @override
  State<GuessSetupScreen> createState() => _GuessSetupScreenState();
}

class _GuessSetupScreenState extends State<GuessSetupScreen> {
  final levelsCtrl = TextEditingController(text: " ");
  final questionsCtrl = TextEditingController(text: " ");
  final timeCtrl = TextEditingController(text: " ");
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
                      color: const Color.fromARGB(255, 199, 140, 21),
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
                      const Icon(Icons.layers, color: Color.fromARGB(255, 221, 167, 60)),
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
                      const Icon(Icons.help_outline, color: const Color.fromARGB(255, 199, 140, 21)),
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
                      const Icon(Icons.palette, color: const Color.fromARGB(255, 199, 140, 21)),
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
                      const Icon(Icons.help_outline, color:const Color.fromARGB(255, 199, 140, 21)),
                ),
              ),

              const SizedBox(height: 30),

      TextFormField(
                controller: timeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Time Per Question (minutes)",
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
                      const Icon(Icons.help_outline, color: const Color.fromARGB(255, 199, 140, 21)),
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
                      const Icon(Icons.help_outline, color: const Color.fromARGB(255, 199, 140, 21)),
                ),
              ),


              const SizedBox(height: 30),

              // ➜ Next Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 226, 179, 86),
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
                        gameTime: int.tryParse(timeCtrl.text),

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
  final int? gameTime;

  const LevelTypeScreen({
    super.key,
    required this.levels,
    required this.questionsPerLevel,
    required this.theme,
    required this.gameTrial,
    required this.gameScore, 
    required this.gameTime, 
  });

  @override
  State<LevelTypeScreen> createState() => _LevelTypeScreenState();
}

class _LevelTypeScreenState extends State<LevelTypeScreen> {
  late List<LevelType> types;

  @override
  void initState() {
    super.initState();
    types = List.generate(widget.levels, (_) => LevelType.textClues);
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
                        color: const Color.fromARGB(255, 199, 140, 21),
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
                        color:Color.fromARGB(255, 245, 230, 201),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 199, 140, 21),
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
                              const Color.fromARGB(255, 233, 185, 89),
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
                             const Color.fromARGB(255, 232, 183, 86),
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
                              builder: (_) => GameCreatorScreen(
                                levelTypes: types,
                                questionsPerLevel:  widget.questionsPerLevel,
                              theme: widget.theme,
                              gameTrial: widget.gameTrial,
                              gameScore: widget.gameScore,
                              gameTime: widget.gameTime,
                              ),
                            ),
                          );
                        },

                      //),
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
class GameCreatorScreen extends StatefulWidget {
  final List<LevelType> levelTypes;
  final int questionsPerLevel;
  final GameTheme theme ;
  final int? gameTrial;
  final int? gameScore;
   final int? gameTime;

  const GameCreatorScreen({
    super.key,
    required this.levelTypes,
    required this.questionsPerLevel,
    required this.theme,
    required this.gameTrial,
    required this.gameScore,
    required this.gameTime,
  });

  @override
  State<GameCreatorScreen> createState() => _GameCreatorScreenState();
}



class _GameCreatorScreenState extends State<GameCreatorScreen> {
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



  List<String> words = [];
  List<String> compoundWords = [];

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





 // ================= FridWord Count =================

void _updateGridWordCount(int count) {
  if (count > maxGridWords) {
    _error("Maximum $maxGridWords words allowed in word grid");
    return;
  }

  setState(() {
    gridWordCount = count;

    if (gridWordCtrls.length < count) {
      gridWordCtrls.addAll(
        List.generate(
          count - gridWordCtrls.length,
          (_) => TextEditingController(),
        ),
      );
    } else if (gridWordCtrls.length > count) {
      gridWordCtrls = gridWordCtrls.sublist(0, count);
    }
  });
}




  // ================= FETCH CLUE =================
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


       if (data['compoundWords'] != null) {
        compoundWords = List<String>.from(
          (data['compoundWords'] as List)
              .map((e) => e['compound'] as String)
        );
       }
      return {
        'words': words,
        'compoundWords': compoundWords,
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

  // ================= FETCH IMAGES =================
  Future<List<String>> fetchImages(String word) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/game/getClueImages?word=$word'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['images']);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }

  // ================= FETCH Words Suggestions=================
  Future<String?> fetchClue(String word, String ageGroup) async {
    try {
      final response = await http.post(
        Uri.parse('${getBackendUrl()}/api/game/generateGuessClue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word, 'ageGroup': ageGroup}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print( "this is tha clue :$data['clue']");
        return data['clue'] as String?;
      } else {

           print( "this is tha clue :nothing");
        return null;
      }
    } catch (e) {
      print("Error fetching clue: $e");
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
        compoundWords = result['compoundWords'] ?? [];
      });
    }
    setState(() => isFetchingWords = false);
  }







  // ================= SAVE QUESTION =================


Future <void> save() async {
  final word = wordCtrl.text.trim().toLowerCase();
  final type = widget.levelTypes[currentLevel];
  String? clueText = clueCtrl.text.trim().isEmpty ? null : clueCtrl.text.trim();
  List<String>? images;

    if (word.isEmpty) {
      _error("Enter a word");
      return;
    }
  

  // ---------------- Clues ----------------
  if (type == LevelType.textClues && clueText == null) {
    setState(() => isLoadingClue = true);
    clueText = await fetchClue(word, "9-12");
    setState(() => isLoadingClue = false);
    if (clueText == null) clueText = "No clue available";
  }

  // ---------------- Picture Clues ----------------
  if (type == LevelType.pictureClues) {
    setState(() => isLoadingClue = true);
    images = await fetchImages(word);
    setState(() => isLoadingClue = false);

    if (images.isEmpty) {
      _error("No images found for this word");
      return;
    }
  }


  final level = currentLevel + 1;

  Map<String, dynamic> question = {
    "level": level,
    "type": type.name,
  };

 


  if (type == LevelType.textClues) {
    question.addAll({
      "text": null,
      "clue": clueCtrl.text.trim(),
      "correctAnswer": [word],
      "image": [],
    });
  }

  if (type == LevelType.pictureClues) {
    question.addAll({
      "text": null,
      "clue": null,
      "correctAnswer": [word],
      "image": [
        selectedClue1Image,
        selectedClue2Image,
      ],
    });
  }

  // ---------------- Save question ----------------
  gameInputs.add(question);

  // ---------------- Clear UI ----------------
  wordCtrl.clear();
  clueCtrl.clear();
  clueCtrl1.clear();
  clueCtrl2.clear();


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
        "scorePerQuestion": widget.gameScore ?? 1,
        "timePerQuestionMin": widget.gameTime ?? 15,
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
if (words.isNotEmpty && type != LevelType.pictureClues && type != LevelType.textClues) ...[
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



         
            if (type == LevelType.textClues) ...[
              TextField(
                controller: clueCtrl,
                decoration: InputDecoration(
                  labelText: "Clue",
                  filled: true,
                  fillColor: Colors.white70,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                label: const Text(
                  "Generate Clue by AI",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 199, 140, 21),
                ),
                onPressed: () async {
                  if (wordCtrl.text.trim().isEmpty) return;
                  setState(() => isLoadingClue = true);
                  final clue = await fetchClue(wordCtrl.text.trim(), "9-12");
                  setState(() {
                    isLoadingClue = false;
                    if (clue != null) clueCtrl.text = clue;
                  });
                },
              ),

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


// ------------------ PICTURE CLUES ------------------
if (type == LevelType.pictureClues) ...[
  const SizedBox(height: 8),

  // ===== COMPOUND WORDS (PICTURE CLUES ONLY) =====
  if (compoundWords.isNotEmpty) ...[
    const Text(
      "Suggested Compound Words:",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 6),
    Wrap(
      spacing: 8,
      runSpacing: 4,
      children: compoundWords.map((c) {
        return ActionChip(
          label: Text(
            c,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 199, 140, 21),
          onPressed: () {
            // OPTIONAL: auto-split into clues
            final parts = c.split(' ');
            if (parts.length >= 2) {
              clueCtrl1.text = parts[0];
              clueCtrl2.text = parts[2];
               wordCtrl.text=parts[4];
            }
          },
        );
      }).toList(),
    ),
    const SizedBox(height: 12),
  ],

              const SizedBox(height: 12),

              // --- Clue 1 ---
              TextField(
                controller: clueCtrl1,
                decoration: const InputDecoration(
                  labelText: "Clue 1",
                  filled: true,
                  fillColor: Colors.white70,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text("Fetch Images for Clue 1",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 199, 140, 21)),
                onPressed: () async {
                  if (clueCtrl1.text.trim().isEmpty) return;
                  setState(() => isFetchingClue1Images = true);
                  clue1Images = await fetchImages(clueCtrl1.text.trim());
                  selectedClue1Image = null;
                  setState(() => isFetchingClue1Images = false);
                },
              ),

              if (clue1Images.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: clue1Images.map((img) {
                    final selected = img == selectedClue1Image;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(img,
                            width: 80, height: 80, fit: BoxFit.cover),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected
                                ? const Color.fromARGB(255, 229, 181, 86)
                                : const Color.fromARGB(255, 199, 140, 21),
                          ),
                          onPressed: () =>
                              setState(() => selectedClue1Image = img),
                          child: Text(selected ? "Selected" : "Select"),
                        ),
                      ],
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),


              // --- Clue 2---
              TextField(
                controller: clueCtrl2,
                decoration: const InputDecoration(
                  labelText: "Clue 2",
                  filled: true,
                  fillColor: Colors.white70,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text("Fetch Images for Clue 2",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 199, 140, 21)),
                onPressed: () async {
                  if (clueCtrl2.text.trim().isEmpty) return;
                  setState(() => isFetchingClue2Images = true);
                  clue2Images = await fetchImages(clueCtrl2.text.trim());
                  selectedClue2Image = null;
                  setState(() => isFetchingClue2Images = false);
                },
              ),

              if (clue2Images.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: clue2Images.map((img) {
                    final selected = img == selectedClue2Image;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(img,
                            width: 80, height: 80, fit: BoxFit.cover),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected
                                ?const Color.fromARGB(255, 233, 184, 85)
                                : const Color.fromARGB(255, 199, 140, 21),
                          ),
                          onPressed: () =>
                              setState(() => selectedClue2Image = img),
                          child: Text(selected ? "Selected" : "Select"),
                        ),
                      ],
                    );
                  }).toList(),
                ),
            ],

            const SizedBox(height: 12),
            if (isLoadingClue || isFetchingWords)
              const Center(child: CircularProgressIndicator()),

          


const SizedBox(height: 16),


   

// ------------------ NAVIGATION BUTTONS ------------------
if (currentLevel == widget.levelTypes.length - 1 &&
    currentQuestion + 1 == widget.questionsPerLevel)


  ElevatedButton(
  onPressed: () async {
    // Save last question (wait for async operations)
    await save();
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
    backgroundColor: const Color.fromARGB(255, 202, 141, 19),
  ),
  child: const Text("Create Game" ,style: TextStyle(color:Colors.white),),
)

else
  // All other questions → Next
  ElevatedButton(
    onPressed: () async {
      // Validate missing letters BEFORE saving
      final type = widget.levelTypes[currentLevel];
      final word = wordCtrl.text.trim();


      await save(); // save current question

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
      backgroundColor:Color.fromARGB(255, 209, 146, 20),
    ),
    child: const Text("Next" ,style:TextStyle(color:Colors.white)),
  ),






          ],
        ),
      ),
    ),
  );
   }




}



