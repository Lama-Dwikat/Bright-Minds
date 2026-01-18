import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';
import 'supervisorDrawingReview.dart';

class KidDrawing {
  final String id;
  final String childName;
  final String? childAgeGroup;
  final String? activityTitle;
  final String? activityType;
  final int? rating;
  final String? supervisorComment;
  final DateTime? createdAt;

  final String drawingUrl; // cloudinary url if exists

  KidDrawing({
    required this.id,
    required this.childName,
    this.childAgeGroup,
    this.activityTitle,
    this.activityType,
    this.rating,
    this.supervisorComment,
    this.createdAt,
    required this.drawingUrl,
  });

  factory KidDrawing.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final rawName = json['childName'] ?? json['child']?['name'];

    return KidDrawing(
      id: rawId?.toString() ?? "",
      childName: rawName?.toString() ?? "Unknown",
      childAgeGroup: json['childAgeGroup']?.toString(),
      activityTitle: json['activityTitle']?.toString(),
      activityType: json['activityType']?.toString(),
      rating: json['rating'] is int ? json['rating'] : int.tryParse("${json['rating']}"),
      supervisorComment: json['supervisorComment']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      drawingUrl: json['drawingUrl']?.toString() ?? "",
    );
  }
}

class SupervisorKidsDrawingsScreen extends StatefulWidget {
  const SupervisorKidsDrawingsScreen({super.key});

  @override
  State<SupervisorKidsDrawingsScreen> createState() =>
      _SupervisorKidsDrawingsScreenState();
}

class _SupervisorKidsDrawingsScreenState extends State<SupervisorKidsDrawingsScreen> {
  String? token;
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  String _searchQuery = '';
  List<KidDrawing> _allDrawings = [];

