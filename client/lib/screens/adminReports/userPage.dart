import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserPage extends StatefulWidget {
  final Map user;

  const UserPage({super.key, required this.user});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late TextEditingController nameCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController passwordCtrl;
  bool get isChild => widget.user['role'] == 'child';
  List kidVideos = [];
  List kidGames = [];
  List kidQuizzes = [];
  Map? parent;
  Map? supervisor;



  String? ageGroup;
  String? cvStatus;

  bool editName = false;
  bool editEmail = false;
  bool editPassword = false;
  bool editAgeGroup = false;
  bool editCvStatus = false;
  bool showInfo = true;
  bool showGames = false;
  bool showVideos = false;
  bool showQuizzes = false;
  bool showKids = false;


  List games = [];
  List videos = [];
  List quizzes = [];
  List kids = [];
  DateTime? dateOfBirth;
  bool editDob = false;


  bool isLoading = true;
  bool get isAdmin => widget.user['role'] == 'admin';


  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.user['name']);
    emailCtrl = TextEditingController(text: widget.user['email']);
    passwordCtrl = TextEditingController();

    ageGroup = widget.user['ageGroup'];
    cvStatus = widget.user['cvStatus'];
     // ✅ Parse DOB from backend "age" field
    if (widget.user['age'] != null) {
       dateOfBirth = DateTime.parse(widget.user['age']);
  }

    _loadSupervisorData();
  }





Future<void> _getParentKids() async {
  final res = await http.get(
    Uri.parse("${getBackendUrl()}/api/users/getParentKids/${widget.user['_id']}"),
  );
  if (res.statusCode == 200) {
    kids = jsonDecode(res.body); // reuse the same `kids` list
  }
}



Future<void> _getKidVideos() async {
  final res = await http.get(
    Uri.parse("${getBackendUrl()}/api/history/getHistory/${widget.user['_id']}"),
  );
  if (res.statusCode == 200) {
    kidVideos = jsonDecode(res.body);
  }
}

Future<void> _getKidQuizzes() async {
  final res = await http.get(
    Uri.parse("${getBackendUrl()}/api/quiz/solvedByUser/${widget.user['_id']}"),
  );
  if (res.statusCode == 200) {
    kidQuizzes = jsonDecode(res.body)["quizzes"] ?? [];
  }
}

Future<void> _getKidGames() async {
  final res = await http.get(
    Uri.parse("${getBackendUrl()}/api/game/getUserGames/${widget.user['_id']}"),
  );
  if (res.statusCode == 200) {
    kidGames = jsonDecode(res.body);
  }
}

Future<void> _getParent() async {
  if (widget.user['parentId'] == null) return;
  final res = await http.get(
    Uri.parse("${getBackendUrl()}/api/users/getme/${widget.user['parentId']}"),
  );
  if (res.statusCode == 200) parent = jsonDecode(res.body);
}

Future<void> _getSupervisor() async {
  if (widget.user['supervisorId'] == null) return;
  final res = await http.get(
    Uri.parse("${getBackendUrl()}/api/users/getme/${widget.user['supervisorId']}"),
  );
  if (res.statusCode == 200) supervisor = jsonDecode(res.body);
}

Future<void> _pickDateOfBirth() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: dateOfBirth ?? DateTime(2015),
    firstDate: DateTime(2005),
    lastDate: DateTime.now(),
  );

  if (picked != null) {
    setState(() => dateOfBirth = picked);

    await _updateSupervisor({
      "age": picked.toIso8601String(), // ✅ backend format
    });

    setState(() => editDob = false);
  }
}



