
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

  @override
  void initState() {
    super.initState();
    _loadUserIdAndQuiz();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
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

  Future<void> submitQuiz() async {
    if (quizData == null) return;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Quiz submitted successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error submitting quiz: $e");
    }
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
      appBar: AppBar(title: Text(quizData!["title"] ?? "Solve Quiz")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final options = q["options"] as List<dynamic>;
          final questionType = q["question_type"];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Text with TTS
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Q${index + 1}: ${q["question_text"]}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => speak(q["question_text"] ?? ""),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Question Image
                  if (q["question_image"] != null)
                    Image.memory(
                      base64Decode(q["question_image"]),
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  // Question Audio (for TTS pronunciation)
                  if (q["question_audio"] != null &&
                      q["question_audio"].toString().isNotEmpty)
                    Row(
                      children: [
                        const Text("Listen Word: "),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => speak(q["question_audio"]),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),

                  // Voice-answer type
                  if (questionType == "voice-answer")
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: isListeningMap[index] == true
                                  ? () => stopListening(index)
                                  : () => startListening(index),
                              child: Text(isListeningMap[index] == true ? "Stop" : "Speak"),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text("You said: ${spokenAnswers[index] ?? ""}"),
                            ),
                            ElevatedButton(
                              onPressed: () => checkVoiceAnswer(index, q["correctAnswer"] ?? ""),
                              child: const Text("Check Answer"),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // Options for multiple-choice or true-false
                  if (questionType != "voice-answer")
                    Column(
                      children: options.asMap().entries.map((entry) {
                        int optIndex = entry.key;
                        var opt = entry.value;
                        Widget optionWidget;

                        if (opt["optionText"] != null &&
                            opt["optionText"].toString().isNotEmpty) {
                          optionWidget = Text(opt["optionText"]);
                        } else if (opt["optionImage"] != null &&
                            opt["optionImage"].toString().isNotEmpty) {
                          optionWidget = Image.memory(
                            base64Decode(opt["optionImage"]),
                            height: 100,
                            fit: BoxFit.cover,
                          );
                        } else if (opt["optionAudio"] != null &&
                            opt["optionAudio"].toString().isNotEmpty) {
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

                        return Row(
                          children: [
                            Expanded(
                              child: RadioListTile(
                                title: optionWidget,
                                value: opt["optionText"] ??
                                    opt["optionAudio"] ??
                                    "Image_${index}_$optIndex",
                                groupValue: answers[index],
                                onChanged: (v) => selectAnswer(index, v),
                              ),
                            ),
                            // TTS for text options
                            if (opt["optionText"] != null &&
                                opt["optionText"].toString().isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.volume_up),
                                onPressed: () => speak(opt["optionText"]),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: submitQuiz,
          child: const Text("Submit Quiz"),
        ),
      ),
    );
  }
}
