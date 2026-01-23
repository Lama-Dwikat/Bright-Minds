// // edit_quiz_page.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// class EditQuizPage extends StatefulWidget {
//   final String videoId;
//   const EditQuizPage({super.key, required this.videoId});

//   @override
//   State<EditQuizPage> createState() => _EditQuizPageState();
// }

// class _EditQuizPageState extends State<EditQuizPage> {
//   Map<String, dynamic>? quizData;
//   bool loading = true;
//   String? userId;

//   final titleController = TextEditingController();
//   final descriptionController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _loadUserIdAndQuiz();
//   }

//   @override
//   void dispose() {
//     titleController.dispose();
//     descriptionController.dispose();
//     super.dispose();
//   }

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
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
//     setState(() => loading = true);
//     try {
//       final response = await http.get(
//         Uri.parse("${getBackendUrl()}/api/quiz/getQuizByVideoId/${widget.videoId}"),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data != null && data.isNotEmpty) {
//           setState(() {
//             quizData = data[0];
//             titleController.text = quizData!['title'] ?? '';
//             descriptionController.text = quizData!['description'] ?? '';
//             loading = false;
//           });
//         } else {
//           setState(() {
//             quizData = null;
//             loading = false;
//           });
//         }
//       } else {
//         setState(() {
//           quizData = null;
//           loading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         quizData = null;
//         loading = false;
//       });
//       debugPrint("Error fetching quiz: $e");
//     }
//   }

//   Future<void> deleteQuiz() async {
//     if (quizData == null) return;
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Delete quiz?'),
//         content: const Text('This will permanently delete the quiz. Continue?'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
//         ],
//       ),
//     );
//     if (ok != true) return;

//     final response = await http.delete(
//       Uri.parse("${getBackendUrl()}/api/quiz/deleteQuiz/${quizData!['_id']}"),
//     );
//     if (response.statusCode == 200) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz deleted successfully!")));
//         Navigator.pop(context);
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: ${response.body}")));
//       }
//     }
//   }
// Widget buildOptionsEditor(Map<String, dynamic> q, int qIndex) {
//   List options = q["options"] ?? [];

//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       const SizedBox(height: 10),
//       const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold)),

//       ...options.asMap().entries.map((entry) {
//         int optIndex = entry.key;
//         var opt = entry.value;

//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8),
//           child: Padding(
//             padding: const EdgeInsets.all(12),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Radio<bool>(
//                       value: true,
//                       groupValue: opt["isCorrect"] == true,
//                       onChanged: (_) {
//                         for (var o in options) {
//                           o["isCorrect"] = false;
//                         }
//                         opt["isCorrect"] = true;
//                         setState(() {});
//                       },
//                     ),
//                     const Text("Correct"),
//                   ],
//                 ),

//                 // Text option
//                 TextField(
//                   controller: TextEditingController(text: opt["optionText"] ?? ""),
//                   decoration: const InputDecoration(labelText: "Option Text"),
//                   onChanged: (v) => opt["optionText"] = v,
//                 ),

//                 const SizedBox(height: 10),

//                 // Image preview
//                 if (opt["optionImage"] != null)
//                   Image.memory(
//                     base64Decode(opt["optionImage"]),
//                     height: 100,
//                   ),

//                 const SizedBox(height: 10),

//                 Row(
//                   children: [
//                     ElevatedButton(
//                       onPressed: () async {
//                         final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//                         if (picked != null) {
//                           final bytes = await picked.readAsBytes();
//                           opt["optionImage"] = base64Encode(bytes);
//                           setState(() {});
//                         }
//                       },
//                       child: const Text("Upload Image"),
//                     ),
//                     const SizedBox(width: 10),
//                     if (opt["optionImage"] != null)
//                       TextButton(
//                         onPressed: () {
//                           opt["optionImage"] = null;
//                           setState(() {});
//                         },
//                         child: const Text("Remove Image"),
//                       ),
//                   ],
//                 ),

