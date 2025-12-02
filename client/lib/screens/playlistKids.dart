


// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// class KidsPlaylistScreen extends StatefulWidget {
//   const KidsPlaylistScreen({super.key});

//   @override
//   State<KidsPlaylistScreen> createState() => _KidsPlaylistScreenState();
// }

// class _KidsPlaylistScreenState extends State<KidsPlaylistScreen> {
//   List<dynamic> playlists = [];
//   bool loading = true;
//   String userId = "";
//   String ageGroup = "";

//   @override
//   void initState() {
//     super.initState();
//     _initAll();
//   }

//   Future<void> _initAll() async {
//     await loadPublishedPlaylists();
//   }

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.122:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
//   }

//   Future<Map<String, dynamic>?> fetchVideoById(String videoId) async {
//     try {
//       final response = await http.get(
//         Uri.parse("${getBackendUrl()}/api/videos/getVideoById/$videoId"),
//         headers: {"Content-Type": "application/json"},
//       );
//       if (response.statusCode == 200) return jsonDecode(response.body);
//       return null;
//     } catch (e) {
//       print("Error fetching video $videoId: $e");
//       return null;
//     }
//   }

//   Future<void> loadPublishedPlaylists() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString("token");
//     if (token == null) return;
//     Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//     userId = decodedToken['id'];
//     ageGroup = decodedToken['ageGroup'];

//     try {
//       final response = await http.get(
//         Uri.parse("${getBackendUrl()}/api/playlists/getPlaylistsByAge/$ageGroup"),
//         headers: {"Content-Type": "application/json"},
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           playlists = jsonDecode(response.body);
//           loading = false;
//         });
//       }
//     } catch (e) {
//       print("Error loading playlists: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: playlists.length,
//               itemBuilder: (_, i) {
//                 return PlaylistCard(
//                   playlist: playlists[i],
//                   fetchVideoById: fetchVideoById,
//                 );
//               },
//             ),
//     );
//   }
// }

// class PlaylistCard extends StatefulWidget {
//   final dynamic playlist;
//   final Future<Map<String, dynamic>?> Function(String) fetchVideoById;

//   const PlaylistCard({super.key, required this.playlist, required this.fetchVideoById});

//   @override
//   State<PlaylistCard> createState() => _PlaylistCardState();
// }

// class _PlaylistCardState extends State<PlaylistCard> {
//   YoutubePlayerController? controller;
//   dynamic currentVideo;

//   @override
//   void dispose() {
//     controller?.pause();
//     controller?.dispose();
//     super.dispose();
//   }

//   void playVideo(dynamic video) {
//     final videoId = YoutubePlayer.convertUrlToId(video['url']);
//     if (videoId == null) return;

//     // Dispose previous controller
//     controller?.pause();
//     controller?.dispose();

//     // Create new controller
//     controller = YoutubePlayerController(
//       initialVideoId: videoId,
//       flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
//     );

//     setState(() {
//       currentVideo = video;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final videos = widget.playlist["videos"] ?? [];

//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       margin: const EdgeInsets.symmetric(vertical: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               widget.playlist["title"] ?? "Untitled",
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton.icon(
//               onPressed: videos.isNotEmpty
//                   ? () async {
//                       final firstVideoId =
//                           videos[0] is String ? videos[0] : videos[0]["_id"].toString();
//                       final firstVideo = await widget.fetchVideoById(firstVideoId);
//                       if (firstVideo != null) playVideo(firstVideo);
//                     }
//                   : null,
//               icon: const Icon(Icons.play_arrow),
//               label: const Text("Play All"),
//             ),
//             const SizedBox(height: 12),

//             // Only show player if controller is ready
//             if (controller != null) ...[
//               YoutubePlayer(
//                 key: ValueKey(currentVideo?['_id'] ?? DateTime.now()), // UNIQUE KEY!
//                 controller: controller!,
//                 showVideoProgressIndicator: true,
//                 progressIndicatorColor: Colors.red,
//               ),
//               const SizedBox(height: 12),
//             ],

//             Column(
//               children: videos.map<Widget>((v) {
//                 return FutureBuilder<Map<String, dynamic>?>(
//                   future: widget.fetchVideoById(v is String ? v : v["_id"].toString()),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) return const SizedBox();
//                     final video = snapshot.data!;
//                     return ListTile(
//                       leading: video["thumbnailUrl"] != null
//                           ? Image.network(video["thumbnailUrl"], width: 80, fit: BoxFit.cover)
//                           : null,
//                       title: Text(video["title"] ?? "Unknown"),
//                       onTap: () => playVideo(video),
//                     );
//                   },
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:async';

class KidsPlaylistScreen extends StatefulWidget {
  const KidsPlaylistScreen({super.key});

  @override
  State<KidsPlaylistScreen> createState() => _KidsPlaylistScreenState();
}

class _KidsPlaylistScreenState extends State<KidsPlaylistScreen> {
  List<dynamic> playlists = [];
  bool loading = true;
  String userId = "";
  String ageGroup = "";

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await loadPublishedPlaylists();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<Map<String, dynamic>?> fetchVideoById(String videoId) async {
    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/videos/getVideoById/$videoId"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print("Error fetching video $videoId: $e");
      return null;
    }
  }

  Future<void> loadPublishedPlaylists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    userId = decodedToken['id'];
    ageGroup = decodedToken['ageGroup'];

    try {
      final response = await http.get(
        Uri.parse("${getBackendUrl()}/api/playlists/getPlaylistsByAge/$ageGroup"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        setState(() {
          playlists = jsonDecode(response.body);
          loading = false;
        });
      }
    } catch (e) {
      print("Error loading playlists: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                return PlaylistCard(
                  playlist: playlists[i],
                  fetchVideoById: fetchVideoById,
                  userId: userId,
                  backendUrl: getBackendUrl(),
                );
              },
            ),
    );
  }
}

