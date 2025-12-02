
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
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'dart:async';




class AddVideoScreen extends StatefulWidget{
  const AddVideoScreen({super.key});

  @override
   State<AddVideoScreen> createState()=> _AddVideoState();

  
}

class _AddVideoState extends State<AddVideoScreen> {
// List existVideos=[];
// bool exist=false;

  String getBackendUrl() {
  if (kIsWeb) {
    // For web, use localhost or network IP
   // return "http://localhost:5000";
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



  List<dynamic> videos = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextPageToken; // for YouTube pagination
  String topic = ""; // user input topic
  Set<String> videoIds = {}; // avoid duplicate videos
    Set<String> addedVideoIds = {}; // track videos already added
    String? userId;
    Timer? fetchTimer;


  final TextEditingController _controller = TextEditingController();




@override
void initState() {
  super.initState();
  getUserId();
    // fetch continuously every 10 seconds
     fetchAddedVideos(); // fetch IDs of already added videos
  // optionally fetch videos immediately if you want:
   fetchVideos();
}

@override
void dispose() {
  fetchTimer?.cancel();
  super.dispose();
}


Future <void> getUserId() async{
  SharedPreferences prefs=await SharedPreferences.getInstance();
  String? token =prefs.getString("token");
  if(token==null)return;
  Map <String,dynamic>decodedToken= JwtDecoder.decode(token);
userId=decodedToken['id'];
}

Future<void> fetchAddedVideos() async {
  try {
    final response = await http.get(
      Uri.parse('${getBackendUrl()}/api/videos/getAllVideos'),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      Set<String> ids = {};
      for (var v in data) {
        if (v is Map && v.containsKey('url')) {
          final url = v['url'] as String?;
          if (url != null) {
            final videoId = YoutubePlayer.convertUrlToId(url);
            if (videoId != null && videoId.isNotEmpty) {
              ids.add(videoId);
            }
          }
        }
      }

      setState(() {
        addedVideoIds = ids;
      });

      print("✅ Added video IDs from all users: $addedVideoIds");
    } else {
      print("❌ Failed to fetch added videos: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error fetching added videos: $e");
  }
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



Future<void> showAddVideoByUrlDialog() async {
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
          title: const Text("Add Video by URL"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: "Video URL (YouTube/Drive)"),
                  onChanged: (value) async {
                    // Auto-generate thumbnail for YouTube
                    if (value.contains("youtube.com") || value.contains("youtu.be")) {
                      String? videoId = YoutubePlayer.convertUrlToId(value);
                      if (videoId != null) {
                        setState(() {
                          thumbnailUrl = "https://img.youtube.com/vi/$videoId/0.jpg";
                        });
                        // Auto-fill title (optional, using your fetchVideos API)
                        titleController.text = "YouTube Video"; // placeholder
                      }
                    }
                    // TODO: Add Drive thumbnail if needed (use Google Drive API)
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: category,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (value) {
                    if (value != null) category = value;
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                const SizedBox(height: 8),


DropdownButtonFormField<String>(
  value: ageGroup,
  items: const [
    DropdownMenuItem(value: "5-8", child: Text("5-8")),
    DropdownMenuItem(value: "9-12", child: Text("9-12")),
  ],
  onChanged: (value) {
              ///    final url = value == null ? "" : value.trim(); // <-- safe check
                // if (url.isEmpty) return;
    if (value != null) {
      setState(() {
        ageGroup = value;   // <-- This is the correct behavior
      });
    }
  },
  decoration: const InputDecoration(labelText: "Age Group"),
),
                  // Auto-generate thumbnail for YouTube
       TextField(
  controller: urlController,
  decoration: const InputDecoration(labelText: "Video URL"),
  onChanged: (url) {
    if (url.contains("youtube.com") || url.contains("youtu.be")) {
      String? videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        setState(() {
          thumbnailUrl = "https://img.youtube.com/vi/$videoId/0.jpg";
          titleController.text = "YouTube Video"; // optional
        });
      }
    } else if (url.contains("drive.google.com")) {
      setState(() {
        thumbnailUrl =
            "https://img.icons8.com/?size=100&id=106753&format=png&color=000000";
        titleController.text = "Drive Video";
      });
    } else {
      setState(() {
        thumbnailUrl = null; // generic placeholder
      });
    }
  },
),








                const SizedBox(height: 8),
                if (thumbnailUrl != null)
                  Image.network(thumbnailUrl!, height: 120, fit: BoxFit.cover),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final videoData = {
                  "title": titleController.text,
                  "description": descriptionController.text,
                  "category": category,
                  "url": urlController.text,
                  "thumbnailUrl": thumbnailUrl ?? "", // fallback empty
                  "ageGroup": ageGroup,
                  "isPuplished": false,
                  "createdBy": userId
                };

                try {
                  final response = await http.post(
                    Uri.parse('${getBackendUrl()}/api/videos/addVideo'),
                    headers: {"Content-Type": "application/json"},
                    body: jsonEncode(videoData),
                  );

                  if (response.statusCode == 201) {

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Video added successfully")),
                    );
                 Navigator.of(context).pop();

                  } else {
                    final resp = jsonDecode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add video: ${resp['message'] ?? 'Unknown'}")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Exception adding video: $e")),
                  );
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

Future<void> addVideoToDatabase(
  dynamic video,
  String title,
  String description,
  String category,
  String ageGroup,
) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  if (token == null) {
    print("❌ No token found");
    return;
  }

  final videoData = {
    "title": title,
    "description": description,
    "category": category,
    "url": "https://www.youtube.com/watch?v=${video['id']['videoId']}",
    "thumbnailUrl": video['snippet']['thumbnails']['default']['url'],
    "ageGroup": ageGroup,
    "isPublished": false,
    "createdBy":userId
  };

  try {
    final response = await http.post(
      Uri.parse('${getBackendUrl()}/api/videos/addVideo'),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(videoData),
    );

    if (response.statusCode == 201) {
      print("✅ Video added successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video added successfully")),
      );
    } else {
      final resp = jsonDecode(response.body);
      print("❌ Failed to add video: ${resp['message'] ?? response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Failed to add video: ${resp['message'] ?? 'Unknown error'}"),
        ),
      );
    }
  } catch (e) {
    print("❌ Exception adding video: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Exception adding video: $e")),
    );
  }
}




