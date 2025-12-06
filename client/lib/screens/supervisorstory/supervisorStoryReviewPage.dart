import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ReadOnlyStoryPage extends StatefulWidget {
  final String storyId;

  const ReadOnlyStoryPage({super.key, required this.storyId});

  @override
  State<ReadOnlyStoryPage> createState() => _ReadOnlyStoryPageState();
}

class _ReadOnlyStoryPageState extends State<ReadOnlyStoryPage> {
  Map<String, dynamic>? story;
  bool isLoading = true;
  int currentPage = 0;

  String getBackendUrl() {
    if (kIsWeb) return "http://localhost:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse("${getBackendUrl()}/api/story/getstorybyid/${widget.storyId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        setState(() {
          story = json.decode(res.body);
          isLoading = false;
        });
      } else {
        print("❌ Error fetching story: ${res.body}");
      }
    } catch (e) {
      print("⚠️ Error: $e");
    }
  }



void _openWriteReviewDialog() {
  int selectedStars = 0;
  TextEditingController commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (context, setInnerState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Write Review",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE06D78),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ⭐⭐⭐⭐⭐
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setInnerState(() {
                            selectedStars = i + 1;
                          });
                        },
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  // 💬 Comment box
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      filled: true,
                      hintText: "Write your feedback here...",
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ✔️ Submit Button
                  ElevatedButton(
                    onPressed: () {
                      _submitReview(selectedStars, commentController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEBA1AB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                    ),
                    child: Text(
                      "Submit Review",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}


 Future<void> _submitReview(int stars, String comment) async {
  if (stars == 0) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Please select rating")));
    return;
  }

  SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("token");

  final body = {
    "storyId": widget.storyId,
    "rating": stars,
    "comment": comment,
  };

  final res = await http.post(
    Uri.parse("${getBackendUrl()}/api/reviewStory"),
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json"
    },
    body: jsonEncode(body),
  );

  Navigator.pop(context); // اغلاق الدايلوج

  if (res.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Review submitted successfully")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${res.body}")),
    );
  }
}


  // ----- رسم عناصر الصفحة -----
  Widget _buildPageContent(Map<String, dynamic> page) {
    return Stack(
      children: page["elements"].map<Widget>((el) {
        if (el["type"] == "text") {
          return Positioned(
            left: (el["x"] ?? 0).toDouble(),
            top: (el["y"] ?? 0).toDouble(),
            child: Text(
              el["content"] ?? "",
              style: TextStyle(
                fontSize: (el["fontSize"] ?? 20).toDouble(),
                color: Colors.black,
              ),
            ),
          );
        }

        if (el["type"] == "image" && el["media"]?["url"] != null) {
          return Positioned(
            left: (el["x"] ?? 0).toDouble(),
            top: (el["y"] ?? 0).toDouble(),
            child: (el["media"]["url"].toString().startsWith("assets/")
                ? Image.asset(
                    el["media"]["url"],
                    width: (el["width"] ?? 150).toDouble(),
                    height: (el["height"] ?? 150).toDouble(),
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    el["media"]["url"],
                    width: (el["width"] ?? 150).toDouble(),
                    height: (el["height"] ?? 150).toDouble(),
                    fit: BoxFit.cover,
                  )),
          );
        }

        return const SizedBox();
      }).toList(),
    );
  }

  void _nextPage() {
    if (currentPage < story!["pages"].length - 1) {
      setState(() => currentPage++);
    }
  }

  void _prevPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || story == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = story!["pages"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
  backgroundColor: const Color(0xFFEBA1AB),
  elevation: 0,
  title: Text(
    "Review Story",
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),
  actions: [
  // يظهر فقط للسوبرفايزر
  FutureBuilder<SharedPreferences>(
    future: SharedPreferences.getInstance(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return SizedBox();

final role = snapshot.data!.getString("userRole") ?? "";
print("ROLE FROM PREFS = $role");
      if (role != "supervisor") return SizedBox();

      return TextButton(
        onPressed: _openWriteReviewDialog,
        child: Text(
          "Write Review",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    },
  ),
],

),



     body: Column(
  children: [
    const SizedBox(height: 10),

    // 🔶 عنوان القصة
    Text(
      story!["title"] ?? "",
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE06D78),
      ),
    ),

    const SizedBox(height: 10),

    // 🔶 الكانفاس + الأسهم + العداد
    Expanded(
      child: Stack(
        children: [
          // ------- الكانفاس -------
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.90,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade100, width: 2),
              ),
              child: _buildPageContent(story!["pages"][currentPage]),
            ),
          ),

          // ------- Left Arrow -------
          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height * 0.30,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  size: 32, color: Color(0xFFEBA1AB)),
              onPressed: _prevPage,
            ),
          ),

          // ------- Right Arrow -------
          Positioned(
            right: 10,
            top: MediaQuery.of(context).size.height * 0.30,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 32, color: Color(0xFFEBA1AB)),
              onPressed: _nextPage,
            ),
          ),

          // ------- Page Counter -------
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBA1AB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Page ${currentPage + 1} / ${story!["pages"].length}",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),

    );
  }

  
}
