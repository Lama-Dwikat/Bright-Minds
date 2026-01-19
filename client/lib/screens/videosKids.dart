// lib/screens/kidVideos.dart
import 'package:bright_minds/screens/playlistKids.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/theme/colors.dart';
import 'dart:async';
import 'package:bright_minds/screens/Quiz/solveQuiz.dart';




class VideosKidScreen extends StatefulWidget {
  const VideosKidScreen({super.key});

  @override
  State<VideosKidScreen> createState() => _VideosKidState();
}

class _VideosKidState extends State<VideosKidScreen> {
  List<dynamic> allVideos = [];
  List<dynamic> filteredVideos = [];
  List<dynamic> playlists = [];
  List<String> favoriteIds = [];
  bool loading = true;
  String searchQuery = "";
  String userId = "";
  String ageGroup="";
  List<dynamic> recommendedVideos = [];
  bool loadingRecommended = false;
  String? _currentHistoryId;
  Timer? _positionTimer;




  // currently playing video
  dynamic currentVideo;
  YoutubePlayerController? ytController;

  @override
  void initState() {
    super.initState();
    _initAll();
    
  }

  Future<void> _initAll() async {
    await loadAllVideos();
    await loadFavorites();
    await loadRecommendedVideos();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }








  // -------------------------
  // Load Favorites
  // -------------------------
  Future<void> loadFavorites() async {
    if (userId.isEmpty) return;
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/users/getUserFavourite/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        favoriteIds = List<String>.from(list.map((e) => e is String ? e : e['_id'].toString()));
      }
    } catch (e) {
      print("❌ loadFavorites error: $e");
    } finally {
      setState(() {});
    }
  }

  // -------------------------
  // Load All Videos
  // -------------------------
  Future<void> loadAllVideos() async {
    setState(() => loading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null) return;

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      userId = decodedToken['id'];
       ageGroup = decodedToken['ageGroup'];

      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/videos/getVideosByAge/$ageGroup"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final decoded = List<dynamic>.from(jsonDecode(response.body));
        // sort by createdAt descending
        decoded.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
        setState(() {
          allVideos = decoded;
          filteredVideos = decoded;
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
        final description = (video["description"] ?? "").toString().toLowerCase();
        return title.contains(searchQuery) || category.contains(searchQuery) || description.contains(searchQuery);
      }).toList();
    });
  }

  // -------------------------
  // Toggle Favorite
  // -------------------------
  void toggleFavorite(dynamic video) async {
    final videoId = video['_id'];
    setState(() {
      if (favoriteIds.contains(videoId)) {
        favoriteIds.remove(videoId);
      } else {
        favoriteIds.add(videoId);
      }
    });

    try {
      final url = favoriteIds.contains(videoId)
          ? "${getBackendUrl()}/api/users/addFavouriteVideo/$userId"
          : "${getBackendUrl()}/api/users/deleteFavouriteVideo/$userId";

      await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"videoId": videoId}),
      );
    } catch (e) {
      print("❌ toggleFavorite error: $e");
    }
  }

  // -------------------------
  // Group by category
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

  // -------------------------
  // Play video
  // -------------------------


void playVideo(dynamic video) async {
  final canWatch = await canWatchVideo(); 
  if (!canWatch) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Daily watch limit reached! Try again tomorrow."))
    );
    return;
  }

  // Dispose old controller
  if (ytController != null) {
    _positionTimer?.cancel();
    saveFinalDuration();
    ytController!.pause();
    ytController!.dispose();
    ytController = null;
  }

  final videoId = YoutubePlayer.convertUrlToId(video['url']);
  if (videoId == null) return;

  // Create new controller **before setState**
  final newController = YoutubePlayerController(
    initialVideoId: videoId,
    flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
  );

  // Assign controller and update state
  setState(() {
    ytController = newController;
    currentVideo = video;
    recommendedVideos = [];
  });

  // Add listener **after assignment**
  ytController!.addListener(videoListener);

  // Save history and increment view
  await saveWatchHistory(video['_id']);
  try {
    await http.put(
      Uri.parse("${getBackendUrl()}/api/videos/incrementView/${video['_id']}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );
  } catch (e) {
    print("❌ Failed to increment view: $e");
  }

  // Start periodic duration update
  int _lastSentSeconds = 0;
  _positionTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
    if (_currentHistoryId == null || ytController == null) return;
    final posSeconds = ytController!.value.position.inSeconds;
    final incrementSeconds = posSeconds - _lastSentSeconds;
    if (incrementSeconds <= 0) return;
    _lastSentSeconds = posSeconds;
    final incrementMinutes = incrementSeconds / 60;

    final response = await http.post(
      Uri.parse("${getBackendUrl()}/api/dailywatch/calculateRecord/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"minutes": incrementMinutes}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (!data['allowed']) {
        _positionTimer?.cancel();
        ytController?.pause();
        ytController?.dispose();
        setState(() {
          currentVideo = null;
          ytController = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Daily watch limit reached!"))
        );
      }
    }
  });

  loadRecommendedVideos();
}


