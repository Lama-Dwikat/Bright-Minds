import 'dart:convert';
import 'dart:typed_data';

import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildMyDrawingsScreen extends StatefulWidget {
  const ChildMyDrawingsScreen({super.key});

  @override
  State<ChildMyDrawingsScreen> createState() => _ChildMyDrawingsScreenState();
}

class _ChildMyDrawingsScreenState extends State<ChildMyDrawingsScreen> {
  bool isLoading = true;
  List<dynamic> drawings = [];

  // ✅ Web-safe platform checks (بديل Platform)
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String getBackendUrl() {
    if (kIsWeb) {
      // return "http://192.168.1.63:3000";
      return "http://localhost:3000";
    }
    if (_isAndroid) return "http://10.0.2.2:3000";
    if (_isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _fetchMyDrawings();
  }

  Future<void> _deleteDrawing(String drawingId, int index) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final url = Uri.parse("${getBackendUrl()}/api/drawings/$drawingId");

      final response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          drawings.removeAt(index);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Drawing deleted 🗑️")),
        );
      } else {
        debugPrint("Failed to delete drawing: ${response.statusCode}");
        debugPrint("BODY: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete drawing")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting drawing: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error while deleting drawing")),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> drawing, int index) async {
    final title = drawing["activityTitle"] ?? "this drawing";

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Drawing"),
          content: Text("Are you sure you want to delete \"$title\"?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final drawingId = drawing["id"] as String;
      await _deleteDrawing(drawingId, index);
    }
  }

  Future<void> _fetchMyDrawings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final url = Uri.parse("${getBackendUrl()}/api/drawings");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          drawings = data;
          isLoading = false;
        });
      } else {
        debugPrint("Failed to load drawings: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching drawings: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _openDrawingFullScreen(Map<String, dynamic> drawing) {
    final bytes = base64Decode(drawing["imageBase64"]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenDrawingView(
          imageBytes: bytes,
          title: drawing["activityTitle"] ?? "My Drawing",
          createdAt: drawing["createdAt"],
        ),
      ),
    );
  }

  // ✅ Responsive helpers (ويب/موبايل)
  double _maxWidthFor(double w) {
    if (kIsWeb) return 1200; // وسّط المحتوى
    return w;
  }

  int _crossAxisCountFor(double w) {
    if (!kIsWeb) return 2; // موبايل مثل ما هو
    if (w < 700) return 2;
    if (w < 1000) return 3;
    if (w < 1300) return 4;
    return 5;
  }

  double _childAspectFor(double w) {
    // 카드 أطول شوي لتحتوي rating/comment
    if (kIsWeb) return 0.72;
    return 3 / 4; // موبايل زي ما كان تقريباً
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Drawings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : drawings.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        "You don't have any drawings yet 🎨",
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final maxW = _maxWidthFor(w);
        final cols = _crossAxisCountFor(w);
        final aspect = _childAspectFor(w);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: drawings.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: aspect,
                ),
                itemBuilder: (context, index) {
                  final drawing = drawings[index];

                  final Uint8List imgBytes =
                      base64Decode(drawing["imageBase64"] as String);

                  DateTime? created;
                  String createdText = "";
                  try {
                    created = DateTime.parse(drawing["createdAt"]);
                    createdText = DateFormat("d MMM yyyy, HH:mm").format(created);
                  } catch (_) {}

                  final int? rating = drawing["rating"] as int?;
                  final String? comment = drawing["supervisorComment"] as String?;

                  return Stack(
                    children: [
                      InkWell(
                        onTap: () => _openDrawingFullScreen(drawing),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.warmHoneyYellow,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14),
                                  ),
                                  child: Image.memory(
                                    imgBytes,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      drawing["activityTitle"] ?? "My Drawing",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (createdText.isNotEmpty)
                                      Text(
                                        createdText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    const SizedBox(height: 6),

                                    // ⭐ rating (صغير وأنيق)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 18,
                                          color: rating != null
                                              ? Colors.amber
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          rating != null
                                              ? "Rating: $rating"
                                              : "No rating yet",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // 💬 comment
                                    Text(
                                      (comment != null && comment.isNotEmpty)
                                          ? comment
                                          : "No comment yet",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Delete button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: "Delete",
                            onPressed: () => _confirmDelete(drawing, index),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================= FULL SCREEN VIEW =================

class _FullScreenDrawingView extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;
  final String? createdAt;

  const _FullScreenDrawingView({
    required this.imageBytes,
    required this.title,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle = "";
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt!);
        subtitle = DateFormat("d MMM yyyy, HH:mm").format(dt);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.amber,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
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
      ),
    );
  }
}










/*import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChildMyDrawingsScreen extends StatefulWidget {
  const ChildMyDrawingsScreen({super.key});

  @override
  State<ChildMyDrawingsScreen> createState() => _ChildMyDrawingsScreenState();
}

class _ChildMyDrawingsScreenState extends State<ChildMyDrawingsScreen> {
  bool isLoading = true;
  List<dynamic> drawings = [];

  String getBackendUrl() {
    if (kIsWeb) {
     // return "http://192.168.1.63:3000";
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMyDrawings();
  }


Future<void> _deleteDrawing(String drawingId, int index) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse("${getBackendUrl()}/api/drawings/$drawingId");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        drawings.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Drawing deleted 🗑️")),
      );
    } else {
  debugPrint("Failed to delete drawing: ${response.statusCode}");
  debugPrint("BODY: ${response.body}");
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Failed to delete drawing")),
  );
}

  } catch (e) {
    debugPrint("Error deleting drawing: $e");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error while deleting drawing")),
    );
  }
}
Future<void> _confirmDelete(Map<String, dynamic> drawing, int index) async {
  final title = drawing["activityTitle"] ?? "this drawing";

  final shouldDelete = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Delete Drawing"),
        content: Text("Are you sure you want to delete \"$title\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );

  if (shouldDelete == true) {
    final drawingId = drawing["id"] as String;
    await _deleteDrawing(drawingId, index);
  }
}

  Future<void> _fetchMyDrawings() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse("${getBackendUrl()}/api/drawings");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return; // ⬅️ مهم بعد الـ await

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        drawings = data;
        isLoading = false;
      });
    } else {
      debugPrint("Failed to load drawings: ${response.statusCode}");
      setState(() {
        isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Error fetching drawings: $e");
    if (!mounted) return; // ⬅️ مهم قبل setState في catch
    setState(() {
      isLoading = false;
    });
  }
}


  void _openDrawingFullScreen(Map<String, dynamic> drawing) {
    final bytes = base64Decode(drawing["imageBase64"]);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenDrawingView(
          imageBytes: bytes,
          title: drawing["activityTitle"] ?? "My Drawing",
          createdAt: drawing["createdAt"],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Drawings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.softSunYellow,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : drawings.isEmpty
              ? _buildEmpty()
              : _buildGrid(),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        "You don't have any drawings yet 🎨",
        style: TextStyle(fontSize: 16),
      ),
    );
  }

Widget _buildGrid() {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: GridView.builder(
      itemCount: drawings.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 أعمدة
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 4,
      ),
      itemBuilder: (context, index) {
        final drawing = drawings[index];

        // الصورة
        final Uint8List imgBytes =
            base64Decode(drawing["imageBase64"] as String);

        // التاريخ
        DateTime? created;
        String createdText = "";
        try {
          created = DateTime.parse(drawing["createdAt"]);
          createdText = DateFormat("d MMM yyyy, HH:mm").format(created);
        } catch (_) {}

        // ⭐ التقييم
        final int? rating = drawing["rating"] as int?;
        // 💬 تعليق السوبرفايزر
        final String? comment = drawing["supervisorComment"] as String?;

        return Stack(
          children: [
            GestureDetector(
              onTap: () => _openDrawingFullScreen(drawing),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.warmHoneyYellow,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // الصورة
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.memory(
                          imgBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // العنوان + التاريخ + التقييم + التعليق
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // عنوان النشاط
                          Text(
                            drawing["activityTitle"] ?? "My Drawing",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // التاريخ
                          Text(
                            createdText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // ⭐ التقييم
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 22,
                                color: rating != null
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating != null
                                    ? "Your rating: $rating"
                                    : "No rating yet",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // 💬 التعليق
                          Text(
                            (comment != null && comment.isNotEmpty)
                                ? comment
                                : "No comment yet",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 23,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // زر الحذف أعلى اليمين
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Delete",
                  onPressed: () => _confirmDelete(drawing, index),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
}

// ================= FULL SCREEN VIEW =================

class _FullScreenDrawingView extends StatelessWidget {
  final Uint8List imageBytes;
  final String title;
  final String? createdAt;

  const _FullScreenDrawingView({
    required this.imageBytes,
    required this.title,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    String subtitle = "";
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt!);
        subtitle = DateFormat("d MMM yyyy, HH:mm").format(dt);
      } catch (_) {}
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
*/