Future<void> _loadSupervisorData() async {
  if (isChild) {
    await Future.wait([
      _getKidVideos(),
      _getKidGames(),
      _getKidQuizzes(),
      _getParent(),
      _getSupervisor(),
    ]);
  } else if (widget.user['role'] == 'parent') {
    await _getParentKids(); // only fetch their kids
  } else {
    await Future.wait([
      _getGames(),
      _getVideos(),
      _getQuizzes(),
      _getKids(),
    ]);
  }

  setState(() => isLoading = false);
}



  // ================= API =================

  Future<void> _getGames() async {
    final res = await http.get(
      Uri.parse("${getBackendUrl()}/api/game/getGameBySupervisor/${widget.user['_id']}"),
    );
    if (res.statusCode == 200) games = jsonDecode(res.body);
  }

  Future<void> _getVideos() async {
    final res = await http.get(
      Uri.parse("${getBackendUrl()}/api/videos/getSupervisorVideos/${widget.user['_id']}"),
    );
    if (res.statusCode == 200) videos = jsonDecode(res.body);
  }

  Future<void> _getQuizzes() async {
    final res = await http.get(
      Uri.parse("${getBackendUrl()}/api/quiz/getQuizByCreator/${widget.user['_id']}"),
    );
    if (res.statusCode == 200) quizzes = jsonDecode(res.body);
  }

  Future<void> _getKids() async {
    final res = await http.get(
      Uri.parse("${getBackendUrl()}/api/users/kidsForSupervisor/${widget.user['_id']}"),
    );
    if (res.statusCode == 200) kids = jsonDecode(res.body);
  }

  // ================= UPDATE =================

  Future<void> _updateSupervisor(Map body) async {
    await http.patch(
      Uri.parse("${getBackendUrl()}/api/users/updateUser/${widget.user['_id']}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
  }

  // ================= DELETE =================

  Future<void> _deleteGame(String id) async {
    await http.delete(Uri.parse("${getBackendUrl()}/api/game/deleteGameById/$id"));
    _getGames();
    setState(() {});
  }

  Future<void> _deleteVideo(String id) async {
    await http.delete(Uri.parse("${getBackendUrl()}/api/videos/deleteVideoById/$id"));
    _getVideos();
    setState(() {});
  }

  Future<void> _deleteQuiz(String id) async {
    await http.delete(Uri.parse("${getBackendUrl()}/api/quiz/deleteQuiz/$id"));
    _getQuizzes();
    setState(() {});
  }
String get roleTitle {
  final role = widget.user['role']?.toString().toLowerCase();
  switch (role) {
    case 'child':
      return "Child";
    case 'supervisor':
      return "Supervisor";
    case 'parent':
      return "Parent";
     case 'admin':
      return "admin";  
    default:
      return "User";
  }
}



  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      //appBar: AppBar(title: const Text("Supervisor Details")),
      appBar: AppBar(
  title: Text(
     ("$roleTitle Details"),
    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold), // text color
  ),
  backgroundColor: const Color.fromARGB(255, 238, 194, 92), // AppBar background color
  centerTitle: true, // optional: centers the title
),

      body: 
       Container(
         
          height: double.infinity,
          child:SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _sectionTitle("$roleTitle Info"),

            _editableRow(
              label: "Name",
              controller: nameCtrl,
              isEditing: editName,
              onEdit: () => setState(() => editName = true),
              onSave: () async {
                await _updateSupervisor({"name": nameCtrl.text});
                setState(() => editName = false);
              },
            ),

            _editableRow(
              label: "Email",
              controller: emailCtrl,
              isEditing: editEmail,
              onEdit: () => setState(() => editEmail = true),
              onSave: () async {
                await _updateSupervisor({"email": emailCtrl.text});
                setState(() => editEmail = false);
              },
            ),

            _editableRow(
              label: "Password",
              controller: passwordCtrl,
              isEditing: editPassword,
              obscure: true,
              onEdit: () => setState(() => editPassword = true),
              onSave: () async {
                await _updateSupervisor({"password": passwordCtrl.text});
                passwordCtrl.clear();
                setState(() => editPassword = false);
              },
            ),

         _dropdownEditable(
    "Role",
    widget.user['role'],
    ["admin", "supervisor", "parent", "child"],
    false, // not editable inline
    () {}, // no edit
    (v) async {
      await _updateSupervisor({"role": v});
      setState(() {});
    },
  ),

 if (!isAdmin) ...[ 
if (isChild) ...[

   _dropdownEditable(
              "Age Group",
              ageGroup,
              ["5-8", "9-12"],
              editAgeGroup,
              () => setState(() => editAgeGroup = true),
              (v) async {
                ageGroup = v;
                await _updateSupervisor({"ageGroup": v});
                setState(() => editAgeGroup = false);
              },
            ),

  _editableDateRow(
  label: "Date of Birth",
  date: dateOfBirth,
  isEditing: editDob,
  onEdit: () => setState(() => editDob = true),
  onPick: _pickDateOfBirth,
),


  _dropdownSection(
    title: "Parent",
    expanded: showInfo,
    onToggle: () => setState(() => showInfo = !showInfo),
    children: [
      ListTile(
        title: Text(parent?['name'] ?? "N/A"),
        subtitle: Text(parent?['email'] ?? ""),
      )
    ],
  ),

  _dropdownSection(
    title: "Supervisor",
    expanded: showGames,
    onToggle: () => setState(() => showGames = !showGames),
    children: [
      ListTile(
        title: Text(supervisor?['name'] ?? "N/A"),
        subtitle: Text(supervisor?['email'] ?? ""),
      )
    ],
  ),

  _dropdownSection(
    title: "Videos Watched",
    expanded: showVideos,
    onToggle: () => setState(() => showVideos = !showVideos),
    children: kidVideos.isNotEmpty
        ? kidVideos.map<Widget>((h) {
            final video = h['videoId'];
            return ListTile(
              leading: Image.network(
                video?['thumbnailUrl'] ?? "",
                width: 50,
                errorBuilder: (_, __, ___) => const Icon(Icons.video_library),
              ),
              title: Text(video?['title'] ?? "Unknown"),
              subtitle: Text(
                "Watched: ${(h['durationWatched'] ?? 0).toString()} min",
              ),
            );
          }).toList()
        : [const Text("No videos watched")],
  ),

  _dropdownSection(
    title: "Games Played",
    expanded: showKids,
    onToggle: () => setState(() => showKids = !showKids),
  children: kidGames.isNotEmpty
    ? getUniqueGamesWithBestScore(kidGames).map<Widget>((g) {
        return ListTile(
          title: Text(g['gameName'] ?? g['name'] ?? "Game"),
          subtitle: Text("Score: ${g['score'] ?? 0}"),
        );
      }).toList()
    : [const Text("No games played")],

  ),

 _dropdownSection(
  title: "Quizzes Solved",
  expanded: showQuizzes,
  onToggle: () => setState(() => showQuizzes = !showQuizzes),
  children: kidQuizzes.isNotEmpty
      ? kidQuizzes.map<Widget>((q) {

          // ✅ ADD THESE TWO LINES HERE
          final userMark = getUserQuizMark(q);
          final totalMark = calculateTotalMark(q);

          return ListTile(
            title: Text(q['title'] ?? "Quiz"),
            subtitle: Text(
              "Score: $userMark / $totalMark",
            ),
          );
        }).toList()
      : [const Text("No quizzes solved")],
),


]else if (widget.user['role'] == 'parent') ...[
  // Only show one section: kids of this parent
  _dropdownSection(
    title: "Kids",
    expanded: showKids,
    onToggle: () => setState(() => showKids = !showKids),
    children: kids.isNotEmpty
        ? kids.map((k) => ListTile(
              title: Text(k['name'] ?? "No Name"),
              subtitle: Text(k['email'] ?? "No Email"),
            )).toList()
        : [const Text("No kids found")],
  ),
]



else...[

     _dropdownEditable(
              "Age Group",
              ageGroup,
              ["5-8", "9-12"],
              editAgeGroup,
              () => setState(() => editAgeGroup = true),
              (v) async {
                ageGroup = v;
                await _updateSupervisor({"ageGroup": v});
                setState(() => editAgeGroup = false);
              },
            ),

     _dropdownEditable(
              "CV Status",
              cvStatus,
              ["pending", "approved", "rejected"],
              editCvStatus,
              () => setState(() => editCvStatus = true),
              (v) async {
                cvStatus = v;
                await _updateSupervisor({"cvStatus": v});
                setState(() => editCvStatus = false);
              },
            ),

_dropdownSection(
  title: "Videos",
   expanded: showVideos,
    onToggle: () => setState(() => showVideos = !showVideos),
 children: [_videoList()],  
),

_dropdownSection(
  title: "Games",
  expanded: showGames,
  onToggle: () => setState(() => showGames = !showGames),
  children: games.isNotEmpty
      ? games.map<Widget>((g) => _buildGameInput(g)).toList()
      : [const Text("No games found")],
),



_dropdownSection(
  title: "Quizzes",
  expanded: showQuizzes,
  onToggle: () => setState(() => showQuizzes = !showQuizzes),
  children: [_listQuizzesWithDetails(quizzes, _deleteQuiz)],
),

 
_dropdownSection(
  title: "Kids Supervised",
   expanded: showKids,
    onToggle: () => setState(() => showKids = !showKids),
 children: [...kids.map((k) => ListTile(
                  title: Text(k['name']),
                  subtitle: Text(k['email']),
                )),],  
),
]
          ],
          ],
        ),
      ),
       ),
    );
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
Widget _editableRow({
  required String label,
  required TextEditingController controller,
  required bool isEditing,
  required VoidCallback onEdit,
  required VoidCallback onSave,
  bool obscure = false,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color.fromARGB(255, 165, 134, 10)), // border for the row
      borderRadius: BorderRadius.circular(6),
      color: const Color.fromARGB(255, 245, 245, 238), // light background for the row
    ),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            enabled: isEditing,
            style: TextStyle(
              color: Colors.grey[900], // darker text color for readability
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.grey[800], // label text color
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none, // remove default underline
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            isEditing ? Icons.save : Icons.edit,
            color: const Color.fromARGB(255, 214, 183, 23), // dark yellow icon
          ),
          onPressed: isEditing ? onSave : onEdit,
        )
      ],
    ),
  );
}

