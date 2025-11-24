import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddQuizPage extends StatefulWidget {
  final String videoId;
  const AddQuizPage({super.key, required this.videoId});

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  List<Map<String, dynamic>> questions = [];

  void addQuestion() {
    if (questions.length >= 5) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Max 5 questions allowed")));
      return;
    }

    questions.add({
      "question": "",
      "type": "mcq", 
      "options": ["", "", "", ""], 
      "correctAnswer": ""
    });

    setState(() {});
  }

  void saveQuiz() async {
    final payload = {
      "videoId": widget.videoId,
      "questions": questions,
    };

    final response = await http.post(
      Uri.parse("http://localhost:3000/api/quiz/createQuiz"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Quiz Created Successfully")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to create quiz")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Quiz")),
      floatingActionButton: FloatingActionButton(
        onPressed: addQuestion,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(labelText: "Question Text"),
                    onChanged: (v) => q["question"] = v,
                  ),

                  const SizedBox(height: 10),

                  DropdownButton<String>(
                    value: q["type"],
                    items: const [
                      DropdownMenuItem(value: "mcq", child: Text("Multiple Choice")),
                      DropdownMenuItem(value: "truefalse", child: Text("True / False")),
                    ],
                    onChanged: (v) {
                      q["type"] = v!;

                      if (v == "truefalse") {
                        q["options"] = ["True", "False"];
                      } else {
                        q["options"] = ["", "", "", ""];
                      }
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 10),

                  if (q["type"] == "mcq") ...[
                    for (int i = 0; i < 4; i++)
                      TextField(
                        decoration: InputDecoration(labelText: "Option ${i + 1}"),
                        onChanged: (v) => q["options"][i] = v,
                      ),
                  ] else ...[
                    const Text("True / False question")
                  ],

                  const SizedBox(height: 10),

                  TextField(
                    decoration:
                        const InputDecoration(labelText: "Correct Answer"),
                    onChanged: (v) => q["correctAnswer"] = v,
                  ),
                ],
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: saveQuiz,
          child: const Text("Save Quiz"),
        ),
      ),
    );
  }
}
