import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class TakeQuizPage extends StatefulWidget {
  final Map<String, dynamic> quizData; // you pass quiz from API
  const TakeQuizPage({super.key, required this.quizData});

  @override
  State<TakeQuizPage> createState() => _TakeQuizPageState();
}

class _TakeQuizPageState extends State<TakeQuizPage> {
  final FlutterTts tts = FlutterTts();

  Future<void> speak(String text) async {
    await tts.setLanguage("en-US");
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.5);
    await tts.speak(text);
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quizData["questions"];

    return Scaffold(
      appBar: AppBar(title: const Text("Quiz")),

      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Question ${index + 1}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      /// 🔊 SPEAK BUTTON
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 28),
                        onPressed: () {
                          speak(q["question_text"] ?? q["question"]);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Text(
                    q["question_text"] ?? q["question"],
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  // OPTIONS
                  Column(
                    children: List.generate(q["options"].length, (i) {
                      final option = q["options"][i];
                      final text = option["optionText"] ?? option;

                      return ListTile(
                        title: Text(text),
                        leading: Radio(
                          value: text,
                          groupValue: q["selected"],
                          onChanged: (v) {
                            setState(() {
                              q["selected"] = v;
                            });
                          },
                        ),
                      );
                    }),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
