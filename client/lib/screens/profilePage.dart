
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String parentName = "Loading...";
  List kidHistory = [];
  List kidQuizzes = [];
  String userId = "";
  Map<String, dynamic>? user;
  bool isLoading = true;

  // Collapsible flags
  bool showVideos = false;
  bool showQuizzes = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => isLoading = true);
    await _getUserId();
    await _fetchUser();

    if (user?["role"] == "child") {
      await _fetchParentName();
      await _getKidHistory(userId);
      await _getChildQuizzes(userId);
    }
    setState(() => isLoading = false);
  }

  Future<void> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString("token") ?? "";
    if (token.isNotEmpty) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];
    }
  }

  Future<void> _fetchUser() async {
    try {
      final response =
          await http.get(Uri.parse('${getBackendUrl()}/api/users/getme/$userId'));

      if (response.statusCode == 200) {
        setState(() {
          user = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    }
  }

  Future<void> _fetchParentName() async {
    final parentId = user?["parentId"];
    if (parentId == null) {
      setState(() => parentName = "N/A");
      return;
    }

    try {
      final response =
          await http.get(Uri.parse('${getBackendUrl()}/api/users/getme/$parentId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          parentName = data["name"] ?? "N/A";
        });
      } else {
        setState(() => parentName = "N/A");
      }
    } catch (e) {
      setState(() => parentName = "N/A");
      debugPrint("Error fetching parent name: $e");
    }
  }

  int calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 0;
    DateTime dob = DateTime.parse(dobString);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _getKidHistory(String kidId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List history = jsonDecode(response.body);
        setState(() {
          kidHistory = history;
        });
      }
    } catch (err) {
      debugPrint("Error fetching history: $err");
    }
  }

  Future<void> _getChildQuizzes(String childId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/quiz/solvedByUser/$childId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          kidQuizzes = data["quizzes"] ?? [];
        });
      } else {
        setState(() => kidQuizzes = []);
      }
    } catch (err) {
      debugPrint("Error fetching child quizzes: $err");
      setState(() => kidQuizzes = []);
    }
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  // Edit field dialog
  /*Future<void> _editField(String field) async {
    final controller = TextEditingController(text: user?[field] ?? "");

    final updated = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit ${field[0].toUpperCase()}${field.substring(1)}"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $field"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (updated != null && updated.isNotEmpty) {
      final response = await http.put(
        Uri.parse('${getBackendUrl()}/api/users/updateprofile/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({field: updated}),
      );

      if (response.statusCode == 200) {
        setState(() {
          user?[field] = updated;
        });
      } else {
        debugPrint("Failed to update $field");
      }
    }
  }*/
  Future<void> _editField(String field) async {
  final controller = TextEditingController(text: user?[field] ?? "");

  final updated = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Edit ${field[0].toUpperCase()}${field.substring(1)}"),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: "Enter new $field"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text("Save"),
        ),
      ],
    ),
  );

  if (updated != null && updated.isNotEmpty) {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.put(
      Uri.parse('${getBackendUrl()}/api/users/updateprofile/$userId'),
      headers: {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode({field: updated}),
    );

    if (response.statusCode == 200) {
      setState(() {
        user?[field] = updated;
      });
    } else {
      debugPrint("Failed to update $field: ${response.body}");
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final age = calculateAge(user?["age"]);
    final profilePictureBytes = user?["profilePicture"]?["data"]?["data"];
    final profilePicture = (profilePictureBytes != null &&
            (profilePictureBytes is List || profilePictureBytes is Uint8List))
        ? ClipOval(
            child: Image.memory(
              Uint8List.fromList(List<int>.from(profilePictureBytes)),
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          )
        : CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.textAccent,
            child: Text(
              user?["name"]?.substring(0, 1).toUpperCase() ?? "U",
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );

    return HomePage(
      title: 'Profile',
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("User data not available"))
              : user?["role"] == "child"
                  ? SingleChildScrollView(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Card
                          Container(
                            margin: const EdgeInsets.only(top: 80),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 70),

                                // Name with edit
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      user?["name"] ?? "N/A",
                                      style: GoogleFonts.robotoSlab(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20, color: Colors.blue),
                                      onPressed: () {
                                        _editField("name");
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Age
                                Text(
                                  "Age: $age | Age Group: ${user?["ageGroup"] ?? "N/A"}",
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.black87),
                                ),
                                const SizedBox(height: 10),

                                // Email with edit
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Email: ${user?["email"] ?? "N/A"}",
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.black87),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20, color: Colors.blue),
                                      onPressed: () {
                                        _editField("email");
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Parent
                                Text(
                                  "Parent: $parentName",
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.black87),
                                ),

                                const SizedBox(height: 20),
                                const Divider(thickness: 1.2),
                                const SizedBox(height: 10),

                                // Video History Dropdown
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => showVideos = !showVideos),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Video History",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Icon(showVideos
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                    ],
                                  ),
                                ),
                                if (showVideos)
                                  kidHistory.isNotEmpty
                                      ? Column(
                                          children: List.generate(
                                              kidHistory.length, (index) {
                                            final video = kidHistory[index];
                                            final watchedAt =
                                                video["watchedAt"] != null
                                                    ? DateFormat('yyyy-MM-dd')
                                                        .format(DateTime.parse(
                                                            video["watchedAt"]))
                                                    : "N/A";
                                            final duration =
                                                video["durationWatched"] ?? 0;
                                            return ListTile(
                                              leading: const Icon(
                                                  Icons.play_circle_fill,
                                                  color:
                                                      AppColors.textAccent),
                                              title: Text(
                                                  "Video ID: ${video["videoId"]?["_id"] ?? "N/A"}"),
                                              subtitle: Text(
                                                  "Watched at: $watchedAt, Duration: $duration mins"),
                                            );
                                          }),
                                        )
                                      : const Text("No video history available."),

                                const SizedBox(height: 20),

                                // Quiz Dropdown
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => showQuizzes = !showQuizzes),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Quizzes Solved",
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Icon(showQuizzes
                                          ? Icons.expand_less
                                          : Icons.expand_more),
                                    ],
                                  ),
                                ),
                                if (showQuizzes)
                                  kidQuizzes.isNotEmpty
                                      ? Column(
                                          children: List.generate(
                                              kidQuizzes.length, (index) {
                                            final quiz = kidQuizzes[index];
                                            return ListTile(
                                              leading: const Icon(Icons.quiz,
                                                  color:
                                                      AppColors.textAccent),
                                              title:
                                                  Text(quiz["quizTitle"] ?? "N/A"),
                                              subtitle: Text(
                                                  "Total Mark: ${quiz["totalMark"] ?? 0} / ${quiz["totalPossibleMark"] ?? 0} | Attempt: ${quiz["attemptNumber"] ?? 0}"),
                                            );
                                          }),
                                        )
                                      : const Text("No quizzes solved yet."),
                              ],
                            ),
                          ),

                          // Profile picture
                          Positioned(
                            top: 20,
                            left: 0,
                            right: 0,
                            child: Center(child: profilePicture),
                          ),
                        ],
                      ),
                    )
