
// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;

// class SpellingApp extends StatelessWidget {
//   const SpellingApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: GameSetupScreen(),
//     );
//   }
// }

// // /// ================= ENUMS =================
// enum GameTheme { animals, food, home, school, technology }

// String themeName(GameTheme t) {
//   switch (t) {
//     case GameTheme.animals:
//       return "Animals";
//     case GameTheme.food:
//       return "Food";
//     case GameTheme.home:
//       return "Home";
//     case GameTheme.school:
//       return "School";
//     case GameTheme.technology:
//       return "Technology";
//   }
// }



// /// ================= PAGE 1: GAME SETUP =================
// class GameSetupScreen extends StatefulWidget {
//   const GameSetupScreen({super.key});

//   @override
//   State<GameSetupScreen> createState() => _GameSetupScreenState();
// }

// class _GameSetupScreenState extends State<GameSetupScreen> {
//   final levelsCtrl = TextEditingController(text: "7");
//   final questionsCtrl = TextEditingController(text: "3");
//   GameTheme selectedTheme = GameTheme.animals;
//   String getBackendUrl() {
//   if (kIsWeb) {
//     // For web, use localhost or network IP
//    // return "http://localhost:5000";
//     return "http://192.168.1.63:3000";

//   } else if (Platform.isAndroid) {
//     // Android emulator
//     return "http://10.0.2.2:3000";
//   } else if (Platform.isIOS) {
//     // iOS emulator
//     return "http://localhost:3000";
//   } else {
//     // fallback
//     return "http://localhost:3000";
//   }
// }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Game Setup")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text("Number of Levels"),
//             TextField(controller: levelsCtrl, keyboardType: TextInputType.number),
//             const SizedBox(height: 12),
//             const Text("Questions per Level"),
//             TextField(controller: questionsCtrl, keyboardType: TextInputType.number),
//             const SizedBox(height: 12),
//             const Text("Choose Theme"),
//             DropdownButton<GameTheme>(
//               isExpanded: true,
//               value: selectedTheme,
//               items: GameTheme.values
//                   .map((e) => DropdownMenuItem(
//                         value: e,
//                         child: Text(themeName(e)),
//                       ))
//                   .toList(),
//               onChanged: (v) => setState(() => selectedTheme = v!),
//             ),
//             const Spacer(),
//             ElevatedButton(
//               child: const Text("Next"),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => LevelTypeScreen(
//                       levels: int.parse(levelsCtrl.text),
//                       questionsPerLevel: int.parse(questionsCtrl.text),
//                       theme: selectedTheme,
//                     ),
//                   ),
//                 );
//               },
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// ================= PAGE 2: CHOOSE LEVEL TYPES =================
// class LevelTypeScreen extends StatefulWidget {
//   final int levels;
//   final int questionsPerLevel;
//   final GameTheme theme;

//   const LevelTypeScreen({
//     super.key,
//     required this.levels,
//     required this.questionsPerLevel,
//     required this.theme,
//   });

//   @override
//   State<LevelTypeScreen> createState() => _LevelTypeScreenState();
// }

// class _LevelTypeScreenState extends State<LevelTypeScreen> {
//   late List<LevelType> types;

