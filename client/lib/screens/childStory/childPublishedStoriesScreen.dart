import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/screens/childStory/readOnlyStoryPage.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../widgets/home.dart';
import '../../theme/colors.dart';

class ChildPublishedStoriesScreen extends StatefulWidget {
  const ChildPublishedStoriesScreen({super.key});

  @override
  State<ChildPublishedStoriesScreen> createState() =>
      _ChildPublishedStoriesScreenState();
}

class _ChildPublishedStoriesScreenState
    extends State<ChildPublishedStoriesScreen> {
  List _stories = [];
  bool _isLoading = true;

  // ✅ (اختياري) cache لعدد اللايكات عشان ما يعيد طلب الشبكة كل rebuild
  final Map<String, int> _likesCache = {};
  final Map<String, Future<int>> _likesFutureCache = {};

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://localhost:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${getBackendUrl()}/api/story/published/all"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _stories = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<int> _getLikesCount(String storyId) async {
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/story/$storyId/likes/count"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['count'];
      }
    } catch (e) {}
    return 0;
  }

  // ✅ Future واحد لكل storyId
  Future<int> _likesFuture(String storyId) {
    if (_likesFutureCache.containsKey(storyId)) return _likesFutureCache[storyId]!;
    final f = _getLikesCount(storyId).then((v) {
      _likesCache[storyId] = v;
      return v;
    });
    _likesFutureCache[storyId] = f;
    return f;
  }

  Future<void> _toggleLike(String storyId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("${getBackendUrl()}/api/story/like"),
        body: jsonEncode({"storyId": storyId}),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ نحدّث الكاش بس بشكل بسيط (ما منعرف زاد ولا نقص، فنعيد fetch count)
        _likesFutureCache.remove(storyId);
        _likesCache.remove(storyId);
        setState(() {});
      }
    } catch (e) {}
  }

  // ===================== WEB RESPONSIVE HELPERS (UI ONLY) =====================
  int _gridCountForWidth(double w) {
    if (w < 600) return 2;   // موبايل
    if (w < 900) return 3;   // تابلت/ويب صغير
    if (w < 1200) return 4;  // ويب متوسط
    return 5;                // ويب كبير
  }

  double _maxContentWidth(double w) {
    if (w >= 900) return 1100; // وسّط المحتوى
    return w;
  }

  double _childAspectRatioForWidth(double w) {
    // على الويب نخلي الكارد أعرض شوي
    if (w >= 900) return 0.85;
    return 0.8; // زي كودك
  }
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Published Stories",
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? const Center(child: Text("No published stories yet."))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final maxW = _maxContentWidth(w);

                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stories.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _gridCountForWidth(w),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: _childAspectRatioForWidth(w),
                          ),
                          itemBuilder: (context, index) {
                            final story = _stories[index];

                            final String title = story['title'] ?? "Untitled";
                            final String childName =
                                story['childId']?['name'] ?? "Unknown";
                            final String? cover = story['coverImage'];
                            final String storyId = story['_id'];

                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ReadOnlyStoryPage(storyId: storyId),
                                  ),
                                );

                                // ✅ لما يرجع من القراءة نعمل refresh بسيط للواجهة
                                // (ما غيرنا منطقك)
                                setState(() {});
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
                                    // الصورة
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        child: cover != null
                                            ? (cover.startsWith("assets/")
                                                ? Image.asset(
                                                    cover,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        Container(
                                                      color: AppColors
                                                          .bgBlushRoseDark,
                                                      child: const Icon(
                                                        Icons
                                                            .menu_book_rounded,
                                                        color: Colors.white,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  )
                                                : Image.network(
                                                    cover,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (c, e, s) =>
                                                        Container(
                                                      color: AppColors
                                                          .bgBlushRoseDark,
                                                      child: const Icon(
                                                        Icons
                                                            .menu_book_rounded,
                                                        color: Colors.white,
                                                        size: 40,
                                                      ),
                                                    ),
                                                  ))
                                            : Container(
                                                color:
                                                    AppColors.bgBlushRoseDark,
                                                child: const Icon(
                                                  Icons.menu_book_rounded,
                                                  color: Colors.white,
                                                  size: 40,
                                                ),
                                              ),
                                      ),
                                    ),

                                    // Likes row
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, right: 8, bottom: 8, top: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          FutureBuilder<int>(
                                            future: _likesFuture(storyId),
                                            builder: (context, snapshot) {
                                              final likes = snapshot.data ??
                                                  _likesCache[storyId] ??
                                                  0;

                                              return Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _toggleLike(storyId),
                                                    child: const Icon(
                                                      Icons.favorite,
                                                      size: 18,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "$likes",
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    // اسم القصة
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),

                                    // اسم الطفل
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8, bottom: 10, right: 8),
                                      child: Text(
                                        "By: $childName",
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}










/*import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/screens/childStory/readOnlyStoryPage.dart';

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../widgets/home.dart'; // تبع الهوم
import '../../theme/colors.dart';

class ChildPublishedStoriesScreen extends StatefulWidget {
  const ChildPublishedStoriesScreen({super.key});

  @override
  State<ChildPublishedStoriesScreen> createState() =>
      _ChildPublishedStoriesScreenState();
}

class _ChildPublishedStoriesScreenState extends State<ChildPublishedStoriesScreen> {
  List _stories = [];
  bool _isLoading = true;

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
    _fetchStories();
 
  }

  

  Future<void> _fetchStories() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("${getBackendUrl()}/api/story/published/all"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _stories = jsonDecode(response.body);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }


Future<int> _getLikesCount(String storyId) async {
  try {
    final response = await http.get(
      Uri.parse("${getBackendUrl()}/api/story/$storyId/likes/count"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['count'];
    }
  } catch (e) {}
  return 0;
}

Future<void> _toggleLike(String storyId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse("${getBackendUrl()}/api/story/like"),
      body: jsonEncode({"storyId": storyId}),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      setState(() {}); // refresh UI
    }
  } catch (e) {}
}



  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Published Stories",
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stories.isEmpty
              ? const Center(
                  child: Text("No published stories yet."),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final story = _stories[index];

                    final String title = story['title'] ?? "Untitled";
                    final String childName =
                        story['childId']?['name'] ?? "Unknown";
                    final String? cover = story['coverImage'];

                   return GestureDetector(
 onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ReadOnlyStoryPage(
        storyId: story['_id'],
      ),
    ),
  );

  // 🔄 لما يرجع الطفل من شاشة القراءة → نعمل refresh
  setState(() {});

  // ⭐ لو عندك fetch badges function هنا استدعيه
  // await _fetchBadges();
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

        // الصورة
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
           child: cover != null
    ? (cover.startsWith("assets/")
        ? Image.asset(cover, fit: BoxFit.cover)
        : Image.network(cover, fit: BoxFit.cover))
    : Container(
        color: AppColors.bgBlushRoseDark,
        child: const Icon(Icons.menu_book_rounded,
            color: Colors.white, size: 40),
      ),

          ),
        ),

        // 👇 Likes row
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // ❤️ Like button + count
              FutureBuilder<int>(
                future: _getLikesCount(story['_id']),
                builder: (context, snapshot) {
                  final likes = snapshot.data ?? 0;

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleLike(story['_id']),
                        child: const Icon(
                          Icons.favorite,
                          size: 18,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$likes",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // 👇 اسم القصة والطفل
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            "By: $childName",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
);

                  },
                ),
    );
  }
}
*/