import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/childDrawing/childDrawingActivitiesByTypeScreen.dart';
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

  String? _sectionSessionId;

  String getBackendUrl() {
    if (kIsWeb) 
    //return "http://192.168.1.63:3000";
    return "http://localhost:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    fetchActivities();
    _startSectionTiming();
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
    _stopSectionTiming();
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

  int _countByType(String type) {
    return activities.where((a) => (a["type"] ?? "").toString() == type).length;
  }

  void _openType(String type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildDrawingActivitiesByTypeScreen(
          type: type,
          title: title,
          allActivities: activities,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Drawing",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.warmHoneyYellow,
        // ✅ زر معرض الرسومات
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library, size: 26),
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
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCategories(),
    );
  }

  Widget _buildCategories() {
    if (activities.isEmpty) {
      return Center(
        child: Text(
          "No drawing activities available yet",
          style: GoogleFonts.robotoSlab(fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
        children: [
          _categoryCard(
            title: "Free Drawing",
            subtitle: "${_countByType("coloring")} activities",
            assetPath: "assets/images/d5.png",
            onTap: () => _openType("coloring", "Free Drawing"),
          ),
          _categoryCard(
            title: "Color by Number",
            subtitle: "${_countByType("colorByNumber")} activities",
            assetPath: "assets/images/d2.png",
            onTap: () => _openType("colorByNumber", "Color by Number"),
          ),
          _categoryCard(
            title: "Tracing",
            subtitle: "${_countByType("tracing")} activities",
            assetPath: "assets/images/d3.png",
            onTap: () => _openType("tracing", "Tracing"),
          ),
          _categoryCard(
            title: "Drawing by Reference",
            subtitle: "${_countByType("surpriseColor")} activities",
            assetPath: "assets/images/d4.png",
            onTap: () => _openType("surpriseColor", "Drawing by Reference"),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required String title,
    required String subtitle,
    required String assetPath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Transform.scale(
                  scale: 1.50,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoSlab(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoSlab(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}