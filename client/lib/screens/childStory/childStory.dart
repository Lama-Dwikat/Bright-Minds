import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../models/story_model.dart';
import 'package:bright_minds/screens/childStory/createStoryPage.dart';
import 'package:bright_minds/screens/childStory/readOnlyStoryPage.dart';
import 'package:bright_minds/theme/colors.dart';


class StoryKidsScreen extends StatefulWidget {
  const StoryKidsScreen({super.key});

  @override
  State<StoryKidsScreen> createState() => _StoryKidsState();
}

class _StoryKidsState extends State<StoryKidsScreen> {
  List<dynamic> _stories = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedStatus = "all"; // all/draft/pending/approved/rejected


  String getBackendUrl() {
  if (kIsWeb) {
   // return "http://192.168.1.122:3000";
    return "http://localhost:3000";
  } else if (Platform.isAndroid) {
    // Android emulator
    return "http://10.0.2.2:3000";
  } else if (Platform.isIOS) {
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
    _fetchChildStories();
  }

  Future<void> _fetchChildStories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
     // await prefs.clear();

      final token = prefs.getString('token');

      if (token == null) {
        print("⚠️ there is no token ");
        setState(() => _isLoading = false);
        return;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final childId = decodedToken['id'];

       print("➡️ URL = ${getBackendUrl()}/api/story/getstoriesbychild/$childId");
print("➡️ TOKEN = $token");
print("➡️ HEADERS SENT:");
print({'Authorization': 'Bearer $token'});
print("ALL PREFS KEYS = ${prefs.getKeys()}");


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


  List<dynamic> get _filteredStories {
  List<dynamic> filtered = _stories;

  // فلترة حسب العنوان أو الكلمات
  if (_searchQuery.isNotEmpty) {
    filtered = filtered.where((story) {
      final title = story['title']?.toLowerCase() ?? "";
      return title.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // فلترة حسب الحالة
  if (_selectedStatus != "all") {
    filtered = filtered.where((story) {
      return story['status'] == _selectedStatus;
    }).toList();
  }

  return filtered;
}



Future<void> _deleteStory(String storyId) async {
  try {
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('${getBackendUrl()}/api/story/delete/$storyId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    print("🔴 DELETE STATUS: ${response.statusCode}");
    print("🔴 DELETE BODY: ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        _stories.removeWhere((story) => story['_id'] == storyId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Story deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(" Failed to delete story: ${response.body}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}


void _showReviewDialog(Map<String, dynamic> review) {
  int rating = review["rating"] ?? 0;
  String comment = review["comment"] ?? "No comment";
  String supervisorName = review["supervisorId"]?["name"] ?? "Unknown Supervisor";
  String date = review["createdAt"] != null
      ? DateTime.parse(review["createdAt"]).toLocal().toString().substring(0, 16)
      : "Unknown date";

  showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(
        backgroundColor: Color(0xFFFFE0E0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const SizedBox(width: 10),
            Text(
              "Supervisor Review",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Icon(
                  i < rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                );
              }),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(Icons.person, color: Colors.grey, size: 22),
                const SizedBox(width: 6),
                Text(
                  supervisorName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                comment,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}




void _confirmDelete(String storyId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          "Delete Story?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this story? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStory(storyId);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      );
    },
  );
}


  Widget _buildStoriesList() {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (_stories.isEmpty) {
    return Center(
      child: Text(
        "There is no stories untill now!",
        style: GoogleFonts.poppins(
          fontSize: 18,
          color: Colors.grey[700],
        ),
      ),
    );
  }




  return GridView.builder(
  padding: const EdgeInsets.all(16),
itemCount: _filteredStories.length,
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,        // صفّين
    crossAxisSpacing: 16,     // مسافة بين الأعمدة
    mainAxisSpacing: 16,      // مسافة بين الصفوف
    childAspectRatio: 0.75,   // نسبة الطول للعرض (لتحتوي الصورة + النص)
  ),
  itemBuilder: (context, index) {
final story = _filteredStories[index];

    String title = story['title'] ?? "Untitled Story";
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

    return Stack(
  children: [
    GestureDetector(
     onTap: () async {
  final status = story['status'];

  if (status == "approved" || status == "pending") {
    // افتح صفحة قراءة فقط
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReadOnlyStoryPage(storyId: story['_id']),
      ),
    );
  } else {
    // افتح صفحة التعديل
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentStoryId', story['_id']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateStoryPage(storyId: story['_id']),
      ),
    ).then((_) => _fetchChildStories());
  }
},


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
           Expanded(
  child: ClipRRect(
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
    ),
    child: imageUrl != null
        ? (imageUrl!.startsWith("assets/")
            ? Image.asset(
                imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              )
            : Image.network(
                imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              ))
        : Container(
            color: const Color(0xFFEEE5FF),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.warmHoneyYellow,
              size: 50,
            ),
          ),
  ),
),


            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 0, 0, 0),
                ),
              ),
            ),

           Padding(
  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // -------- STATUS BADGE --------
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _statusColor(status),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          status,
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),

      Row(
        children: [

          // -------- ⭐ REVIEW BUTTON --------
          if (story['reviews'] != null && story['reviews'].isNotEmpty)
            GestureDetector(
              onTap: () => _showReviewDialog(story['reviews'][0]),
              child: Icon(Icons.star, color: Colors.amber, size: 26),
            ),

          const SizedBox(width: 10),

          // -------- ❤️ LIKES --------
          const Icon(Icons.favorite, color: Colors.pink, size: 16),
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
    ),


    // زر الحذف
   Positioned(
  top: 8,
  right: 6,
  child: PopupMenuButton<String>(
    elevation: 4,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    icon: const Icon(
      Icons.more_vert,
      color: Color.fromARGB(255, 0, 0, 0), // بنفسجي غامق شوي
      size: 24,
    ),
    onSelected: (value) {
      if (value == "delete") {
        _confirmDelete(story['_id']);
      }
    },
    itemBuilder: (context) => [
      PopupMenuItem(
        value: "delete",
        child: Row(
          children: [
            const Icon(Icons.delete, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              "Delete Story",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  ),
)


  ],
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
      return Color(0xFFEBA1AB); // draft
  }
}


  @override
  Widget build(BuildContext context) {
    // هنا نغلف ListView بـ SizedBox ليأخذ ارتفاع الشاشة كاملة
    return Stack(
  children: [
    HomePage(
      title:"Stories",
      child: Column(
  children: [

    // 🟣 هنا نضيف مربع البحث والفلترة
    Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // مربع البحث
          TextField(
            decoration: InputDecoration(
              hintText: "Search your stories...",
              prefixIcon: Icon(Icons.search, color: Color(0xFFEBA1AB)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12),

          // فلاتر الحالة
         SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _filterChip("all", "All"),
      _filterChip("draft", "Draft"),
      _filterChip("pending", "Pending"),
      _filterChip("needs_edit", "Needs Edit"),
      _filterChip("approved", "Approved"),
      _filterChip("rejected", "Rejected"),
    ],
  ),
)

        ],
      ),
    ),

    // 🟣 الآن نعرض GridView
    Expanded(
      child: _buildStoriesList(),
    ),
  ],
),

    ),

    // الزر فوق الواجهة كلها
   Positioned(
  bottom: 100,  // الرفع عن الفوتر
  right: 10,
  child: GestureDetector(
  onTap: () async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('currentStoryId');

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CreateStoryPage(storyId: null)),
  ).then((_) => _fetchChildStories());
},




    child: Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 250, 206, 148),  // بنفسجي
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



  Widget _filterChip(String value, String label) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: _selectedStatus == value,
      selectedColor: AppColors.storyButton,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
    ),
  );
}


  
}