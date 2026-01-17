


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
import 'package:bright_minds/screens/supervisorstory/supervisorStories.dart';
import 'package:bright_minds/screens/supervisorDrawing/supervisorDrawingHome.dart';
import 'package:bright_minds/screens/gameSupervisor.dart';
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
void _showAddTaskDialog() {
  final TextEditingController taskController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Add New Task"),
        content: TextField(
          controller: taskController,
          decoration: const InputDecoration(
            hintText: "Enter task description",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (taskController.text.trim().isNotEmpty) {
                addTask(taskController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      );
    },
  );
}
Future<void> addTask(String description) async {
  try {
    final response = await http.post(
      Uri.parse("${getBackendUrl()}/api/tasks/addTask"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "description": description,
        "supervisorId": userId,
        "done": false,
      }),
    );

    if (response.statusCode == 201) {
      fetchTasks(); // refresh list
    } else {
      print("Failed to add task: ${response.body}");
    }
  } catch (e) {
    print("Error adding task: $e");
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
                      color: AppColors.badgesButton,
                    border: const Border(
                  top: BorderSide(color: Color.fromARGB(255, 243, 182, 59), width: 2),
                   left: BorderSide(color: Color.fromARGB(255, 222, 174, 77), width: 2),
                   right: BorderSide(color: Color.fromARGB(255, 232, 175, 62), width: 2),
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
    color: const Color.fromARGB(255, 248, 217, 154),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: const Color.fromARGB(255, 213, 160, 55), width: 1),
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
                    ? const Color.fromARGB(255, 199, 153, 61)
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
    //  const SizedBox(height: 12),

      // Today's Tasks Header
   Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Today's Tasks",
      style: GoogleFonts.robotoSlab(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    IconButton(
      icon: const Icon(Icons.add_circle, color: Color(0xFF6E4A4A), size: 28),
      onPressed: () {
        _showAddTaskDialog();
      },
    ),
  ],
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



              
          //     const SizedBox(height: 16),
          //  _buildFullWidthButton(
          //    label: "Kids",
          //  imagePath: "assets/images/kids.png", // <-- your kids image
          //     color: AppColors.peachPinkLight,
          //     onPressed: () {
          //      Navigator.push(
          //    context,
          //       MaterialPageRoute(builder: (context) => SupervisorKidsScreen()),
          //    );
          // },
          //      ),


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
                    color: const Color(0xFFFFD9C0),
                    onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupervisorStoriesScreen(),
      // builder: (context) => SupervisorStoryScreen(),
      ),
    );
  },
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => supervo()));},

                ),
                _mainButton(
                  label: "Videos",
                 imagePath: "assets/images/video.png",
                  color: const Color.fromARGB(255, 254, 220, 168),
                   onTap: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorVideosPage()));},

                ),
                _mainButton(
                  label: "Games",
                 // icon: Icons.videogame_asset_rounded,
                 imagePath: "assets/images/Games.png",
                  color: const Color.fromARGB(255, 244, 201, 152),
                 onTap: () { 
                  Navigator.push(context, MaterialPageRoute(builder: (context) => GamesHomePage()));},
  
                ),
                _mainButton(
                  label: "Drawing",
                 // icon: Icons.brush_rounded,
                 imagePath: "assets/images/Drawing.png",
                  color: const Color(0xFFF9E2CE),
                 onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SupervisorDrawingHome(),
    ),
  );
},

                ),
                
              ],
            ),
         const SizedBox(height: 16),
       _buildFullWidthButton(
  label: "Kids",
  imagePath: "assets/images/kids.png",
  color: const Color(0xFFFFE7C8),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupervisorKidsScreen()),
    );
  },
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

// @override
//   Widget build(BuildContext context) {
//     return HomePage(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 16),

//             // ⭐ Dynamic greeting
//             Text(
//               "Hi, $childName! 👋",
//               style: GoogleFonts.poppins(
//                 fontSize: 44,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFFB66A6A),
//               ),
//             ),
//             Text(
//               "Ready for a fun learning day?",
//               style: GoogleFonts.poppins(
//                 fontSize: 25,
//                 color: const Color(0xFF5C4B51),
//               ),
//             ),

