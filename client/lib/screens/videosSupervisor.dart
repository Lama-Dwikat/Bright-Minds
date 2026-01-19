

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
import 'package:bright_minds/screens/Quiz/addQuiz.dart';
import 'package:bright_minds/screens/Quiz/editQuiz.dart';
import 'package:bright_minds/screens/playlistSupervisor.dart';
import 'package:bright_minds/screens/analytics.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';




class SupervisorVideosPage extends StatefulWidget {
  const SupervisorVideosPage({super.key});

  @override
  State<SupervisorVideosPage> createState() => _SupervisorVideosPageState();
}

class _SupervisorVideosPageState extends State<SupervisorVideosPage> {
  List<dynamic> allVideos = [];
  List<dynamic> filteredVideos = [];
  List<dynamic> playlists = [];
  bool loading = true;
  String searchQuery = "";
  String userId="";
  dynamic currentVideo;
  YoutubePlayerController? ytController;


  // for playlist creation/editing
  Set<String> selectedVideoIds = {};
  bool playlistLoading = false;

  @override
  void initState() {
    super.initState();
    loadSupervisorVideos();

  }


String getBackendUrl() {
  if (kIsWeb) {
    return "http://192.168.1.74:3000";

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
//------------------------
//check exist quiz
//-------------------
Future<bool> checkQuizExists(String videoId) async {
  try {
    final response = await http.get(
      Uri.parse("${getBackendUrl()}/api/quiz/getQuizByVideoId/$videoId"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      
      final data = jsonDecode(response.body);
      print("videoId for quiz : $videoId");
      print("reponse body for video quiz :${response.body}");
       if (data != null && data.isNotEmpty) {
     print("response body for quiz 200 retur true");
        return true; // Quiz exists
       }
      else {
             print("response body for quiz 200 return false");
        return false; // No quiz
            }

    } else if (response.statusCode == 400) {
            print("response body for quiz 400");
      return false; // No quiz
    } else {
      print("Failed to check quiz: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error checking quiz: $e");
    return false;
  }
}

//-----------------------------
// Play Video 
//-----------------------------
void playVideo(dynamic video) {
  final videoId = YoutubePlayer.convertUrlToId(video['url']);
  if (videoId == null) return;

  // Dispose old controller if exists
  ytController?.pause();
  ytController?.dispose();

  ytController = YoutubePlayerController(
    initialVideoId: videoId,
    flags: const YoutubePlayerFlags(
      autoPlay: true,
      mute: false,
    ),
  );

  setState(() {
    currentVideo = video;
  });
}


//---------------------
// Recommned video 
//----------------------------

Future<void> toggleRecommendVideo(String videoId, bool currentState) async {
  try {
    final response = await http.put(
      Uri.parse("${getBackendUrl()}/api/videos/setRecommend/$videoId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "recommended": !currentState, // toggle the current state
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        for (var video in allVideos) {
          if (video["_id"] == videoId) {
            video["recommended"] = !currentState; // update locally
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentState
              ? "Marked as recommended"
              : "Removed from recommended"),
        ),
      );
    } else {
      print("Failed: ${response.body}");
    }
  } catch (e) {
    print("❌ toggleRecommendVideo error: $e");
  }
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

      // 🔥 Update only the edited video locally
      setState(() {
        for (var video in allVideos) {
          if (video["_id"] == id) {
            video["title"] = title;
            video["description"] = desc;
            video["category"] = category;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video updated")),
      );
    }
    } catch (e) {
      print("❌ Update error: $e");
    }
  }

 






  Future<void> deleteVideo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("${getBackendUrl()}/api/videos/deleteVideoById/$id"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {

      // 🔥 Remove video locally without refreshing entire screen
      setState(() {
        allVideos.removeWhere((video) => video["_id"] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video deleted")),
      );
    } else {
      print("Delete video failed: ${response.statusCode} ${response.body}");
    }
    } catch (e) {
      print("❌ Delete error: $e");
    }
  }

  Future<void> _showDeleteConfirmation(String videoId) async {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Delete Video"),
        content: const Text("Are you sure you want to delete this video? This action cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(), // dismiss only
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 232, 192, 112),
            ),
            child: const Text("Yes, Delete"),
            onPressed: () async {
              Navigator.of(context).pop(); // close dialog first
              await deleteVideo(videoId); // call your existing delete
            },
          ),
        ],
      );
    },
  );
}




