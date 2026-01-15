import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:bright_minds/screens/childStory.dart';
import 'package:bright_minds/screens/videosKids.dart';
import 'package:bright_minds/screens/videosKids.dart';
import 'package:bright_minds/screens/childStory/childStory.dart';
import 'package:bright_minds/screens/childStory/childPublishedStoriesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/screens/childStory/childBadgesScreen.dart';
import 'package:bright_minds/screens/childDrawing/childDrawingActivities.dart';
import 'package:http/http.dart' as http;


class HomeChild extends StatefulWidget {
  const HomeChild({super.key});

  @override
  _HomeChildState createState() => _HomeChildState();
}

class _HomeChildState extends State<HomeChild> {
  String childName = "Kid";

  // ✅ Quote state
  bool _quoteLoading = true;
  String _quoteText = "Keep going — you’re doing amazing! ⭐";
  String _quoteAuthor = "";
  String? _quoteError;

  // ✅ Auto refresh timer
  Timer? _quoteTimer;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  @override
  void initState() {
    super.initState();
    _loadChildName();
    _fetchKidsQuote();
    _startQuoteAutoRefresh();
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChildName() async {
  final prefs = await SharedPreferences.getInstance();

  final savedName =
      (prefs.getString("userName") ?? prefs.getString("name") ?? "Kid").trim();

  setState(() {
    childName = savedName.isEmpty ? "Kid" : savedName;
  });
}



  void _startQuoteAutoRefresh() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (!_quoteLoading) _fetchKidsQuote();
    });
  }

  Future<void> _fetchKidsQuote() async {
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _quoteLoading = false;
          _quoteError = "Token missing. Please login again.";
        });
        return;
      }

      final url = Uri.parse("${getBackendUrl()}/api/kids/quote");

      final resp = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final quote = data["quote"] ?? {};

        final text = (quote["text"] ?? "").toString();
        final author = (quote["author"] ?? "").toString();

        setState(() {
          _quoteText = text.isEmpty ? "Keep going — you’re doing amazing! ⭐" : text;
          _quoteAuthor = author;
          _quoteLoading = false;
        });
      } else {
        setState(() {
          _quoteLoading = false;
          _quoteError = "Failed to load quote (${resp.statusCode})";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quoteLoading = false;
        _quoteError = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ⭐ Dynamic greeting
            Text(
              "Hi, $childName! 👋",
              style: GoogleFonts.poppins(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB66A6A),
              ),
            ),
            Text(
              "Ready for a fun learning day?",
              style: GoogleFonts.poppins(
                fontSize: 25,
                color: const Color(0xFF5C4B51),
              ),
            ),

            const SizedBox(height: 24),

            // ✨ Quote box (API only)
            _quoteCard(),

            const SizedBox(height: 28),

            // 🔸 Menu buttons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              children: [
                _mainButton(
                  label: "Stories",
                  imagePath: "assets/images/story2.png",
                  color: const Color(0xFFFFD9C0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryKidsScreen()),
                    );
                  },
                ),
                _mainButton(
                  label: "Videos",
                  imagePath: "assets/images/video.png",
                  color: const Color(0xFFE6C8D5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideosKidScreen()),
                    );
                  },
                ),
                _mainButton(
                  label: "Games",
                  imagePath: "assets/images/Games.png",
                  color: const Color(0xFFEFD8D8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryKidsScreen()),
                    );
                  },
                ),
                _mainButton(
                  label: "Drawing",
                  imagePath: "assets/images/Drawing.png",
                  color: const Color(0xFFF9E2CE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChildDrawingActivitiesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 25),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChildPublishedStoriesScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD8C4),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        color: Color(0xFF6E4A4A), size: 38),
                    const SizedBox(width: 10),
                    Text(
                      "Published Kids Stories",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildBadgesScreen(childName: childName),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7C8),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFF6E4A4A), size: 38),
                    const SizedBox(width: 10),
                    Text(
                      "My Badges",
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4A4A),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ✅ Quote UI (no image)
  Widget _quoteCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6C9),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "✨ Quote of the Day ✨",
                  style: GoogleFonts.robotoSlab(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFAD5E5E),
                  ),
                ),
              ),
              IconButton(
                tooltip: "Refresh",
                onPressed: _quoteLoading ? null : _fetchKidsQuote,
                icon: const Icon(Icons.refresh, color: Color(0xFF6E4A4A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_quoteLoading)
            const Center(child: CircularProgressIndicator())
          else if (_quoteError != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                _quoteError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoSlab(
                  fontSize: 28,
                  color: const Color(0xFF5C4B51),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    _quoteText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 25,
                      color: const Color(0xFF5C4B51),
                    ),
                  ),
                  if (_quoteAuthor.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "- $_quoteAuthor",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4A4A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🌼 styled button component
  Widget _mainButton({
    required String label,
    IconData? icon,
    String? imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                height: 90,
                width: 90,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(icon, size: 48, color: const Color(0xFF8F5F5F)),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6F4C4C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
