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
  Map<String, dynamic>? latestReview;
bool isReviewLoading = true;


  String getBackendUrl() {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStory();
     _loadLatestReview();
  }

  Future<void> _loadStory() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
     // Uri.parse('${getBackendUrl()}/api/story/getstorybyid/${widget.storyId}'),
     Uri.parse('${getBackendUrl()}/api/story/${widget.storyId}'),

      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        story = json.decode(response.body);
        isLoading = false;
      });
    } else {
      print(" Error fetching story: ${response.body}");
    }
  } catch (e) {
    print(" Error: $e");
  }
}



Future<void> _loadLatestReview() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('${getBackendUrl()}/api/reviewStory/story/${widget.storyId}?latestOnly=true'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print("🟣 REVIEW RESPONSE: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final list = data['data'];
      setState(() {
        if (list is List && list.isNotEmpty) {
          latestReview = list[0]; // آخر تعليق
        } else {
          latestReview = null;
        }
        isReviewLoading = false;
      });
    } else {
      setState(() => isReviewLoading = false);
      print("❌ Error fetching review: ${response.body}");
    }
  } catch (e) {
    print("⚠️ Review error: $e");
    setState(() => isReviewLoading = false);
  }
}


  Widget _buildPageContent(Map<String, dynamic> page) {
  return Stack(
    children: page["elements"].map<Widget>((el) {
      // ------ SAFE NUM PARSING ------
      final double x = (el["x"] ?? 0).toDouble();
      final double y = (el["y"] ?? 0).toDouble();
      final double width =
          el["width"] != null ? (el["width"] as num).toDouble() : 150;
      final double height =
          el["height"] != null ? (el["height"] as num).toDouble() : 150;

      // ------ TEXT ------
      if (el["type"] == "text") {
        return Positioned(
          left: x,
          top: y,
          child: Text(
            el["content"] ?? "",
            style: TextStyle(
              fontSize: (el["fontSize"] ?? 20).toDouble(),
              color: Colors.black,
            ),
          ),
        );
      }

      // ------ IMAGE ------
      if (el["type"] == "image" && el["media"]?["url"] != null) {
        final String url = el["media"]["url"];

        return Positioned(
          left: x,
          top: y,
          child: url.startsWith("assets/")
              ? Image.asset(
                  url,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  url,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                ),
        );
      }

      return const SizedBox();
    }).toList(),
  );
}


  void _nextPage() {
    if (currentPage < story!["pages"].length - 1) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _prevPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || story == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = story!["pages"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 185, 185),
        elevation: 0,
        title: Text(
          story!["title"] ?? "Story",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      ),

     body: Column(
  children: [
    Expanded(
      child: Stack(
        children: [
      // ------- Canvas -------
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.90,
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pink.shade100, width: 2),
              ),
              child: _buildPageContent(pages[currentPage]),
            ),
          ),

          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height * 0.40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  size: 32, color: Color(0xFFEBA1AB)),
              onPressed: _prevPage,
            ),
          ),
          Positioned(
            right: 10,
            top: MediaQuery.of(context).size.height * 0.40,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 32, color: Color(0xFFEBA1AB)),
              onPressed: _nextPage,
            ),
          ),
          Positioned(
            bottom: 30,
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
                  "Page ${currentPage + 1} / ${pages.length}",
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

    if (isReviewLoading)
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      )
    else if (latestReview != null)
      Container(
        width: double.infinity,
        margin:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBA1AB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Supervisor Comment",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE26A8B),
              ),
            ),
            const SizedBox(height: 6),
            if (latestReview!['rating'] != null)
              Row(
                children: List.generate(
                  (latestReview!['rating'] as num).toInt(),
                  (index) => const Icon(Icons.star,
                      color: Colors.amber, size: 18),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              latestReview!['comment'] ?? "No comment",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
      )
    else
      const SizedBox(height: 8),
  ],
),

    );
  }
}
