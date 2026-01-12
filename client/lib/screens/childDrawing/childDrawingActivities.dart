import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/childDrawing/childDrawingCanvas.dart';
import 'package:bright_minds/screens/childDrawing/childMyDrawings.dart';

class ChildDrawingActivitiesScreen extends StatefulWidget {
  const ChildDrawingActivitiesScreen({super.key});

  @override
  State<ChildDrawingActivitiesScreen> createState() =>
      _ChildDrawingActivitiesScreenState();
}

class _ChildDrawingActivitiesScreenState
    extends State<ChildDrawingActivitiesScreen> {
  bool isLoading = true;
  List activities = [];

  String? _sectionSessionId; // ✅ timing session id for drawing section

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    fetchActivities();
    _startSectionTiming(); // ✅ start section timing
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> _startSectionTiming() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final url = Uri.parse("${getBackendUrl()}/api/drawing/time/start");

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"scope": "section"}),
      );

      if (resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        _sectionSessionId = data["sessionId"];
      } else {
        debugPrint("start section timing failed: ${resp.statusCode} ${resp.body}");
      }
    } catch (e) {
      debugPrint("start section timing error: $e");
    }
  }

  Future<void> _stopSectionTiming() async {
    if (_sectionSessionId == null) return;

    try {
      final token = await _getToken();
      if (token == null) return;

      final url = Uri.parse("${getBackendUrl()}/api/drawing/time/stop");

      final resp = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"sessionId": _sectionSessionId}),
      );

      if (resp.statusCode == 200) {
        _sectionSessionId = null;
      } else {
        debugPrint("stop section timing failed: ${resp.statusCode} ${resp.body}");
      }
    } catch (e) {
      debugPrint("stop section timing error: $e");
    }
  }

  @override
  void dispose() {
    _stopSectionTiming(); // ✅ stop when leaving screen
    super.dispose();
  }

  Future<void> fetchActivities() async {
    final token = await _getToken();
    final url = Uri.parse("${getBackendUrl()}/api/activities");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        activities = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      debugPrint("Failed to load activities: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Drawing Activities",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
        actions: [
          IconButton(
            icon: const Icon(Icons.collections),
            tooltip: "My Drawings",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChildMyDrawingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        "No drawing activities available yet",
        style: GoogleFonts.robotoSlab(fontSize: 16),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChildDrawingCanvasScreen(
                  activityId: activity["_id"],
                  imageUrl: activity["imageUrl"],
                  title: activity["title"],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.bgWarmPinkLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    activity["imageUrl"],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity["title"],
                        style: GoogleFonts.robotoSlab(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Type: ${activity["type"]}",
                        style: GoogleFonts.robotoSlab(fontSize: 14),
                      ),
                      Text(
                        "Age Group: ${activity["ageGroup"]}",
                        style: GoogleFonts.robotoSlab(fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap to start drawing 🎨",
                        style: GoogleFonts.robotoSlab(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
