import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/screens/supervisorstory/supervisorStoryReviewPage.dart';

class SupervisorStoriesScreen extends StatefulWidget {
  const SupervisorStoriesScreen({super.key});

  @override
  State<SupervisorStoriesScreen> createState() =>
      _SupervisorStoriesScreenState();
}

class _SupervisorStoriesScreenState extends State<SupervisorStoriesScreen> {
  List _stories = [];
  List _filteredStories = [];
  bool _isLoading = true;

  String _searchQuery = "";
  String _selectedStatus = "pending"; // مبدئياً نعرض pending أول شيء

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.122:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchSupervisorStories();
  }

  Future<void> _fetchSupervisorStories() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/story/supervisor/all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _stories = data is List ? data : [];
          _isLoading = false;
        });

        _applyFilters();
      } else {
        print('❌ Error getting stories: ${response.statusCode}');
        print(response.body);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('⚠️ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List filtered = _stories;

    // فلترة باسم الطفل
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        final childName = (s['childId']?['name'] ?? '').toString().toLowerCase();
        final title = (s['title'] ?? '').toString().toLowerCase();
        final q = _searchQuery.toLowerCase();
        return childName.contains(q) || title.contains(q);
      }).toList();
    }

    // فلترة بحسب الحالة
    if (_selectedStatus != "all") {
      filtered = filtered.where((s) => s['status'] == _selectedStatus).toList();
    }

    // نخلي pending فوق
    final statusOrder = {
      "pending": 0,
      "needs_edit": 1,
      "approved": 2,
      "rejected": 3,
    };

    filtered.sort((a, b) {
      final sa = statusOrder[a['status']] ?? 99;
      final sb = statusOrder[b['status']] ?? 99;
      return sa - sb;
    });

    setState(() {
      _filteredStories = filtered;
    });
  }



void _confirmPublishStory(String storyId) async {
  final confirm = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Publish Story"),
      content: const Text(
          "Are you sure you want to publish this story for all children?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFEBA1AB)),
          child: const Text("Publish"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await _publishStory(storyId);
  }
}


Future<void> _publishStory(String storyId) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.patch(
      Uri.parse("${getBackendUrl()}/api/story/publish/$storyId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Story published successfully 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      // refresh
      _fetchSupervisorStories();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to publish: ${response.body}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error publishing story: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
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
        return AppColors.bgBlushRoseDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Stories",
      child: Column(
        children: [
          // 🔎 Search
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by child name or title...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFEBA1AB)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),

          // 🔘 Filters row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip("all", "All"),
                _filterChip("pending", "Pending"),
                _filterChip("approved", "Approved"),
                _filterChip("rejected", "Rejected"),
                _filterChip("needs_edit", "Needs Edit"),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 📚 Stories grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredStories.isEmpty
                    ? Center(
                        child: Text(
                          "No stories found.",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredStories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (context, index) {
                          final story = _filteredStories[index];

                          final String title = story['title'] ?? "Untitled";
                          final String status = story['status'] ?? "draft";
                          final String childName =
                              story['childId']?['name'] ?? "Unknown child";
                          final String? cover = story['coverImage'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReadOnlyStoryPage(
                                    storyId: story['_id'],
                                  ),
                                ),
                              ).then((_) => _fetchSupervisorStories());
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
                                              color: const Color(0xFFEEE5FF),
                                              child: const Icon(
                                                Icons.menu_book_rounded,
                                                color: Color(0xFFEBA1AB),
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
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      "By: $childName",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                 Padding(
  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
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

      // 🔥 هنا نضيف زر Publish فقط عندما Approved
      if (status == "approved")
        GestureDetector(
          onTap: () => _confirmPublishStory(story['_id']),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFEBA1AB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "Publish",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
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
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedStatus == value,
        selectedColor: Color(0xFFEBA1AB),
        onSelected: (selected) {
          setState(() {
            _selectedStatus = value;
          });
          _applyFilters();
        },
      ),
    );
  }
}