//-----------
//////////////////
///
Future<bool> canWatchVideo() async {
  final response = await http.get(
    Uri.parse("${getBackendUrl()}/api/dailywatch/canWatch/$userId"),
    headers: {"Content-Type": "application/json"},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['allowed'] ?? false;
  }
  return false;
}


//-------------------------
//Recommended Videos
//-------------------------
Future<void> loadRecommendedVideos() async {
  if (currentVideo == null) return;

  setState(() => loadingRecommended = true);

  try {
    final response = await http.get(
     Uri.parse("${getBackendUrl()}/api/videos/getRecommendedVideos/$ageGroup"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final decoded = List<dynamic>.from(jsonDecode(response.body));
      setState(() {
        recommendedVideos = decoded;
        print ("recommended videos: $recommendedVideos");
      });
    } else {
      print("Failed to load recommended videos: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error loading recommended videos: $e");
  } finally {
    setState(() => loadingRecommended = false);
  }
}


//-------------------------
//Save Video at History
//-------------------------

Future<void> saveWatchHistory(String videoId) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString("token");
  if (token == null) return;

  final decodedToken = JwtDecoder.decode(token);
  final userId = decodedToken["id"];

  final response = await http.post(
    Uri.parse("${getBackendUrl()}/api/history/createHistory"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"userId": userId, "videoId": videoId}),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    _currentHistoryId = data["_id"];   // 👈 STORE HISTORY ID HERE
    print("HISTORY ID AT START: $_currentHistoryId");   // 👈 ADD THIS HERE
  }

  print("Save history: ${response.statusCode} ${response.body}");
}


//-------------------------
//Update Video Duration
//-------------------------

// Update Video Duration in minutes
void updateVideoDuration(String historyId, double minutes) async {
  print("Updating history $historyId with $minutes minutes");
  await http.put(
    Uri.parse("${getBackendUrl()}/api/history/updateDuration/$historyId"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"durationWatched": minutes}),
  );
}



// Save final duration in minutes
void saveFinalDuration() {
  if (_currentHistoryId != null && ytController != null) {
    final seconds = ytController!.value.position.inSeconds;
    if (seconds > 0) {
      final minutes = seconds / 60;
      updateVideoDuration(_currentHistoryId!, minutes);
    }
  }
}


// Listener to update every few seconds
void videoListener() {
  if (!mounted) return;
  if (_currentHistoryId == null) return;
  if (ytController == null) return;

  final seconds = ytController!.value.position.inSeconds;
  if (seconds > 0) {
    final minutes = seconds / 60;
    updateVideoDuration(_currentHistoryId!, minutes);
  }
}



@override
void dispose() {
  _positionTimer?.cancel();
  saveFinalDuration();

  ytController?.dispose();
  super.dispose();
}





