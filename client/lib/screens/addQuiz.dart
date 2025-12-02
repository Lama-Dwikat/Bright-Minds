



import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  //final durationController = TextEditingController();
  String? userId;

  String quizLevel = "easy";
  String ageGroup = "5-8";

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  void addMultipleChoiceQuestion() {
    questions.add({
      "question_type": "multiple-choice",
      "question_text": "",
      "question_image": null,
      "question_audio": null,
      "options": List.generate(4, (i) => {
            "optionType": "text",
            "optionText": "",
            "optionImage": null,
            "optionAudio": null,
            "isCorrect": false
          }),
      "correctAnswer": "",
    });
    setState(() {});
  }

  void addVoiceAnswerQuestion() {
    questions.add({
      "question_type": "voice-answer",
      "question_text": "",
      "question_audio": null,
      "options": [],
      "correctAnswer": "", // Teacher types the word here
    });
    setState(() {});
  }

  Future<String?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }
    return null;
  }

  void saveQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    userId = decodedToken['id'];

    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final payload = {
      "title": titleController.text,
      "description": descriptionController.text,
      //"duration": int.tryParse(durationController.text) ?? 1,
      "videoId": widget.videoId,
      "createdBy": userId,
      "level": quizLevel,
      "ageGroup": ageGroup,
      "questions": questions.map((q) {
        return {
          "question_type": q["question_type"],
          "question_text": q["question_text"],
          "question_image": q["question_image"],
          "question_audio": q["question_audio"],
          "options": q["options"].map((opt) {
            return {
              "optionText": opt["optionText"],
              "optionImage": opt["optionImage"],
              "optionAudio": opt["optionAudio"],
              "isCorrect": opt["isCorrect"]
            };
          }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Quiz")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addMultipleChoiceQuestion(),
        child: const Icon(Icons.add),
        tooltip: "Add Multiple Choice Question",
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: "Quiz Title *"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: "Description *"),
          ),
          const SizedBox(height: 10),
          // TextField(
          //   controller: durationController,
          //   decoration:
          //       const InputDecoration(labelText: "Duration (minutes) *"),
          //   keyboardType: TextInputType.number,
          // ),
          const SizedBox(height: 20),
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
          ...questions.asMap().entries.map((entry) {
            int qIndex = entry.key;
            var q = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Question ${qIndex + 1}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextField(
                      decoration:
                          const InputDecoration(labelText: "Question Text"),
                      onChanged: (v) => q["question_text"] = v,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text("Add Image"),
                          onPressed: () async {
                            String? base64 = await pickImage();
                            if (base64 != null) {
                              setState(() {
                                q["question_image"] = base64;
                              });
                            }
                          },
                        ),
                        if (q["question_image"] != null)
                          const SizedBox(width: 10),
                        if (q["question_image"] != null)
                          const Icon(Icons.check, color: Colors.green)
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButton<String>(
                      value: q["question_type"],
                      items: const [
                        DropdownMenuItem(
                            value: "multiple-choice",
                            child: Text("Multiple Choice")),
                        DropdownMenuItem(
                            value: "true-false",
                            child: Text("True / False")),
                        DropdownMenuItem(
                            value: "voice-answer",
                            child: Text("Voice Answer")),
                      ],
                      onChanged: (v) {
                        q["question_type"] = v!;
                        if (v == "true-false") {
                          q["options"] = [
                            {
                              "optionType": "text",
                              "optionText": "true",
                              "optionImage": null,
                              "optionAudio": null,
                              "isCorrect": false
                            },
                            {
                              "optionType": "text",
                              "optionText": "false",
                              "optionImage": null,
                              "optionAudio": null,
                              "isCorrect": false
                            },
                          ];
                        } else if (v == "voice-answer") {
                          q["options"] = [];
                          q["correctAnswer"] = "";
                        } else {
                          q["options"] = List.generate(4, (i) => {
                                "optionType": "text",
                                "optionText": "",
                                "optionImage": null,
                                "optionAudio": null,
                                "isCorrect": false
                              });
                        }
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    if (q["question_type"] == "voice-answer")
                      TextField(
                        decoration: const InputDecoration(
                            labelText: "Correct Word (Teacher Input)"),
                        onChanged: (v) => q["correctAnswer"] = v,
                      ),
                    const SizedBox(height: 10),
                    // Options for multiple-choice or true-false
                    if (q["options"].isNotEmpty)
                      Column(
                        children: q["options"].asMap().entries.map<Widget>((optEntry) {
                          int optIndex = optEntry.key;
                          var opt = optEntry.value;
                          return Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration:
                                      InputDecoration(labelText: "Option ${optIndex + 1}"),
                                  onChanged: (v) {
                                    opt["optionText"] = v;
                                  },
                                ),
                              ),
                              Checkbox(
                                value: opt["isCorrect"],
                                onChanged: (v) {
                                  setState(() {
                                    for (var o in q["options"]) o["isCorrect"] = false;
                                    opt["isCorrect"] = true;
                                    q["correctAnswer"] = opt["optionText"];
                                  });
                                },
                              ),
                            ],
                          );
                        }).toList(),
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

// VoiceAnswerWidget for SolveQuiz
class VoiceAnswerWidget extends StatefulWidget {
  final String correctWord;
  const VoiceAnswerWidget({super.key, required this.correctWord});

  @override
  State<VoiceAnswerWidget> createState() => _VoiceAnswerWidgetState();
}

class _VoiceAnswerWidgetState extends State<VoiceAnswerWidget> {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _spokenText = "";

  Future<void> startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _spokenText = val.recognizedWords;
        });
      });
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void checkAnswer() {
    String spoken = _spokenText.toLowerCase().trim();
    String correct = widget.correctWord.toLowerCase().trim();

    if (spoken == correct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correct!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Incorrect, you said: $_spokenText")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isListening ? stopListening : startListening,
          child: Text(_isListening ? "Stop" : "Speak"),
        ),
        const SizedBox(height: 10),
        Text("You said: $_spokenText"),
        ElevatedButton(
          onPressed: checkAnswer,
          child: const Text("Check Answer"),
        ),
      ],
    );
  }
}
