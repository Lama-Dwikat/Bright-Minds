

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
import 'package:bright_minds/screens/addQuiz.dart';


class SupervisorVideosPage extends StatefulWidget {
  const SupervisorVideosPage({super.key});

  @override
  State<SupervisorVideosPage> createState() => _SupervisorVideosPageState();
}



// class _SupervisorVideosPageState extends State<SupervisorVideosPage> {
//   List<dynamic> allVideos = [];
//   List<dynamic> filteredVideos = [];
//   bool loading = true;
//   String searchQuery = "";

//   @override
//   void initState() {
//     super.initState();
//     loadSupervisorVideos();
//   }
//     String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.122:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
//   }

//   Future<void> loadSupervisorVideos() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString("token");

//     if (token == null) return;

//     try {
//       Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//       String userId = decodedToken['id'];
//       final response = await http.get(
//         Uri.parse("${getBackendUrl()}/api/videos/getSupervisorVideos/$userId"),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           allVideos = jsonDecode(response.body);
//           filteredVideos = allVideos; // initially show all videos
//           loading = false;
//         });
//       }
//     } catch (e) {
//       print("❌ Error loading videos: $e");
//     }
//   }

//   void filterVideos(String query) {
//     setState(() {
//       searchQuery = query.toLowerCase();
//       filteredVideos = allVideos.where((video) {
//         final title = (video["title"] ?? "").toLowerCase();
//         final category = (video["category"] ?? "").toLowerCase();
//         return title.contains(searchQuery) || category.contains(searchQuery);
//       }).toList();
//     });
//   }

//     // -----------------------------------------------------
//   // EDIT VIDEO
//   // -----------------------------------------------------
//   void showEditDialog(dynamic video) {
//     final titleController = TextEditingController(text: video["title"]);
//     final descriptionController = TextEditingController(text: video["description"]);

//     List<String> categories = [
//       "English",
//       "Arabic",
//       "Math",
//       "Science",
//       "Animation",
//       "Art",
//       "Music",
//       "Coding/Technology"
//     ];

//     String selectedCategory = video["category"] ?? categories.first;

