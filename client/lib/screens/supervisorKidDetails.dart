

import 'package:bright_minds/screens/supervisorKids.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class KidDetails extends StatefulWidget {
  final Map<String, dynamic> kid;

  const KidDetails({super.key, required this.kid});

  @override
  State<KidDetails> createState() => _KidDetailsState();
}

class _KidDetailsState extends State<KidDetails> {
  String parentName = "Loading...";
  List kidHistory =  [];
   Map<String, List> videoHistoryByKid = {};


  @override
  void initState() {
    super.initState();
    fetchParentName();
     getKidHistory(widget.kid['_id']);

  }

  String getBackendUrl() {
    if (kIsWeb) {
    return "http://192.168.1.63:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else if (Platform.isIOS) {
      return "http://localhost:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  Future<void> fetchParentName() async {
    final parentId = widget.kid["parentId"];
    if (parentId == null) {
      setState(() {
        parentName = "N/A";
      });
      return;
    }

    try {
      final response =
          await http.get(Uri.parse('${getBackendUrl()}/api/users/getme/$parentId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          parentName = data["name"] ?? "N/A";
        });
      } else {
        setState(() {
          parentName = "N/A";
        });
      }
    } catch (e) {
      setState(() {
        parentName = "N/A";
      });
      print("Error fetching parent name: $e");
    }
  }

  int calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 0;
    DateTime dob = DateTime.parse(dobString);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> getKidHistory(String kidId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List history = jsonDecode(response.body);
        videoHistoryByKid[kidId] = history;
        setState(() {});
      }
    } catch (err) {
      print("❌ Error fetching history: $err");
    }
  }

  @override
  Widget build(BuildContext context) {
    final age = calculateAge(widget.kid["age"]);
       kidHistory = videoHistoryByKid[widget.kid['_id']] ?? [];
    final profilePictureBytes = widget.kid["profilePicture"]?["data"]?["data"];
    final profilePicture = (profilePictureBytes != null && profilePictureBytes is List)
        ? ClipOval(
            child: Image.memory(
              Uint8List.fromList(List<int>.from(profilePictureBytes)),
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          )
        : CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.bgBlushRoseDark,
            child: Text(
              widget.kid["name"][0].toUpperCase(),
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          );

     return HomePage(
      title: 'Kid Details',
      child: SingleChildScrollView(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Background card for data
            Container(
              margin: const EdgeInsets.only(top: 80),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 70), // Space for profile picture
                  Text(
                    widget.kid["name"] ?? "N/A",
                    style: GoogleFonts.robotoSlab(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Age: $age | Age Group: ${widget.kid["ageGroup"] ?? "N/A"}",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Email: ${widget.kid["email"] ?? "N/A"}",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
             
                  Text(
                    "Parent: $parentName",
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 10),
          
               widget.kid["videoHistory"] != null &&
        widget.kid["videoHistory"].isNotEmpty
    ? Column(
        children: List.generate(widget.kid["videoHistory"].length, (index) {
          final video = widget.kid["videoHistory"][index];
          final watchedAt = video["watchedAt"] != null
              ? DateFormat('yyyy-MM-dd')
                  .format(DateTime.parse(video["watchedAt"]))
              : "N/A";
          final duration = video["duration"] ?? 0;
          return ListTile(
            leading: const Icon(Icons.play_circle_fill,
                color: AppColors.bgBlushRoseDark),
            title: Text("Video ID: ${video["video"] ?? "N/A"}"),
            subtitle:
                Text("Watched at: $watchedAt, Duration: $duration mins"),
          );
        }),
      )
    : Container(), // <-- ADD THIS

const SizedBox(height: 10),





                    
 
                
ExpansionTile(
 //title: const Text("Video History"), // REQUIRED!
  title: const Text(
    "Videos History",
    style: TextStyle(
      fontSize: 22, // bigger font
      fontWeight: FontWeight.bold, // bold
      color: Colors.black, // optional: text color
    ),
  ),
  children: [
    SizedBox(
      height: 150, // Set height for the horizontal list
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: kidHistory.map((historyItem) {
            final video = historyItem['videoId'];
            return Container(
              width: 120, // Width of each video card
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  (video != null && video['thumbnailUrl'] != null)
                      ? Image.network(
                          video['thumbnailUrl'],
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.video_library, size: 80),
                  const SizedBox(height: 5),
                  // Title
                  Text(
                    video?['title'] ?? "Unknown",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Watched duration
                  Text(
                    "${(historyItem['durationWatched'] ?? 0).toStringAsFixed(2)} min",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  // Watched date
                  Text(
                    historyItem['watchedAt'] != null
                        ? DateFormat('yyyy-MM-dd').format(
                            DateTime.parse(historyItem['watchedAt']).toLocal())
                        : "Unknown",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    ),
  ],
),








              

                      //: const Text("No video history available."),
                ],
              ),
            ),
            // Profile picture positioned on top
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(child: profilePicture),
            ),
          ],
        ),
      ),
    );
  }
}






  
 
              