
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


class AddVideosScreen extends StatefulWidget {
  const AddVideosScreen({super.key});

  @override
  State<AddVideosScreen> createState() => _SupervisorVideosState();
}

class _SupervisorVideosState extends State<AddVideosScreen> {
  List<dynamic> videos = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextPageToken; // for YouTube pagination
  String topic = ""; // user input topic
  Set<String> videoIds = {}; // avoid duplicate videos
    Set<String> addedVideoIds = {}; // track videos already added
    String? userId;

  final TextEditingController _controller = TextEditingController();

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.122:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }


@override
void initState() {
  super.initState();

  // Fetch added videos first, then fetch YouTube videos
  fetchAddedVideos().then((_) {
    fetchVideos();
  });
}

   
     Future<void> fetchAddedVideos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) return;
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    setState((){
      userId= decodedToken['id'];
      print ("userId fro addvideo : $userId");
    });
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/videos/allvideo'),
        headers: {
          "Content-Type": "application/json",
        },
      );
      print(addedVideoIds);

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
    "isPuplished": false,
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
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              // send data to backend
              addVideoToDatabase(video,
                  titleController.text,
                  descriptionController.text,
                  category,
                  ageGroup);
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return HomePage(
       title: " Adding Videos ",
      child:Column(
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
      // YoutubePlayer(
      //   controller: YoutubePlayerController(
      //     initialVideoId: videoId,
      //     flags: const YoutubePlayerFlags(
      //       autoPlay: false,
      //       mute: false,
      //     ),
      //   ),
      //   showVideoProgressIndicator: true,
      //   progressIndicatorColor: Colors.redAccent,
      // ),

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

    // "Already Added" badge
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
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
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
        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
        child: Text(
          channel,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
      // Add button
Padding(
  padding: const EdgeInsets.all(8.0),
  child: ElevatedButton.icon(
    onPressed: () {
      showAddVideoDialog(video); // open popup dialog
    },
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

          // Show More Button (always visible if there is nextPageToken)
         if (nextPageToken != null)
       // Always show the button even if nextPageToken is null (first time)
         Padding(
          padding: const EdgeInsets.all(8.0),
            child: isLoadingMore
           ? const CircularProgressIndicator()
      : ElevatedButton(
          onPressed: () {
            fetchVideos(loadMore: true); // fetch more videos
          },
          child: const Text("Show More"),
        ),
            ),

        ],
      ),
    );
  }
}
