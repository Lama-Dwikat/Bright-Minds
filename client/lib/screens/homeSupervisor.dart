


import 'package:bright_minds/screens/supervisorKids.dart';
import 'package:bright_minds/screens/addVideo.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:intl/intl.dart';
import 'package:bright_minds/screens/videosSupervisor.dart';
import 'package:bright_minds/screens/gameSupervisor.dart';

import 'package:bright_minds/screens/supervisorStories.dart';


import 'package:bright_minds/screens/analytics.dart';


class HomeSupervisor extends StatefulWidget {
  const HomeSupervisor({super.key});

  @override
  _HomeSupervisorState createState() => _HomeSupervisorState();
}

class _HomeSupervisorState extends State<HomeSupervisor> {
  final List<Map<String, dynamic>> weekdays = [
    {"day": "Mon", "key": 1},
    {"day": "Tue", "key": 2},
    {"day": "Wed", "key": 3},
    {"day": "Thu", "key": 4},
    {"day": "Fri", "key": 5},
    {"day": "Sat", "key": 6},
    {"day": "Sun", "key": 7},
  ];

  String? token;
  String? userId;
  String? userName;
  String? profilePictureBase64 = "";
  List tasks = [];
  bool done=false;

String getBackendUrl() {
  if (kIsWeb) {
    return "http://192.168.1.63:3000";

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


  @override
  void initState() {
    super.initState();
    fetchSupervisor();
  }

  void fetchSupervisor() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    token = pref.getString('token');
    if (token == null) {
      print("no token found");
      return;
    }

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token!);
    //print("DECODED TOKEN = $decodedToken");

    setState(() {
      userId = decodedToken['id'];
      userName = decodedToken['name'];
      profilePictureBase64 = decodedToken['profilePicture'];
    });

    fetchTasks(); // Fetch tasks after setting userId
  }

  void fetchTasks() async {
    if (userId == null) return;
    var response = await http.get(
      Uri.parse('${getBackendUrl()}/api/tasks/getTodayTasks/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        tasks = data is List ? data : [];
       // print("tasks= $tasks");
      });
    } else {
      print('Failed to load tasks: ${response.statusCode}');
    }
  }