class PlaylistCard extends StatefulWidget {
  final dynamic playlist;
  final Future<Map<String, dynamic>?> Function(String) fetchVideoById;
  final String userId;
  final String backendUrl;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.fetchVideoById,
    required this.userId,
    required this.backendUrl,
  });

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  YoutubePlayerController? controller;
  dynamic currentVideo;
  String? _currentHistoryId;
  Timer? _positionTimer;

  @override
  void dispose() {
    _positionTimer?.cancel();
    saveFinalDuration();
    controller?.dispose();
    super.dispose();
  }

  // -------------------------------
  // History and Duration Functions
  // -------------------------------
  Future<void> saveWatchHistory(String videoId) async {
    final response = await http.post(
      Uri.parse("${widget.backendUrl}/api/history/createHistory"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": widget.userId, "videoId": videoId}),
    );
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _currentHistoryId = data["_id"];
    }
  }

  void updateVideoDuration(String historyId, double minutes) async {
    await http.put(
      Uri.parse("${widget.backendUrl}/api/history/updateDuration/$historyId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"durationWatched": minutes}),
    );
  }

  void saveFinalDuration() {
    if (_currentHistoryId != null && controller != null) {
      final seconds = controller!.value.position.inSeconds;
      if (seconds > 0) {
        updateVideoDuration(_currentHistoryId!, seconds / 60);
      }
    }
  }

  void videoListener() {
    if (!mounted || _currentHistoryId == null || controller == null) return;
    final seconds = controller!.value.position.inSeconds;
    if (seconds > 0) updateVideoDuration(_currentHistoryId!, seconds / 60);
  }

  Future<bool> canWatchVideo() async {
    final response = await http.get(
      Uri.parse("${widget.backendUrl}/api/dailywatch/canWatch/${widget.userId}"),
      headers: {"Content-Type": "application/json"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['allowed'] ?? false;
    }
    return false;
  }

  // -------------------------------
  // Play Video
  // -------------------------------
  void playVideo(dynamic video) async {
    final allowed = await canWatchVideo();
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily watch limit reached!"))
      );
      return;
    }

    // Dispose previous controller
    _positionTimer?.cancel();
    saveFinalDuration();
    controller?.pause();
    controller?.dispose();

    final videoId = YoutubePlayer.convertUrlToId(video['url']);
    if (videoId == null) return;

    final newController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    setState(() {
      controller = newController;
      currentVideo = video;
    });

    controller!.addListener(videoListener);

    // Save history & increment view
    await saveWatchHistory(video['_id']);
    try {
      await http.put(
        Uri.parse("${widget.backendUrl}/api/videos/incrementView/${video['_id']}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": widget.userId}),
      );
    } catch (e) {
      print("Failed to increment view: $e");
    }

    int lastSentSeconds = 0;
    _positionTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_currentHistoryId == null || controller == null) return;

      final posSeconds = controller!.value.position.inSeconds;
      final incrementSeconds = posSeconds - lastSentSeconds;
      if (incrementSeconds <= 0) return;
      lastSentSeconds = posSeconds;
      final incrementMinutes = incrementSeconds / 60;

      final response = await http.post(
        Uri.parse("${widget.backendUrl}/api/dailywatch/calculateRecord/${widget.userId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"minutes": incrementMinutes}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!data['allowed']) {
          _positionTimer?.cancel();
          controller?.pause();
          controller?.dispose();
          setState(() {
            currentVideo = null;
            controller = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Daily watch limit reached!"))
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.playlist["videos"] ?? [];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.playlist["title"] ?? "Untitled",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: videos.isNotEmpty
                  ? () async {
                      final firstVideoId =
                          videos[0] is String ? videos[0] : videos[0]["_id"].toString();
                      final firstVideo = await widget.fetchVideoById(firstVideoId);
                      if (firstVideo != null) playVideo(firstVideo);
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text("Play All"),
            ),
            const SizedBox(height: 12),

            if (controller != null) ...[
              YoutubePlayer(
                key: ValueKey(currentVideo?['_id'] ?? DateTime.now()),
                controller: controller!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
              ),
              const SizedBox(height: 12),
            ],

            Column(
              children: videos.map<Widget>((v) {
                return FutureBuilder<Map<String, dynamic>?>(
                  future: widget.fetchVideoById(v is String ? v : v["_id"].toString()),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final video = snapshot.data!;
                    return ListTile(
                      leading: video["thumbnailUrl"] != null
                          ? Image.network(video["thumbnailUrl"], width: 80, fit: BoxFit.cover)
                          : null,
                      title: Text(video["title"] ?? "Unknown"),
                      onTap: () => playVideo(video),
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
