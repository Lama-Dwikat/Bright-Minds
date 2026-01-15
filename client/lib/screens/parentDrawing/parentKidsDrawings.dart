import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:bright_minds/theme/colors.dart';

class ParentKidDrawing {
  final String id;
  final String childName;
  final String? childAgeGroup;
  final String? activityTitle;
  final String? activityType;
  final int? rating;
  final String? supervisorComment;
  final String imageBase64;
  final String contentType;
  final DateTime? createdAt;

  ParentKidDrawing({
    required this.id,
    required this.childName,
    this.childAgeGroup,
    this.activityTitle,
    this.activityType,
    this.rating,
    this.supervisorComment,
    required this.imageBase64,
    required this.contentType,
    this.createdAt,
  });

  factory ParentKidDrawing.fromJson(Map<String, dynamic> json) {
    return ParentKidDrawing(
      id: json['id'] ?? json['_id'],
      childName: json['childName'] ?? '',
      childAgeGroup: json['childAgeGroup'],
      activityTitle: json['activityTitle'],
      activityType: json['activityType'],
      rating: json['rating'],
      supervisorComment: json['supervisorComment'],
      imageBase64: json['imageBase64'],
      contentType: json['contentType'] ?? 'image/png',
      createdAt:
          json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class ParentKidsDrawingsScreen extends StatefulWidget {
  const ParentKidsDrawingsScreen({super.key});

  @override
  State<ParentKidsDrawingsScreen> createState() =>
      _ParentKidsDrawingsScreenState();
}

class _ParentKidsDrawingsScreenState extends State<ParentKidsDrawingsScreen> {
  String? token;
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  List<ParentKidDrawing> _drawings = [];

  String _searchChild = '';

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return "http://10.0.2.2:3000";
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      setState(() {
        _isError = true;
        _errorMessage = "No token found. Please sign in again.";
      });
      return;
    }
    _fetchKidsDrawings();
  }

  Future<void> _fetchKidsDrawings() async {
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final url = Uri.parse("${getBackendUrl()}/api/parent/kids-drawings");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          final list = body
              .map((e) => ParentKidDrawing.fromJson(e))
              .toList()
              .cast<ParentKidDrawing>();

          setState(() {
            _drawings = list;
          });
        } else {
          setState(() {
            _isError = true;
            _errorMessage = "Unexpected response format.";
          });
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = "Failed to load drawings: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ParentKidDrawing> get _filteredDrawings {
    if (_searchChild.trim().isEmpty) return _drawings;
    final q = _searchChild.toLowerCase();
    return _drawings.where((d) => d.childName.toLowerCase().contains(q)).toList();
  }

  Uint8List _decodeImage(String base64Str) {
    return base64Decode(base64Str);
  }

  void _openFullScreen(ParentKidDrawing d) {
    final bytes = _decodeImage(d.imageBase64);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenParentDrawingView(
          imageBytes: bytes,
          title: d.activityTitle ?? "Drawing",
          createdAt: d.createdAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDrawings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kids Drawings",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search by child name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) {
                setState(() {
                  _searchChild = v;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                    ? Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No drawings found.",
                              style: GoogleFonts.robotoSlab(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchKidsDrawings,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final d = filtered[index];
                                final imgBytes = _decodeImage(d.imageBase64);

                                return InkWell(
                                  onTap: () => _openFullScreen(d), // ✅ فتح Full Screen
                                  borderRadius: BorderRadius.circular(16),
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            topRight: Radius.circular(16),
                                          ),
                                          child: Image.memory(
                                            imgBytes,
                                            fit: BoxFit.cover,
                                            height: 180,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                d.childName,
                                                style: GoogleFonts.robotoSlab(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (d.childAgeGroup != null)
                                                Text(
                                                  "Age group: ${d.childAgeGroup}",
                                                  style: GoogleFonts.robotoSlab(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                              if (d.activityTitle != null)
                                                Text(
                                                  "Activity: ${d.activityTitle}",
                                                  style: GoogleFonts.robotoSlab(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                ),
                                              const SizedBox(height: 6),

                                              // ⭐ Rating
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 18,
                                                    color: d.rating != null
                                                        ? Colors.amber
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    d.rating != null
                                                        ? "Rating: ${d.rating}"
                                                        : "No rating yet",
                                                    style: GoogleFonts.robotoSlab(
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),

                                              // 💬 Comment
                                              if (d.supervisorComment != null &&
                                                  d.supervisorComment!.isNotEmpty)
                                                Text(
                                                  "Comment: ${d.supervisorComment}",
                                                  style: GoogleFonts.robotoSlab(
                                                    fontSize: 13,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                )
                                              else
                                                Text(
                                                  "No comment from supervisor yet",
                                                  style: GoogleFonts.robotoSlab(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),

                                              const SizedBox(height: 6),
                                              Text(
                                                "Tap to view 👆",
                                                style: GoogleFonts.robotoSlab(
                                                  fontSize: 12,
                                                  color: Colors.black54,
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
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ================= FULL SCREEN VIEW =================
class _FullScreenParentDrawingView extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;
  final DateTime? createdAt;

  const _FullScreenParentDrawingView({
    required this.imageBytes,
    required this.title,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle = "";
    if (createdAt != null) {
      subtitle = DateFormat("d MMM yyyy, HH:mm").format(createdAt!.toLocal());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.bgWarmPink,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: InteractiveViewer(
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