Widget _dropdownEditable(
  String label,
  String? value,
  List<String> items,
  bool isEditing,
  VoidCallback onEdit,
  Function(String) onSave,
) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade700), // border for dropdown
      borderRadius: BorderRadius.circular(6),
      color: const Color.fromARGB(255, 244, 242, 231),
    ),
    child: Row(
      children: [
        Expanded(
          child: isEditing
              ? DropdownButtonFormField<String>(
                  value: items.contains(value) ? value : null,
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                  items: items
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: TextStyle(color: Colors.grey[900]),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSave(v);
                  },
                )
              : TextFormField(
                  enabled: false,
                  initialValue: value ?? "Not set",
                  style: TextStyle(
                    color: Colors.grey[900], // dark text
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                  ),
                ),
        ),
        IconButton(
          icon: const Icon(
            Icons.edit,
            color: Color.fromARGB(255, 214, 183, 23), // dark yellow
          ),
          onPressed: onEdit,
        )
      ],
    ),
  );
}


Widget _editableDateRow({
  required String label,
  required DateTime? date,
  required bool isEditing,
  required VoidCallback onEdit,
  required VoidCallback onPick, // called when picking date
}) {
  final formatted = date != null
      ? "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"
      : "Not set";

  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: const Color.fromARGB(255, 165, 134, 10)), // same as _editableRow
      borderRadius: BorderRadius.circular(6),
      color: const Color.fromARGB(255, 245, 245, 238), // same as _editableRow
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatted,
                style: TextStyle(
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(
            isEditing ? Icons.calendar_today : Icons.edit,
            color: const Color.fromARGB(255, 214, 183, 23), // same as _editableRow
          ),
          onPressed: isEditing ? onPick : onEdit,
        ),
      ],
    ),
  );
}


  Widget _videoList() {
    if (videos.isEmpty) return const Text("No videos found");

    return Column(
      children: videos.map((v) {
        return Card(
          child: ListTile(
            leading: Image.network(
              v['thumbnailUrl']?? "https://via.placeholder.com/150",
              width: 80,
              fit: BoxFit.cover,
            ),
            title: Text(v['title'] ?? "Untitled"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Color.fromARGB(255, 214, 191, 20)),
              onPressed: () => _deleteVideo(v['_id']),
            ),
          ),
        );
      }).toList(),
    );
  }