//   @override
//   void initState() {
//     super.initState();
//     types = List.generate(widget.levels, (i) => LevelType.oneMissing);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Choose Level Types")),
//       body: ListView.builder(
//         itemCount: widget.levels,
//         itemBuilder: (_, i) {
//           return ListTile(
//             title: Text("Level ${i + 1}"),
//             trailing: DropdownButton<LevelType>(
//               value: types[i],
//               items: LevelType.values
//                   .map((t) => DropdownMenuItem(
//                         value: t,
//                         child: Text(levelName(t)),
//                       ))
//                   .toList(),
//               onChanged: (v) => setState(() => types[i] = v!),
//             ),
//           );
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: const Icon(Icons.arrow_forward),
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => GameCreatorScreen(
//                 levelTypes: types,
//                 questionsPerLevel: widget.questionsPerLevel,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class SpellingGameScreen extends StatefulWidget {
//   final List<SpellingLevel> levels;
//   const SpellingGameScreen({super.key, required this.levels});

//   @override
//   State<SpellingGameScreen> createState() => _SpellingGameScreenState();
// }

// class _SpellingGameScreenState extends State<SpellingGameScreen> {
//   int level = 0, q = 0;
//   late SpellingQuestion question;
//   List<String?> slots = [];
//   List<String> available = [];
//   bool solved = false;

//   @override
//   void initState() {
//     super.initState();
//     load();
//   }

// void load() {
//   question = widget.levels[level].questions[q];

//   // Initialize slots based on level type
//   if (question.levelType == LevelType.oneMissing ||
//       question.levelType == LevelType.twoMissing ||
//       question.levelType == LevelType.allMissing) {
//     // Only missing letters empty
//     slots = List.generate(question.word.length, (i) {
//       return question.missingIndexes.contains(i) ? null : question.word[i];
//     });
//     available = List.from(question.choices)..shuffle();
//   } else if (question.levelType == LevelType.guessByClueHints) {
//     // Level 5: all empty, limited choices
//     slots = List.filled(question.word.length, null);
//     available = List.from(question.choices)..shuffle();
//   } else if (question.levelType == LevelType.guessByClueNoHints) {
//     // Level 7: all empty, full alphabet as choices
//     slots = List.filled(question.word.length, null);
//     available = List.generate(26, (i) => String.fromCharCode(97 + i));
//   } else {
//     // Word grid or picture clue (optional)
//     slots = List.generate(question.word.length, (i) => question.word[i]);
//     available = List.from(question.choices)..shuffle();
//   }

//   solved = false;
//   setState(() {});
// }


//   void drop(String l, int i) {
//     if (slots[i] != null) return;
//     setState(() {
//       slots[i] = l;
//       available.remove(l);
//       if (!slots.contains(null) && slots.join() == question.word) solved = true;
//     });
//   }

//   void next() {
//     if (++q < widget.levels[level].questions.length) {
//       load();
//     } else if (++level < widget.levels.length) {
//       q = 0;
//       load();
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(levelName(question.levelType))),
//       body: Column(
//         children: [
//           if (question.clue != null)
//             Padding(
//               padding: const EdgeInsets.all(8),
//               child: Text(question.clue!, style: const TextStyle(fontSize: 18)),
//             ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: List.generate(slots.length, (i) {
//               return DragTarget<String>(
//                 onAccept: (l) => drop(l, i),
//                 builder: (_, __, ___) => Container(
//                   margin: const EdgeInsets.all(4),
//                   width: 48,
//                   height: 60,
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(border: Border.all()),
//                   child: Text(slots[i] ?? "", style: const TextStyle(fontSize: 24)),
//                 ),
//               );
//             }),
//           ),
//           if (available.isNotEmpty)
//             Wrap(
//               children: available.map((l) {
//                 return Draggable<String>(
//                   data: l,
//                   feedback: tile(l, 0.7),
//                   childWhenDragging: tile(l, 0.3),
//                   child: tile(l, 1),
//                 );
//               }).toList(),
//             ),
//           if (solved) ElevatedButton(onPressed: next, child: const Text("Next"))
//         ],
//       ),
//     );
//   }

//   Widget tile(String l, double o) {
//     return Opacity(
//       opacity: o,
//       child: Container(
//         width: 48,
//         height: 48,
//         margin: const EdgeInsets.all(4),
//         alignment: Alignment.center,
//         decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
//         child: Text(l.toUpperCase(), style: const TextStyle(fontSize: 20)),
//       ),
//     );
//   }
// }


// // ================= MODELS =================
// class SpellingQuestion {
//   final String word;
//   final LevelType levelType;
//   final List<int> missingIndexes;
//   final List<String> choices;
//   final String? clue;
//   final List<String>? images;

//   SpellingQuestion({
//     required this.word,
//     required this.levelType,
//     required this.missingIndexes,
//     required this.choices,
//     this.clue,
//     this.images,
//   });
// }

// class SpellingLevel {
//   final List<SpellingQuestion> questions;
//   SpellingLevel(this.questions);
// }

// // ================= ENUMS =================
// enum LevelType {
//   oneMissing,
//   twoMissing,
//   allMissing,
//   wordGrid,
//   guessByClueHints,
//   pictureClues,
//   guessByClueNoHints,
// }

