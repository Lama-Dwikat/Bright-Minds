import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';



class AddQuizPage extends StatefulWidget {
  final String videoId;
  const AddQuizPage({super.key, required this.videoId});

  @override
  State<AddQuizPage> createState() => _AddQuizPageState();
}

class _AddQuizPageState extends State<AddQuizPage> {
  List<Map<String, dynamic>> questions = [];

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final durationController = TextEditingController();
  String? userId;


  String quizLevel = "easy";
  String ageGroup = "5-8";


// Future <void> getUserId() async{
//   SharedPreferences prefs=await SharedPreferences.getInstance();
//   String? token =prefs.getString("token");
//   if(token==null)return;
//   Map <String,dynamic>decodedToken= JwtDecoder.decode(token);
// userId=decodedToken['id'];
// }
  // ---------------- BACKEND URL ----------------
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

  // ---------------- ADD QUESTION ----------------
  void addQuestion() {
    questions.add({
      "question_type": "multiple-choice",
      "question_text": "",
      "options": [
        {"optionText": "", "isCorrect": false},
        {"optionText": "", "isCorrect": false},
        {"optionText": "", "isCorrect": false},
        {"optionText": "", "isCorrect": false}
      ],
      "isCorrect": false,
      "correctAnswer": "",
    });

    setState(() {});
  }

  // ---------------- SAVE QUIZ ----------------
  void saveQuiz() async {
      SharedPreferences prefs=await SharedPreferences.getInstance();
  String? token =prefs.getString("token");
  if(token==null)return;
  Map <String,dynamic>decodedToken= JwtDecoder.decode(token);
userId=decodedToken['id'];
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final payload = {
      "title": titleController.text,
      "description": descriptionController.text,
      "duration": int.tryParse(durationController.text) ?? 1,
      "videoId": widget.videoId,
      "createdBy":userId,
      "level": quizLevel,
      "ageGroup": ageGroup,
      "questions": questions.map((q) {
        return {
          "question_type": q["question_type"],
          "question_text": q["question_text"],
          "options": q["options"],
          "isCorrect": false,
          "correctAnswer": q["correctAnswer"]
        };
      }).toList(),
    };

    final response = await http.post(
      Uri.parse('${getBackendUrl()}/api/quiz/createQuiz'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz Created Successfully")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Quiz")),
      floatingActionButton: FloatingActionButton(
        onPressed: addQuestion,
        child: const Icon(Icons.add),
      ),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          // ---------------- QUIZ TITLE ----------------
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Quiz Title *"),
          ),
          const SizedBox(height: 10),

          // ---------------- QUIZ DESCRIPTION ----------------
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: "Description *"),
          ),
          const SizedBox(height: 10),

          // ---------------- DURATION ----------------
          TextField(
            controller: durationController,
            decoration: const InputDecoration(labelText: "Duration (minutes) *"),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          // ---------------- LEVEL ----------------
          DropdownButtonFormField<String>(
            value: quizLevel,
            items: const [
              DropdownMenuItem(value: "easy", child: Text("Easy")),
              DropdownMenuItem(value: "medium", child: Text("Medium")),
              DropdownMenuItem(value: "hard", child: Text("Hard")),
            ],
            onChanged: (v) => setState(() => quizLevel = v!),
            decoration: const InputDecoration(labelText: "Level"),
          ),

          const SizedBox(height: 20),

          // ---------------- AGE GROUP ----------------
          DropdownButtonFormField<String>(
            value: ageGroup,
            items: const [
              DropdownMenuItem(value: "5-8", child: Text("5-8 years")),
              DropdownMenuItem(value: "9-12", child: Text("9-12 years")),
            ],
            onChanged: (v) => setState(() => ageGroup = v!),
            decoration: const InputDecoration(labelText: "Age Group"),
          ),

          const SizedBox(height: 25),

          // ---------------- QUESTIONS LIST ----------------
          ...questions.asMap().entries.map((entry) {
            int index = entry.key;
            var q = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text("Question ${index + 1}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),

                    const SizedBox(height: 10),

                    TextField(
                      decoration:
                          const InputDecoration(labelText: "Question Text"),
                      onChanged: (v) => q["question_text"] = v,
                    ),

                    const SizedBox(height: 10),

                    DropdownButton<String>(
                      value: q["question_type"],
                      items: const [
                        DropdownMenuItem(
                            value: "multiple-choice",
                            child: Text("Multiple Choice")),
                        DropdownMenuItem(
                            value: "true-false", child: Text("True / False")),
                      ],
                      onChanged: (v) {
                        q["question_type"] = v!;
                        if (v == "true-false") {
                          q["options"] = [
                            {"optionText": "True", "isCorrect": false},
                            {"optionText": "False", "isCorrect": false}
                          ];
                        } else {
                          q["options"] = [
                            {"optionText": "", "isCorrect": false},
                            {"optionText": "", "isCorrect": false},
                            {"optionText": "", "isCorrect": false},
                            {"optionText": "", "isCorrect": false}
                          ];
                        }
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 10),

                    // ------------- MCQ OPTIONS -------------
                    if (q["question_type"] == "multiple-choice")
                      Column(
                        children: List.generate(4, (i) {
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                      labelText: "Option ${i + 1}"),
                                  onChanged: (v) =>
                                      q["options"][i]["optionText"] = v,
                                ),
                              ),
                              Checkbox(
                                value: q["options"][i]["isCorrect"],
                                onChanged: (v) {
                                  setState(() {
                                    for (var opt in q["options"]) {
                                      opt["isCorrect"] = false;
                                    }
                                    q["options"][i]["isCorrect"] = true;
                                    q["correctAnswer"] =
                                        q["options"][i]["optionText"];
                                  });
                                },
                              )
                            ],
                          );
                        }),
                      ),

                    // ------------- TRUE/FALSE -------------
                    if (q["question_type"] == "true-false")
                      Column(
                        children: List.generate(2, (i) {
                          return Row(
                            children: [
                              Text(q["options"][i]["optionText"]),
                              Checkbox(
                                value: q["options"][i]["isCorrect"],
                                onChanged: (v) {
                                  setState(() {
                                    q["options"][0]["isCorrect"] = false;
                                    q["options"][1]["isCorrect"] = false;
                                    q["options"][i]["isCorrect"] = true;
                                    q["correctAnswer"] =
                                        q["options"][i]["optionText"];
                                  });
                                },
                              )
                            ],
                          );
                        }),
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: saveQuiz,
          child: const Text("Save Quiz"),
        ),
      ),
    );
  }
}