//                 const SizedBox(height: 10),

//                 // Audio word
//                 TextField(
//                   controller: TextEditingController(text: opt["optionAudio"] ?? ""),
//                   decoration: const InputDecoration(labelText: "Audio Word (TTS)"),
//                   onChanged: (v) => opt["optionAudio"] = v,
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     ],
//   );
// }

//   void openEditForm() {
//     if (quizData == null) return;
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => EditQuizFormPage(quizData: quizData!)),
//     ).then((_) => fetchQuiz()); // refresh after returning
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (quizData == null) {
//       return const Scaffold(body: Center(child: Text("No quiz found.")));
//     }

//     final questions = quizData!["questions"] as List<dynamic>? ?? [];

//     return Scaffold(
//       appBar: AppBar(title: Text(quizData!["title"] ?? "Edit Quiz")),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(12),
//         itemCount: questions.length,
//         itemBuilder: (context, index) {
//           final q = Map<String, dynamic>.from(questions[index] ?? {});
//           final options = List<dynamic>.from(q['options'] ?? []);
//           return Card(
//             margin: const EdgeInsets.only(bottom: 16),
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//                 Text("Q${index + 1}: ${q['question_text'] ?? ''}",
//                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                 const SizedBox(height: 6),
//                 if (q["question_image"] != null)
//                   Image.memory(base64Decode(q["question_image"]), height: 120, fit: BoxFit.cover),
//                 if (q["question_audio"] != null) ...[
//                   const SizedBox(height: 6),
//                   Text("Audio word: ${q['question_audio']}"),
//                 ],
//                 const SizedBox(height: 8),
//                 if (options.isNotEmpty)
//                   Column(
//                     children: options.map<Widget>((opt) {
//                       final isCorrect = opt['isCorrect'] == true;
//                       if (opt['optionText'] != null && (opt['optionText'] as String).isNotEmpty) {
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                           child: Text(opt['optionText'],
//                               style: TextStyle(
//                                   fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
//                                   color: isCorrect ? Colors.green : Colors.black)),
//                         );
//                       }
//                       if (opt['optionImage'] != null) {
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                           child: Image.memory(base64Decode(opt['optionImage']), height: 80),
//                         );
//                       }
//                       if (opt['optionAudio'] != null && (opt['optionAudio'] as String).isNotEmpty) {
//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 4),
//                           child: Row(children: [
//                             const Icon(Icons.volume_up),
//                             const SizedBox(width: 8),
//                             Text(opt['optionAudio']),
//                             if (isCorrect) ...[
//                               const SizedBox(width: 8),
//                               const Text('(correct)', style: TextStyle(color: Colors.green))
//                             ]
//                           ]),
//                         );
//                       }
//                       return const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 4),
//                         child: Text("No content"),
//                       );
//                     }).toList(),
//                   ),
//               ]),
//             ),
//           );
//         },
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(children: [
//           Expanded(child: ElevatedButton(onPressed: openEditForm, child: const Text("Edit Quiz"))),
//           const SizedBox(width: 10),
//           Expanded(
//             child: ElevatedButton(
//               onPressed: deleteQuiz,
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               child: const Text("Delete Quiz"),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }
// }

// /// ---------- Edit form page ----------
// /// Supports editing title/description, every question and option,
// /// add question (MCQ or voice), delete question, add/remove options, save changes.
// class EditQuizFormPage extends StatefulWidget {
//   final Map<String, dynamic> quizData;
//   const EditQuizFormPage({super.key, required this.quizData});

//   @override
//   State<EditQuizFormPage> createState() => _EditQuizFormPageState();
// }

// class _EditQuizFormPageState extends State<EditQuizFormPage> {
//   late List<Map<String, dynamic>> questions;
//   final titleController = TextEditingController();
//   final descriptionController = TextEditingController();
//   bool saving = false;

//   @override
//   void initState() {
//     super.initState();
//     // Deep copy to avoid mutating original until saved
//     questions = (widget.quizData['questions'] as List<dynamic>? ?? [])
//         .map((q) => Map<String, dynamic>.from(q as Map))
//         .toList();
//     titleController.text = widget.quizData['title'] ?? '';
//     descriptionController.text = widget.quizData['description'] ?? '';
//   }

//   @override
//   void dispose() {
//     titleController.dispose();
//     descriptionController.dispose();
//     super.dispose();
//   }

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
//   }

//   Future<void> pickQuestionImage(int qIndex) async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
//     if (file == null) return;
//     final bytes = await file.readAsBytes();
//     setState(() {
//       questions[qIndex]['question_image'] = base64Encode(bytes);
//     });
//   }

//   Future<void> pickOptionImage(int qIndex, int optIndex) async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
//     if (file == null) return;
//     final bytes = await file.readAsBytes();
//     setState(() {
//       questions[qIndex]['options'][optIndex]['optionImage'] = base64Encode(bytes);
//     });
//   }

//   void addMultipleChoiceQuestion() {
//     questions.add({
//       "question_type": "multiple-choice",
//       "question_text": "",
//       "question_image": null,
//       "question_audio": null,
//       "options": List.generate(4, (i) => {
//             "optionType": "text",
//             "optionText": "",
//             "optionImage": null,
//             "optionAudio": null,
//             "isCorrect": i == 0 // default first option correct=false? keep false to force teacher select
//           }),
//       "correctAnswer": "",
//     });
//     setState(() {});
//   }

//   void addVoiceAnswerQuestion() {
//     questions.add({
//       "question_type": "voice-answer",
//       "question_text": "",
//       "question_image": null,
//       "question_audio": "", // teacher provided word for TTS
//       "options": [],
//       "correctAnswer": "",
//     });
//     setState(() {});
//   }

//   void deleteQuestion(int index) {
//     showDialog<bool>(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Delete question?'),
//         content: const Text('This will remove the question from the quiz.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
//           ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
//         ],
//       ),
//     ).then((ok) {
//       if (ok == true) {
//         setState(() {
//           questions.removeAt(index);
//         });
//       }
//     });
//   }

//   void addOption(int qIndex) {
//     final q = questions[qIndex];
//     q['options'] = List<Map<String, dynamic>>.from(q['options'] ?? []);
//     q['options'].add({
//       "optionType": "text",
//       "optionText": "",
//       "optionImage": null,
//       "optionAudio": null,
//       "isCorrect": false
//     });
//     setState(() {});
//   }

//   void removeOption(int qIndex, int optIndex) {
//     final q = questions[qIndex];
//     if ((q['options'] as List).length <= 1) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("At least one option required.")));
//       return;
//     }
//     setState(() {
//       q['options'].removeAt(optIndex);
//     });
//   }

//   void markCorrectOption(int qIndex, int optIndex) {
//     final q = questions[qIndex];
//     for (int i = 0; i < (q['options'] as List).length; i++) {
//       q['options'][i]['isCorrect'] = i == optIndex;
//     }
//     // update correctAnswer field for backward compatibility
//     final correct = q['options'][optIndex];
//     if (correct['optionType'] == 'text') {
//       q['correctAnswer'] = correct['optionText'];
//     } else if (correct['optionType'] == 'audio') {
//       q['correctAnswer'] = correct['optionAudio'];
//     } else if (correct['optionType'] == 'image') {
//       q['correctAnswer'] = 'image';
//     }
//     setState(() {});
//   }

//   void changeQuestionType(int qIndex, String newType) {
//     final q = questions[qIndex];
//     q['question_type'] = newType;
//     if (newType == 'true-false') {
//       q['options'] = [
//         {"optionType": "text", "optionText": "true", "optionImage": null, "optionAudio": null, "isCorrect": false},
//         {"optionType": "text", "optionText": "false", "optionImage": null, "optionAudio": null, "isCorrect": false},
//       ];
//       q['correctAnswer'] = "";
//     } else if (newType == 'voice-answer') {
//       q['options'] = [];
//       q['question_audio'] = q['question_audio'] ?? ""; // teacher word
//       q['correctAnswer'] = q['correctAnswer'] ?? "";
//     } else {
//       // multiple-choice
//       q['options'] = q['options'] != null && (q['options'] as List).isNotEmpty
//           ? q['options']
//           : List.generate(4, (i) => {
//                 "optionType": "text",
//                 "optionText": "",
//                 "optionImage": null,
//                 "optionAudio": null,
//                 "isCorrect": false
//               });
//       q['correctAnswer'] = q['correctAnswer'] ?? "";
//     }
//     setState(() {});
//   }

//   Future<void> saveQuiz() async {
//     setState(() => saving = true);

//     final payload = {
//       "title": titleController.text,
//       "description": descriptionController.text,
//       "questions": questions,
//     };

//     try {
//       final response = await http.put(
//         Uri.parse("${getBackendUrl()}/api/quiz/updateQuiz/${widget.quizData['_id']}"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode(payload),
//       );

//       if (response.statusCode == 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz updated successfully!")));
//           Navigator.pop(context);
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
//       }
//     } finally {
//       if (mounted) setState(() => saving = false);
//     }
//   }

//   Widget buildOptionEditor(int qIndex, int optIndex) {
//     final opt = questions[qIndex]['options'][optIndex] as Map<String, dynamic>;
//     final optType = opt['optionType'] ?? 'text';

//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 6),
//       child: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Row(children: [
//             Expanded(
//               child: DropdownButtonFormField<String>(
//                 value: optType,
//                 items: const [
//                   DropdownMenuItem(value: "text", child: Text("Text")),
//                   DropdownMenuItem(value: "image", child: Text("Image")),
//                   DropdownMenuItem(value: "audio", child: Text("Audio (TTS word)")),
//                 ],
//                 onChanged: (v) {
//                   final newType = v ?? 'text';
//                   opt['optionType'] = newType;
//                   // reset fields
//                   if (newType == 'text') {
//                     opt['optionText'] = opt['optionText'] ?? "";
//                     opt['optionImage'] = null;
//                     opt['optionAudio'] = null;
//                   } else if (newType == 'image') {
//                     opt['optionImage'] = opt['optionImage'] ?? null;
//                     opt['optionText'] = "";
//                     opt['optionAudio'] = null;
//                   } else {
//                     opt['optionAudio'] = opt['optionAudio'] ?? "";
//                     opt['optionText'] = "";
//                     opt['optionImage'] = null;
//                   }
//                   setState(() {});
//                 },
//                 decoration: const InputDecoration(labelText: "Option type"),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Column(children: [
//               Row(children: [
//                 Checkbox(
//                     value: opt['isCorrect'] == true,
//                     onChanged: (_) => markCorrectOption(qIndex, optIndex)),
//                 const Text("Correct")
//               ])
//             ]),
//             const SizedBox(width: 8),
//             IconButton(
//                 onPressed: () => removeOption(qIndex, optIndex),
//                 icon: const Icon(Icons.delete, color: Colors.red)),
//           ]),
//           const SizedBox(height: 8),
//           if (opt['optionType'] == 'text') ...[
//             TextField(
//               decoration: InputDecoration(labelText: "Option text"),
//               controller: TextEditingController(text: opt['optionText'] ?? '')
//                 ..selection = TextSelection.collapsed(offset: (opt['optionText'] ?? '').length),
//               onChanged: (v) => opt['optionText'] = v,
//             ),
//           ] else if (opt['optionType'] == 'audio') ...[
//             TextField(
//               decoration: const InputDecoration(labelText: "TTS word for this option"),
//               controller: TextEditingController(text: opt['optionAudio'] ?? '')
//                 ..selection = TextSelection.collapsed(offset: (opt['optionAudio'] ?? '').length),
//               onChanged: (v) => opt['optionAudio'] = v,
//             ),
//           ] else if (opt['optionType'] == 'image') ...[
//             Row(children: [
//               ElevatedButton.icon(
//                   onPressed: () => pickOptionImage(qIndex, optIndex),
//                   icon: const Icon(Icons.image),
//                   label: const Text("Pick Image")),
//               const SizedBox(width: 8),
//               if (opt['optionImage'] != null) const Icon(Icons.check, color: Colors.green),
//             ]),
//           ],
//         ]),
//       ),
//     );
//   }

//   Widget buildQuestionEditor(int qIndex) {
//     final q = questions[qIndex];
//     final qType = q['question_type'] ?? 'multiple-choice';
//     q['options'] = q['options'] ?? [];

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//           Row(children: [
//             Text("Question ${qIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
//             const Spacer(),
//             IconButton(
//                 onPressed: () => deleteQuestion(qIndex),
//                 icon: const Icon(Icons.delete_forever, color: Colors.red))
//           ]),
//           const SizedBox(height: 8),
//           TextField(
//             decoration: const InputDecoration(labelText: "Question Text"),
//             controller: TextEditingController(text: q['question_text'] ?? '')
//               ..selection = TextSelection.collapsed(offset: (q['question_text'] ?? '').length),
//             onChanged: (v) => q['question_text'] = v,
//           ),
//           const SizedBox(height: 8),
//           TextField(
//             decoration: const InputDecoration(labelText: "Question Audio (TTS word, optional)"),
//             controller: TextEditingController(text: q['question_audio'] ?? '')
//               ..selection = TextSelection.collapsed(offset: (q['question_audio'] ?? '').length),
//             onChanged: (v) => q['question_audio'] = v,
//           ),
//           const SizedBox(height: 8),
//           Row(children: [
//             ElevatedButton.icon(onPressed: () => pickQuestionImage(qIndex), icon: const Icon(Icons.image), label: const Text("Pick Image")),
//             const SizedBox(width: 10),
//             if (q['question_image'] != null) const Icon(Icons.check, color: Colors.green)
//           ]),
//           const SizedBox(height: 12),
//           DropdownButtonFormField<String>(
//             value: qType,
//             items: const [
//               DropdownMenuItem(value: "multiple-choice", child: Text("Multiple Choice")),
//               DropdownMenuItem(value: "true-false", child: Text("True / False")),
//               DropdownMenuItem(value: "voice-answer", child: Text("Voice Answer")),
//             ],
//             onChanged: (v) {
//               changeQuestionType(qIndex, v ?? 'multiple-choice');
//             },
//             decoration: const InputDecoration(labelText: "Question Type"),
//           ),
//           const SizedBox(height: 12),
//           if (q['question_type'] == 'voice-answer') ...[
//             const Text("Voice answer question — teacher types the correct word below:"),
//             const SizedBox(height: 6),
//             TextField(
//               decoration: const InputDecoration(labelText: "Correct word (teacher input)"),
//               controller: TextEditingController(text: q['correctAnswer'] ?? '')
//                 ..selection = TextSelection.collapsed(offset: (q['correctAnswer'] ?? '').length),
//               onChanged: (v) => q['correctAnswer'] = v,
//             ),
//           ] else ...[
//             // Options editor
//             const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold)),
//             const SizedBox(height: 6),
//             Column(
//               children: List.generate((q['options'] as List).length, (optIndex) => buildOptionEditor(qIndex, optIndex)),
//             ),
//             const SizedBox(height: 8),
//             Row(children: [
//               ElevatedButton(onPressed: () => addOption(qIndex), child: const Text("Add Option")),
//               const SizedBox(width: 8),
//               ElevatedButton(
//                   onPressed: () {
//                     // quick helper: auto fill correctAnswer from selected option
//                     final correctOpt = (q['options'] as List).firstWhere((o) => o['isCorrect'] == true, orElse: () => null);
//                     if (correctOpt != null) {
//                       if (correctOpt['optionType'] == 'text') q['correctAnswer'] = correctOpt['optionText'];
//                       else if (correctOpt['optionType'] == 'audio') q['correctAnswer'] = correctOpt['optionAudio'];
//                       else q['correctAnswer'] = 'image';
//                       setState(() {});
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("correctAnswer updated from marked option")));
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No option marked correct")));
//                     }
//                   },
//                   child: const Text("Sync correctAnswer")),
//             ])
//           ]
//         ]),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Edit Quiz")),
//       body: saving
//           ? const Center(child: CircularProgressIndicator())
//           : ListView(
//               padding: const EdgeInsets.all(12),
//               children: [
//                 TextField(controller: titleController, decoration: const InputDecoration(labelText: "Quiz Title")),
//                 const SizedBox(height: 10),
//                 TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
//                 const SizedBox(height: 20),
//                 // question editors
//                 ...questions.asMap().entries.map((e) => buildQuestionEditor(e.key)).toList(),
//                 const SizedBox(height: 12),
//                 Row(children: [
//                   ElevatedButton(onPressed: addMultipleChoiceQuestion, child: const Text("Add MCQ")),
//                   const SizedBox(width: 8),
//                   ElevatedButton(onPressed: addVoiceAnswerQuestion, child: const Text("Add Voice Question")),
//                   const SizedBox(width: 8),
//                   ElevatedButton(
//                       onPressed: () {
//                         // clear all questions
//                         showDialog<bool>(
//                           context: context,
//                           builder: (_) => AlertDialog(
//                             title: const Text("Delete all questions?"),
//                             content: const Text("This will remove all questions from the quiz."),
//                             actions: [
//                               TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
//                               ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete All")),
//                             ],
//                           ),
//                         ).then((ok) {
//                           if (ok == true) {
//                             setState(() {
//                               questions.clear();
//                             });
//                           }
//                         });
//                       },
//                       style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                       child: const Text("Delete All Questions"))
//                 ]),
//                 const SizedBox(height: 20),
//                 ElevatedButton(onPressed: saveQuiz, child: const Text("Save Changes")),
//                 const SizedBox(height: 40),
//               ],
//             ),
//     );
//   }
// }



//   // floatingActionButton: FloatingActionButton(
//   //       onPressed: () => addMultipleChoiceQuestion(),
//   //       child: const Icon(Icons.add),
//   //      // tooltip: "Add Multiple Choice Question",
//   //     ),

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class EditQuizPage extends StatefulWidget {
  final String videoId;
  const EditQuizPage({super.key, required this.videoId});

  @override
  State<EditQuizPage> createState() => _EditQuizPageState();
}

class _EditQuizPageState extends State<EditQuizPage> {
  Map<String, dynamic>? quizData;
  bool loading = true;
  String? userId;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserIdAndQuiz();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
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
    setState(() => loading = true);
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
            titleController.text = quizData!['title'] ?? '';
            descriptionController.text = quizData!['description'] ?? '';
            loading = false;
          });
        } else {
          setState(() {
            quizData = null;
            loading = false;
          });
        }
      } else {
        setState(() {
          quizData = null;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        quizData = null;
        loading = false;
      });
      debugPrint("Error fetching quiz: $e");
    }
  }

  Future<void> deleteQuiz() async {
    if (quizData == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete quiz?'),
        content: const Text('This will permanently delete the quiz. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;

    final response = await http.delete(
      Uri.parse("${getBackendUrl()}/api/quiz/deleteQuiz/${quizData!['_id']}"),
    );
    if (response.statusCode == 200) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz deleted successfully!")));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: ${response.body}")));
      }
    }
  }

  void openEditForm() {
    if (quizData == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditQuizFormPage(quizData: quizData!)),
    ).then((_) => fetchQuiz()); // refresh after returning
  }

  // --- DESIGN STYLES ---
  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  BoxDecoration optionDecoration(bool isCorrect) {
    return BoxDecoration(
      color: isCorrect ? Colors.green.shade100 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (quizData == null) {
      return const Scaffold(body: Center(child: Text("No quiz found.")));
    }

    final questions = quizData!["questions"] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(quizData!["title"] ?? "Edit Quiz",style:TextStyle( color:Colors.white)),
        backgroundColor: const Color.fromARGB(255, 193, 160, 42),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final q = Map<String, dynamic>.from(questions[index] ?? {});
          final options = List<dynamic>.from(q['options'] ?? []);
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: cardDecoration(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Q${index + 1}: ${q['question_text'] ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              if (q["question_image"] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.memory(base64Decode(q['question_image']), height: 120, fit: BoxFit.cover),
                ),
              if (q["question_audio"] != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.volume_up, color: Color.fromARGB(255, 223, 183, 63)),
                  const SizedBox(width: 6),
                  Text(q['question_audio']),
                ]),
              ],
              const SizedBox(height: 8),
              if (options.isNotEmpty)
                Column(
                  children: options.map<Widget>((opt) {
                    final isCorrect = opt['isCorrect'] == true;
                    if (opt['optionText'] != null && (opt['optionText'] as String).isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: optionDecoration(isCorrect),
                        child: Text(opt['optionText'],
                            style: TextStyle(
                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                color: isCorrect ? Colors.green.shade800 : Colors.black87)),
                      );
                    }
                    if (opt['optionImage'] != null) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Image.memory(base64Decode(opt['optionImage']), height: 80),
                      );
                    }
                    if (opt['optionAudio'] != null && (opt['optionAudio'] as String).isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: optionDecoration(isCorrect),
                        child: Row(children: [
                          const Icon(Icons.volume_up, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(opt['optionAudio']),
                        ]),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text("No content"),
                    );
                  }).toList(),
                ),
            ]),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: openEditForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 181, 153, 49),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Edit Quiz", style: TextStyle(fontSize: 16, color:Colors.white)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: deleteQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 211, 170, 58),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text("Delete Quiz", style: TextStyle(fontSize: 16, color:Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// ---------- EditQuizFormPage ----------