// String levelName(LevelType type) {
//   switch (type) {
//     case LevelType.oneMissing:
//       return "One Missing Letter";
//     case LevelType.twoMissing:
//       return "Two Missing Letters";
//     case LevelType.allMissing:
//       return "Build the Word";
//     case LevelType.wordGrid:
//       return "Word Grid";
//     case LevelType.guessByClueHints:
//       return "Guess by Clue (Hints)";
//     case LevelType.pictureClues:
//       return "Picture Clues";
//     case LevelType.guessByClueNoHints:
//       return "Final Challenge";
//   }
// }

// // ================= PAGE 3: CREATE QUESTIONS =================
// class GameCreatorScreen extends StatefulWidget {
//   final List<LevelType> levelTypes;
//   final int questionsPerLevel;

//   const GameCreatorScreen({
//     super.key,
//     required this.levelTypes,
//     required this.questionsPerLevel,
//   });

//   @override
//   State<GameCreatorScreen> createState() => _GameCreatorScreenState();
// }

// class _GameCreatorScreenState extends State<GameCreatorScreen> {
//   final List<SpellingLevel> levels = [];
//   final TextEditingController wordCtrl = TextEditingController();
//   final TextEditingController clueCtrl = TextEditingController();

//   int currentLevel = 0;
//   int currentQuestion = 0;
//   final List<int> missing = [];
//   final List<String> choices = [];
//   final alphabet = List.generate(26, (i) => String.fromCharCode(97 + i));
//   bool isLoadingClue = false;

//   void _error(String msg) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }

//   // ================= FETCH CLUE FROM BACKEND =================
//   Future<String?> fetchClue(String word, String ageGroup) async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://YOUR_BACKEND_URL/game/generateGuessClue'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'word': word, 'ageGroup': ageGroup}),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['clue'] as String?;
//       } else {
//         return null;
//       }
//     } catch (e) {
//       print("Error fetching clue: $e");
//       return null;
//     }
//   }

//   // ================= SAVE QUESTION =================
//   void save() async {
//     final word = wordCtrl.text.trim().toLowerCase();
//     if (word.isEmpty) {
//       _error("Enter a word");
//       return;
//     }

//     final type = widget.levelTypes[currentLevel];
//     String? clueText = clueCtrl.text.trim().isEmpty ? null : clueCtrl.text.trim();

//     // Auto-generate clue for guessByClueNoHints or guessByClueHints if not provided
//     if ((type == LevelType.guessByClueNoHints || type == LevelType.guessByClueHints) && clueText == null) {
//       setState(() => isLoadingClue = true);
//       clueText = await fetchClue(word, "6-8"); // Change ageGroup dynamically if needed
//       setState(() => isLoadingClue = false);
//       if (clueText == null) clueText = "No clue available";
//     }

//     // ================= VALIDATIONS =================
//     switch (type) {
//       case LevelType.oneMissing:
//         if (missing.length != 1) {
//           _error("Select exactly 1 missing letter");
//           return;
//         }
//         if (choices.isEmpty) {
//           _error("Select letter choices");
//           return;
//         }
//         break;
//       case LevelType.twoMissing:
//         if (missing.length != 2) {
//           _error("Select exactly 2 missing letters");
//           return;
//         }
//         if (choices.length < 3) {
//           _error("Select at least 3 letter choices");
//           return;
//         }
//         break;
//       case LevelType.allMissing:
//         if (missing.length != word.length) {
//           _error("All letters must be missing");
//           return;
//         }
//         if (choices.length < word.length) {
//           _error("Choices must include all letters of the word");
//           return;
//         }
//         break;
//       case LevelType.wordGrid:
//         break;
//       case LevelType.guessByClueHints:
//         if (clueText?.isEmpty ?? true) {
//           _error("Clue is required");
//           return;
//         }
//         if (choices.length < word.length) {
//           _error("Provide limited letter choices");
//           return;
//         }
//         break;
//       case LevelType.pictureClues:
//         _error("Picture questions handled later");
//         return;
//       case LevelType.guessByClueNoHints:
//         if (clueText?.isEmpty ?? true) {
//           _error("Clue is required");
//           return;
//         }
//         break;
//     }

//     if (levels.length <= currentLevel) levels.add(SpellingLevel([]));

