import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:bright_minds/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supervisorDrawingReview.dart';

/// موديل بسيط يمثل رسم طفل واحد
class KidDrawing {
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

  KidDrawing({
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

  factory KidDrawing.fromJson(Map<String, dynamic> json) {
    return KidDrawing(
      id: json['id'] ?? json['_id'],
      childName: json['childName'] ?? '',
      childAgeGroup: json['childAgeGroup'],
      activityTitle: json['activityTitle'],
      activityType: json['activityType'],
      rating: json['rating'],
      supervisorComment: json['supervisorComment'],
      imageBase64: json['imageBase64'],
      contentType: json['contentType'] ?? 'image/png',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

class SupervisorKidsDrawingsScreen extends StatefulWidget {
  const SupervisorKidsDrawingsScreen({super.key});

  @override
  State<SupervisorKidsDrawingsScreen> createState() =>
      _SupervisorKidsDrawingsScreenState();
}

class _SupervisorKidsDrawingsScreenState
    extends State<SupervisorKidsDrawingsScreen> {
  String? token;
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  List<KidDrawing> _allDrawings = [];

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000";
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator
      return "http://10.0.2.2:3000";
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS emulator
      return "http://localhost:3000";
    } else {
      // fallback
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
      final url =
          Uri.parse("${getBackendUrl()}/api/supervisor/kids-drawings");

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
          final List<KidDrawing> list = body
              .map((e) => KidDrawing.fromJson(e as Map<String, dynamic>))
              .toList();

          setState(() {
            _allDrawings = list;
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
          _errorMessage =
              "Failed to load drawings: ${response.statusCode}";
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

  List<KidDrawing> get _filteredDrawings {
    if (_searchQuery.trim().isEmpty) return _allDrawings;
    final q = _searchQuery.toLowerCase();
    return _allDrawings.where((d) {
      return d.childName.toLowerCase().contains(q);
    }).toList();
  }

  Uint8List _decodeImage(String base64Str) {
    return base64Decode(base64Str);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDrawings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kids Drawings",
          style: GoogleFonts.robotoSlab(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.bgWarmPink,
      ),
      body: Column(
        children: [
          // 🔍 حقل البحث عن طريق اسم الطفل
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
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // محتوى رئيسي
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
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final d = filtered[index];
                                return InkWell(
                                  onTap: () async {
                                    // نروح لشاشة الريفيو
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SupervisorDrawingReviewScreen(
                                          drawing: d,
                                        ),
                                      ),
                                    );
                                    // بعد الرجعة نعمل refresh
                                    _fetchKidsDrawings();
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // الصورة
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: Image.memory(
                                              _decodeImage(d.imageBase64),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                d.childName,
                                                style:
                                                    GoogleFonts.robotoSlab(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (d.activityTitle != null)
                                                Text(
                                                  d.activityTitle!,
                                                  style: GoogleFonts
                                                      .robotoSlab(
                                                    fontSize: 13,
                                                    color: Colors
                                                        .grey.shade700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              const SizedBox(height: 4),
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
                                                        ? d.rating
                                                            .toString()
                                                        : "No rating",
                                                    style:
                                                        GoogleFonts.robotoSlab(
                                                      fontSize: 12,
                                                      color: Colors
                                                          .grey.shade800,
                                                    ),
                                                  ),
                                                ],
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