/// Only design updated (cards, shadows, spacing, colors)
class EditQuizFormPage extends StatefulWidget {
  final Map<String, dynamic> quizData;
  const EditQuizFormPage({super.key, required this.quizData});

  @override
  State<EditQuizFormPage> createState() => _EditQuizFormPageState();
}

class _EditQuizFormPageState extends State<EditQuizFormPage> {
  late List<Map<String, dynamic>> questions;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    questions = (widget.quizData['questions'] as List<dynamic>? ?? [])
        .map((q) => Map<String, dynamic>.from(q as Map))
        .toList();
    titleController.text = widget.quizData['title'] ?? '';
    descriptionController.text = widget.quizData['description'] ?? '';
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(color: const Color.fromARGB(255, 200, 157, 38).withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 4)),
      ],
    );
  }

  BoxDecoration optionDecoration(bool isCorrect) {
    return BoxDecoration(
      color: isCorrect ? Colors.green.shade100 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: isCorrect ? Colors.green : Colors.grey.shade300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Quiz"), backgroundColor: const Color.fromARGB(255, 193, 162, 41)),
      body: saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                      labelText: "Quiz Title",
                      filled: true,
                      fillColor: Colors.purple.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                      labelText: "Description",
                      filled: true,
                      fillColor: Colors.blue.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 20),
                ...questions.asMap().entries.map((e) {
                  final qIndex = e.key;
                  final q = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Question ${qIndex + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.delete_forever, color: Colors.red)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: TextEditingController(text: q['question_text']),
                          decoration: const InputDecoration(labelText: "Question Text"),
                          onChanged: (v) => q['question_text'] = v,
                        ),
                        const SizedBox(height: 6),
                        // options can also use optionDecoration in buildOptionEditor
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
