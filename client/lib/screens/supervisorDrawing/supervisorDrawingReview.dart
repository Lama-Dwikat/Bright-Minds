import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import 'package:bright_minds/theme/colors.dart';
import 'supervisorKidsDrawings.dart'; // عشان نستخدم KidDrawing

class SupervisorDrawingReviewScreen extends StatefulWidget {
  final KidDrawing drawing;

  const SupervisorDrawingReviewScreen({super.key, required this.drawing});

  @override
  State<SupervisorDrawingReviewScreen> createState() =>
      _SupervisorDrawingReviewScreenState();
}

class _SupervisorDrawingReviewScreenState
    extends State<SupervisorDrawingReviewScreen> {
  late TextEditingController _commentController;
  double _rating = 3;
  bool _isSaving = false;

  String? _token;

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
    _commentController =
        TextEditingController(text: widget.drawing.supervisorComment ?? '');
    _rating = (widget.drawing.rating?.toDouble() ?? 3).clamp(1, 5);
    _loadToken();
  }

  Future<void> _loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Uint8List _decodeImage(String base64Str) {
    return base64Decode(base64Str);
  }

  Future<void> _saveReview() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No token found, please sign in again.")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final url = Uri.parse(
          "${getBackendUrl()}/api/supervisor/drawings/${widget.drawing.id}/review");

      final body = jsonEncode({
        "comment": _commentController.text.trim(),
        "rating": _rating.toInt(),
      });

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review saved successfully ✅")),
        );
        Navigator.pop(context); // نرجع لقائمة الـ Kids Drawings
      } else {
        print("Save review failed: ${response.statusCode}");
        print("BODY: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Failed to save review: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      print("Error saving review: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildStarsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _rating;

        return IconButton(
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Review Drawing",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الصورة الكبيرة
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  _decodeImage(d.imageBase64),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // معلومات الطفل + النشاط
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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

            // Rating
            Text(
              "Rating",
              style: GoogleFonts.robotoSlab(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildStarsRow(),
            const SizedBox(height: 16),

            // Comment
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
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write a feedback for the child...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgWarmPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