void showAddVideoDialog(dynamic video) {
  final TextEditingController titleController =
      TextEditingController(text: video['snippet']['title']);
  final TextEditingController descriptionController =
      TextEditingController(text: video['snippet']['description'] ?? "");
  //final TextEditingController categoryController = TextEditingController();
  String category = "English"; // default value
final List<String> categories = [
"English",
 "Arabic",
 "Math",
 "Science",
"Animation",
"Art",
"Music",
"Coding/Technology"
];
  String ageGroup = "5-8"; // default value

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Add Video"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 8),
           DropdownButtonFormField<String>(
             value: category,
               items: categories
           .map((c) => DropdownMenuItem(
            value: c,
            child: Text(c),
          ))
                .toList(),
             onChanged: (value) {
    if (value != null) category = value;
              },
      decoration: const InputDecoration(
    labelText: "Category",
        ),
       ),

              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: ageGroup,
                items: const [
                  DropdownMenuItem(value: "5-8", child: Text("5-8")),
                  DropdownMenuItem(value: "9-12", child: Text("9-12")),
                ],
                onChanged: (value) {
                  if (value != null) ageGroup = value;
                },
                decoration: const InputDecoration(labelText: "Age Group"),
              ),
              const SizedBox(height: 8),
              Text("URL: https://www.youtube.com/watch?v=${video['id']['videoId']}"),
              const SizedBox(height: 8),
              Image.network(video['snippet']['thumbnails']['default']['url']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
  onPressed: () async {
    Navigator.of(context).pop(); // close dialog
    await addVideoToDatabase(video,
        titleController.text,
        descriptionController.text,
        category,
        ageGroup);
    await fetchAddedVideos(); // refresh added video IDs
    setState(() {}); // trigger rebuild to show "Added" badge
  },
  child: const Text("Save"),
)

        ],
      );
    },
  );
}



@override
Widget build(BuildContext context) {
  return HomePage(
    title: "Add Video",
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          // ---------------- SCROLLABLE CONTENT ---------------- //
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ---------------- SEARCH BAR ---------------- //
                      Row(
                        children: [
                          Expanded(
                                            flex:3,

                            child: TextField(
                              
                              controller: _controller,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(vertical: 0.1),

                                labelText: "Enter topic to fetch videos",
                                border: OutlineInputBorder(),
                              ),
                              onSubmitted: (value) {
                                topic = value;
                                fetchVideos();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                        
                          child:  SizedBox(
                              height:50,

        child: 
        ElevatedButton(
  onPressed: () {
    topic = _controller.text;
    fetchVideos();
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.bgBlushRoseVeryDark,
    foregroundColor: Colors.white,
    //padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),

  ),
  child: const Text("Search", style:TextStyle(fontSize:16.5)),
),
                          )
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ---------------- VIDEO LIST ---------------- //
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (videos.isEmpty)
                        const Center(child: Text('No videos found.'))
                      else
                        Column(
                          children: List.generate(videos.length, (index) {
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
                                  // ---------- VIDEO PLAYER ---------- //
                                  Stack(
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
                                      if (addedVideoIds.contains(videoId))
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            width: 70,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.8),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              "Added",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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
                                    padding:
                                        const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                    child: Text(
                                      channel,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton.icon(
                                      onPressed: () => showAddVideoDialog(video),
                                      icon: const Icon(Icons.add),
                                      label: const Text("Add"),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),

                      const SizedBox(height: 80), // space for floating button
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            bottom: 25,
            right: 1,
            child: ElevatedButton.icon(
              onPressed: showAddVideoByUrlDialog,
              icon: const Icon(Icons.cloud_upload_outlined, size: 24),
              label: const Text(
                "Upload Video by URL",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bgBlushRoseVeryDark,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 8,
                shadowColor: AppColors.bgBlushRoseDark,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}