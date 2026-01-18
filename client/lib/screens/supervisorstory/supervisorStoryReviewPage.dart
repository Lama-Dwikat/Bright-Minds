import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  // ✅ Yellow theme
  static const Color kMainYellow = Color.fromARGB(255, 251, 222, 141);
  static const Color kSoftBg = Color(0xFFFFF8E6);
  static const Color kCanvasBg = Color(0xFFFFF3D9);
  static const Color kTextDark = Color(0xFF6E4A4A);

  // ✅ IMPORTANT: base canvas size that elements were designed on
  // غيّريهم لو مشروعك كان عامل الكانفا على مقاس مختلف
  static const double baseW = 360;
  static const double baseH = 640;

  String getBackendUrl() {
    if (kIsWeb) return "http://localhost:3000";
    return "http://10.0.2.2:3000"; // android emulator
  }

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse("${getBackendUrl()}/api/story/${widget.storyId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          story = json.decode(res.body);
          isLoading = false;
        });
      } else {
        // ignore: avoid_print
        print("❌ Error fetching story: ${res.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _openWriteReviewDialog() {
    int selectedStars = 0;
    final commentController = TextEditingController();

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
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 15),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return IconButton(
                          icon: Icon(
                            i < selectedStars ? Icons.star : Icons.star_border,
                            color: kMainYellow,
                            size: 36,
                          ),
                          onPressed: () {
                            setInnerState(() => selectedStars = i + 1);
                          },
                        );
                      }),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        filled: true,
                        hintText: "Write your feedback here...",
                        fillColor: kSoftBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: () {
                        _submitReview(selectedStars, commentController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMainYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: Text(
                        "Submit Review",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select rating")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
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
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${res.body}")),
      );
    }
  }

  // ✅ Canvas (portrait) + scale positions & sizes
  Widget _buildScaledPage(Map<String, dynamic> page, double canvasW, double canvasH) {
    final sx = canvasW / baseW;
    final sy = canvasH / baseH;

    final elements = (page["elements"] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Stack(
      children: elements.map<Widget>((el) {
        final type = (el["type"] ?? "").toString();

        final x = ((el["x"] ?? 0).toDouble()) * sx;
        final y = ((el["y"] ?? 0).toDouble()) * sy;

        if (type == "text") {
          final content = (el["content"] ?? "").toString();
          final fs = ((el["fontSize"] ?? 20).toDouble()) * ((sx + sy) / 2);

          return Positioned(
            left: x,
            top: y,
            child: Text(
              content,
              style: TextStyle(
                fontSize: fs,
                color: Colors.black,
              ),
            ),
          );
        }

        if (type == "image" && el["media"]?["url"] != null) {
          final url = el["media"]["url"].toString();
          final w = ((el["width"] ?? 150).toDouble()) * sx;
          final h = ((el["height"] ?? 150).toDouble()) * sy;

          final img = url.startsWith("assets/")
              ? Image.asset(url, width: w, height: h, fit: BoxFit.cover)
              : Image.network(url, width: w, height: h, fit: BoxFit.cover);

          return Positioned(left: x, top: y, child: img);
        }

        return const SizedBox.shrink();
      }).toList(),
    );
  }

  void _nextPage() {
    final pages = (story?["pages"] as List? ?? []);
    if (currentPage < pages.length - 1) {
      setState(() => currentPage++);
    }
  }

  void _prevPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
    }
  }

  double _maxWidth(double w) {
    if (!kIsWeb) return w;
    if (w >= 1400) return 980;
    if (w >= 1100) return 900;
    if (w >= 900) return 820;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || story == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = (story!["pages"] as List? ?? []);
    if (pages.isEmpty) {
      return const Scaffold(body: Center(child: Text("No pages found.")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kMainYellow,
        elevation: 0,
        title: Text(
          "Review Story",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final role = snapshot.data!.getString("userRole") ?? "";
              if (role != "supervisor") return const SizedBox();

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
      body: LayoutBuilder(
        builder: (context, c) {
          final maxW = _maxWidth(c.maxWidth);

          // ✅ Portrait canvas: 3/4 ratio (width/height = 0.75)
          // يعني height أكبر من width
          const portraitRatio = 3 / 4;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: Column(
                  children: [
                    const SizedBox(height: 6),

                    Text(
                      (story!["title"] ?? "").toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kTextDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: Stack(
                        children: [
                          // ------- CANVAS (Portrait) -------
                          Center(
                            child: AspectRatio(
                              aspectRatio: portraitRatio, // ✅ طولي
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kCanvasBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: kMainYellow.withOpacity(0.55),
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: LayoutBuilder(
                                    builder: (context, cc) {
                                      return _buildScaledPage(
                                        Map<String, dynamic>.from(pages[currentPage]),
                                        cc.maxWidth,
                                        cc.maxHeight,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ------- Left Arrow -------
                          Positioned(
                            left: 6,
                            top: c.maxHeight * 0.32,
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios, size: 30, color: kMainYellow),
                              onPressed: _prevPage,
                            ),
                          ),

                          // ------- Right Arrow -------
                          Positioned(
                            right: 6,
                            top: c.maxHeight * 0.32,
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward_ios, size: 30, color: kMainYellow),
                              onPressed: _nextPage,
                            ),
                          ),

                          // ------- Page Counter -------
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kMainYellow,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Page ${currentPage + 1} / ${pages.length}",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
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
              ),
            ),
          );
        },
      ),
    );
  }
}










/*import 'package:flutter/material.dart';
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
  Uri.parse("${getBackendUrl()}/api/story/${widget.storyId}"),
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
*/





/*
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

  // ✅ Yellow theme (as you requested)
  static const Color kMainYellow = Color.fromARGB(255, 251, 222, 141);
  static const Color kSoftBg = Color(0xFFFFF8E6); // warm cream
  static const Color kCanvasBg = Color(0xFFFFF3D9); // slightly deeper cream
  static const Color kTextDark = Color(0xFF6E4A4A); // warm brown

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
        Uri.parse("${getBackendUrl()}/api/story/${widget.storyId}"),
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
                        color: kTextDark,
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
                            color: kMainYellow,
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
                        fillColor: kSoftBg,
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
                        backgroundColor: kMainYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: Text(
                        "Submit Review",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select rating")),
      );
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
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    Navigator.pop(context);

    if (res.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully")),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kMainYellow,
        elevation: 0,
        title: Text(
          "Review Story",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              final role = snapshot.data!.getString("userRole") ?? "";
              print("ROLE FROM PREFS = $role");
              if (role != "supervisor") return const SizedBox();

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
              color: kTextDark,
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
                      color: kCanvasBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kMainYellow.withOpacity(0.55), width: 2),
                    ),
                    child: _buildPageContent(story!["pages"][currentPage]),
                  ),
                ),

                // ------- Left Arrow -------
                Positioned(
                  left: 10,
                  top: MediaQuery.of(context).size.height * 0.30,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 32, color: kMainYellow),
                    onPressed: _prevPage,
                  ),
                ),

                // ------- Right Arrow -------
                Positioned(
                  right: 10,
                  top: MediaQuery.of(context).size.height * 0.30,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 32, color: kMainYellow),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: kMainYellow,
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

*/