  Future<void> publishVideo(String videoId, bool publish) async {
    try {
      final response = await http.put(
        Uri.parse("${getBackendUrl()}/api/videos/publishVideo/$videoId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"isPublished": publish}),
      );

      if (response.statusCode == 200) {
          setState(() {
        for (var video in allVideos) {
          if (video["_id"] == videoId) {
            video["isPublished"] = publish;   // update UI only
          }
        }
      });
        }
      //}
       else {
        print("Publish video failed: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ publish Video error: $e");
    }
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
                                            backgroundColor: const Color.fromARGB(255, 221, 171, 72),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AddVideoScreen(),
                                              ),
                                            ).then((_) =>    loadSupervisorVideos());

                                            // _initAll());
                                          },
                                          child: const Icon(Icons.add, size: 28, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Expanded(
                                child:Column(
  children: [
    // Show YouTube player only if a video is selected
    if (currentVideo != null && ytController != null)
      Container(
        height: 220, // adjust height
        color: Colors.black,
        child: Stack(
          children: [
            YoutubePlayer(
              controller: ytController!,
              showVideoProgressIndicator: true,
              onReady: () {
                ytController!.addListener(() {
                  // optional: track progress
                });
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  ytController?.pause();
                  ytController?.dispose();
                  setState(() {
                    currentVideo = null;
                    ytController = null;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      Expanded(
  child: ListView(
     children: categorized.keys.map((category) {
    final videos = categorized[category]!; // use the same map
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
                return GestureDetector(
                  onTap: () =>
                   
                   playVideo(video),
                   
                  
                  
                  child: Container(
                    width: 250,
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
                                icon: const Icon(Icons.edit, color: Color.fromARGB(255, 242, 181, 59), size: 20),
                                onPressed: () => showEditDialog(video),
                                tooltip: "Edit Video",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Color.fromARGB(255, 242, 181, 59), size: 20),
                                onPressed: () => _showDeleteConfirmation(video["_id"]),
                                tooltip: "Delete Video",
                              ),
                              IconButton(
                                icon: Icon(
                                  video["isPublished"] == true ? Icons.check_circle : Icons.check_circle_outline,
                                  color: video["isPublished"] == true ? Colors.green : Color.fromARGB(255, 242, 181, 59),
                                ),
                                onPressed: () => publishVideo(video["_id"], !(video["isPublished"] == true)),
                                tooltip: video["isPublished"] == true ? "Unpublish" : "Publish",
                              ),
                          
                              IconButton(
  icon: const Icon(Icons.quiz, color: Colors.blue, size: 20),
  onPressed: () async {
    bool exists = await checkQuizExists(video["_id"]);

    if (exists) {
      // Go to solve/view quiz page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditQuizPage(videoId: video["_id"]), // Your solve quiz page
        ),
      );
    } else {
      // Go to create quiz page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddQuizPage(videoId: video["_id"]),
        ),
      );
    }
  },
  tooltip: "Quiz",
),

                              IconButton(
                                onPressed: () => toggleRecommendVideo(video["_id"], video["recommended"] == true),
                                icon: Icon(
                                  video["recommended"] == true ? Icons.star : Icons.star_border,
                                  color: video["recommended"] == true ? Colors.amber : Colors.grey,
                                ),
                                tooltip: video["recommended"] == true
                                    ? "Click to remove recommendation"
                                    : "Click to recommend this video",
                              ),
                            ],
                          ),
                        ],
                      ),
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
)
  ],
                                ),
                                ),
                              ],
                            ),
                    ],
                  ),

                  // ---------------------------
                  // Playlist tab
                  // ---------------------------
                   SupervisorPlaylistScreen(),

                  // ---------------------------
                  // Analytics
                  // ---------------------------
                      AnalyticsScreen(),
                ],
              )
                
            ),
          ],
        ),
      ),
    );
  }
}



