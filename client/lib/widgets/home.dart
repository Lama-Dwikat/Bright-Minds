



import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bright_minds/widgets/navItem.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/screens/Signin.dart';
import 'package:bright_minds/screens/profilePage.dart';
import 'package:bright_minds/screens/homeParent.dart';
import 'package:bright_minds/screens/homeChild.dart';
import 'package:bright_minds/screens/homeSupervisor.dart';
import 'package:bright_minds/screens/homeAdmin.dart';
import 'package:bright_minds/screens/childStory/childNotificationsScreen.dart';
import 'package:bright_minds/screens/Settings/parentSettingsScreen.dart';
import 'package:bright_minds/screens/Settings/childSettingsScreen.dart';
import 'package:bright_minds/screens/Settings/supervisorSettingsScreen.dart';
import 'package:bright_minds/screens/challenges/SupervisorWeeklyPlannerScreen.dart';
import 'package:bright_minds/screens/challenges/childWeeklyChallenges.dart';
import 'package:bright_minds/screens/challenges/parentKidWeeklyChallengesScreen.dart';
import 'package:bright_minds/screens/chat.dart';
import 'package:bright_minds/screens/challenges/parentChooseKidChallengesScreen.dart';



class HomePage extends StatefulWidget {
  const HomePage({super.key, this.child,this.title = "Home"});
  final Widget? child;
  final String title; 
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {


     String? token;
     String?userId;
     String ? userName;
     String ?role ;
    // String? profilePictureBase64= "";
    Uint8List? profileImageBytes;
     String? selectedValue; // <-- add this

  @override

  void initState() {
    super.initState();
    fetchSupervisorData();
    
  }



  void fetchSupervisorData() async {

SharedPreferences pref= await SharedPreferences.getInstance();
String? token= pref.getString('token');
if (token==null){
  print("no token found");
  return;
} 
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
 // print("DECODED TOKEN CODE 1 = $decodedToken");
     setState(() {
       userId= decodedToken['id'];

     userName= decodedToken['name'];
     role=decodedToken['role'];
     });
                 fetchProfilePicture();


}
    
  Future<void> fetchProfilePicture() async {
  final response = await http.get(
    Uri.parse('${getBackendUrl()}/api/users/getme/$userId'),
    headers: {"content-type": "application/json"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    final bytes = Uint8List.fromList(
      List<int>.from(
        data['profilePicture']['data']['data'],
      ),
    );

    setState(() {
      profileImageBytes = bytes;
    });
  }
}




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
  Widget build(BuildContext context) {

      final Size screenSize = MediaQuery.of(context).size;
  final double screenHeight = screenSize.height;
  final double screenWidth = screenSize.width;

  final bool isMobile = screenWidth < 600; // breakpoint
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
        child: AppBar(

          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
             // gradient: AppColors.pinkToPeach,
             color:Color.fromARGB(255, 241, 196, 137),
            ),


       


child: Padding(
  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      // Left side: profile picture + title
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  selectedValue = value;
                });
                if (value == 'myProfile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(),
                    ),
                  );
                } else if (value == 'LogOut') {
                  SharedPreferences.getInstance().then((prefs) {
                    prefs.remove('token');
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                    );
                  });
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'myProfile',
                  child: Text("My Profile"),
                ),
                const PopupMenuItem<String>(
                  value: 'LogOut',
                  child: Text("Log Out"),
                ),
              ],
              color: const Color.fromARGB(255, 198, 159, 82),
              offset: const Offset(0, 50),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: (profileImageBytes != null)
                    ? MemoryImage(profileImageBytes!)
                    : null,
                child: (profileImageBytes == null ||
                        profileImageBytes!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),

            const SizedBox(width: 10),

            // Title text with wrapping
            Expanded(
              child: Text(
                widget.title,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: const TextStyle(
                  color: Colors.brown,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(width: 10),

      // Logo stays fixed on the right
      Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        width: MediaQuery.of(context).size.width * 0.25,
      ),
    ],
  ),
),

          ),
        ),
      ),
    
      body: SafeArea(
  child: widget.child ?? const Center(child: Text("No content")),
),

      bottomNavigationBar: SizedBox(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.09,
              decoration: BoxDecoration(

                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
             color:Color.fromARGB(255, 241, 196, 137),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(

                    horizontal: MediaQuery.of(context).size.width * 0.04),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    navItem(
                      icon: Icons.emoji_events_outlined,
                      label: "Competitions",
                      color: Colors.white,
                       onTap: () {
    if (role == "supervisor") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SupervisorWeeklyPlannerScreen()),
      );
    } 
   else if (role == 'child') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildWeeklyChallengesScreen()),
    );
  }
  else if (role == 'parent') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ParentChooseKidChallengesScreen(),
    ),
  );
}

  else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Challenges are available for supervisors only.")),
      );
    }
  },
                      iconSize: MediaQuery.of(context).size.width * 0.09,
                    ),
                    navItem(
  icon: Icons.notifications_none,
  label: "Alerts",
  color: Colors.white,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChildNotificationsScreen(),
      ),
    );
  },
  iconSize: MediaQuery.of(context).size.width * 0.1,
),

                    const SizedBox(width: 29),
                    // navItem(
                    //   icon: Icons.chat_outlined,
                    //   label: "Messages",
                    //   color: Colors.white,
                    //   onTap: () {
                    //     Navigator.push(context,MaterialPageRoute(builder: (context)=> ChatUsersScreen(currentUserId:userId!)));
                    //   },
                    //   iconSize: MediaQuery.of(context).size.width * 0.09,
                    // ),
                    navItem(
  icon: Icons.chat_outlined,
  label: "Messages",
  color: Colors.white,
  onTap: () {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatUsersScreen(currentUserId: userId!),
        ),
      );
    } else {
      print("User ID not loaded yet.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loading user data, please wait...")),
      );
    }
  },
  iconSize: MediaQuery.of(context).size.width * 0.09,
),

                    navItem(
                      icon: Icons.settings_outlined,
                      label: "Settings",
                      color: Colors.white,
                      onTap: () {
  if (role == 'parent') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentSettingsScreen()),
    );
  }
  else if (role == 'child') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChildSettingsScreen()),
    );
  } else if (role == 'supervisor') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SupervisorSettingsScreen()),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ParentSettingsScreen()),
    );
  }
},

                      iconSize: MediaQuery.of(context).size.width * 0.09,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.02,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.17,
                height: MediaQuery.of(context).size.width * 0.17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                 Color.fromARGB(255, 214, 179, 133),

                 Color.fromARGB(255, 224, 196, 159),

                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                          color:Color.fromARGB(255, 241, 196, 137),

                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: IconButton(
                  icon: const Icon(Icons.home_rounded),
                  iconSize: MediaQuery.of(context).size.width * 0.1,

                  color: Colors.white,
                  onPressed: () {
                    if(role=='supervisor'){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => HomeSupervisor()));
                   } else if (role == 'child') {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => HomeChild()));
                    } else if (role == 'admin') {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => HomeAdmin()));
                       } else if (role == 'parent') {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => HomeParent()));
                       }

                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:bright_minds/widgets/navItem.dart';