//     showDialog(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           title: const Text("Edit Video"),
//           content: SingleChildScrollView(
//             child: Column(
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(labelText: "Title"),
//                 ),
//                 TextField(
//                   controller: descriptionController,
//                   decoration: const InputDecoration(labelText: "Description"),
//                 ),
//                 DropdownButtonFormField(
//                   value: selectedCategory,
//                   items: categories.map((c) =>
//                       DropdownMenuItem(value: c, child: Text(c))).toList(),
//                   onChanged: (v) => selectedCategory = v.toString(),
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 updateVideo(video["_id"], titleController.text,
//                     descriptionController.text, selectedCategory);
//               },
//               child: const Text("Save"),
//             )
//           ],
//         );
//       },
//     );
//   }

//   Future<void> updateVideo(String id, String title, String desc, String category) async {
//     try {
//       final response = await http.put(
//         Uri.parse("${getBackendUrl()}/api/videos/updateVideoById/$id"),
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "title": title,
//           "description": desc,
//           "category": category,
//         }),
//       );

//       if (response.statusCode == 200) {
//         loadSupervisorVideos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Video updated")),
//         );
//       }
//     } catch (e) {
//       print("❌ Update error: $e");
//     }
//   }

//   // -----------------------------------------------------
//   // DELETE VIDEO
//   // -----------------------------------------------------
//   Future<void> deleteVideo(String id) async {
//     try {
//       final response = await http.delete(
//         Uri.parse("${getBackendUrl()}/api/videos/deleteVideoById/$id"),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (response.statusCode == 200) {
//         loadSupervisorVideos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Video deleted")),
//         );
//       }
//     } catch (e) {
//       print("❌ Delete error: $e");
//     }
//   }

//   // -----------------------------------------------------
//   // PUBLISH VIDEO
//   // -----------------------------------------------------
//   Future<void> publishVideo(String id) async {
//     try {
//       final response = await http.put(
//         Uri.parse("${getBackendUrl()}/api/videos/publishVideo/$id"),
//         headers: {"Content-Type": "application/json"},
//         body:jsonEncode({"isPublished":true}),
//       );

//       if (response.statusCode == 200) {
//         loadSupervisorVideos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Video Published")),
//         );
//       }
//     } catch (e) {
//       print("❌ Publish error: $e");
//     }
//   }

//   Future<void> notPublishVideo(String id) async {
//     try {
//       final response = await http.put(
//         Uri.parse("${getBackendUrl()}/api/videos/publishVideo/$id"),
//         headers: {"Content-Type": "application/json"},
//         body:jsonEncode({"isPublished":false}),
//       );

//       if (response.statusCode == 200) {
//         loadSupervisorVideos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Video Published")),
//         );
//       }
//     } catch (e) {
//       print("❌ Publish error: $e");
//     }
//   }
//   // -----------------------------------------------------
//   // GROUP BY CATEGORY
//   // -----------------------------------------------------
//   Map<String, List<dynamic>> groupByCategory(List videos) {
//     Map<String, List<dynamic>> map = {};

//     for (var v in videos) {
//       String cat = v["category"] ?? "Others";
//       if (!map.containsKey(cat)) map[cat] = [];
//       map[cat]!.add(v);
//     }

//     return map;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final categorized = groupByCategory(filteredVideos);

//   return HomePage(
//   title: "Videos",
//   child: DefaultTabController(
//     length: 3,
//     child: Column(
//       children: [
//         // Tabs
//         TabBar(
//           labelColor: Colors.blue,
//           unselectedLabelColor: Colors.grey,
//           indicatorColor: Colors.blue,
//           tabs: const [
//             Tab(text: "Videos Library", icon: Icon(Icons.video_library)),
//             Tab(text: "Playlist", icon: Icon(Icons.playlist_play)),
//             Tab(text: "Analytics", icon: Icon(Icons.bar_chart)),
//           ],
//         ),

//         // Tab Views
//         Expanded(
//           child: TabBarView(
//             children: [
//               // ---------------------------
//               // Videos Library
//               // ---------------------------
//               Stack(
//                 children: [
//                   loading
//                       ? const Center(child: CircularProgressIndicator())
//                       : Column(
//                           children: [
//                          // Search bar with "+" button
//                        Padding(
//                       padding: const EdgeInsets.all(8.0),
//                      child: Row(
//                  children: [
//                  Expanded(
//                  child: TextField(
//                  decoration: InputDecoration(
//             hintText: "Search by title or category",
//             prefixIcon: const Icon(Icons.search),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//           ),
//           onChanged: (value) => filterVideos(value),
//         ),
//       ),
//       const SizedBox(width: 8),
//       SizedBox(
//         height: 48,
//         width: 48,
//         child: ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             padding: EdgeInsets.zero,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(8),
//             ),
//             backgroundColor: AppColors.bgWarmPinkDark,
//           ),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => AddVideoScreen(),
//               ),
//             );
//           },
//              child: const Icon(Icons.add, size: 28,color:Colors.white),
//                 ),
//                ),
//                      ],
//                      )   ,
//                   ),

//                             // Horizontal video rows
//                             Expanded(
//                               child: ListView(
//                                 children: groupByCategory(filteredVideos)
//                                     .keys
//                                     .map((category) {
//                                   final videos = groupByCategory(filteredVideos)[category]!;
//                                   return Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Padding(
//                                         padding: const EdgeInsets.all(12),
//                                         child: Text(
//                                           category,
//                                           style: const TextStyle(
//                                               fontSize: 20,
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                       ),
//                                       SizedBox(
//                                         height: 270,
//                                         child: ListView.builder(
//                                           scrollDirection: Axis.horizontal,
//                                           itemCount: videos.length,
//                                           itemBuilder: (_, index) {
//                                             final video = videos[index];
//                                             return Container(
//                                               width: 220,
//                                               margin: const EdgeInsets.symmetric(horizontal: 8),
//                                               child: Card(
//                                                 elevation: 3,
//                                                 child: Column(
//                                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                                   children: [
//                                                     ClipRRect(
//                                                       borderRadius: const BorderRadius.vertical(
//                                                           top: Radius.circular(4)),
//                                                       child: Image.network(
//                                                         video["thumbnailUrl"],
//                                                         width: double.infinity,
//                                                         height: 140,
//                                                         fit: BoxFit.cover,
//                                                       ),
//                                                     ),
//                                                     Padding(
//                                                       padding: const EdgeInsets.all(6.0),
//                                                       child: Text(
//                                                         video["title"],
//                                                         maxLines: 2,
//                                                         overflow: TextOverflow.ellipsis,
//                                                         style: const TextStyle(
//                                                             fontWeight: FontWeight.bold),
//                                                       ),
//                                                     ),
//                                                     if (video["description"] != null &&
//                                                         video["description"]
//                                                             .toString()
//                                                             .isNotEmpty)
//                                                       Padding(
//                                                         padding: const EdgeInsets.symmetric(
//                                                             horizontal: 6.0),
//                                                         child: Text(
//                                                           video["description"],
//                                                           maxLines: 2,
//                                                           overflow: TextOverflow.ellipsis,
//                                                           style: const TextStyle(
//                                                               color: Colors.black45, fontSize: 12),
//                                                         ),
//                                                       ),
//                                                    // ButtonBar(
//                                                    Row(
//                                                       //alignment: MainAxisAlignment.spaceBetween,
                                                    
