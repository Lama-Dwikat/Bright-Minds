



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
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  

    void addMultipleChoiceQuestion() {
    questions.add({
      "question_type": "multiple-choice",
      "questionInputType": "text",
      "question_text": "",
      "question_image": null,
      "question_audio": null,
      "options": List.generate(4, (_) => {
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
 // if (!kIsWeb) 
  return Scaffold(
    backgroundColor: const Color(0xFFFFF3E0), // soft playful background
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 215, 146, 36),
      elevation: 0,
      title: const Text(
        "🧩 Create Quiz",
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
      ),
    ),

    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.orangeAccent,
      onPressed: addMultipleChoiceQuestion,
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: "Add Multiple Choice Question",
    ),

    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        /// Quiz Title
        TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: "Quiz Title *",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        /// Quiz Description
        TextField(
          controller: descriptionController,
          decoration: InputDecoration(
            labelText: "Description *",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.description, color: Colors.deepPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        /// Level Dropdown
        DropdownButtonFormField<String>(
          value: quizLevel,
          items: const [
            DropdownMenuItem(value: "easy", child: Text("Easy")),
            DropdownMenuItem(value: "medium", child: Text("Medium")),
            DropdownMenuItem(value: "hard", child: Text("Hard")),
          ],
          onChanged: (v) => setState(() => quizLevel = v!),
          decoration: InputDecoration(
            labelText: "Level",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.bar_chart, color: Colors.deepPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        /// Age Group Dropdown
        DropdownButtonFormField<String>(
          value: ageGroup,
          items: const [
            DropdownMenuItem(value: "5-8", child: Text("5-8 years")),
            DropdownMenuItem(value: "9-12", child: Text("9-12 years")),
          ],
          onChanged: (v) => setState(() => ageGroup = v!),
          decoration: InputDecoration(
            labelText: "Age Group",
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.child_care, color: Colors.deepPurple),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 25),

        /// Questions List
        ...questions.asMap().entries.map((entry) {
          int qIndex = entry.key;
          var q = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFECB3), Color.fromARGB(255, 243, 212, 158)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Question Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "📝 Question ${qIndex + 1}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 191, 150, 52),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                
TextField(
  decoration: InputDecoration(
    labelText: "Question Text",
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
  onChanged: (v) => q["question_text"] = v,
),

const SizedBox(height: 8),

/// Question Audio (typed text only)
TextField(
  decoration: InputDecoration(
    labelText: "Question Audio (typed text)",
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  ),
  onChanged: (v) => q["question_audio"] = v,
),

                  const SizedBox(height: 12),

                  /// Add Image Button
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 211, 176, 62),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Text("Add Image", style: TextStyle(color: Colors.white)),
                        onPressed: () async {
                          String? base64 = await pickImage();
                          if (base64 != null) {
                            setState(() {
                              q["question_image"] = base64;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      if (q["question_image"] != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// Question Type Dropdown
                  DropdownButton<String>(
                    value: q["question_type"],
                    items: const [
                      DropdownMenuItem(
                          value: "multiple-choice", child: Text("Multiple Choice")),
                      DropdownMenuItem(value: "true-false", child: Text("True / False")),
                      DropdownMenuItem(value: "voice-answer", child: Text("Voice Answer")),
                    ],
                    // onChanged: (v) {
                    //   q["question_type"] = v!;
                    //   setState(() {});
                    // },
                    onChanged: (v) {
  q["question_type"] = v!;

  if (v == "true-false") {
    q["options"] = q["options"].take(2).toList();
  }

  setState(() {});
},

                  ),
                  const SizedBox(height: 12),

                  /// Voice Answer Field
                  if (q["question_type"] == "voice-answer")
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Correct Word (Teacher Input)",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                        //  borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => q["correctAnswer"] = v,
                    ),
                  const SizedBox(height: 12),

                  /// Options for multiple-choice or true-false
                   if (q["options"].isNotEmpty && q["question_type"] != "voice-answer")

                 
if (q["options"].isNotEmpty && q["question_type"] != "voice-answer")
  Column(
    children: q["options"].asMap().entries.map<Widget>((optEntry) {
      int optIndex = optEntry.key;
      var opt = optEntry.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Choice Chips for Option Type
            Row(
              children: [
                ChoiceChip(
                  label: const Text("Text"),
                  selected: opt["optionType"] == "text",
                  onSelected: (_) {
                    setState(() {
                      opt["optionType"] = "text";
                      opt["optionImage"] = null;
                      opt["optionAudio"] = null;
                    });
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("Image"),
                  selected: opt["optionType"] == "image",
                  onSelected: (_) {
                    setState(() {
                      opt["optionType"] = "image";
                      opt["optionText"] = "";
                      opt["optionAudio"] = null;
                    });
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text("Audio"),
                  selected: opt["optionType"] == "audio",
                  onSelected: (_) {
                    setState(() {
                      opt["optionType"] = "audio";
                      opt["optionText"] = "";
                      opt["optionImage"] = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Conditional Input Based on Option Type
            if (opt["optionType"] == "text")
              TextField(
                decoration: InputDecoration(
                  labelText: "Option ${optIndex + 1} Text",
                  border: InputBorder.none,
                ),
                onChanged: (v) => opt["optionText"] = v,
              ),

            if (opt["optionType"] == "audio")
              TextField(
                decoration: InputDecoration(
                  labelText: "Option ${optIndex + 1} Audio (typed text)",
                  border: InputBorder.none,
                ),
                onChanged: (v) => opt["optionAudio"] = v,
              ),

            if (opt["optionType"] == "image")
              ElevatedButton(
                onPressed: () async {
                  String? base64 = await pickImage();
                  if (base64 != null) {
                    setState(() {
                      opt["optionImage"] = base64;
                    });
                  }
                },
                child: const Text("Pick Image"),
              ),

            /// Correct Answer Checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Checkbox(
                  value: opt["isCorrect"],
                  activeColor: const Color.fromARGB(255, 189, 154, 59),
                  onChanged: (v) {
                    setState(() {
                      for (var o in q["options"]) o["isCorrect"] = false;
                      opt["isCorrect"] = true;
                      // Set correctAnswer based on optionType
                      if (opt["optionType"] == "text") {
                        q["correctAnswer"] = opt["optionText"];
                      } else if (opt["optionType"] == "audio") {
                        q["correctAnswer"] = opt["optionAudio"];
                      } else if (opt["optionType"] == "image") {
                        q["correctAnswer"] = opt["optionImage"];
                      }
                    });
                  },
                ),
                const Text("Correct Answer"),
              ],
            ),
          ],
        ),
      );
    }).toList(),
  ),

                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 30),
      ],
    ),

    bottomNavigationBar: Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 211, 170, 58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: saveQuiz,
        child: const Text(
          "Save Quiz",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
}







  