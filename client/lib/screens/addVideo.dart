
// import 'package:flutter/material.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// import 'package:bright_minds/widgets/home.dart';
// import 'package:bright_minds/theme/colors.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'dart:typed_data';



// class AddVideoScreen extends StatefulWidget{
//   const AddVideoScreen({super.key});

//   @override
//    State<AddVideoScreen> createState()=> _AddVideoState();

  
// }

// class _AddVideoState extends State<AddVideoScreen> {
// // List existVideos=[];
// // bool exist=false;

//   String getBackendUrl() {
//   if (kIsWeb) {
//     // For web, use localhost or network IP
//    // return "http://localhost:5000";
//     return "http://localhost:3000";

//   } else if (Platform.isAndroid) {
//     // Android emulator
//     return "http://10.0.2.2:3000";
//   } else if (Platform.isIOS) {
//     // iOS emulator
//     return "http://localhost:3000";
//   } else {
//     // fallback
//     return "http://localhost:3000";
//   }
// }


// // // Future<bool> searchExistVideo(String url) async {
// // // var response = await http.get(Uri.parse('${getBackendUrl()}/api/videos/getAllVideos'),
// // // headers: {"Content-Type":"application/json"});
// // //        try{
// // //   if(response.statusCode==200){
// // //     var data =jsonDecode(response.body);
// // //     existVideos=data is List ? data : [];
// // //     if (existVideos.isNotEmpty){
// // //         return existVideos.any((video)=> video['url']==url);
// // //           }
// // //           else return false;
     
// // //   }   else return false;
// // //        }catch(error){
// // //         print("error checking video : $error");
// // //         return false;
// // //        }


// // // }

// //}
//   List<dynamic> videos = [];
//   bool isLoading = false;
//   bool isLoadingMore = false;
//   String? nextPageToken; // for YouTube pagination
//   String topic = ""; // user input topic
//   Set<String> videoIds = {}; // avoid duplicate videos
//     Set<String> addedVideoIds = {}; // track videos already added
//     String? userId;

//   final TextEditingController _controller = TextEditingController();




// @override
// void initState() {
//   super.initState();

