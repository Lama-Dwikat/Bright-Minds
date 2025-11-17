
// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:http/http.dart' as http;
// // import 'dart:convert';
// // import 'dart:io' show Platform;
// // import 'package:flutter/foundation.dart' show kIsWeb;
// // import 'package:jwt_decoder/jwt_decoder.dart';
// // import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// // class SupervisorVideosScreen extends StatefulWidget {
// //   const SupervisorVideosScreen({super.key});

// //   @override
// //   State<SupervisorVideosScreen> createState() => _SupervisorVideosState();
// // }

// // class _SupervisorVideosState extends State<SupervisorVideosScreen> {
// //   List<dynamic> videos = [];
// //   bool isLoading = true; // loading indicator

// //   String getBackendUrl() {
// //     if (kIsWeb) {
// //       return "http://192.168.1.122:3000";
// //     } else if (Platform.isAndroid) {
// //       return "http://10.0.2.2:3000";
// //     } else {
// //       return "http://localhost:3000";
// //     }
// //   }

// //   void fetchVideos() async {
// //     SharedPreferences prefs = await SharedPreferences.getInstance();
// //     String? token = prefs.getString('token');

// //     if (token == null) {
// //       print("❌ No token found");
// //       setState(() {
// //         isLoading = false;
// //       });
// //       return;
// //     }

// //     print("✅ Token found, fetching videos...");

// //     try {
// //     final url = Uri.parse(
// //   '${getBackendUrl()}/api/videos/fetchVideosFromAPI?topic=${Uri.encodeComponent('english letters')}',
// // );


// //       final response = await http.get(
// //         url,
// //         headers: {
// //           "Authorization": "Bearer $token",
// //           "Content-Type": "application/json",
// //         },
// //       );

// //       print("✅ Response status: ${response.statusCode}");
// //       print("✅ Response body: ${response.body}");

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);

// //         if (data['items'] != null && data['items'] is List) {
// //           setState(() {
// //             videos = data['items'];
// //             isLoading = false;
// //           });
// //           print("✅ Loaded ${videos.length} videos");
// //         } else {
// //           print("❌ 'items' not found in response");
// //           setState(() {
// //             isLoading = false;
// //           });
// //         }
// //       } else {
// //         print("❌ Failed to fetch videos: ${response.statusCode}");
// //         setState(() {
// //           isLoading = false;
// //         });
// //       }
// //     } catch (e) {
// //       print("❌ Exception fetching videos: $e");
// //       setState(() {
// //         isLoading = false;
// //       });
// //     }
// //   }

// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchVideos();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Supervisor Videos'),
// //         centerTitle: true,
// //         backgroundColor: Colors.redAccent,
// //       ),
// //       body: isLoading
// //           ? const Center(child: CircularProgressIndicator())
// //           : videos.isEmpty
// //               ? const Center(child: Text('No videos found.'))
// //               : ListView.builder(
// //                   itemCount: videos.length,
// //                   itemBuilder: (context, index) {
// //                     final video = videos[index];
// //                     final videoId = video['id']['videoId'];
// //                     final title = video['snippet']['title'];
// //                     final channel = video['snippet']['channelTitle'];