Widget _dropdownSection({
  required String title,
  required bool expanded,
  required VoidCallback onToggle,
  required List<Widget> children,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
      ],
    ),
  );
}






Widget _listQuizzesWithDetails(List quizzes, Function(String) onDelete) {
  if (quizzes.isEmpty) return const Text("No quizzes found");

  return Column(
    children: quizzes.map((quiz) {
      final questions = quiz['questions'] as List? ?? [];

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      quiz['title'] ?? "Untitled Quiz",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromARGB(255, 209, 174, 36)),
                    onPressed: () => onDelete(quiz['_id']),
                  ),
                ],
              ),
              if (quiz['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(quiz['description']),
                ),

              // Quiz details
              Text(
                  "Level: ${quiz['level'] ?? '-'} | Duration: ${quiz['duration'] ?? '-'} mins | Age: ${quiz['ageGroup'] ?? '-'} | Attempts: ${quiz['attempts'] ?? '-'}"),
              const SizedBox(height: 8),

              // Questions
...questions.map((q) {
  final options = q['options'] as List? ?? [];
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
        color: const Color.fromARGB(255, 246, 243, 228),
        borderRadius: BorderRadius.circular(6)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Q: ${q['question_text'] ?? 'No question'}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        // ✅ Fixed image display
        if (q['question_image'] != null && q['question_image'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(q['question_image']),
                height: 70,
                width: 70,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => const Icon(Icons.broken_image),
              ),
            ),
          ),

        if (q['question_audio'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text("Audio: ${q['question_audio']}"),
          ),
        const SizedBox(height: 4),
        Text(
          "Options:",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        ...options.map((opt) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(opt['optionText'] ?? '-'),
                if (opt['isCorrect'] == true)
                  const Text(" ✅", style: TextStyle(color: Color.fromARGB(255, 214, 183, 23))),
              ],
            ),
          );
        }),
        Text(
          "Correct Answer: ${q['correctAnswer'] ?? '-'}",
          style: const TextStyle(color: Color.fromARGB(255, 91, 75, 9)),
        ),
      ],
    ),
  );
}).toList(),

            ],
          ),
        ),
      );
    }).toList(),
  );
 }

 