//   // Fetch added videos first, then fetch YouTube videos
//   fetchAddedVideos().then((_) {
//     fetchVideos();
//   });
// }

   
//      Future<void> fetchAddedVideos() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token');
//     if (token == null) return;
//     Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
//     setState((){
//       userId= decodedToken['id'];
//       print ("userId fro addvideo : $userId");
//     });
//     try {
//       final response = await http.get(
//         Uri.parse('${getBackendUrl()}/api/videos/allvideo'),
//         headers: {
//           "Content-Type": "application/json",
//         },
//       );
//       print(addedVideoIds);

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         setState(() {
//           addedVideoIds = data
//               .map<String>((v) => v['url'].toString().split('v=')[1])
//               .toSet();
//         });
//       }
//      } catch (e) {
//       print("❌ Error fetching added videos: $e");
//      }
//      }




//   Future<void> fetchVideos({bool loadMore = false}) async {
//     if (topic.trim().isEmpty) return;

//     if (!loadMore) {
//       setState(() {
//         isLoading = true;
//         videos.clear();
//         videoIds.clear();
//         nextPageToken = null; // reset pagination for new topic
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
//         "Content-Type": "application/json",
//       });

//       print("✅ Response status: ${response.statusCode}");
//       print("✅ Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         if (data['items'] != null && data['items'] is List) {
//           final newVideos = data['items']
//               .where((v) => !videoIds.contains(v['id']['videoId']))
//               .toList();

//           setState(() {
//             videos.addAll(newVideos);
//             videoIds.addAll(newVideos.map((v) => v['id']['videoId']));
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

// Future<void> showAddVideoByUrlDialog() async {
//   final TextEditingController urlController = TextEditingController();
//   final TextEditingController titleController = TextEditingController();
//   final TextEditingController descriptionController = TextEditingController();
//   String category = "English";
//   String ageGroup = "5-8";
//   final List<String> categories = [
//     "English", "Arabic", "Math", "Science", "Animation", "Art", "Music", "Coding/Technology"
//   ];

//   String? thumbnailUrl;

//   showDialog(
//     context: context,
//     builder: (context) {
//       return StatefulBuilder(builder: (context, setState) {
//         return AlertDialog(
//           title: const Text("Add Video by URL"),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: urlController,
//                   decoration: const InputDecoration(labelText: "Video URL (YouTube/Drive)"),
//                   onChanged: (value) async {
//                     // Auto-generate thumbnail for YouTube
//                     if (value.contains("youtube.com") || value.contains("youtu.be")) {
//                       String? videoId = YoutubePlayer.convertUrlToId(value);
//                       if (videoId != null) {
//                         setState(() {
//                           thumbnailUrl = "https://img.youtube.com/vi/$videoId/0.jpg";
//                         });
//                         // Auto-fill title (optional, using your fetchVideos API)
//                         titleController.text = "YouTube Video"; // placeholder
//                       }
//                     }
//                     // TODO: Add Drive thumbnail if needed (use Google Drive API)
//                   },
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(labelText: "Title"),
//                 ),
//                 const SizedBox(height: 8),
//                 TextField(
//                   controller: descriptionController,
//                   decoration: const InputDecoration(labelText: "Description"),
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   value: category,
//                   items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//                   onChanged: (value) {
//                     if (value != null) category = value;
//                   },
//                   decoration: const InputDecoration(labelText: "Category"),
//                 ),
//                 const SizedBox(height: 8),
//                 DropdownButtonFormField<String>(
//                   value: ageGroup,
//                   items: const [
//                     DropdownMenuItem(value: "5-8", child: Text("5-8")),
//                     DropdownMenuItem(value: "9-12", child: Text("9-12")),
//                   ],
               
//                   onChanged: (value) async {
//               final url = value == null ? "" : value.trim(); // <-- safe check
//                  if (url.isEmpty) return;

//                // Auto-generate thumbnail for YouTube
//           if (url.contains("youtube.com") || url.contains("youtu.be")) {
//              String? videoId = YoutubePlayer.convertUrlToId(url);
//            if (videoId != null) {
//                 setState(() {
//                thumbnailUrl = "https://img.youtube.com/vi/$videoId/0.jpg";
//                  });
//             titleController.text = "YouTube Video";
//              }
//                   } 
//   // // Default thumbnail for Google Drive

//   else if (url.contains("drive.google.com")) {
//   setState(() {
//     thumbnailUrl = "https://img.icons8.com/?size=100&id=106753&format=png&color=000000"; // default thumbnail
//   });
//   titleController.text = "Drive Video";
// }

//   // else if (url.contains("drive.google.com")) {
//   //   setState(() {
//   //     thumbnailUrl =
//   //         "https://i.ibb.co/9qBf1n0/default-video-thumbnail.png"; // default thumbnail
//   //   });
//   //   titleController.text = "Drive Video";
//   // } 
//   // Fallback for other links
//   else {
//     setState(() {
//     //   thumbnailUrl =
//     //       "https://i.ibb.co/9qBf1n0/default-video-thumbnail.png";

//     if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
//   Image.network(thumbnailUrl!, height: 120, fit: BoxFit.cover);
//         else
//   Container(
//     height: 120,
//     width: double.infinity,
//     color: Colors.black,
//     child: const Center(
//       child: Icon(Icons.videocam, color: Colors.black, size: 40),
//     ),
//   );
//      });
//   }
// },

//                   decoration: const InputDecoration(labelText: "Age Group"),
//                 ),
//                 const SizedBox(height: 8),
//                 if (thumbnailUrl != null)
//                   Image.network(thumbnailUrl!, height: 120, fit: BoxFit.cover),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();

//                 final videoData = {
//                   "title": titleController.text,
//                   "description": descriptionController.text,
//                   "category": category,
//                   "url": urlController.text,
//                   "thumbnailUrl": thumbnailUrl ?? "", // fallback empty
//                   "ageGroup": ageGroup,
//                   "isPuplished": false,
//                   "createdBy": userId
//                 };

//                 try {
//                   final response = await http.post(
//                     Uri.parse('${getBackendUrl()}/api/videos/addVideo'),
//                     headers: {"Content-Type": "application/json"},
//                     body: jsonEncode(videoData),
//                   );

//                   if (response.statusCode == 201) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Video added successfully")),
//                     );
//                   } else {
//                     final resp = jsonDecode(response.body);
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(content: Text("Failed to add video: ${resp['message'] ?? 'Unknown'}")),
//                     );
//                   }
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Exception adding video: $e")),
//                   );
//                 }
//               },
//               child: const Text("Save"),
//             ),
//           ],
//         );
//       });
//     },
//   );
// }

// Future<void> addVideoToDatabase(
//   dynamic video,
//   String title,
//   String description,
//   String category,
//   String ageGroup,
// ) async {
//   SharedPreferences prefs = await SharedPreferences.getInstance();
//   String? token = prefs.getString('token');
//   if (token == null) {
//     print("❌ No token found");
//     return;
//   }

//   final videoData = {
//     "title": title,
//     "description": description,
//     "category": category,
//     "url": "https://www.youtube.com/watch?v=${video['id']['videoId']}",
//     "thumbnailUrl": video['snippet']['thumbnails']['default']['url'],
//     "ageGroup": ageGroup,
//     "isPublished": false,
//     "createdBy":userId
//   };

//   try {
//     final response = await http.post(
//       Uri.parse('${getBackendUrl()}/api/videos/addVideo'),
//       headers: {
//         "Content-Type": "application/json",
//       },
//       body: jsonEncode(videoData),
//     );

//     if (response.statusCode == 201) {
//       print("✅ Video added successfully");
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Video added successfully")),
//       );
//     } else {
//       final resp = jsonDecode(response.body);
//       print("❌ Failed to add video: ${resp['message'] ?? response.body}");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content:
//               Text("Failed to add video: ${resp['message'] ?? 'Unknown error'}"),
//         ),
//       );
//     }
//   } catch (e) {
//     print("❌ Exception adding video: $e");
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Exception adding video: $e")),
//     );
//   }
// }




// void showAddVideoDialog(dynamic video) {
//   final TextEditingController titleController =
//       TextEditingController(text: video['snippet']['title']);
//   final TextEditingController descriptionController =
//       TextEditingController(text: video['snippet']['description'] ?? "");
//   //final TextEditingController categoryController = TextEditingController();
//   String category = "English"; // default value
// final List<String> categories = [
// "English",
//  "Arabic",
//  "Math",
//  "Science",
// "Animation",
// "Art",
// "Music",
// "Coding/Technology"
// ];
//   String ageGroup = "5-8"; // default value

//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: const Text("Add Video"),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: const InputDecoration(labelText: "Title"),
//               ),
//               const SizedBox(height: 8),
//               TextField(
//                 controller: descriptionController,
//                 decoration: const InputDecoration(labelText: "Description"),
//               ),
//               const SizedBox(height: 8),
//            DropdownButtonFormField<String>(
//              value: category,
//                items: categories
//            .map((c) => DropdownMenuItem(
//             value: c,
//             child: Text(c),
//           ))
//                 .toList(),
//              onChanged: (value) {
//     if (value != null) category = value;
//               },
//       decoration: const InputDecoration(
//     labelText: "Category",
//         ),
//        ),

//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: ageGroup,
//                 items: const [
//                   DropdownMenuItem(value: "5-8", child: Text("5-8")),
//                   DropdownMenuItem(value: "9-12", child: Text("9-12")),
//                 ],
//                 onChanged: (value) {
//                   if (value != null) ageGroup = value;
//                 },
//                 decoration: const InputDecoration(labelText: "Age Group"),
//               ),
//               const SizedBox(height: 8),
//               Text("URL: https://www.youtube.com/watch?v=${video['id']['videoId']}"),
//               const SizedBox(height: 8),
//               Image.network(video['snippet']['thumbnails']['default']['url']),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // close dialog
//             },
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop(); // close dialog
//               // send data to backend
//               addVideoToDatabase(video,
//                   titleController.text,
//                   descriptionController.text,
//                   category,
//                   ageGroup);
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       );
//     },
//   );
// }


// @override
// Widget build(BuildContext context) {
//   return HomePage(
//     title: "Add Video",
//     child: Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [

//           // -------------------- FIXED SCROLL AREA -------------------- //
//           Expanded(
//             child: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [

//                   // ---------- TOP INTRO ---------- //
//                   Text(
//                     "Upload By URL or Search by Topic",
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),