void updateTaskStatus(String taskId, bool isDone) async {
  try {
              print("task id is : $taskId}");

    final url = Uri.parse("${getBackendUrl()}/api/tasks/updateTask/$taskId");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"
       ,"Authorization": "Bearer $token",},
      body: jsonEncode({"done": isDone}),
    );

    if (response.statusCode == 200) {
      fetchTasks(); // Refresh UI
    } else {
      print("Failed to update task");
    }
  } catch (e) {
    print("Error updating task: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final formattedDate = DateFormat("d MMM yyyy").format(today);

    return HomePage(
      child: SingleChildScrollView(
      //  padding: const EdgeInsets.all(20),
      padding: const EdgeInsets.only(left: 10, right: 10, bottom: 20),

      //  child: Center(
          child: Column(
            children: [
SizedBox(
  height: 400,
  child: LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final imageWidth = 100.0;

      return Stack(
        children: [


          // ------------------- TASK LIST -------------------
          Positioned(
            left: imageWidth-55 , // space for image
            right: 0,              // take all remaining screen width
            top: 60,
            bottom: 0,
            
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DATE HEADER
                  Container(
                    height: 50,
                   // padding: const EdgeInsets.all(10),
                   padding: const EdgeInsets.only(left: 5, right: 10, bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bgWarmPink,
                    border: const Border(
                  top: BorderSide(color: AppColors.bgSoftPinkVeryDark, width: 2),
                   left: BorderSide(color: AppColors.bgSoftPinkVeryDark, width: 2),
                   right: BorderSide(color: AppColors.bgSoftPinkVeryDark, width: 2),
                  bottom: BorderSide(color: Colors.transparent, width: 0), // NO BOTTOM BORDER
                    ),     
                                   ),
                    child: Text(
                      formattedDate,
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                
// 🔥 MAIN BORDER BOX
Container(
 padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: AppColors.bgWarmPink,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.bgSoftPinkVeryDark, width: 1),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // WEEKDAYS
      Container(
  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
  decoration: BoxDecoration(
    color: Colors.white, // <-- YOUR BACKGROUND COLOR HERE

   // borderRadius: BorderRadius.circular(12),
  ),
     child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: weekdays.map((entry) {
            final day = entry['day']!;
            final dayNum = entry['key']!;
            final isToday = today.weekday == dayNum;
            return Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.bgSoftPinkVeryDark
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                day,
                style: GoogleFonts.robotoSlab(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isToday ? Colors.white : Colors.black,
                ),
              ),
            );
          }).toList(),
        ),
      ),
      ),
      const SizedBox(height: 12),

      // Today's Tasks Header
      Text(
        "Today's Tasks",
        style: GoogleFonts.robotoSlab(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      // SCROLLABLE TASK LIST
      SizedBox(
        height: 160,
        child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: tasks[index]['done'] == true,
                    onChanged: (_) {
                      setState(() {
                        tasks[index]['done'] = !tasks[index]['done'];
                      });
                      updateTaskStatus(task['_id'], tasks[index]['done']);
                    },
                  ),
                  Expanded(
                    child: Text(
                      task['description'] ?? '',
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        decoration: tasks[index]['done'] == true
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
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

                  const SizedBox(height: 12),

                  // Today's Tasks Header
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Today's Tasks",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // SCROLLABLE TASK LIST
                  Container(
                    height: 160,
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: tasks[index]['done'] == true,
                                onChanged: (_) {
                                  setState(() {
                                    tasks[index]['done'] =
                                        !tasks[index]['done'];
                                  });
                                  updateTaskStatus(
                                      task['_id'], tasks[index]['done']);
                                },
                              ),
                              Expanded(
                                child: Text(
                                  task['description'] ?? '',
                                  style: GoogleFonts.robotoSlab(
                                    fontSize: 16,
                                    decoration: tasks[index]['done'] == true
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
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
          ),

          // ------------------- IMAGE -------------------
          Positioned(
            left: -7,
            top: -12,
            child: Image.asset(
              "assets/images/tasks3.png",
              width: imageWidth,
              height: 150,
            ),
          ),
        ],
      );
    },
  ),
),



              
              const SizedBox(height: 16),
           _buildFullWidthButton(
             label: "Kids",
           imagePath: "assets/images/kids.png", // <-- your kids image
              color: AppColors.peachPinkLight,
              onPressed: () {
               Navigator.push(
             context,
                MaterialPageRoute(builder: (context) => SupervisorKidsScreen()),
             );
          },
               ),


             const SizedBox(height: 16),
            

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              children: [
                _mainButton(
                  label: "Stories",
                  //icon: Icons.menu_book_rounded,
                  imagePath: "assets/images/story2.png",
                  color: AppColors.bgBlushRose,
                    onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupervisorStoriesScreen(),
      ),
    );
  },
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => supervo()));},

                ),
                _mainButton(
                  label: "Videos",
                 // icon: Icons.ondemand_video_rounded,
                 imagePath: "assets/images/video.png",
                  color: AppColors.bgBlushRoseLight,
                   onTap: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorVideosPage()));},

                ),
                _mainButton(
                  label: "Games",
                 // icon: Icons.videogame_asset_rounded,
                 imagePath: "assets/images/Games.png",
                  color: AppColors.bgWarmPinkLight,
                 onTap: () { 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => GamesHomePage()));},
  
                ),
                _mainButton(
                  label: "Drawing",
                 // icon: Icons.brush_rounded,
                 imagePath: "assets/images/Drawing.png",
                  color: AppColors.bgWarmPink,
                  onTap: () { 
                   Navigator.push(context, MaterialPageRoute(builder: (context) => AnalyticsScreen()));},

                ),
                
              ],
            ),

            const SizedBox(height: 36),
            ],
          ),
       // ),
      ),
    );
  }

Widget _mainButton({
  required String label,
  IconData? icon,        
  String? imagePath,      
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath,
              height: 60,
              width: 60,
              fit: BoxFit.contain,
            )
          else if (icon != null)
            Icon(icon, size: 40, color: Colors.indigo[900]),

          const SizedBox(height: 10),

          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              //color: const Color.fromARGB(255, 255, 251, 251),
               color: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}



  Widget _buildFullWidthButton({
  required String label,
  required String imagePath,
  required Color color,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    //width: 2 * 200 + 16, // Two buttons width + spacing
    width:double.infinity,
    height: 80, // adjust height as needed
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // center horizontally
        crossAxisAlignment: CrossAxisAlignment.center, // center vertically
        children: [
          Image.asset(
            imagePath,
            width: 55, // same as icon
            height: 55, // same as icon
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12), // space between image and text
          Text(
            label,
            style: GoogleFonts.robotoSlab(
              fontSize: 25, // adjust font size
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ),
  );
}
}