// import 'package:bright_minds/theme/colors.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// import 'package:bright_minds/screens/Signin.dart';
// import 'package:bright_minds/screens/profilePage.dart';
// import 'package:bright_minds/screens/homeParent.dart';
// import 'package:bright_minds/screens/homeChild.dart';
// import 'package:bright_minds/screens/homeSupervisor.dart';
// import 'package:bright_minds/screens/homeAdmin.dart';
// import 'package:bright_minds/screens/childStory/childNotificationsScreen.dart';
// import 'package:bright_minds/screens/Settings/parentSettingsScreen.dart';
// import 'package:bright_minds/screens/Settings/childSettingsScreen.dart';
// import 'package:bright_minds/screens/Settings/supervisorSettingsScreen.dart';
// import 'package:bright_minds/screens/challenges/SupervisorWeeklyPlannerScreen.dart';
// import 'package:bright_minds/screens/challenges/childWeeklyChallenges.dart';
// import 'package:bright_minds/screens/chat.dart';

// class HomePage extends StatefulWidget {
//   const HomePage({super.key, this.child, this.title = "Home"});
//   final Widget? child;
//   final String title;

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   String? userId;
//   String? userName;
//   String? role;
//   Uint8List? profileImageBytes;

//   @override
//   void initState() {
//     super.initState();
//     fetchUserData();
//   }