//                   SizedBox(height: 30),

//                   // ---------- UPLOAD URL BUTTON ---------- //
//                   Container(
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: Colors.deepPurple.shade50,
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                     child: TextButton.icon(
//                       onPressed: showAddVideoByUrlDialog,
//                       icon: Icon(Icons.link, color: Colors.deepPurple),
//                       label: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         child: Text(
//                           "Upload Video by URL",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.deepPurple,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   SizedBox(height: 25),

//                   // ---------- DIVIDER ---------- //
//                   Row(
//                     children: [
//                       Expanded(child: Divider()),
//                       Padding(
//                         padding: EdgeInsets.symmetric(horizontal: 10),
//                         child: Text(
//                           "OR",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey.shade500,
//                           ),
//                         ),
//                       ),
//                       Expanded(child: Divider()),
//                     ],
//                   ),

//                   SizedBox(height: 25),

//                   // ---------- SEARCH BOX (FIXED ROW) ---------- //
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextField(
//                           controller: _controller,
//                           decoration: const InputDecoration(
//                             labelText: "Enter topic (Arabic or English)",
//                             border: OutlineInputBorder(),
//                           ),
//                           onSubmitted: (value) {
//                             topic = value;
//                             fetchVideos();
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       ElevatedButton(
//                         onPressed: () {
//                           topic = _controller.text;
//                           fetchVideos();
//                         },
//                         child: const Text("Search"),
//                       ),
//                     ],
//                   ),

//                   SizedBox(height: 20),

//                   // ---------- VIDEO RESULTS LIST ---------- //
//                   if (isLoading)
//                     const Center(child: CircularProgressIndicator())
//                   else if (videos.isEmpty)
//                     const Center(child: Text('No videos found.'))
//                   else
//                     Column(
//                       children: List.generate(videos.length, (index) {
//                         final video = videos[index];
//                         final videoId = video['id']['videoId'];
//                         final title = video['snippet']['title'];
//                         final channel = video['snippet']['channelTitle'];

//                         return Card(
//                           margin: const EdgeInsets.all(10),
//                           elevation: 5,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [

//                               // ---------- VIDEO PLAYER ---------- //
//                               Stack(
//                                 children: [
//                                   YoutubePlayer(
//                                     controller: YoutubePlayerController(
//                                       initialVideoId: videoId,
//                                       flags: const YoutubePlayerFlags(
//                                         autoPlay: false,
//                                         mute: false,
//                                       ),
//                                     ),
//                                     showVideoProgressIndicator: true,
//                                     progressIndicatorColor: Colors.redAccent,
//                                   ),

//                                   if (addedVideoIds.contains(videoId))
//                                     Positioned(
//                                       top: 8,
//                                       right: 8,
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 8, vertical: 4),
//                                         decoration: BoxDecoration(
//                                           color:
//                                               Colors.green.withOpacity(0.8),
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: const Text(
//                                           "Added",
//                                           style: TextStyle(
//                                             color: Colors.white,
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 12,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),

//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   title,
//                                   style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),

//                               Padding(
//                                 padding: const EdgeInsets.only(
//                                     left: 8.0, bottom: 8.0),
//                                 child: Text(
//                                   channel,
//                                   style: const TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ),

//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: ElevatedButton.icon(
//                                   onPressed: () =>
//                                       showAddVideoDialog(video),
//                                   icon: const Icon(Icons.add),
//                                   label: const Text("Add"),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         );
//                       }),
//                     ),

//                   SizedBox(height: 20),

//                   // ---------- SHOW MORE BUTTON ---------- //
//                   if (nextPageToken != null)
//                     isLoadingMore
//                         ? const CircularProgressIndicator()
//                         : ElevatedButton(
//                             onPressed: () => fetchVideos(loadMore: true),
//                             child: const Text("Show More"),
//                           ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }



import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/theme/colors.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoState();
}

class _AddVideoState extends State<AddVideoScreen> {
  List<dynamic> videos = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextPageToken;
  String topic = "";
  Set<String> videoIds = {};
  Set<String> addedVideoIds = {};
  String? userId;

  final TextEditingController _controller = TextEditingController();

  String getBackendUrl() {
    if (kIsWeb) return "http://localhost:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    fetchAddedVideos().then((_) => fetchVideos());
  }

  Future<void> fetchAddedVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    setState(() {
      userId = decodedToken['id'];
    });

    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/videos/allvideo'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          addedVideoIds = data
              .map<String>((v) => v['url'].toString().split('v=')[1])
              .toSet();
        });
      }
    } catch (e) {
      print("❌ Error fetching added videos: $e");
    }
  }

  Future<void> fetchVideos({bool loadMore = false}) async {
    if (topic.trim().isEmpty) return;

    setState(() {
      if (!loadMore) {
        isLoading = true;
        videos.clear();
        videoIds.clear();
        nextPageToken = null;
      } else {
        isLoadingMore = true;
      }
    });

    try {
      final uri = Uri.parse('${getBackendUrl()}/api/videos/fetchVideosFromAPI')
          .replace(queryParameters: {"topic": topic, if (nextPageToken != null) "pageToken": nextPageToken!});
      final response = await http.get(uri, headers: {"Content-Type": "application/json"});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
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
      } else {
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

  Future<void> showAddYouTubeDialog() async {
    final TextEditingController urlController = TextEditingController();
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String category = "English";
    String ageGroup = "5-8";
    final List<String> categories = [
      "English", "Arabic", "Math", "Science", "Animation", "Art", "Music", "Coding/Technology"
    ];
    String? thumbnailUrl;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Add YouTube Video"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(labelText: "YouTube Video URL"),
                    onChanged: (value) {
                      if (value.contains("youtube.com") || value.contains("youtu.be")) {
                        String? videoId = YoutubePlayer.convertUrlToId(value);
                        if (videoId != null) {
                          setState(() {
                            thumbnailUrl = "https://img.youtube.com/vi/$videoId/0.jpg";
                            titleController.text = "YouTube Video"; // optional auto-fill
                          });
                        }
                      } else {
                        setState(() {
                          thumbnailUrl = null;
                          titleController.text = "";
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
                  const SizedBox(height: 8),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: category,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => category = value ?? category,
                    decoration: const InputDecoration(labelText: "Category"),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: ageGroup,
                    items: const [
                      DropdownMenuItem(value: "5-8", child: Text("5-8")),
                      DropdownMenuItem(value: "9-12", child: Text("9-12")),
                    ],
                    onChanged: (value) => ageGroup = value ?? ageGroup,
                    decoration: const InputDecoration(labelText: "Age Group"),
                  ),
                  const SizedBox(height: 8),
                  if (thumbnailUrl != null)
                    Image.network(thumbnailUrl!, height: 120, fit: BoxFit.cover),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  final videoData = {
                    "title": titleController.text,
                    "description": descriptionController.text,
                    "category": category,
                    "url": urlController.text,
                    "thumbnailUrl": thumbnailUrl ?? "",
                    "ageGroup": ageGroup,
                    "isPublished": false,
                    "createdBy": userId
                  };
                  try {
                    final response = await http.post(
                      Uri.parse('${getBackendUrl()}/api/videos/addVideo'),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode(videoData),
                    );

                    if (response.statusCode == 201) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video added successfully")));
                    } else {
                      final resp = jsonDecode(response.body);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to add video: ${resp['message'] ?? 'Unknown'}")),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exception adding video: $e")));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Add Video",
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ---------- OPTION CARDS ---------- //
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: showAddYouTubeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.link, size: 36, color: Colors.deepPurple),
                          SizedBox(height: 8),
                          Text("Upload YouTube URL", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: Offset(0, 3))],
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.search, size: 36, color: Colors.green),
                          SizedBox(height: 8),
                          Text("Search by Topic", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ---------- SEARCH BOX ---------- //
            Row(
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

            const SizedBox(height: 20),

            // ---------- VIDEO LIST ---------- //
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      YoutubePlayer(
                                        controller: YoutubePlayerController(
                                          initialVideoId: videoId,
                                          flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
                                        ),
                                        showVideoProgressIndicator: true,
                                        progressIndicatorColor: Colors.redAccent,
                                      ),
                                      if (addedVideoIds.contains(videoId))
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "Added",
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                    child: Text(channel, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () => showAddYouTubeDialog(),
                                      icon: const Icon(Icons.add),
                                      label: const Text("Add"),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
