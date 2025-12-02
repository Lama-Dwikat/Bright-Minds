// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// class SolveQuizPage extends StatefulWidget {
//   final String videoId;
//   const SolveQuizPage({super.key, required this.videoId});

//   @override
//   State<SolveQuizPage> createState() => _SolveQuizPageState();
// }

// class _SolveQuizPageState extends State<SolveQuizPage> {
//   Map<String, dynamic>? quizData;
//   Map<int, dynamic> answers = {}; // store selected answers
//   bool loading = true;
//   String? userId;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserIdAndQuiz();
//   }

//   // ---------------- BACKEND URL ----------------
//   String getBackendUrl() {
//     if (kIsWeb) {
//       return "http://192.168.1.63:3000";
//     } else if (Platform.isAndroid) {
//       return "http://10.0.2.2:3000";
//     } else if (Platform.isIOS) {
//       return "http://localhost:3000";
//     } else {
//       return "http://localhost:3000";
//     }
//   }

//   Future<void> _loadUserIdAndQuiz() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString("token");
//     if (token != null) {
//       Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//       userId = decodedToken['id'];
//     }
//     await fetchQuiz();
//   }

//   Future<void> fetchQuiz() async {
//     try {
//       final response = await http.get(
//         Uri.parse("${getBackendUrl()}/api/quiz/getQuizByVideoId/${widget.videoId}"),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data != null && data.isNotEmpty) {
//           setState(() {
//             quizData = data[0]; // take first quiz for this video
//             loading = false;
//           });
//         } else {
//           setState(() {
//             loading = false;
//           });
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("No quiz available for this video")),
//           );
//         }
//       } else {
//         setState(() => loading = false);
//         print("Failed to load quiz: ${response.body}");
//       }
//     } catch (e) {
//       setState(() => loading = false);
//       print("Error fetching quiz: $e");
//     }
//   }

//   void selectAnswer(int questionIndex, dynamic answer) {
//     setState(() {
//       answers[questionIndex] = answer;
//     });
//   }

//   Future<void> submitQuiz() async {
//     if (quizData == null) return;

//     final payload = {
//       "quizId": quizData!["_id"],
//       "userId": userId,
//       "answers": answers.entries.map((e) {
//         return {
//           "questionIndex": e.key,
//           "answer": e.value,
//         };
//       }).toList(),
//     };

//     try {
//       final response = await http.post(
//         Uri.parse("${getBackendUrl()}/api/quiz/submitQuiz"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(payload),
//       );

//       if (response.statusCode == 200) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Quiz submitted successfully!")),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Failed: ${response.body}")),
//         );
//       }
//     } catch (e) {
//       print("Error submitting quiz: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // if (loading) {
//     //   return const Scaffold(
//     //     appBar: AppBar(title: Text("Solve Quiz")),
//     //     body: Center(child: CircularProgressIndicator()),
//     //   );
//     // }

 
//     final questions = quizData!["questions"] as List<dynamic>;

//     return Scaffold(
//       appBar: AppBar(title: Text(quizData!["title"] ?? "Solve Quiz")),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: questions.length,
//         itemBuilder: (context, index) {
//           final q = questions[index];
//           final options = q["options"] as List<dynamic>;

//           return Card(
//             margin: const EdgeInsets.only(bottom: 16),
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("Q${index + 1}: ${q["question_text"]}",
//                       style: const TextStyle(
//                           fontWeight: FontWeight.bold, fontSize: 16)),
//                   const SizedBox(height: 10),
//                   ...options.map((opt) {
//                     return RadioListTile(
//                       title: Text(opt["optionText"]),
//                       value: opt["optionText"],
//                       groupValue: answers[index],
//                       onChanged: (v) => selectAnswer(index, v),
//                     );
//                   }).toList(),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(12),
//         child: ElevatedButton(
//           onPressed: submitQuiz,
//           child: const Text("Submit Quiz"),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SolveQuizPage extends StatefulWidget {
  final String videoId;
  const SolveQuizPage({super.key, required this.videoId});

  @override
  State<SolveQuizPage> createState() => _SolveQuizPageState();
}

class _SolveQuizPageState extends State<SolveQuizPage> {
  Map<String, dynamic>? quizData;
  Map<int, dynamic> answers = {};
  bool loading = true;
  String? userId;
  final FlutterTts flutterTts = FlutterTts(); // TTS instance

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
            quizData = data[0]; // take first quiz
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
    await flutterTts.stop();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
  

    final questions = quizData!["questions"] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(quizData!["title"] ?? "Solve Quiz")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = questions[index];
          final options = q["options"] as List<dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text("Q${index + 1}: ${q["question_text"]}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () => speak(q["question_text"]),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...options.map((opt) {
                    return Row(
                      children: [
                        Expanded(
                          child: RadioListTile(
                            title: Text(opt["optionText"]),
                            value: opt["optionText"],
                            groupValue: answers[index],
                            onChanged: (v) => selectAnswer(index, v),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () => speak(opt["optionText"] ?? ""),
                        ),
                      ],
                    );
                  }).toList(),
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