//             const SizedBox(height: 24),

//             // ✨ Quote box (API only)
//             _quoteCard(),

//             const SizedBox(height: 28),

//             // 🔸 Menu buttons
//             GridView.count(
//               crossAxisCount: 2,
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               crossAxisSpacing: 18,
//               mainAxisSpacing: 18,
//               children: [
//                 _mainButton(
//                   label: "Stories",
//                   imagePath: "assets/images/story2.png",
//                   color: const Color(0xFFFFD9C0),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const StoryKidsScreen()),
//                     );
//                   },
//                 ),
//                 _mainButton(
//                   label: "Videos",
//                   imagePath: "assets/images/video.png",
//                   color: const Color(0xFFE6C8D5),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const VideosKidScreen()),
//                     );
//                   },
//                 ),
//                 _mainButton(
//                   label: "Games",
//                   imagePath: "assets/images/Games.png",
//                   color: const Color(0xFFEFD8D8),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => const gamesKidScreen()),
//                     );
//                   },

//                 ),
//                 _mainButton(
//                   label: "Drawing",
//                   imagePath: "assets/images/Drawing.png",
//                   color: const Color(0xFFF9E2CE),
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => const ChildDrawingActivitiesScreen(),
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),

//             const SizedBox(height: 25),

    

//             const SizedBox(height: 30),

//             InkWell(
//               onTap: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => ChildBadgesScreen(childName: childName),
//                   ),
//                 );
//               },
//               borderRadius: BorderRadius.circular(20),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFE7C8),
//                   borderRadius: BorderRadius.circular(18),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 6,
//                       offset: Offset(0, 3),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Icon(Icons.emoji_events_rounded,
//                         color: Color(0xFF6E4A4A), size: 38),
//                     const SizedBox(width: 10),
//                     Text(
//                       "Kids",
//                       style: GoogleFonts.poppins(
//                         fontSize: 30,
//                         fontWeight: FontWeight.w600,
//                         color: const Color(0xFF6E4A4A),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ Quote UI (no image)
//   Widget _quoteCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFFFE6C9),
//         borderRadius: BorderRadius.circular(18),
//       ),
//       padding: const EdgeInsets.all(14),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   "✨ Quote of the Day ✨",
//                   style: GoogleFonts.robotoSlab(
//                     fontSize: 28,
//                     fontWeight: FontWeight.bold,
//                     color: const Color(0xFFAD5E5E),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 tooltip: "Refresh",
//                 onPressed: _quoteLoading ? null : _fetchKidsQuote,
//                 icon: const Icon(Icons.refresh, color: Color(0xFF6E4A4A)),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           if (_quoteLoading)
//             const Center(child: CircularProgressIndicator())
//           else if (_quoteError != null)
//             Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF3E8),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               padding: const EdgeInsets.all(12),
//               child: Text(
//                 _quoteError!,
//                 textAlign: TextAlign.center,
//                 style: GoogleFonts.robotoSlab(
//                   fontSize: 28,
//                   color: const Color(0xFF5C4B51),
//                 ),
//               ),
//             )
//           else
//             Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFF3E8),
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 children: [
//                   Text(
//                     _quoteText,
//                     textAlign: TextAlign.center,
//                     style: GoogleFonts.robotoSlab(
//                       fontSize: 25,
//                       color: const Color(0xFF5C4B51),
//                     ),
//                   ),
//                   if (_quoteAuthor.trim().isNotEmpty) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       "- $_quoteAuthor",
//                       style: GoogleFonts.robotoSlab(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: const Color(0xFF6E4A4A),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // 🌼 styled button component
//   Widget _mainButton({
//     required String label,
//     IconData? icon,
//     String? imagePath,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(24),
//       child: Container(
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 6,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (imagePath != null)
//               Image.asset(
//                 imagePath,
//                 height: 90,
//                 width: 90,
//                 fit: BoxFit.contain,
//               )
//             else if (icon != null)
//               Icon(icon, size: 48, color: const Color(0xFF8F5F5F)),
//             const SizedBox(height: 10),
//             Text(
//               label,
//               style: GoogleFonts.poppins(
//                 fontSize: 24,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF6F4C4C),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