//   void fetchUserData() async {
//     SharedPreferences pref = await SharedPreferences.getInstance();
//     String? token = pref.getString('token');
//     if (token == null) return;

//     final decoded = JwtDecoder.decode(token);
//     setState(() {
//       userId = decoded['id'];
//       userName = decoded['name'];
//       role = decoded['role'];
//     });

//     fetchProfilePicture();
//   }

//   Future<void> fetchProfilePicture() async {
//     final response = await http.get(
//       Uri.parse('${getBackendUrl()}/api/users/getme/$userId'),
//       headers: {"content-type": "application/json"},
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       setState(() {
//         profileImageBytes = Uint8List.fromList(
//           List<int>.from(data['profilePicture']['data']['data']),
//         );
//       });
//     }
//   }

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
//   }

//   // =========================
//   // BUILD
//   // =========================
//   @override
//   Widget build(BuildContext context) {
//     final bool isMobile = MediaQuery.of(context).size.width < 700;

//     return isMobile ? _mobileLayout(context) : _webLayout(context);
//   }

//   // =========================
//   // MOBILE LAYOUT (UNCHANGED)
//   // =========================
//   Widget _mobileLayout(BuildContext context) {
//     return Scaffold(
//       appBar: _mobileAppBar(context),
//       body: SafeArea(
//         child: widget.child ?? const Center(child: Text("No content")),
//       ),
//       bottomNavigationBar: _mobileBottomNav(context),
//     );
//   }

//   // =========================
//   // WEB LAYOUT (NEW)
//   // =========================
//   Widget _webLayout(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 251, 237, 228),
//       body: Row(
//         children: [
//           _webSidebar(context),
//           Expanded(
//             child: Column(
//               children: [
//                 _webTopBar(context),
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(24),
//                     child: widget.child ??
//                         const Center(child: Text("No content")),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================
//   // MOBILE APP BAR
//   // =========================
//   PreferredSizeWidget _mobileAppBar(BuildContext context) {
//     return AppBar(
//       automaticallyImplyLeading: false,
//       backgroundColor: const Color.fromARGB(255, 241, 196, 137),
//       title: Row(
//         children: [
//           PopupMenuButton<String>(
//             onSelected: _handleProfileMenu,
//             itemBuilder: _profileMenuItems,
//             child: CircleAvatar(
//               backgroundImage:
//                   profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
//               child: profileImageBytes == null
//                   ? const Icon(Icons.person)
//                   : null,
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               widget.title,
//               style: const TextStyle(
//                 color: Colors.brown,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 22,
//               ),
//             ),
//           ),
//           Image.asset('assets/images/logo.png', width: 80),
//         ],
//       ),
//     );
//   }

//   // =========================
//   // WEB TOP BAR
//   // =========================
//   Widget _webTopBar(BuildContext context) {
//     return Container(
//       height: 70,
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       color: const Color.fromARGB(255, 241, 196, 137),
//       child: Row(
//         children: [
//           Text(
//             widget.title,
//             style: const TextStyle(
//               fontSize: 26,
//               fontWeight: FontWeight.bold,
//               color: Colors.brown,
//             ),
//           ),
//           const Spacer(),
//           PopupMenuButton<String>(
//             onSelected: _handleProfileMenu,
//             itemBuilder: _profileMenuItems,
//             child: CircleAvatar(
//               backgroundImage:
//                   profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
//               child: profileImageBytes == null
//                   ? const Icon(Icons.person)
//                   : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================
//   // WEB SIDEBAR
//   // =========================
//   Widget _webSidebar(BuildContext context) {
//     return Container(
//       width: 260,
//           color: const Color.fromARGB(255, 250, 225, 190), // background color behind the form
//       child: Column(
//         children: [
//           const SizedBox(height: 30),
//           Image.asset('assets/images/logo.png', width: 140),
//           const SizedBox(height: 30),

//           _sideItem(Icons.home, "Home", _goHome),
//           _sideItem(Icons.notifications, "Alerts", () {
//             Navigator.push(context,
//                 MaterialPageRoute(builder: (_) => const ChildNotificationsScreen()));
//           }),
//           _sideItem(Icons.chat, "Messages", () {
//             if (userId != null) {
//               Navigator.push(context,
//                   MaterialPageRoute(builder: (_) => ChatUsersScreen(currentUserId: userId!)));
//             }
//           }),
//           _sideItem(Icons.emoji_events, "Challenges", _openChallenges),
//           _sideItem(Icons.settings, "Settings", _openSettings),
//         ],
//       ),
//     );
//   }

//   Widget _sideItem(IconData icon, String text, VoidCallback onTap) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.brown),
//       title: Text(text),
//       onTap: onTap,
//     );
//   }

//   // =========================
//   // MOBILE BOTTOM NAV (UNCHANGED)
//   // =========================
//   Widget _mobileBottomNav(BuildContext context) {
//     return SizedBox(
//       height: MediaQuery.of(context).size.height * 0.1,
//       child: Center(child: Text("⬆️ Same bottom nav as before")),
//     );
//   }

//   // =========================
//   // HELPERS
//   // =========================
//   void _handleProfileMenu(String value) {
//     if (value == 'myProfile') {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (_) => ProfilePage()));
//     } else {
//       SharedPreferences.getInstance().then((prefs) {
//         prefs.remove('token');
//         Navigator.pushReplacement(
//             context, MaterialPageRoute(builder: (_) => SignInScreen()));
//       });
//     }
//   }

//   List<PopupMenuEntry<String>> _profileMenuItems(BuildContext context) {
//     return const [
//       PopupMenuItem(value: 'myProfile', child: Text("My Profile")),
//       PopupMenuItem(value: 'LogOut', child: Text("Log Out")),
//     ];
//   }

//   void _goHome() {
//     if (role == 'child') {
//       Navigator.push(context, MaterialPageRoute(builder: (_) => HomeChild()));
//     } else if (role == 'parent') {
//       Navigator.push(context, MaterialPageRoute(builder: (_) => HomeParent()));
//     } else if (role == 'supervisor') {
//       Navigator.push(context, MaterialPageRoute(builder: (_) => HomeSupervisor()));
//     } else {
//       Navigator.push(context, MaterialPageRoute(builder: (_) => HomeAdmin()));
//     }
//   }

//   void _openChallenges() {
//     if (role == "supervisor") {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (_) => const SupervisorWeeklyPlannerScreen()));
//     } else if (role == "child") {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (_) => const ChildWeeklyChallengesScreen()));
//     }
//   }

//   void _openSettings() {
//     if (role == 'parent') {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (_) => const ParentSettingsScreen()));
//     } else if (role == 'child') {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (_) => const ChildSettingsScreen()));
//     } else if (role == 'supervisor') {
//       Navigator.push(context,
//           MaterialPageRoute(builder: (_) => const SupervisorSettingsScreen()));
//     }
//   }
// }