//                                                       children: [
//                                                         IconButton(
//                                                           icon: const Icon(Icons.edit,
//                                                               color: AppColors.bgWarmPinkVeryDark, size: 20),
//                                                           onPressed: () =>
//                                                               showEditDialog(video),
//                                                         ),
//                                                         IconButton(
//                                                           icon: const Icon(Icons.delete,
//                                                               color:AppColors.bgWarmPinkVeryDark, size: 20),
//                                                           onPressed: () =>
//                                                               deleteVideo(video["_id"]),
//                                                         ),
//                                                      IconButton(
//   icon: Icon(
//     Icons.check_circle,
//     color: video["isPublished"] == true
//         ? Colors.green
//         : AppColors.bgWarmPinkVeryDark,
//     size: 20,
//   ),
//   onPressed: video["isPublished"] == true
//       ? () => notPublishVideo(video["_id"]) // unpublish if already published
//       : () => publishVideo(video["_id"]),    // publish if not published
// ),
 
//                                                         IconButton(
//                                           icon: const Icon(Icons.quiz, color: Colors.blue, size: 20),
//                                         onPressed: () {
//                                      Navigator.push(
//                                        context,
//                                   MaterialPageRoute(
//                                        builder: (_) => AddQuizPage(videoId: video["_id"]),
//                                       ),
//                                            );
//                                           },
//                                            ),

//                                                       ],
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 }).toList(),
//                               ),
//                             ),
//                           ],
//                         ),
//                   // Floating "+" button
           
//                                 ],
//                               ),

//               // ---------------------------
//               // Playlist
//               // ---------------------------
//               Center(
//                 child: Text(
//                   "Playlist Page (Coming Soon)",
//                   style: TextStyle(fontSize: 18, color:Colors.black),
//                 ),
//               ),

//               // ---------------------------
//               // Analytics
//               // ---------------------------
//               Center(
//                 child: Text(
//                   "Analytics Page (Coming Soon)",
//                   style: TextStyle(fontSize: 18,  color:Colors.black),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   ),
// );
//   }
// }




// Replace the whole _SupervisorVideosPageState with this updated version
class _SupervisorVideosPageState extends State<SupervisorVideosPage> {
  List<dynamic> allVideos = [];
  List<dynamic> filteredVideos = [];
  List<dynamic> playlists = [];
  bool loading = true;
  String searchQuery = "";
  String userId="";

  // for playlist creation/editing
  Set<String> selectedVideoIds = {};
  bool playlistLoading = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await loadSupervisorVideos();
    await loadPlaylists();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }



  // -------------------------
  // Load Supervisor Videos
  // -------------------------
  Future<void> loadSupervisorVideos() async {
    setState(() => loading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null) return;

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      String userId = decodedToken['id'];

      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/videos/getSupervisorVideos/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          allVideos = jsonDecode(response.body);
          filteredVideos = allVideos;
        });
      } else {
        print("Failed to load videos: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ Error loading videos: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void filterVideos(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredVideos = allVideos.where((video) {
        final title = (video["title"] ?? "").toString().toLowerCase();
        final category = (video["category"] ?? "").toString().toLowerCase();
        return title.contains(searchQuery) || category.contains(searchQuery);
      }).toList();
    });
  }