Widget _buildGameInput(Map game) {
  final textList = game['input'] as List? ?? [];


  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with game name and delete icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                game['name'] ?? "Untitled Game",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color.fromARGB(255, 200, 145, 17)),
                onPressed: () => _deleteGame(game['_id']),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Game input details
          if (textList.isNotEmpty)
            Column(
              children: textList.map((input) {
                final textItems = input['text'] as List? ?? [];
                final images = input['image'] as List? ?? [];
                final lettersClue = input['lettersClue'] as List? ?? [];
                final correctAnswer = input['correctAnswer'] as List? ?? [];
                final clue = input['clue'] ?? "-";

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 249, 246, 234),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (textItems.isNotEmpty)
                        Text("Text: ${textItems.map((e) => e ?? '-').join(' ')}"),
                      if (images.isNotEmpty)
                        Column(
                          children: images.map((img) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Image.network(
                                img,
                                height: 70,
                                width: 70,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, st) =>
                                    const Icon(Icons.broken_image),

                              ),
                            );
                          }).toList(),
                        ),
                      if (lettersClue.isNotEmpty)
                        Text("Letters clue: ${lettersClue.join(', ')}"),
                      if (correctAnswer.isNotEmpty)
                        Text(
                          "Correct Answer: ${correctAnswer.map((e) => e ?? '-').join(', ')}",
                        ),
                      if (clue != null && clue != "-")
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text("Clue: $clue"),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          if (textList.isEmpty) const Text("No input for this game"),
        ],
      ),
    ),
  );
}

List<Map<String, dynamic>> getUniqueGamesWithBestScore(List games) {
  final Map<String, Map<String, dynamic>> unique = {};

  for (final g in games) {
    final name = g['gameName'] ?? g['name'] ?? 'Unknown';
    final score = g['score'] ?? 0;

    if (!unique.containsKey(name)) {
      unique[name] = g;
    } else {
      final existingScore = unique[name]!['score'] ?? 0;
      if (score > existingScore) {
        unique[name] = g; // keep best score
      }
    }
  }

  return unique.values.toList();
}


int getUserQuizMark(Map quiz) {
  final submissions = quiz['submissions'] as List? ?? [];
  if (submissions.isEmpty) return 0;
  return submissions.last['totalMark'] ?? 0;
}


int calculateTotalMark(Map quiz) {
  int totalMark = 0;

  if (quiz["questions"] != null) {
    final questions = quiz["questions"] as List<dynamic>;
    for (var q in questions) {
      totalMark += (q["mark"] != null && q["mark"] > 0)
          ? q["mark"] as int
          : 1;
    }
  }

  return totalMark;
}



}



