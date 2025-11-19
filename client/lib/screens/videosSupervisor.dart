

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/screens/addVideo.dart';
import 'package:bright_minds/theme/colors.dart';


class SupervisorVideosPage extends StatefulWidget {
  const SupervisorVideosPage({super.key});

  @override
  State<SupervisorVideosPage> createState() => _SupervisorVideosPageState();
}



class _SupervisorVideosPageState extends State<SupervisorVideosPage> {
  List<dynamic> allVideos = [];
  List<dynamic> filteredVideos = [];
  bool loading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    loadSupervisorVideos();
  }
    String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> loadSupervisorVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token == null) return;

    try {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String userId = decodedToken['id'];
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/videos/getSupervisorVideos/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          allVideos = jsonDecode(response.body);
          filteredVideos = allVideos; // initially show all videos
          loading = false;
        });
      }
    } catch (e) {
      print("❌ Error loading videos: $e");
    }
  }

  void filterVideos(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredVideos = allVideos.where((video) {
        final title = (video["title"] ?? "").toLowerCase();
        final category = (video["category"] ?? "").toLowerCase();
        return title.contains(searchQuery) || category.contains(searchQuery);
      }).toList();
    });
  }

    // -----------------------------------------------------
  // EDIT VIDEO
  // -----------------------------------------------------
  void showEditDialog(dynamic video) {
    final titleController = TextEditingController(text: video["title"]);
    final descriptionController = TextEditingController(text: video["description"]);

    List<String> categories = [
      "English",
      "Arabic",
      "Math",
      "Science",
      "Animation",
      "Art",
      "Music",
      "Coding/Technology"
    ];

    String selectedCategory = video["category"] ?? categories.first;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Edit Video"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                DropdownButtonFormField(
                  value: selectedCategory,
                  items: categories.map((c) =>
                      DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => selectedCategory = v.toString(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateVideo(video["_id"], titleController.text,
                    descriptionController.text, selectedCategory);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  Future<void> updateVideo(String id, String title, String desc, String category) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/videos/updateVideo/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "description": desc,
          "category": category,
        }),
      );

      if (response.statusCode == 200) {
        loadSupervisorVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video updated")),
        );
      }
    } catch (e) {
      print("❌ Update error: $e");
    }
  }

  // -----------------------------------------------------
  // DELETE VIDEO
  // -----------------------------------------------------
  Future<void> deleteVideo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("${getBackendUrl()}/api/videos/deleteVideo/$id"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        loadSupervisorVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video deleted")),
        );
      }
    } catch (e) {
      print("❌ Delete error: $e");
    }
  }

  // -----------------------------------------------------
  // PUBLISH VIDEO
  // -----------------------------------------------------
  Future<void> publishVideo(String id) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/videos/publish/$id"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        loadSupervisorVideos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video Published")),
        );
      }
    } catch (e) {
      print("❌ Publish error: $e");
    }
  }

  // -----------------------------------------------------
  // GROUP BY CATEGORY
  // -----------------------------------------------------
  Map<String, List<dynamic>> groupByCategory(List videos) {
    Map<String, List<dynamic>> map = {};

    for (var v in videos) {
      String cat = v["category"] ?? "Others";
      if (!map.containsKey(cat)) map[cat] = [];
      map[cat]!.add(v);
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final categorized = groupByCategory(filteredVideos);

  return HomePage(
  title: "Videos",
  child: DefaultTabController(
    length: 3,
    child: Column(
      children: [
        // Tabs
        TabBar(
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "Videos Library", icon: Icon(Icons.video_library)),
            Tab(text: "Playlist", icon: Icon(Icons.playlist_play)),
            Tab(text: "Analytics", icon: Icon(Icons.bar_chart)),
          ],
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            children: [
              // ---------------------------
              // Videos Library
              // ---------------------------
              Stack(
                children: [
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                         // Search bar with "+" button
                       Padding(
                      padding: const EdgeInsets.all(8.0),
                     child: Row(
                 children: [
                 Expanded(
                 child: TextField(
                 decoration: InputDecoration(
            hintText: "Search by title or category",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) => filterVideos(value),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        height: 48,
        width: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: AppColors.bgWarmPinkDark,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddVideosScreen(),
              ),
            );
          },
             child: const Icon(Icons.add, size: 28,color:Colors.white),
                ),
               ),
                     ],
                     )   ,
                  ),

                            // Horizontal video rows
                            Expanded(
                              child: ListView(
                                children: groupByCategory(filteredVideos)
                                    .keys
                                    .map((category) {
                                  final videos = groupByCategory(filteredVideos)[category]!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 300,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: videos.length,
                                          itemBuilder: (_, index) {
                                            final video = videos[index];
                                            return Container(
                                              width: 220,
                                              margin: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Card(
                                                elevation: 3,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius: const BorderRadius.vertical(
                                                          top: Radius.circular(4)),
                                                      child: Image.network(
                                                        video["thumbnailUrl"],
                                                        width: double.infinity,
                                                        height: 140,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.all(6.0),
                                                      child: Text(
                                                        video["title"],
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                    if (video["description"] != null &&
                                                        video["description"]
                                                            .toString()
                                                            .isNotEmpty)
                                                      Padding(
                                                        padding: const EdgeInsets.symmetric(
                                                            horizontal: 6.0),
                                                        child: Text(
                                                          video["description"],
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                              color: Colors.black45, fontSize: 12),
                                                        ),
                                                      ),
                                                    ButtonBar(
                                                      alignment: MainAxisAlignment.spaceBetween,
                                                    
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.edit,
                                                              color: AppColors.bgWarmPinkVeryDark, size: 20),
                                                          onPressed: () =>
                                                              showEditDialog(video),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete,
                                                              color:AppColors.bgWarmPinkVeryDark, size: 20),
                                                          onPressed: () =>
                                                              deleteVideo(video["_id"]),
                                                        ),
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.check_circle,
                                                            color: video["isPublished"] == true
                                                                ? Colors.green
                                                                : AppColors.bgWarmPinkVeryDark,
                                                            size: 20,
                                                          ),
                                                          onPressed: video["isPublished"] == true
                                                              ? null
                                                              : () => publishVideo(video["_id"]),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                  // Floating "+" button
           
                                ],
                              ),

              // ---------------------------
              // Playlist
              // ---------------------------
              Center(
                child: Text(
                  "Playlist Page (Coming Soon)",
                  style: TextStyle(fontSize: 18, color:Colors.black),
                ),
              ),

              // ---------------------------
              // Analytics
              // ---------------------------
              Center(
                child: Text(
                  "Analytics Page (Coming Soon)",
                  style: TextStyle(fontSize: 18,  color:Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}