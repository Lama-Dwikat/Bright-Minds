import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/story_model.dart';

class StoryKidsScreen extends StatefulWidget {
  const StoryKidsScreen({super.key});

  @override
  State<StoryKidsScreen> createState() => _StoryKidsState();
}

class _StoryKidsState extends State<StoryKidsScreen> {
  List<dynamic> _stories = [];
  bool _isLoading = true;

  String getBackendUrl() {
    if (kIsWeb) {
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
    _fetchChildStories();
  }

  Future<void> _fetchChildStories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        print("⚠️ there is no token ");
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final childId = decodedToken['id'];

      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/story/getstoriesbychild/$childId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _stories = data is List ? data : data['stories'] ?? [];
          _isLoading = false;
        });
      } else {
        print('❌Error in getting stories: ${response.statusCode}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('⚠️ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStoriesList() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_stories.isEmpty) {
    return Center(
      child: Text(
        "😅 لا توجد قصص حتى الآن!",
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  return GridView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: _stories.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,        // صفّين
    crossAxisSpacing: 16,     // مسافة بين الأعمدة
    mainAxisSpacing: 16,      // مسافة بين الصفوف
    childAspectRatio: 0.75,   // نسبة الطول للعرض (لتحتوي الصورة + النص)
  ),
  itemBuilder: (context, index) {
    final story = _stories[index];

    String title = story['title'] ?? "بدون عنوان";
    String status = story['status'] ?? "draft";
    int likesCount = story['likesCount'] ?? 0;

    String? imageUrl;
    if (story['coverImage'] != null) {
      imageUrl = story['coverImage'];
    } else if (story['pages'] != null &&
        story['pages'].isNotEmpty &&
        story['pages'][0]['elements'] != null) {
      for (var el in story['pages'][0]['elements']) {
        if (el['type'] == 'image' && el['media']?['url'] != null) {
          imageUrl = el['media']['url'];
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصورة المربعة
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Color(0xFFEEE5FF),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Color(0xFF673AB7),
                          size: 50,
                        ),
                      ),
              ),
            ),

            // المحتوى النصي
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A148C),
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // حالة القصة
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // لايكات
                  Row(
                    children: [
                      const Icon(Icons.favorite,
                          color: Colors.pink, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        likesCount.toString(),
                        style: GoogleFonts.poppins(fontSize: 12),
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

}

Color _statusColor(String status) {
  switch (status) {
    case "approved":
      return Colors.green;
    case "pending":
      return Colors.orange;
    case "rejected":
      return Colors.red;
    case "needs_edit":
      return Colors.blueGrey;
    default:
      return Color(0xFF673AB7); // draft
  }
}


  @override
  Widget build(BuildContext context) {
    // هنا نغلف ListView بـ SizedBox ليأخذ ارتفاع الشاشة كاملة
    return Stack(
  children: [
    homePage(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: _buildStoriesList(),
      ),
    ),

    // الزر فوق الواجهة كلها
   Positioned(
  bottom: 100,  // الرفع عن الفوتر
  right: 10,
  child: GestureDetector(
    onTap: () {
      print("Create new story pressed");
    },
    child: Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 159, 104, 255),  // بنفسجي
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 40,   // أكبر
        ),
      ),
    ),
  ),
),
  ],
);

  }
}
