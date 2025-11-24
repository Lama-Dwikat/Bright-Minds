// lib/screens/kidVideos.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';



class VideosKidScreen extends StatefulWidget {
  const VideosKidScreen({super.key});

  @override
  State<VideosKidScreen> createState() => _VideosKidState();
}

class _VideosKidState extends State<VideosKidScreen> {
  List<dynamic> allVideos = [];
  List<dynamic> filteredVideos = [];
  List<String> favoriteIds = [];
  bool loading = true;
  String searchQuery = "";
  String? userId;
String?ageGroup;
  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _getUserIdFromToken();
    await loadVideos();
    await loadFavorites();
  }

  Future<void> _getUserIdFromToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        final decoded = JwtDecoder.decode(token);
        userId = decoded['id']?.toString();
        ageGroup=decoded['ageGroup'];
      } catch (e) {
        userId = null;
      }
    }
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  
  // --------------------------
  // Load all published videos
  // --------------------------
  Future<void> loadVideos() async {
    setState(() => loading = true);
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/videos/getPublishedVideos/$ageGroup"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        allVideos = jsonDecode(response.body);
        filteredVideos = List.from(allVideos);
      } else {
        print("Failed to load videos: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("❌ loadVideos error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // --------------------------
  // Favorites
  // --------------------------
  Future<void> loadFavorites() async {
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/favorites/getUserFavorites/$userId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body);
        // expect list of video ids or objects; normalize
        favoriteIds = List<String>.from(list.map((e) => e is String ? e : e['_id'].toString()));
      } else {
        print("Failed to load favorites: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ loadFavorites error: $e");
    } finally {
      setState(() {});
    }
  }

  Future<void> toggleFavorite(String videoId) async {
    try {
      if (favoriteIds.contains(videoId)) {
        final response = await http.delete(
          Uri.parse("${getBackendUrl()}/api/favorites/remove/$videoId"),
        headers: {"Content-Type": "application/json"},
        );
        if (response.statusCode == 200) {
          favoriteIds.remove(videoId);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from favorites")));
        } else {
          print("Failed to remove favorite: ${response.statusCode} ${response.body}");
        }
      } else {
        final response = await http.post(
          Uri.parse("${getBackendUrl()}/api/favorites/add"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"videoId": videoId}),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          favoriteIds.add(videoId);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to favorites")));
        } else {
          print("Failed to add favorite: ${response.statusCode} ${response.body}");
        }
      }
    } catch (e) {
      print("❌ toggleFavorite error: $e");
    }
  }

  // --------------------------
  // Play / view / history actions
  // --------------------------
  Future<void> _onPlayVideo(Map<String, dynamic> video) async {
    final vid = video["_id"].toString();
    try {
      // increment views
      await http.put(
        Uri.parse("${getBackendUrl()}/api/videos/incrementView/$vid"),
        headers: {"Content-Type": "application/json"},
      );
      // add to history
      if (userId != null) {
        await http.post(
          Uri.parse("${getBackendUrl()}/api/history/add"),
        headers: {"Content-Type": "application/json"},
          body: jsonEncode({"videoId": vid}),
        );
      }
    } catch (e) {
      print("❌ play actions error: $e");
    }

    // Navigate to a simple player/detail screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoDetailPlayer(video: video)),
    ).then((_) async {
      // refresh videos and favorites and recommended after playback
      await loadVideos();
      await loadFavorites();
    });
  }

  // --------------------------
  // Search & Recommended
  // --------------------------
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

  List<dynamic> recommendedTopN(int n) {
    final list = List<dynamic>.from(allVideos);
    list.sort((a, b) {
      final av = (a["views"] ?? 0) is int ? (a["views"] ?? 0) : int.tryParse((a["views"] ?? "0").toString()) ?? 0;
      final bv = (b["views"] ?? 0) is int ? (b["views"] ?? 0) : int.tryParse((b["views"] ?? "0").toString()) ?? 0;
      return bv.compareTo(av);
    });
    return list.take(n).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommended = recommendedTopN(6);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Videos"),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await loadVideos();
                await loadFavorites();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Search
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Search by title or category",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (value) => filterVideos(value),
                      ),
                      const SizedBox(height: 12),

                      // --- Recommended strip
                      if (recommended.isNotEmpty) ...[
                        const Text("Recommended for you", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: recommended.length,
                              itemBuilder: (_, i) {
                                final v = recommended[i];
                                return GestureDetector(
                                  onTap: () => _onPlayVideo(v),
                                  child: Container(
                                    width: 260,
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Card(
                                      elevation: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: v["thumbnailUrl"] != null
                                                ? Image.network(v["thumbnailUrl"],
                                                    width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.videocam))
                                                : Container(color: Colors.grey[200], child: const Icon(Icons.videocam)),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                    child: Text(
                                                  v["title"] ?? "",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                )),
                                                IconButton(
                                                  padding: EdgeInsets.zero,
                                                  icon: Icon(
                                                    favoriteIds.contains(v["_id"].toString()) ? Icons.favorite : Icons.favorite_border,
                                                    color: favoriteIds.contains(v["_id"].toString()) ? Colors.red : Colors.grey,
                                                  ),
                                                  onPressed: () => toggleFavorite(v["_id"].toString()),
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // --- All videos grouped by category (or flat list if you prefer)
                      const Text("All videos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      // Grid of videos
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredVideos.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (_, index) {
                          final video = filteredVideos[index];
                          final vidId = video["_id"].toString();
                          return GestureDetector(
                            onTap: () => _onPlayVideo(video),
                            child: Card(
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: video["thumbnailUrl"] != null
                                        ? Image.network(video["thumbnailUrl"], width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.videocam)))
                                        : Container(color: Colors.grey[200], child: const Icon(Icons.videocam)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Text(video["title"] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text((video["category"] ?? ""), style: const TextStyle(fontSize: 12, color: Colors.black54))),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: Icon(favoriteIds.contains(vidId) ? Icons.favorite : Icons.favorite_border,
                                              color: favoriteIds.contains(vidId) ? Colors.red : Colors.grey),
                                          onPressed: () => toggleFavorite(vidId),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                    child: Text("Views: ${video["views"] ?? 0}", style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}


class VideoDetailPlayer extends StatefulWidget {
  final Map<String, dynamic> video;
  const VideoDetailPlayer({super.key, required this.video});

  @override
  State<VideoDetailPlayer> createState() => _VideoDetailPlayerState();
}

class _VideoDetailPlayerState extends State<VideoDetailPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.video['url'] ?? '';
    final videoId = YoutubePlayer.convertUrlToId(videoUrl) ?? '';
    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.video['title'] ?? '';
    final description = widget.video['description'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            YoutubePlayer(
              controller: _controller,
              showVideoProgressIndicator: true,
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(child: Text(description)),
            ),
          ],
        ),
      ),
    );
  }
}
