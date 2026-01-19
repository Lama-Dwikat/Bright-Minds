import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'package:bright_minds/theme/colors.dart';
import 'supervisorKidsDrawings.dart'; // KidDrawing

class SupervisorDrawingReviewScreen extends StatefulWidget {
  final KidDrawing drawing;
  final String token;
  final String imageUrl;

  const SupervisorDrawingReviewScreen({
    super.key,
    required this.drawing,
    required this.token,
    required this.imageUrl,
  });

  @override
  State<SupervisorDrawingReviewScreen> createState() =>
      _SupervisorDrawingReviewScreenState();
}

class _SupervisorDrawingReviewScreenState
    extends State<SupervisorDrawingReviewScreen> {
  late TextEditingController _commentController;
  double _rating = 3;
  bool _isSaving = false;

  Future<Uint8List>? _imageBytesFuture;

  String getBackendUrl() {
    if (kIsWeb) return "http://localhost:3000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _commentController =
        TextEditingController(text: widget.drawing.supervisorComment ?? '');
    _rating = (widget.drawing.rating?.toDouble() ?? 3).clamp(1, 5);

    if (!_isPublicUrl(widget.imageUrl)) {
      _imageBytesFuture = _loadProtectedBytes(widget.imageUrl);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _isPublicUrl(String url) {
    final lower = url.toLowerCase();

    if (lower.contains("cloudinary.com")) return true;

    final backend = getBackendUrl().toLowerCase();
    if (lower.startsWith("http") && !lower.startsWith(backend)) return true;

    return false;
  }

  Future<Uint8List> _loadProtectedBytes(String url) async {
    final res = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    if (res.statusCode != 200) {
      throw Exception("Image load failed (${res.statusCode})");
    }
    return res.bodyBytes;
  }

  Future<void> _saveReview() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found, please sign in again.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url = Uri.parse(
        "${getBackendUrl()}/api/supervisor/drawings/${widget.drawing.id}/review",
      );

      final body = jsonEncode({
        "comment": _commentController.text.trim(),
        "rating": _rating.toInt(),
      });

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review saved successfully ✅")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to save review: ${response.statusCode}\n${response.body}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildStarsRow({bool webMode = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _rating;

        return IconButton(
          visualDensity: webMode ? VisualDensity.compact : VisualDensity.standard,
          onPressed: () => setState(() => _rating = starIndex.toDouble()),
          icon: Icon(
            Icons.star,
            color: isFilled ? Colors.amber : Colors.grey.shade400,
            size: webMode ? 26 : 32,
          ),
        );
      }),
    );
  }

  Widget _imageViewer() {
    final url = widget.imageUrl;
    final isPublic = _isPublicUrl(url);

    if (isPublic) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 40),
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

    return FutureBuilder<Uint8List>(
      future: _imageBytesFuture ?? _loadProtectedBytes(url),
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
            child: const Icon(Icons.broken_image, size: 40),
          );
        }
        return Image.memory(snap.data!, fit: BoxFit.contain);
      },
    );
  }

  Widget _infoCard() {
    final d = widget.drawing;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              d.childName,
              style: GoogleFonts.robotoSlab(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            if (d.childAgeGroup != null)
              Text(
                "Age group: ${d.childAgeGroup}",
                style: GoogleFonts.robotoSlab(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
              ),
            if (d.activityTitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Activity: ${d.activityTitle}",
                  style: GoogleFonts.robotoSlab(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            if (d.activityType != null)
              Text(
                "Type: ${d.activityType}",
                style: GoogleFonts.robotoSlab(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard({required bool webMode}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Rating",
              style: GoogleFonts.robotoSlab(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStarsRow(webMode: webMode),
            const SizedBox(height: 14),
            Text(
              "Comment",
              style: GoogleFonts.robotoSlab(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: webMode ? 8 : 4,
              decoration: InputDecoration(
                hintText: "Write a feedback for the child...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // ✅ زر أصغر بالويب
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: webMode ? 40 : 48,
                width: webMode ? 160 : double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softSunYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(
                      vertical: webMode ? 10 : 14,
                      horizontal: webMode ? 14 : 18,
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(Icons.save, size: webMode ? 18 : 22),
                  label: Text(
                    _isSaving ? "Saving..." : "Save Review",
                    style: GoogleFonts.robotoSlab(
                      fontSize: webMode ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WEB layout
  Widget _buildWebBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // container width to avoid super wide layout
        final maxW = w.clamp(900.0, 1200.0);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT (image + info)
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _imageViewer(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _infoCard(),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // RIGHT (review)
                  Expanded(
                    flex: 4,
                    child: _reviewCard(webMode: true),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ MOBILE layout (زي تبعك)
  Widget _buildMobileBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _imageViewer(),
            ),
          ),
          const SizedBox(height: 16),
          _infoCard(),
          const SizedBox(height: 16),
          _reviewCard(webMode: false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Review Drawing",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.softSunYellow.withOpacity(0.12), Colors.white],
          ),
        ),
        child: kIsWeb ? _buildWebBody() : _buildMobileBody(),
      ),
    );
  }
}











/*import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'package:bright_minds/theme/colors.dart';
import 'supervisorKidsDrawings.dart'; // KidDrawing

class SupervisorDrawingReviewScreen extends StatefulWidget {
  final KidDrawing drawing;
  final String token;
  final String imageUrl;

  const SupervisorDrawingReviewScreen({
    super.key,
    required this.drawing,
    required this.token,
    required this.imageUrl,
  });

  @override
  State<SupervisorDrawingReviewScreen> createState() =>
      _SupervisorDrawingReviewScreenState();
}

class _SupervisorDrawingReviewScreenState
    extends State<SupervisorDrawingReviewScreen> {
  late TextEditingController _commentController;
  double _rating = 3;
  bool _isSaving = false;

  String getBackendUrl() {
    if (kIsWeb) return "http://localhost:3000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _commentController =
        TextEditingController(text: widget.drawing.supervisorComment ?? '');
    _rating = (widget.drawing.rating?.toDouble() ?? 3).clamp(1, 5);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool _isPublicUrl(String url) {
    final lower = url.toLowerCase();

    // cloudinary / public cdn
    if (lower.contains("cloudinary.com")) return true;

    // if it's not from our backend host, treat as public
    final backend = getBackendUrl().toLowerCase();
    if (lower.startsWith("http") && !lower.startsWith(backend)) return true;

    return false; // likely protected backend endpoint
  }

  Future<Uint8List> _loadProtectedBytes(String url) async {
    final res = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    if (res.statusCode != 200) {
      throw Exception("Image load failed (${res.statusCode})");
    }
    return res.bodyBytes;
  }

  Future<void> _saveReview() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found, please sign in again.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url = Uri.parse(
        "${getBackendUrl()}/api/supervisor/drawings/${widget.drawing.id}/review",
      );

      final body = jsonEncode({
        "comment": _commentController.text.trim(),
        "rating": _rating.toInt(),
      });

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review saved successfully ✅")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to save review: ${response.statusCode}\n${response.body}",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildStarsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _rating;

        return IconButton(
          onPressed: () => setState(() => _rating = starIndex.toDouble()),
          icon: Icon(
            Icons.star,
            color: isFilled ? Colors.amber : Colors.grey.shade400,
            size: 32,
          ),
        );
      }),
    );
  }

  Widget _imageViewer() {
    final url = widget.imageUrl;
    final isPublic = _isPublicUrl(url);

    if (isPublic) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, size: 40),
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

    // Protected backend endpoint => fetch bytes and show Image.memory (web-safe)
    return FutureBuilder<Uint8List>(
      future: _loadProtectedBytes(url),
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
            child: const Icon(Icons.broken_image, size: 40),
          );
        }
        return Image.memory(snap.data!, fit: BoxFit.contain);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drawing;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Review Drawing",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _imageViewer(),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.childName,
                      style: GoogleFonts.robotoSlab(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (d.childAgeGroup != null)
                      Text(
                        "Age group: ${d.childAgeGroup}",
                        style: GoogleFonts.robotoSlab(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    if (d.activityTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Activity: ${d.activityTitle}",
                          style: GoogleFonts.robotoSlab(
                            fontSize: 14,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    if (d.activityType != null)
                      Text(
                        "Type: ${d.activityType}",
                        style: GoogleFonts.robotoSlab(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Rating",
              style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStarsRow(),
            const SizedBox(height: 16),

            Text(
              "Comment",
              style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a feedback for the child...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softSunYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? "Saving..." : "Save Review",
                  style: GoogleFonts.robotoSlab(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
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
*/









/*import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'package:bright_minds/theme/colors.dart';
import 'supervisorKidsDrawings.dart'; // KidDrawing

class SupervisorDrawingReviewScreen extends StatefulWidget {
  final KidDrawing drawing;
  final String token;
  final String imageUrl;

  const SupervisorDrawingReviewScreen({
    super.key,
    required this.drawing,
    required this.token,
    required this.imageUrl,
  });

  @override
  State<SupervisorDrawingReviewScreen> createState() =>
      _SupervisorDrawingReviewScreenState();
}

class _SupervisorDrawingReviewScreenState
    extends State<SupervisorDrawingReviewScreen> {
  late TextEditingController _commentController;
  double _rating = 3;
  bool _isSaving = false;

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
    _commentController = TextEditingController(text: widget.drawing.supervisorComment ?? '');
    _rating = (widget.drawing.rating?.toDouble() ?? 3).clamp(1, 5);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    if (widget.token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found, please sign in again.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final url = Uri.parse(
        "${getBackendUrl()}/api/supervisor/drawings/${widget.drawing.id}/review",
      );

      final body = jsonEncode({
        "comment": _commentController.text.trim(),
        "rating": _rating.toInt(),
      });

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review saved successfully ✅")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save review: ${response.statusCode}\n${response.body}")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildStarsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _rating;

        return IconButton(
          onPressed: () => setState(() => _rating = starIndex.toDouble()),
          icon: Icon(
            Icons.star,
            color: isFilled ? Colors.amber : Colors.grey.shade400,
            size: 32,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.drawing;
    final isCloudinary = widget.imageUrl.startsWith("http");

    return Scaffold(
      appBar: AppBar(
        title: Text("Review Drawing", style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.imageUrl,
                  headers: isCloudinary ? null : {"Authorization": "Bearer ${widget.token}"},
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 40),
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
            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.childName, style: GoogleFonts.robotoSlab(fontSize: 18, fontWeight: FontWeight.bold)),
                    if (d.childAgeGroup != null)
                      Text("Age group: ${d.childAgeGroup}", style: GoogleFonts.robotoSlab(fontSize: 14, color: Colors.grey.shade800)),
                    if (d.activityTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text("Activity: ${d.activityTitle}", style: GoogleFonts.robotoSlab(fontSize: 14, color: Colors.grey.shade800)),
                      ),
                    if (d.activityType != null)
                      Text("Type: ${d.activityType}", style: GoogleFonts.robotoSlab(fontSize: 13, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text("Rating", style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildStarsRow(),
            const SizedBox(height: 16),

            Text("Comment", style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a feedback for the child...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softSunYellow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? "Saving..." : "Save Review",
                  style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/