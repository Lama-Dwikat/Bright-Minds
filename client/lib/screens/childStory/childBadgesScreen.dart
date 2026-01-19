import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ChildBadgesScreen extends StatefulWidget {
  final String childName;

  const ChildBadgesScreen({super.key, required this.childName});

  @override
  State<ChildBadgesScreen> createState() => _ChildBadgesScreenState();
}

class _ChildBadgesScreenState extends State<ChildBadgesScreen> {
  List<dynamic> badges = [];
  bool isLoading = true;

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/badge/my"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      print("📌 Badge response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        setState(() {
          badges = decoded["badges"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("⚠ Error loading badges: $e");
      setState(() => isLoading = false);
    }
  }

  // ===================== WEB RESPONSIVE HELPERS (UI ONLY) =====================
  double _maxContentWidth(double w) {
    if (w >= 900) return 1000; // وسّط المحتوى بالويب
    return w;
  }

  int _gridCountForWidth(double w) {
    if (w < 600) return 2;   // موبايل
    if (w < 900) return 3;   // تابلت/ويب صغير
    return 4;                // ويب أكبر
  }

  double _childAspectRatioForWidth(double w) {
    // نخلي الكارد متوازن بالويب
    if (w >= 900) return 1.05;
    return 1.0;
  }
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD8C4),
        elevation: 0,
        title: Text(
          "Badges",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6E4A4A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6E4A4A)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : badges.isEmpty
              ? Center(
                  child: Text(
                    "No badges yet 🥺",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: const Color(0xFF6E4A4A),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final maxW = _maxContentWidth(w);

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                "Your Achievements 🎉",
                                style: GoogleFonts.poppins(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6E4A4A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: GridView.builder(
                                  itemCount: badges.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _gridCountForWidth(w),
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio:
                                        _childAspectRatioForWidth(w),
                                  ),
                                  itemBuilder: (context, index) {
                                    final badge = badges[index];

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFE9CC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFF1C58A),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFE4B5)
                                                .withOpacity(0.6),
                                            blurRadius: 6,
                                            offset: const Offset(2, 3),
                                          )
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.emoji_events,
                                            size: 52,
                                            color: Color(0xFFCC8C39),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "${badge["type"]}",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF6E4A4A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
class ChildBadgesScreen extends StatefulWidget {
  final String childName;

  const ChildBadgesScreen({super.key, required this.childName});

  @override
  State<ChildBadgesScreen> createState() => _ChildBadgesScreenState();
}

class _ChildBadgesScreenState extends State<ChildBadgesScreen> {
  List<dynamic> badges = [];
  bool isLoading = true;

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

 Future<void> _loadBadges() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${getBackendUrl()}/api/badge/my"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("📌 Badge response: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      setState(() {
        badges = decoded["badges"] ?? [];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("⚠ Error loading badges: $e");
    setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFFFFD8C4),
        elevation: 0,
        title: Text(    
          "Badges",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF6E4A4A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6E4A4A)),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : badges.isEmpty
              ? Center(
                  child: Text(
                    "No badges yet 🥺",
                    style: GoogleFonts.poppins(
                        fontSize: 18, color: Color(0xFF6E4A4A)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "Your Achievements 🎉",
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6E4A4A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          itemCount: badges.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                          ),
                          itemBuilder: (context, index) {
                            final badge = badges[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE9CC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: const Color(0xFFF1C58A), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFE4B5)
                                        .withOpacity(0.6),
                                    blurRadius: 6,
                                    offset: const Offset(2, 3),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      size: 52, color: Color(0xFFCC8C39)),
                                  const SizedBox(height: 12),
                                  Text(
                                    badge["type"],
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6E4A4A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
*/