//     levels[currentLevel].questions.add(
//       SpellingQuestion(
//         word: word,
//         levelType: type,
//         missingIndexes: List.from(missing),
//         choices: List.from(choices),
//         clue: clueText,
//       ),
//     );

//     // Clear fields for next question
//     wordCtrl.clear();
//     clueCtrl.clear();
//     missing.clear();
//     choices.clear();

//     if (++currentQuestion >= widget.questionsPerLevel) {
//       currentQuestion = 0;
//       currentLevel++;
//     }

//     if (currentLevel >= widget.levelTypes.length) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => SpellingGameScreen(levels: levels),
//         ),
//       );
//     }

//     setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     final word = wordCtrl.text;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text("${levelName(widget.levelTypes[currentLevel])} (Q${currentQuestion + 1})"),
//       ),
//       body: Column(
//         children: [
//           TextField(controller: wordCtrl, decoration: const InputDecoration(labelText: "Word")),
//           TextField(controller: clueCtrl, decoration: const InputDecoration(labelText: "Clue (optional)")),
//           if (isLoadingClue)
//             const Padding(
//               padding: EdgeInsets.all(8),
//               child: CircularProgressIndicator(),
//             ),
//           if (word.isNotEmpty)
//             Wrap(
//               children: List.generate(word.length, (i) {
//                 return ChoiceChip(
//                   label: Text(word[i]),
//                   selected: missing.contains(i),
//                   onSelected: (_) => setState(() {
//                     missing.contains(i) ? missing.remove(i) : missing.add(i);
//                   }),
//                 );
//               }),
//             ),
//           Wrap(
//             children: alphabet.map((l) {
//               return ChoiceChip(
//                 label: Text(l),
//                 selected: choices.contains(l),
//                 onSelected: (_) => setState(() {
//                   choices.contains(l) ? choices.remove(l) : choices.add(l);
//                 }),
//               );
//             }).toList(),
//           ),
//           const Spacer(),
//           ElevatedButton(onPressed: save, child: const Text("Save")),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SpellingApp extends StatelessWidget {
  const SpellingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameSetupScreen(),
    );
  }
}

// ================= ENUMS =================
enum GameTheme { animals, food, home, school, technology }

String themeName(GameTheme t) {
  switch (t) {
    case GameTheme.animals:
      return "Animals";
    case GameTheme.food:
      return "Food";
    case GameTheme.home:
      return "Home";
    case GameTheme.school:
      return "School";
    case GameTheme.technology:
      return "Technology";
  }
}