//     // -----------------------------------------------------
//   // EDIT VIDEO
//   // -----------------------------------------------------
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
        Uri.parse("${getBackendUrl()}/api/videos/updateVideoById/$id"),
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

  // -------------------------
  // Playlist APIs
  // -------------------------
  Future<void> loadPlaylists() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null) return;

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];

      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/playlists/getPlaylistBySupervisor/$userId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          playlists = jsonDecode(response.body);
        });
      } else {
        print("Failed to load playlists: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ loadPlaylists error: $e");
    }
  }

  Future<void> createPlaylist({
    required String title,
    String? description,
    required String category,
    required List<String> videoIds,
  }) async {
    setState(() => playlistLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${getBackendUrl()}/api/playlists/createPlaylist"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "title": title,
          "description": description ?? "",
          "category": category,
          "videos": videoIds,
          "isPublished": false,
          "createdBy":userId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await loadPlaylists();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Playlist created")));
      } else {
        print("Create playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ createPlaylist error: $e");
    } finally {
      setState(() => playlistLoading = false);
    }
  }

  Future<void> updatePlaylist(String playlistId, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/updatePlaylist/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Playlist updated")));
      } else {
        print("Update playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ updatePlaylist error: $e");
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      final response = await http.delete(
        Uri.parse("${getBackendUrl()}/api/playlists/deletePlaylist/$playlistId"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Playlist deleted")));
      } else {
        print("Delete playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ deletePlaylist error: $e");
    }
  }

  Future<void> publishPlaylist(String playlistId, bool publish) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/publishPlaylist/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isPublished": publish}),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(publish ? "Playlist published" : "Playlist unpublished")));
      } else {
        print("Publish playlist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ publishPlaylist error: $e");
    }
  }

  Future<void> addVideoToPlaylist(String playlistId, String videoId) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/addVideo/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"videoId": videoId}),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
      } else {
        print("addVideoToPlaylist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ addVideoToPlaylist error: $e");
    }
  }

  Future<void> removeVideoFromPlaylist(String playlistId, String videoId) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/playlists/deleteVideo/$playlistId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"videoId": videoId}),
      );

      if (response.statusCode == 200) {
        await loadPlaylists();
      } else {
        print("removeVideoFromPlaylist failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ removeVideoFromPlaylist error: $e");
    }
  }



  Future<void> deleteVideo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("${getBackendUrl()}/api/videos/deleteVideoById/$id"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        await _initAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video deleted")),
        );
      }
    } catch (e) {
      print("❌ Delete error: $e");
    }
  }

  Future<void> publishVideo(String id) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/videos/publishVideo/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isPublished": true}),
      );

      if (response.statusCode == 200) {
        await _initAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video Published")),
        );
      }
    } catch (e) {
      print("❌ Publish error: $e");
    }
  }

  Future<void> notPublishVideo(String id) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/videos/publishVideo/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isPublished": false}),
      );

      if (response.statusCode == 200) {
        await _initAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video Unpublished")),
        );
      }
    } catch (e) {
      print("❌ Publish error: $e");
    }
  }

  // -------------------------
  // UI Helpers (dialogs)
  // -------------------------
  void showCreatePlaylistDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
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
    String selectedCategory = categories.first;
    selectedVideoIds.clear();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Create Playlist"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                  DropdownButtonFormField(
                    value: selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedCategory = v.toString()),
                  ),
                  const SizedBox(height: 12),
                  const Text("Select videos to include:"),
                  SizedBox(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: allVideos.length,
                      itemBuilder: (_, i) {
                        final v = allVideos[i];
                        final id = v["_id"].toString();
                        final title = v["title"] ?? "";
                        return CheckboxListTile(
                          value: selectedVideoIds.contains(id),
                          onChanged: (val) => setStateDialog(() {
                            if (val == true) selectedVideoIds.add(id); else selectedVideoIds.remove(id);
                          }),
                          title: Text(title),
                          secondary: v["thumbnailUrl"] != null
                              ? Image.network(v["thumbnailUrl"], width: 40, height: 40, fit: BoxFit.cover)
                              : const SizedBox(width: 40, height: 40),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: selectedVideoIds.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await createPlaylist(
                          title: titleController.text.isEmpty ? "New Playlist" : titleController.text,
                          description: descController.text,
                          category: selectedCategory,
                          videoIds: selectedVideoIds.toList(),
                        );
                        setState(() {});
                      },
                child: playlistLoading ? const CircularProgressIndicator() : const Text("Create"),
              )
            ],
          );
        });
      },
    );
  }

  void showPlaylistDetailDialog(dynamic playlist) {
    // playlist contains: title, description, category, videos (array of ids or populated objects), isPublished, _id
    showDialog(
      context: context,
      builder: (_) {
        final titleController = TextEditingController(text: playlist["title"]);
        final descController = TextEditingController(text: playlist["description"]);
        final categoryController = TextEditingController(text: playlist["category"]);
        final currentVideos = List<String>.from(
            (playlist["videos"] ?? []).map((v) => v is String ? v : v["_id"].toString()));

        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text("Playlist: ${playlist["title"]}"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category")),
                  const SizedBox(height: 12),
                  const Text("Videos in playlist:"),
                  SizedBox(
                    height: 200,
                    width: double.maxFinite,
                    child: ListView.builder(
                      itemCount: currentVideos.length,
                      itemBuilder: (_, index) {
                        final vidId = currentVideos[index];
                        final v = allVideos.firstWhere((el) => el["_id"].toString() == vidId, orElse: () => null);
                        final title = v != null ? (v["title"] ?? "Unknown") : "Unknown video (deleted)";
                        return ListTile(
                          leading: v != null && v["thumbnailUrl"] != null
                              ? Image.network(v["thumbnailUrl"], width: 56, height: 40, fit: BoxFit.cover)
                              : const SizedBox(width: 56, height: 40),
                          title: Text(title),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () async {
                              await removeVideoFromPlaylist(playlist["_id"], vidId);
                              await loadPlaylists();
                              setStateDialog(() {});
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await deletePlaylist(playlist["_id"]);
                },
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await updatePlaylist(playlist["_id"], {
                    "title": titleController.text,
                    "description": descController.text,
                    "category": categoryController.text,
                  });
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  // -------------------------
  // Layout
  // -------------------------
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
                  // Videos Library (unchanged)
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
                                                builder: (context) => AddVideoScreen(),
                                              ),
                                            ).then((_) => _initAll());
                                          },
                                          child: const Icon(Icons.add, size: 28, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
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
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 270,
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
                                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                                          child: Image.network(
                                                            video["thumbnailUrl"] ?? "",
                                                            width: double.infinity,
                                                            height: 140,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (_, __, ___) => Container(
                                                              color: Colors.grey[200],
                                                              height: 140,
                                                              child: const Center(child: Icon(Icons.videocam)),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.all(6.0),
                                                          child: Text(
                                                            video["title"] ?? "",
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        if (video["description"] != null && video["description"].toString().isNotEmpty)
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                            child: Text(
                                                              video["description"],
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle(color: Colors.black45, fontSize: 12),
                                                            ),
                                                          ),
                                                        Row(
                                                          children: [
                                                            IconButton(
                                                              icon: const Icon(Icons.edit, color: AppColors.bgWarmPinkVeryDark, size: 20),
                                                              onPressed: () => showEditDialog(video),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.delete, color: AppColors.bgWarmPinkVeryDark, size: 20),
                                                              onPressed: () => deleteVideo(video["_id"]),
                                                            ),
                                                            IconButton(
                                                              icon: Icon(
                                                                Icons.check_circle,
                                                                color: video["isPublished"] == true ? Colors.green : AppColors.bgWarmPinkVeryDark,
                                                                size: 20,
                                                              ),
                                                              onPressed: video["isPublished"] == true ? () => notPublishVideo(video["_id"]) : () => publishVideo(video["_id"]),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(Icons.quiz, color: Colors.blue, size: 20),
                                                              onPressed: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (_) => AddQuizPage(videoId: video["_id"]),
                                                                  ),
                                                                );
                                                              },
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
                    ],
                  ),

                  // ---------------------------
                  // Playlist tab
                  // ---------------------------
                  Scaffold(
                    body: playlists.isEmpty
                        ? Center(child: Text("No playlists yet", style: TextStyle(fontSize: 16)))
                        : ListView.builder(
                            itemCount: playlists.length,
                            itemBuilder: (_, i) {
                              final p = playlists[i];
                              final pVideos = (p["videos"] ?? []);
                              // pick thumbnail from first video if exists
                              String? thumb;
                              if (pVideos.isNotEmpty) {
                                final first = pVideos[0];
                                if (first is String) {
                                  final v = allVideos.firstWhere((el) => el["_id"].toString() == first, orElse: () => null);
                                  thumb = v != null ? v["thumbnailUrl"] : null;
                                } else if (first is Map && first["thumbnailUrl"] != null) {
                                  thumb = first["thumbnailUrl"];
                                }
                              }
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: ListTile(
                                  leading: thumb != null
                                      ? Image.network(thumb, width: 72, fit: BoxFit.cover)
                                      : const SizedBox(width: 72, child: Icon(Icons.playlist_play)),
                                  title: Text(p["title"] ?? "Untitled"),
                                  subtitle: Text("${p["category"] ?? "No category"} • ${ (p["videos"] ?? []).length } videos"),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(p["isPublished"] == true ? Icons.check_circle : Icons.check_circle_outline,
                                            color: p["isPublished"] == true ? Colors.green : AppColors.bgWarmPinkVeryDark),
                                        onPressed: () => publishPlaylist(p["_id"], !(p["isPublished"] == true)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => showPlaylistDetailDialog(p),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deletePlaylist(p["_id"]),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: showCreatePlaylistDialog,
                      label: const Text("Create Playlist"),
                      icon: const Icon(Icons.playlist_add),
                    ),
                  ),

                  // ---------------------------
                  // Analytics
                  // ---------------------------
                  Center(
                    child: Text(
                      "Analytics Page (Coming Soon)",
                      style: TextStyle(fontSize: 18, color: Colors.black),
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