:Center(
  child: SingleChildScrollView(
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // Card
        Container(
          width: MediaQuery.of(context).size.width * 0.85, // wider card
          margin: const EdgeInsets.only(top: 80),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 80), // space for avatar

              // Name (bigger)
              // Text(
              //   user?["name"] ?? "N/A",
              //   textAlign: TextAlign.center,
              //   style: GoogleFonts.robotoSlab(
              //     fontSize: 30,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      user?["name"] ?? "N/A",
      style: GoogleFonts.robotoSlab(
        fontSize: 30,
        fontWeight: FontWeight.bold,
      ),
    ),
    const SizedBox(width: 8),
    IconButton(
      icon: const Icon(Icons.edit, size: 22, color: Colors.blue),
      onPressed: () => _editField("name"),
      tooltip: "Edit name",
    ),
  ],
),

              const SizedBox(height: 16),

              // Email (bigger)
              // Text(
              //   user?["email"] ?? "N/A",
              //   textAlign: TextAlign.center,
              //   style: const TextStyle(
              //     fontSize: 20,
              //     color: Colors.black87,
              //   ),
              // ),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text(
      user?["email"] ?? "N/A",
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black87,
      ),
    ),
    const SizedBox(width: 6),
    IconButton(
      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
      onPressed: () => _editField("email"),
      tooltip: "Edit email",
    ),
  ],
),

              const SizedBox(height: 24),

              // Role badge (larger)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.textAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  user?["role"]?.toUpperCase() ?? "N/A",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textAccent,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 30), // extra height
            ],
          ),
        ),

        // Floating profile picture
        Positioned(
          top: 0,
          child: profilePicture,
        ),
      ],
    ),
  ),
),


     

    );
  }
}