// ================= PAGE 1: GAME SETUP =================
class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final levelsCtrl = TextEditingController(text: "7");
  final questionsCtrl = TextEditingController(text: "3");
  GameTheme selectedTheme = GameTheme.animals;

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
    return Scaffold(
      appBar: AppBar(title: const Text("Game Setup")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Number of Levels"),
            TextField(controller: levelsCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            const Text("Questions per Level"),
            TextField(controller: questionsCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            const Text("Choose Theme"),
            DropdownButton<GameTheme>(
              isExpanded: true,
              value: selectedTheme,
              items: GameTheme.values
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(themeName(e)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedTheme = v!),
            ),
            const Spacer(),
            ElevatedButton(
              child: const Text("Next"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelTypeScreen(
                      levels: int.parse(levelsCtrl.text),
                      questionsPerLevel: int.parse(questionsCtrl.text),
                      theme: selectedTheme,
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

// ================= PAGE 2: CHOOSE LEVEL TYPES =================
class LevelTypeScreen extends StatefulWidget {
  final int levels;
  final int questionsPerLevel;
  final GameTheme theme;

  const LevelTypeScreen({
    super.key,
    required this.levels,
    required this.questionsPerLevel,
    required this.theme,
  });

  @override
  State<LevelTypeScreen> createState() => _LevelTypeScreenState();
}

class _LevelTypeScreenState extends State<LevelTypeScreen> {
  late List<LevelType> types;

  @override
  void initState() {
    super.initState();
    types = List.generate(widget.levels, (i) => LevelType.oneMissing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Level Types")),
      body: ListView.builder(
        itemCount: widget.levels,
        itemBuilder: (_, i) {
          return ListTile(
            title: Text("Level ${i + 1}"),
            trailing: DropdownButton<LevelType>(
              value: types[i],
              items: LevelType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(levelName(t)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => types[i] = v!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.arrow_forward),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GameCreatorScreen(
                levelTypes: types,
                questionsPerLevel: widget.questionsPerLevel,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================= PAGE 3: CREATE QUESTIONS =================
class GameCreatorScreen extends StatefulWidget {
  final List<LevelType> levelTypes;
  final int questionsPerLevel;

  const GameCreatorScreen({
    super.key,
    required this.levelTypes,
    required this.questionsPerLevel,
  });

  @override
  State<GameCreatorScreen> createState() => _GameCreatorScreenState();
}

class _GameCreatorScreenState extends State<GameCreatorScreen> {
  final List<SpellingLevel> levels = [];
  final TextEditingController wordCtrl = TextEditingController();
  final TextEditingController clueCtrl = TextEditingController();
  final alphabet = List.generate(26, (i) => String.fromCharCode(97 + i));
  final List<int> missing = [];
  final List<String> choices = [];
  int currentLevel = 0;
  int currentQuestion = 0;
  bool isLoadingClue = false;

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

  // ================= FETCH CLUE =================
  Future<String?> fetchClue(String word, String ageGroup) async {
    try {
      final response = await http.post(
        Uri.parse('${getBackendUrl()}/game/generateGuessClue'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'word': word, 'ageGroup': ageGroup}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['clue'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      print("Error fetching clue: $e");
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

  // ================= SAVE QUESTION =================
  void save() async {
    final word = wordCtrl.text.trim().toLowerCase();
    if (word.isEmpty) {
      _error("Enter a word");
      return;
    }

    final type = widget.levelTypes[currentLevel];
    String? clueText = clueCtrl.text.trim().isEmpty ? null : clueCtrl.text.trim();
    List<String>? images;

    if ((type == LevelType.guessByClueNoHints || type == LevelType.guessByClueHints) && clueText == null) {
      setState(() => isLoadingClue = true);
      clueText = await fetchClue(word, "6-8");
      setState(() => isLoadingClue = false);
      if (clueText == null) clueText = "No clue available";
    }

    // Picture Clues: fetch images
    if (type == LevelType.pictureClues) {
      setState(() => isLoadingClue = true);
      images = await fetchImages(word);
      setState(() => isLoadingClue = false);

      if (images.isEmpty) {
        _error("No images found for this word");
        return;
      }
    }

    if (levels.length <= currentLevel) levels.add(SpellingLevel([]));

    levels[currentLevel].questions.add(
      SpellingQuestion(
        word: word,
        levelType: type,
        missingIndexes: List.from(missing),
        choices: List.from(choices),
        clue: clueText,
        images: images,
      ),
    );

    // Clear inputs
    wordCtrl.clear();
    clueCtrl.clear();
    missing.clear();
    choices.clear();

    if (++currentQuestion >= widget.questionsPerLevel) {
      currentQuestion = 0;
      currentLevel++;
    }

    if (currentLevel >= widget.levelTypes.length) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SpellingGameScreen(levels: levels),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final word = wordCtrl.text;

    return Scaffold(
      appBar: AppBar(
        title: Text("${levelName(widget.levelTypes[currentLevel])} (Q${currentQuestion + 1})"),
      ),
      body: Column(
        children: [
          TextField(controller: wordCtrl, decoration: const InputDecoration(labelText: "Word")),
          TextField(controller: clueCtrl, decoration: const InputDecoration(labelText: "Clue (optional)")),
          if (isLoadingClue)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          if (word.isNotEmpty)
            Wrap(
              children: List.generate(word.length, (i) {
                return ChoiceChip(
                  label: Text(word[i]),
                  selected: missing.contains(i),
                  onSelected: (_) => setState(() {
                    missing.contains(i) ? missing.remove(i) : missing.add(i);
                  }),
                );
              }),
            ),
          Wrap(
            children: alphabet.map((l) {
              return ChoiceChip(
                label: Text(l),
                selected: choices.contains(l),
                onSelected: (_) => setState(() {
                  choices.contains(l) ? choices.remove(l) : choices.add(l);
                }),
              );
            }).toList(),
          ),
          const Spacer(),
          ElevatedButton(onPressed: save, child: const Text("Save")),
        ],
      ),
    );
  }
}

// ================= GAME SCREEN =================
class SpellingGameScreen extends StatefulWidget {
  final List<SpellingLevel> levels;
  const SpellingGameScreen({super.key, required this.levels});

  @override
  State<SpellingGameScreen> createState() => _SpellingGameScreenState();
}

class _SpellingGameScreenState extends State<SpellingGameScreen> {
  int level = 0, q = 0;
  late SpellingQuestion question;
  List<String?> slots = [];
  List<String> available = [];
  bool solved = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    question = widget.levels[level].questions[q];

    // Initialize slots
    if (question.levelType == LevelType.oneMissing ||
        question.levelType == LevelType.twoMissing ||
        question.levelType == LevelType.allMissing) {
      slots = List.generate(question.word.length, (i) {
        return question.missingIndexes.contains(i) ? null : question.word[i];
      });
      available = List.from(question.choices)..shuffle();
    } else if (question.levelType == LevelType.guessByClueHints) {
      slots = List.filled(question.word.length, null);
      available = List.from(question.choices)..shuffle();
    } else if (question.levelType == LevelType.guessByClueNoHints) {
      slots = List.filled(question.word.length, null);
      available = List.generate(26, (i) => String.fromCharCode(97 + i));
    } else {
      slots = List.generate(question.word.length, (i) => question.word[i]);
      available = List.from(question.choices)..shuffle();
    }

    solved = false;
    setState(() {});
  }

  void drop(String l, int i) {
    if (slots[i] != null) return;
    setState(() {
      slots[i] = l;
      available.remove(l);
      if (!slots.contains(null) && slots.join() == question.word) solved = true;
    });
  }

  void next() {
    if (++q < widget.levels[level].questions.length) {
      load();
    } else if (++level < widget.levels.length) {
      q = 0;
      load();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(levelName(question.levelType))),
      body: Column(
        children: [
          if (question.clue != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(question.clue!, style: const TextStyle(fontSize: 18)),
            ),

          // Picture clue images
          if (question.levelType == LevelType.pictureClues && question.images != null)
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: question.images!.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: Image.network(question.images![i]),
                ),
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(slots.length, (i) {
              return DragTarget<String>(
                onAccept: (l) => drop(l, i),
                builder: (_, __, ___) => Container(
                  margin: const EdgeInsets.all(4),
                  width: 48,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Text(slots[i] ?? "", style: const TextStyle(fontSize: 24)),
                ),
              );
            }),
          ),
          if (available.isNotEmpty)
            Wrap(
              children: available.map((l) {
                return Draggable<String>(
                  data: l,
                  feedback: tile(l, 0.7),
                  childWhenDragging: tile(l, 0.3),
                  child: tile(l, 1),
                );
              }).toList(),
            ),
          if (solved) ElevatedButton(onPressed: next, child: const Text("Next"))
        ],
      ),
    );
  }

  Widget tile(String l, double o) {
    return Opacity(
      opacity: o,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(4),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
        child: Text(l.toUpperCase(), style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

// ================= MODELS =================
class SpellingQuestion {
  final String word;
  final LevelType levelType;
  final List<int> missingIndexes;
  final List<String> choices;
  final String? clue;
  final List<String>? images;

  SpellingQuestion({
    required this.word,
    required this.levelType,
    required this.missingIndexes,
    required this.choices,
    this.clue,
    this.images,
  });
}

class SpellingLevel {
  final List<SpellingQuestion> questions;
  SpellingLevel(this.questions);
}

// ================= ENUMS =================
enum LevelType {
  oneMissing,
  twoMissing,
  allMissing,
  wordGrid,
  guessByClueHints,
  pictureClues,
  guessByClueNoHints,
}

String levelName(LevelType type) {
  switch (type) {
    case LevelType.oneMissing:
      return "One Missing Letter";
    case LevelType.twoMissing:
      return "Two Missing Letters";
    case LevelType.allMissing:
      return "Build the Word";
    case LevelType.wordGrid:
      return "Word Grid";
    case LevelType.guessByClueHints:
      return "Guess by Clue (Hints)";
    case LevelType.pictureClues:
      return "Picture Clues";
    case LevelType.guessByClueNoHints:
      return "Final Challenge";
  }
}