  String getBackendUrl() {
    if (kIsWeb) return "http://localhost:3000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
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
      final url = Uri.parse("${getBackendUrl()}/api/supervisor/kids-drawings");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is List) {
          final list = body
              .map((e) => KidDrawing.fromJson(e as Map<String, dynamic>))
              .toList();

          setState(() => _allDrawings = list);
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
              "Failed to load drawings: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage = "Error: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<KidDrawing> get _filteredDrawings {
    if (_searchQuery.trim().isEmpty) return _allDrawings;
    final q = _searchQuery.toLowerCase();
    return _allDrawings.where((d) => d.childName.toLowerCase().contains(q)).toList();
  }

  // must match backend route: /api/supervisor/drawings/:id/image
  String _fallbackImageUrl(String drawingId) {
    return "${getBackendUrl()}/api/supervisor/drawings/$drawingId/image";
  }

  // prefer cloudinary url
  String _bestImageUrl(KidDrawing d) {
    if (d.drawingUrl.trim().isNotEmpty) return d.drawingUrl;
    return _fallbackImageUrl(d.id);
  }

  int _crossAxisCountForWidth(double w) {
    if (!kIsWeb) return 2;
    if (w >= 1300) return 5;
    if (w >= 1000) return 4;
    if (w >= 700) return 3;
    return 2;
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
        backgroundColor: AppColors.softSunYellow,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search by child name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                    ? Center(
                        child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No drawings found.",
                              style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchKidsDrawings,
                            child: LayoutBuilder(
                              builder: (context, c) {
                                return GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _crossAxisCountForWidth(c.maxWidth),
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final d = filtered[index];
                                    final imageUrl = _bestImageUrl(d);

                                    return InkWell(
                                      onTap: () async {
                                        if (token == null || d.id.isEmpty) return;

                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => SupervisorDrawingReviewScreen(
                                              drawing: d,
                                              token: token!,
                                              imageUrl: imageUrl,
                                            ),
                                          ),
                                        );

                                        _fetchKidsDrawings();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 5,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  topRight: Radius.circular(16),
                                                ),
                                                child: _DrawingThumb(
                                                  imageUrl: imageUrl,
                                                  // إذا cloudinary => true (بدون توكن)
                                                  isPublic: d.drawingUrl.trim().isNotEmpty,
                                                  token: token!,
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    d.childName,
                                                    style: GoogleFonts.robotoSlab(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  if (d.activityTitle != null)
                                                    Text(
                                                      d.activityTitle!,
                                                      style: GoogleFonts.robotoSlab(
                                                        fontSize: 13,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 18,
                                                        color: d.rating != null ? Colors.amber : Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        d.rating?.toString() ?? "No rating",
                                                        style: GoogleFonts.robotoSlab(
                                                          fontSize: 12,
                                                          color: Colors.grey.shade800,
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

/// ✅ Web-safe image loader:
/// - لو URL public (cloudinary) => Image.network
/// - لو protected endpoint => نجيب bytes بـ http.get مع Authorization ثم Image.memory
class _DrawingThumb extends StatelessWidget {
  final String imageUrl;
  final bool isPublic;
  final String token;

  const _DrawingThumb({
    required this.imageUrl,
    required this.isPublic,
    required this.token,
  });

  Future<Uint8List> _loadBytes() async {
    final res = await http.get(
      Uri.parse(imageUrl),
      headers: {"Authorization": "Bearer $token"},
    );
    if (res.statusCode != 200) {
      throw Exception("Image load failed (${res.statusCode})");
    }
    return res.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    if (isPublic) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image),
        ),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
      );
    }

    // protected => bytes
    return FutureBuilder<Uint8List>(
      future: _loadBytes(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: Colors.grey.shade100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        if (!snap.hasData) {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image),
          );
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }
}










/*import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:bright_minds/theme/colors.dart';
import 'package:google_fonts/google_fonts.dart';

import 'supervisorDrawingReview.dart';

class KidDrawing {
  final String id;
  final String childName;
  final String? childAgeGroup;
  final String? activityTitle;
  final String? activityType;
  final int? rating;
  final String? supervisorComment;
  final DateTime? createdAt;

  // ✅ NEW
  final String drawingUrl;

  KidDrawing({
    required this.id,
    required this.childName,
    this.childAgeGroup,
    this.activityTitle,
    this.activityType,
    this.rating,
    this.supervisorComment,
    this.createdAt,
    required this.drawingUrl,
  });

  factory KidDrawing.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'];
    final rawName = json['childName'] ?? json['child']?['name'];

    return KidDrawing(
      id: rawId?.toString() ?? "",
      childName: rawName?.toString() ?? "Unknown",
      childAgeGroup: json['childAgeGroup']?.toString(),
      activityTitle: json['activityTitle']?.toString(),
      activityType: json['activityType']?.toString(),
      rating: json['rating'] is int ? json['rating'] : int.tryParse("${json['rating']}"),
      supervisorComment: json['supervisorComment']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,

      // ✅ NEW
      drawingUrl: json['drawingUrl']?.toString() ?? "",
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
    if (kIsWeb) 
    //return "http://192.168.1.63:3000";
      return "http://localhost:3000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetch();
  }

  Future<void> _loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
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
      final url = Uri.parse("${getBackendUrl()}/api/supervisor/kids-drawings");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body is List) {
          final list = body
              .map((e) => KidDrawing.fromJson(e as Map<String, dynamic>))
              .toList();

          setState(() => _allDrawings = list);
        } else {
          setState(() {
            _isError = true;
            _errorMessage = "Unexpected response format.";
          });
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = "Failed to load drawings: ${response.statusCode}\n${response.body}";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _errorMessage = "Error: $e";
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<KidDrawing> get _filteredDrawings {
    if (_searchQuery.trim().isEmpty) return _allDrawings;
    final q = _searchQuery.toLowerCase();
    return _allDrawings.where((d) => d.childName.toLowerCase().contains(q)).toList();
  }

  // ✅ NOTE: must match backend route: /api/supervisor/drawings/:id/image
  String _fallbackImageUrl(String drawingId) {
    return "${getBackendUrl()}/api/supervisor/drawings/$drawingId/image";
  }

  // ✅ prefer cloudinary url if exists
  String _bestImageUrl(KidDrawing d) {
    if (d.drawingUrl.trim().isNotEmpty) return d.drawingUrl;
    return _fallbackImageUrl(d.id);
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
        backgroundColor: AppColors.softSunYellow,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Search by child name",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _isError
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              "No drawings found.",
                              style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchKidsDrawings,
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final d = filtered[index];
                                final imageUrl = _bestImageUrl(d);

                                return InkWell(
                                  onTap: () async {
                                    if (token == null || d.id.isEmpty) return;

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SupervisorDrawingReviewScreen(
                                          drawing: d,
                                          token: token!,
                                          imageUrl: imageUrl,
                                        ),
                                      ),
                                    );

                                    _fetchKidsDrawings();
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                            child: Image.network(
                                              imageUrl,
                                              headers: d.drawingUrl.trim().isNotEmpty
                                                  ? null // cloudinary doesn't need auth
                                                  : {"Authorization": "Bearer ${token!}"},
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                color: Colors.grey.shade200,
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.broken_image),
                                              ),
                                              loadingBuilder: (ctx, child, progress) {
                                                if (progress == null) return child;
                                                return Container(
                                                  color: Colors.grey.shade100,
                                                  alignment: Alignment.center,
                                                  child: const CircularProgressIndicator(),
                                                );
                                              },
                                            ),
                                          ),
                                        ),

                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                d.childName,
                                                style: GoogleFonts.robotoSlab(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (d.activityTitle != null)
                                                Text(
                                                  d.activityTitle!,
                                                  style: GoogleFonts.robotoSlab(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.star,
                                                    size: 18,
                                                    color: d.rating != null ? Colors.amber : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    d.rating?.toString() ?? "No rating",
                                                    style: GoogleFonts.robotoSlab(
                                                      fontSize: 12,
                                                      color: Colors.grey.shade800,
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
*/