@override
Widget build(BuildContext context) {

if (currentVideo != null) {
   if ( !kIsWeb) {
  return HomePage(
    title: currentVideo['title'] ?? "Playing Video",
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

currentVideo != null && ytController != null
    ? YoutubePlayerBuilder(
        player: YoutubePlayer(
          key: ValueKey(ytController!.initialVideoId),   // ★ NEW LINE REQUIRED
          controller: ytController!,
          showVideoProgressIndicator: true,
          onReady: () {
            ytController!.addListener(videoListener);
          },
          onEnded: (metaData) {
            saveFinalDuration();
          },
        ),
        builder: (context, player) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              player,                 // NEW: actual player
              const SizedBox(height: 8),
              // Recommended videos list goes here...
            ],
          );
        },
      )
    : Container(), // Placeholder if no video

        const SizedBox(height: 8),

        // Recommended Videos Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            "Recommended for you",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Recommended Videos List
        Expanded(
          child: loadingRecommended
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: recommendedVideos.length,
                  itemBuilder: (_, index) {
                    final video = recommendedVideos[index];
                    final isFav = favoriteIds.contains(video['_id']);

                    return GestureDetector(
                      onTap: () => playVideo(video),
                      child: Container(
                        height: 100,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            // Video Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                video['thumbnailUrl'] ?? "",
                                width: 160,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Title + Category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    video['title'] ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    video['category'] ?? "Unknown Category",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Play / Favorite Buttons
                            IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.red,
                              ),
                              onPressed: () => toggleFavorite(video),
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
else {
  // WEB DESIGN
  return HomePage(
    title :"Video",
    child: Column(
      children: [
        // Fixed height video player (instead of Expanded)
        if (currentVideo != null && ytController != null)
          Container(
            height: 400, // fixed height for web
            padding: const EdgeInsets.all(16),
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                key: ValueKey(ytController!.initialVideoId),
                controller: ytController!,
                showVideoProgressIndicator: true,
                onReady: () {
                  ytController!.addListener(videoListener);
                },
                onEnded: (metaData) {
                  saveFinalDuration();
                },
              ),
              builder: (context, player) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: player),
                    const SizedBox(height: 12),
                    Text(
                      currentVideo?['title'] ?? "Playing Video",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // Recommended Videos Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recommended for you",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Recommended Videos Grid in Flexible
        Flexible(
          child: loadingRecommended
              ? const Center(child: CircularProgressIndicator())
            

                    : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendedVideos.length,
                  itemBuilder: (_, index) {
                    final video = recommendedVideos[index];
                    final isFav = favoriteIds.contains(video['_id']);
                  return GestureDetector(
                 onTap: () => playVideo(video),
                     child: Container(
    width: 270,
    height:800,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    child: Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: Image.network(
              video["thumbnailUrl"] ?? "",
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),

          // Text Info
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Title
                Text(
                  video["title"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  video["description"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

         
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Created Date
      Text(
        video["createdAt"] != null
            ? "Created: ${DateTime.parse(video["createdAt"]).toLocal().toString().split(' ')[0]}"
            : "",
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),

      Row(
        children: [
          // Favorite
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () => toggleFavorite(video),
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
);

                  },
                    ),
        ),
      ]
    ),
                );
                
}



}
  // Otherwise, show the normal tabs UI
  final categorized = groupByCategory(filteredVideos);
  final favoriteVideos =
      allVideos.where((v) => favoriteIds.contains(v['_id'])).toList();

  return HomePage(
    title: "Videos",
    child: DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: const [
              Tab(text: "Videos Library", icon: Icon(Icons.video_library)),
              Tab(text: "Playlists", icon: Icon(Icons.playlist_play)),
              Tab(text: "Favourites", icon: Icon(Icons.favorite)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
// Videos Library
loading
    ? const Center(child: CircularProgressIndicator())
    : ListView(
        children: categorized.keys.map((category) {
          final videos = categorized[category]!;
          
          // sort newest → oldest
          videos.sort(
            (a, b) => DateTime.parse(b['createdAt'])
                .compareTo(DateTime.parse(a['createdAt'])),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Title
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Video Cards List
              SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: videos.length,
                  itemBuilder: (_, index) {
                    final video = videos[index];
                    final isFav = favoriteIds.contains(video['_id']);
                  return GestureDetector(
                 onTap: () => playVideo(video),
                     child: Container(
    width: 270,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    child: Card(
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            child: Image.network(
              video["thumbnailUrl"] ?? "",
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),

          // Text Info
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Title
                Text(
                  video["title"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  video["description"] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

         
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Created Date
      Text(
        video["createdAt"] != null
            ? "Created: ${DateTime.parse(video["createdAt"]).toLocal().toString().split(' ')[0]}"
            : "",
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),

      Row(
        children: [
          // Favorite
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: () => toggleFavorite(video),
          ),

          // Quiz Icon
         // if (video["hasQuiz"] == true) // <-- check your API field
            IconButton(
              icon: const Icon(Icons.quiz, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SolveQuizPage(videoId: video['_id']),
                  ),
                );
              },
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
);

                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),


                // Playlists
              KidsPlaylistScreen(),
      

                 favoriteVideos.isEmpty
                  ? const Center(child: Text("No favorite videos"))
                  : ListView.builder(
                   itemCount: favoriteVideos.length,
                   itemBuilder: (context, index) {
                  final video = favoriteVideos[index];

                    return Container(
                     height: 120, // Bigger row
                       padding: const EdgeInsets.all(8),
                          child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Thumbnail
                          ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                         child: Image.network(
                         video['thumbnailUrl'] ?? "",
                        width: 120,
                         height: 120,
                        fit: BoxFit.cover,
                       ),
                     ),

                const SizedBox(width: 12),

                // Title + Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        video['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // Category
                      Text(
                        video['category'] ?? "Unknown Category",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Play button
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 32),
                  onPressed: () => playVideo(video),
                ),
              ],
            ),
          );
        },
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