
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';

class SolveQuizPage extends StatefulWidget {
  final String videoId;
  const SolveQuizPage({super.key, required this.videoId});

  @override
  State<SolveQuizPage> createState() => _SolveQuizPageState();
}

class _SolveQuizPageState extends State<SolveQuizPage> {
  Map<String, dynamic>? quizData;
  Map<int, dynamic> answers = {}; // stores selected answers
  Map<int, String> spokenAnswers = {}; // stores voice answers
  Map<int, bool> isListeningMap = {}; // track listening state per question
  bool loading = true;
  String? userId;
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
bool showResult = false;
int score = 0;
List<bool> correctAnswers = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndQuiz();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  Future<void> _loadUserIdAndQuiz() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token != null) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];
    }
    await fetchQuiz();
  }

  Future<void> fetchQuiz() async {
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/quiz/getQuizByVideoId/${widget.videoId}"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data.isNotEmpty) {
          setState(() {
            quizData = data[0];
            loading = false;
          });
        } else {
          setState(() => loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No quiz available for this video")),
          );
        }
      } else {
        setState(() => loading = false);
        print("Failed to load quiz: ${response.body}");
      }
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching quiz: $e");
    }
  }

  void selectAnswer(int questionIndex, dynamic answer) {
    setState(() {
      answers[questionIndex] = answer;
    });
  }

  // Future<void> submitQuiz() async {
  //   if (quizData == null) return;

  //   final payload = {
  //     "quizId": quizData!["_id"],
  //     "userId": userId,
  //     "answers": answers.entries.map((e) => {
  //       "questionIndex": e.key,
  //       "answer": e.value,
  //     }).toList(),
  //   };

  //   try {
  //     final response = await http.post(
  //       Uri.parse("${getBackendUrl()}/api/quiz/submitQuiz"),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(payload),
  //     );

  //     if (response.statusCode == 200) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Quiz submitted successfully!")),
  //       );
  //       Navigator.pop(context);
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Failed: ${response.body}")),
  //       );
  //     }
  //   } catch (e) {
  //     print("Error submitting quiz: $e");
  //   }
  // }
Future<void> submitQuiz() async {
  if (quizData == null) return;

  // submit to backend
  final payload = {
    "quizId": quizData!["_id"],
    "userId": userId,
    "answers": answers.entries.map((e) => {
      "questionIndex": e.key,
      "answer": e.value,
    }).toList(),
  };

  try {
    final response = await http.post(
      Uri.parse("${getBackendUrl()}/api/quiz/submitQuiz"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      // calculate result locally
      _calculateResult();

      // show result screen
      setState(() => showResult = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz submitted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
  } catch (e) {
    print("Error submitting quiz: $e");
  }
}

void _calculateResult() {
  if (quizData == null) return;
  final questions = quizData!["questions"] as List<dynamic>;

  int tempScore = 0;
  correctAnswers = [];

  for (int i = 0; i < questions.length; i++) {
    final q = questions[i];
    final correct = q["correctAnswer"];
    final answer = answers[i];

    if (q["question_type"] == "voice-answer") {
      double similarity = StringSimilarity.compareTwoStrings(
        (answer ?? "").toString().toLowerCase().trim(),
        (correct ?? "").toString().toLowerCase().trim()
      );
      if (similarity > 0.8) {
        tempScore++;
        correctAnswers.add(true);
      } else {
        correctAnswers.add(false);
      }
    } else {
      if (answer == correct) {
        tempScore++;
        correctAnswers.add(true);
      } else {
        correctAnswers.add(false);
      }
    }
  }

  score = tempScore;
}


  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await flutterTts.stop();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  Future<void> startListening(int questionIndex) async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => isListeningMap[questionIndex] = true);

      _speech.listen(
        onResult: (val) {
          setState(() {
            spokenAnswers[questionIndex] = val.recognizedWords;
          });
        },
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  Future<void> stopListening(int questionIndex) async {
    if (_speech.isListening) {
      await _speech.stop();
      setState(() => isListeningMap[questionIndex] = false);
    }
  }

void checkVoiceAnswer(int questionIndex, String correctAnswer) {
  final spoken = (spokenAnswers[questionIndex] ?? "").toLowerCase().trim();
  if (spoken.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No voice input detected!")),
    );
    return;
  }

  // Use similarity check
  double similarity = StringSimilarity.compareTwoStrings(spoken, correctAnswer.toLowerCase().trim());
  if (similarity > 0.8) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Correct!")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Incorrect, you said: $spoken")),
    );
  }

  answers[questionIndex] = spoken;
}


 @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (quizData == null) {
      return const Scaffold(
        body: Center(child: Text("No quiz found.")),
      );
    }

    final questions = quizData!["questions"] as List<dynamic>;
   

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
       // centerTitle: true,
        title: Text(
          quizData!["title"] ?? "Fun Quiz 🎉",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ),
      body:  showResult ? _buildResultView(questions) : _buildQuizView(questions),
      bottomNavigationBar: showResult ? null :
        Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          onPressed: submitQuiz,
          child: const Text(
            "🎉 Submit Quiz",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color:Colors.white),
          ),
        ),
      ),
      
    );
  }



