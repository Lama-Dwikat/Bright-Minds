// import 'package:flutter/material.dart';



// class SpellingFarmGame extends StatelessWidget {
//   const SpellingFarmGame({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: const FarmGameScreen(),
//     );
//   }
// }

// enum FarmStage { seed, plant, fruit, harvest, market }

// class FarmGameScreen extends StatefulWidget {
//   const FarmGameScreen({super.key});

//   @override
//   State<FarmGameScreen> createState() => _FarmGameScreenState();
// }

// class _FarmGameScreenState extends State<FarmGameScreen> {
//   FarmStage stage = FarmStage.seed;

//   final List<String> words = ['CAT', 'TREE', 'APPLE', 'SHOP'];
//   int wordIndex = 0;
//   final TextEditingController controller = TextEditingController();

//   void checkAnswer() {
//     if (controller.text.toUpperCase() == words[wordIndex]) {
//       controller.clear();
//       setState(() {
//         wordIndex++;
//         advanceStage();
//       });
//     }
//   }

//   void advanceStage() {
//     if (stage == FarmStage.seed) {
//       stage = FarmStage.plant;
//     } else if (stage == FarmStage.plant) {
//       stage = FarmStage.fruit;
//     } else if (stage == FarmStage.fruit) {
//       stage = FarmStage.harvest;
//     } else if (stage == FarmStage.harvest) {
//       stage = FarmStage.market;
//     }
//   }

//   Widget buildFarmScene() {
//     switch (stage) {
//       case FarmStage.seed:
//         return scene('🌱', 'Seed planted');
//       case FarmStage.plant:
//         return scene('🌿', 'Farmer is watering');
//       case FarmStage.fruit:
//         return scene('🌳🍎', 'Fruits appeared');
//       case FarmStage.harvest:
//         return scene('🧑‍🌾🍎', 'Farmer is harvesting');
//       case FarmStage.market:
//         return scene('🏪💰', 'Fruits sold in market');
//     }
//   }

//   Widget scene(String emoji, String text) {
//     return AnimatedContainer(
//       duration: const Duration(seconds: 1),
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.green.shade100,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(emoji, style: const TextStyle(fontSize: 80)),
//           const SizedBox(height: 12),
//           Text(text,
//               style:
//                   const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.lightGreen.shade50,
//       appBar: AppBar(
//         title: const Text('Spelling Farm Game'),
//         backgroundColor: Colors.green,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Expanded(child: Center(child: buildFarmScene())),
//             if (stage != FarmStage.market) ...[
//               Text(
//                 'Spell the word:',
//                 style:
//                     const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               Text(
//                 words[wordIndex],
//                 style: const TextStyle(
//                     fontSize: 28,
//                     letterSpacing: 3,
//                     color: Colors.green),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: controller,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 22),
//                 decoration: InputDecoration(
//                   hintText: 'Type here',
//                   filled: true,
//                   fillColor: Colors.white,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               ElevatedButton(
//                 onPressed: checkAnswer,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
//                 ),
//                 child: const Text('Check',
//                     style:
//                         TextStyle(fontSize: 20, color: Colors.white)),
//               ),
//             ] else
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text(
//                   '🎉 GREAT JOB! GAME COMPLETE 🎉',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               )
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';




class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Word Game Levels')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Level1Page()),
                );
              },
              child: const Text('Level 1'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Level2Page()),
                );
              },
              child: const Text('Level 2'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Level3Page()),
                );
              },
              child: const Text('Level 3'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- LEVEL 1 ----------------
class Level1Page extends StatefulWidget {
  const Level1Page({super.key});

  @override
  State<Level1Page> createState() => _Level1PageState();
}

class _Level1PageState extends State<Level1Page> {
  final String word = "FLUTTER";
  String displayedWord = "FL_TTER";
  final List<String> letters = ["A", "E", "I", "O", "U", "L", "F", "T", "R"];
  String result = "";

  void checkLetter(String letter) {
    setState(() {
      if (letter == "U") {
        result = "Correct!";
        displayedWord = word;
      } else {
        result = "Try Again!";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level 1')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Word: $displayedWord", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: letters.map((letter) {
                return ElevatedButton(
                  onPressed: () => checkLetter(letter),
                  child: Text(letter),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 20, color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- LEVEL 2 ----------------
class Level2Page extends StatefulWidget {
  const Level2Page({super.key});

  @override
  State<Level2Page> createState() => _Level2PageState();
}

class _Level2PageState extends State<Level2Page> {
  final String word = "APLE";
  final List<String> letters = ["A", "B", "C", "P", "L", "E","P"];
  List<String> selectedLetters = [];
  String result = "";

  void selectLetter(String letter) {
    setState(() {
      if (!selectedLetters.contains(letter)) selectedLetters.add(letter);
      if (selectedLetters.join() == word) {
        result = "Correct!";
      }
    });
  }

  void reset() {
    setState(() {
      selectedLetters = [];
      result = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level 2')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Selected: ${selectedLetters.join()}", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: letters.map((letter) {
                return ElevatedButton(
                  onPressed: () => selectLetter(letter),
                  child: Text(letter),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 20, color: Colors.green)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: reset, child: const Text("Reset")),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- LEVEL 3 ----------------
class Level3Page extends StatefulWidget {
  const Level3Page({super.key});

  @override
  State<Level3Page> createState() => _Level3PageState();
}

class _Level3PageState extends State<Level3Page> {
  final String word = "BANANA";
  final TextEditingController controller = TextEditingController();
  String result = "";

  void checkWord() {
    setState(() {
      if (controller.text.toUpperCase() == word) {
        result = "Correct!";
      } else {
        result = "Try Again!";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Level 3')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Hint: A yellow fruit with long shape", style: TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Enter word"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: checkWord, child: const Text("Check")),
            const SizedBox(height: 20),
            Text(result, style: const TextStyle(fontSize: 20, color: Colors.blue)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