// //                     return Card(
// //                       margin: const EdgeInsets.all(10),
// //                       elevation: 5,
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           YoutubePlayer(
// //                             controller: YoutubePlayerController(
// //                               initialVideoId: videoId,
// //                               flags: const YoutubePlayerFlags(
// //                                 autoPlay: false,
// //                                 mute: false,
// //                               ),
// //                             ),
// //                             showVideoProgressIndicator: true,
// //                             progressIndicatorColor: Colors.redAccent,
// //                           ),
// //                           Padding(
// //                             padding: const EdgeInsets.all(8.0),
// //                             child: Text(
// //                               title,
// //                               style: const TextStyle(
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.bold,
// //                               ),
// //                             ),
// //                           ),
// //                           Padding(
// //                             padding:
// //                                 const EdgeInsets.only(left: 8.0, bottom: 8.0),
// //                             child: Text(
// //                               channel,
// //                               style: const TextStyle(
// //                                 color: Colors.grey,
// //                                 fontSize: 14,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     );
// //                   },
// //                 ),
// //     );
// //   }
// // }


// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// class SupervisorVideosScreen extends StatefulWidget {
//   const SupervisorVideosScreen({super.key});

//   @override
//   State<SupervisorVideosScreen> createState() => _SupervisorVideosState();
// }

// class _SupervisorVideosState extends State<SupervisorVideosScreen> {
//   List<dynamic> videos = [];
//   bool isLoading = true;
//   bool isLoadingMore = false;
//   String? nextPageToken; // for YouTube pagination
//   final String topic = "english letters";

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.122:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
//   }

//   Future<void> fetchVideos({bool loadMore = false}) async {
//     if (!loadMore) {
//       setState(() {
//         isLoading = true;
//       });
//     } else {
//       setState(() {
//         isLoadingMore = true;
//       });
//     }

//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');

//     if (token == null) {
//       print("❌ No token found");
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//       return;
//     }

//     try {
//       final queryParams = {
//         "topic": topic,
//         if (nextPageToken != null) "pageToken": nextPageToken!,
//       };

//       final uri = Uri.parse('${getBackendUrl()}/api/videos/fetchVideosFromAPI')
//           .replace(queryParameters: queryParams);

//       final response = await http.get(uri, headers: {
//         "Authorization": "Bearer $token",
//         "Content-Type": "application/json",
//       });

//       print("✅ Response status: ${response.statusCode}");
//       print("✅ Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data['items'] != null && data['items'] is List) {
//           setState(() {
//             videos.addAll(data['items']); // append new videos
//             nextPageToken = data['nextPageToken'];
//             isLoading = false;
//             isLoadingMore = false;
//           });
//           print("✅ Loaded ${videos.length} videos so far");
//         } else {
//           print("❌ 'items' not found in response");
//           setState(() {
//             isLoading = false;
//             isLoadingMore = false;
//           });
//         }
//       } else {
//         print("❌ Failed to fetch videos: ${response.statusCode}");
//         setState(() {
//           isLoading = false;
//           isLoadingMore = false;
//         });
//       }
//     } catch (e) {
//       print("❌ Exception: $e");
//       setState(() {
//         isLoading = false;
//         isLoadingMore = false;
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchVideos();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Supervisor Videos'),
//         centerTitle: true,
//         backgroundColor: Colors.redAccent,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : videos.isEmpty
//               ? const Center(child: Text('No videos found.'))
//               : Column(
//                   children: [
//                     Expanded(
//                       child: ListView.builder(
//                         itemCount: videos.length,
//                         itemBuilder: (context, index) {
//                           final video = videos[index];
//                           final videoId = video['id']['videoId'];
//                           final title = video['snippet']['title'];
//                           final channel = video['snippet']['channelTitle'];

//                           return Card(
//                             margin: const EdgeInsets.all(10),
//                             elevation: 5,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 YoutubePlayer(
//                                   controller: YoutubePlayerController(
//                                     initialVideoId: videoId,
//                                     flags: const YoutubePlayerFlags(
//                                       autoPlay: false,
//                                       mute: false,
//                                     ),
//                                   ),
//                                   showVideoProgressIndicator: true,
//                                   progressIndicatorColor: Colors.redAccent,
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Text(
//                                     title,
//                                     style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.only(
//                                       left: 8.0, bottom: 8.0),
//                                   child: Text(
//                                     channel,
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     if (nextPageToken != null)
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: isLoadingMore
//                             ? const CircularProgressIndicator()
//                             : ElevatedButton(
//                                 onPressed: () {
//                                   fetchVideos(loadMore: true);
//                                 },
//                                 child: const Text("Show More"),
//                               ),
//                       ),
//                   ],
//                 ),
//     );
//   }
// }

/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SupervisorVideosScreen extends StatefulWidget {
  const SupervisorVideosScreen({super.key});

  @override
  State<SupervisorVideosScreen> createState() => _SupervisorVideosState();
}

class _SupervisorVideosState extends State<SupervisorVideosScreen> {
  List<dynamic> videos = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextPageToken; // for YouTube pagination
  String topic = ""; // user input topic
  Set<String> videoIds = {}; // avoid duplicate videos

  final TextEditingController _controller = TextEditingController();

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<void> fetchVideos({bool loadMore = false}) async {
    if (topic.trim().isEmpty) return;

    if (!loadMore) {
      setState(() {
        isLoading = true;
        videos.clear();
        videoIds.clear();
        nextPageToken = null; // reset pagination for new topic
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print("❌ No token found");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    try {
      final queryParams = {
        "topic": topic,
        if (nextPageToken != null) "pageToken": nextPageToken!,
      };

      final uri = Uri.parse('${getBackendUrl()}/api/videos/fetchVideosFromAPI')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      });

      print("✅ Response status: ${response.statusCode}");
      print("✅ Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['items'] != null && data['items'] is List) {
          final newVideos = data['items']
              .where((v) => !videoIds.contains(v['id']['videoId']))
              .toList();

          setState(() {
            videos.addAll(newVideos);
            videoIds.addAll(newVideos.map((v) => v['id']['videoId']));
            nextPageToken = data['nextPageToken'];
            isLoading = false;
            isLoadingMore = false;
          });

          print("✅ Loaded ${videos.length} videos so far");
        } else {
          print("❌ 'items' not found in response");
          setState(() {
            isLoading = false;
            isLoadingMore = false;
          });
        }
      } else {
        print("❌ Failed to fetch videos: ${response.statusCode}");
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Videos'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: "Enter topic (Arabic or English)",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      topic = value;
                      fetchVideos();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    topic = _controller.text;
                    fetchVideos();
                  },
                  child: const Text("Search"),
                ),
              ],
            ),
          ),

          // Videos List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : videos.isEmpty
                    ? const Center(child: Text('No videos found.'))
                    : ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final videoId = video['id']['videoId'];
                          final title = video['snippet']['title'];
                          final channel = video['snippet']['channelTitle'];

                          return Card(
                            margin: const EdgeInsets.all(10),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                YoutubePlayer(
                                  controller: YoutubePlayerController(
                                    initialVideoId: videoId,
                                    flags: const YoutubePlayerFlags(
                                      autoPlay: false,
                                      mute: false,
                                    ),
                                  ),
                                  showVideoProgressIndicator: true,
                                  progressIndicatorColor: Colors.redAccent,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 8.0, bottom: 8.0),
                                  child: Text(
                                    channel,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Show More Button (always visible if there is nextPageToken)
          if (nextPageToken != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () {
                        fetchVideos(loadMore: true);
                      },
                      child: const Text("Show More"),
                    ),
            ),
        ],
      ),
    );
  }
}
*/