_buildQuizView(List<dynamic>questions){
     return Container(
        decoration: quizBackground(),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            final options = q["options"] as List<dynamic>;
            final questionType = q["question_type"];

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: quizCardDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.purple,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q["question_text"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Colors.pink),
                        onPressed: () => speak(q["question_text"] ?? ""),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Question Image
                  if (q["question_image"] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        base64Decode(q["question_image"]),
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Question Audio
                  if (q["question_audio"] != null && q["question_audio"].toString().isNotEmpty)
                    Row(
                      children: [
                        const Text("🔊 Listen: "),
                        IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.purple),
                          onPressed: () => speak(q["question_audio"]),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),

                  // Voice-answer type
                  if (questionType == "voice-answer")
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🎤 Speak your answer!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(
                                  isListeningMap[index] == true ? Icons.stop : Icons.mic,
                                ),
                                label: Text(isListeningMap[index] == true ? "Stop" : "Speak"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 223, 159, 235),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: isListeningMap[index] == true
                                    ? () => stopListening(index)
                                    : () => startListening(index),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  spokenAnswers[index] ?? "Say something...",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => checkVoiceAnswer(index, q["correctAnswer"] ?? ""),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("✅ Check Answer"),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Multiple-choice / True-False
                  if (questionType != "voice-answer")
                    Column(
                      children: options.asMap().entries.map((entry) {
                        int optIndex = entry.key;
                        var opt = entry.value;
                        Widget optionWidget;

                        if (opt["optionText"] != null && opt["optionText"].toString().isNotEmpty) {
                          optionWidget = Text(opt["optionText"]);
                        } else if (opt["optionImage"] != null && opt["optionImage"].toString().isNotEmpty) {
                          optionWidget = Image.memory(
                            base64Decode(opt["optionImage"]),
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        } else if (opt["optionAudio"] != null && opt["optionAudio"].toString().isNotEmpty) {
                          optionWidget = Row(
                            children: [
                              const Text("Audio Option"),
                              IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: () => speak(opt["optionAudio"]),
                              ),
                            ],
                          );
                        } else {
                          optionWidget = const Text("No Content");
                        }

                        return RadioListTile(
                          value: opt["optionText"] ?? opt["optionAudio"] ?? "Image_${index}_$optIndex",
                          groupValue: answers[index],
                          onChanged: (v) => selectAnswer(index, v),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          tileColor: Colors.pink.shade50,
                          title: optionWidget,
                          activeColor: Colors.purple,
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
          
        ),
      );
}



Widget _buildResultView(List<dynamic> questions) {
  return Container(
    decoration: quizBackground(),
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          "Your Score: $score / ${questions.length}",
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final userAnswer = answers[index] ?? "No Answer";
              final correct = q["correctAnswer"] ?? "";

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: quizCardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q${index + 1}: ${q["question_text"]}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text("Your Answer: $userAnswer",
                        style: TextStyle(
                            color: correctAnswers[index] ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                    Text("Correct Answer: $correct",
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // go back to previous page
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("Back", style: TextStyle(fontSize: 20, color: Colors.white)),
        ),
      ],
    ),
  );
}



}






BoxDecoration quizBackground() {
  return const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFFFFD6E8),
        Color(0xFFD6ECFF),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}
BoxDecoration quizCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.pink.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
