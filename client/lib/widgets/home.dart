



import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:bright_minds/widgets/navItem.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/screens/Signin.dart';
import 'package:bright_minds/screens/profilePage.dart';
import 'package:bright_minds/screens/home/homeParent.dart';
import 'package:bright_minds/screens/home/homeChild.dart';
import 'package:bright_minds/screens/home/homeSupervisor.dart';
import 'package:bright_minds/screens/home/homeAdmin.dart';
import 'package:bright_minds/screens/childStory/childNotificationsScreen.dart';
import 'package:bright_minds/screens/Settings/parentSettingsScreen.dart';
import 'package:bright_minds/screens/Settings/childSettingsScreen.dart';
import 'package:bright_minds/screens/Settings/supervisorSettingsScreen.dart';
import 'package:bright_minds/screens/challenges/SupervisorWeeklyPlannerScreen.dart';
import 'package:bright_minds/screens/challenges/childWeeklyChallenges.dart';
import 'package:bright_minds/screens/chat.dart';
import 'package:bright_minds/screens/challenges/parentChooseKidChallengesScreen.dart';








class HomePage extends StatefulWidget {
  const HomePage({super.key, this.child, this.title = "Home"});
  final Widget? child;
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userId;
  String? userName;
  String? role;
  Uint8List? profileImageBytes;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');
    if (token == null) return;

    final decoded = JwtDecoder.decode(token);
    setState(() {
      userId = decoded['id'];
      userName = decoded['name'];
      role = decoded['role'];
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
      setState(() {
        profileImageBytes = Uint8List.fromList(
          List<int>.from(data['profilePicture']['data']['data']),
        );
      });
    }
  }

  String getBackendUrl() {
    if (kIsWeb) 
    //return "http://192.168.1.74:3000";
    return "http://localhost:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return isMobile ? _mobileLayout(context) : _webLayout(context);
  }

  // =========================
  // MOBILE LAYOUT (UNCHANGED)
  // =========================
  Widget _mobileLayout(BuildContext context) {
    return Scaffold(
      appBar: _mobileAppBar(context),
      body: SafeArea(
        child: widget.child ?? const Center(child: Text("No content")),
      ),
      bottomNavigationBar: _mobileBottomNav(context),
    );
  }

  // =========================
  // WEB LAYOUT (NEW)
  // =========================
  Widget _webLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 251, 237, 228),
      body: Row(
        children: [
          _webSidebar(context),
          Expanded(
            child: Column(
              children: [
                _webTopBar(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: widget.child ?? const Center(child: Text("No content")),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // MOBILE APP BAR
  // =========================
// =========================
// MOBILE APP BAR (UNCHANGED)
// =========================
PreferredSizeWidget _mobileAppBar(BuildContext context) {
return AppBar(
  automaticallyImplyLeading: false,
  backgroundColor: const Color.fromARGB(255, 241, 196, 137),
  toolbarHeight: 60, // keeps AppBar height fixed (adjust if needed)
  titleSpacing: 0,
  flexibleSpace: Padding(
    padding: const EdgeInsets.only(top: 15, left: 10, right: 10), // top pushes row to top
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center, // title & logo same line
      children: [
        Row(
          children: [
            PopupMenuButton<String>(
              onSelected: _handleProfileMenu,
              itemBuilder: _profileMenuItems,
              child: CircleAvatar(
                backgroundImage: profileImageBytes != null
                    ? MemoryImage(profileImageBytes!)
                    : null,
                child: profileImageBytes == null
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        Image.asset(
          'assets/images/logo.png',
          width: 100,
        ),
      ],
    ),
  ),
);



}


  // =========================
  // WEB TOP BAR
  // =========================
  Widget _webTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color.fromARGB(255, 241, 196, 137),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: _handleProfileMenu,
            itemBuilder: _profileMenuItems,
            child: CircleAvatar(
              backgroundImage:
                  profileImageBytes != null ? MemoryImage(profileImageBytes!) : null,
              child: profileImageBytes == null ? const Icon(Icons.person) : null,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // WEB SIDEBAR
  // =========================
  Widget _webSidebar(BuildContext context) {
    return Container(
      width: 260,
      color: const Color.fromARGB(255, 250, 225, 190),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Image.asset('assets/images/logo.png', width: 140),
          const SizedBox(height: 30),
          _sideItem(Icons.home, "Home", _goHome),
          _sideItem(Icons.notifications, "Alerts", () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ChildNotificationsScreen()));
          }),
          _sideItem(Icons.chat, "Messages", () {
            if (userId != null) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ChatUsersScreen(currentUserId: userId!)));
            }
          }),
          _sideItem(Icons.emoji_events, "Challenges", _openChallenges),
          _sideItem(Icons.settings, "Settings", _openSettings),
        ],
      ),
    );
  }

  Widget _sideItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown),
      title: Text(text),
      onTap: onTap,
    );
  }


// =========================
// MOBILE BOTTOM NAV 
// =========================
Widget _mobileBottomNav(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return SizedBox(
    height: screenHeight * 0.1,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: screenHeight * 0.09,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 241, 196, 137),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
                        MaterialPageRoute(
                            builder: (_) => const SupervisorWeeklyPlannerScreen()),
                      );
                    } else if (role == 'child') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChildWeeklyChallengesScreen()),
                      );
                    } else if (role == 'parent') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ParentChooseKidChallengesScreen()),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Challenges are available for supervisors only.")),
                      );
                    }
                  },
                  iconSize: screenWidth * 0.09,
                ),
                navItem(
                  icon: Icons.notifications_none,
                  label: "Alerts",
                  color: Colors.white,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChildNotificationsScreen(),
                      ),
                    );
                  },
                  iconSize: screenWidth * 0.1,
                ),
                const SizedBox(width: 29),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Loading user data, please wait...")),
                      );
                    }
                  },
                  iconSize: screenWidth * 0.09,
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
                    } else if (role == 'child') {
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
                  iconSize: screenWidth * 0.09,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -screenHeight * 0.02,
          child: Container(
            width: screenWidth * 0.17,
            height: screenWidth * 0.17,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 214, 179, 133),
                  const Color.fromARGB(255, 224, 196, 159),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 241, 196, 137),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: IconButton(
              icon: const Icon(Icons.home_rounded),
              iconSize: screenWidth * 0.1,
              color: Colors.white,
              onPressed: () {
                _goHome();
              },
            ),
          ),
        ),
      ],
    ),
  );
}


  // =========================
  // HELPERS
  // =========================
  void _handleProfileMenu(String value) {
    if (value == 'myProfile') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()));
    } else {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('token');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SignInScreen()));
      });
    }
  }

  List<PopupMenuEntry<String>> _profileMenuItems(BuildContext context) {
    return const [
      PopupMenuItem(value: 'myProfile', child: Text("My Profile")),
      PopupMenuItem(value: 'LogOut', child: Text("Log Out")),
    ];
  }

  void _goHome() {
    if (role == 'child') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeChild()));
    } else if (role == 'parent') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeParent()));
    } else if (role == 'supervisor') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeSupervisor()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeAdmin()));
    }
  }

  void _openChallenges() {
    if (role == "supervisor") {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const SupervisorWeeklyPlannerScreen()));
    } else if (role == "child") {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ChildWeeklyChallengesScreen()));
    }else if (role == "parent") {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ParentChooseKidChallengesScreen()));
    }
  }

  void _openSettings() {
    if (role == 'parent') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentSettingsScreen()));
    } else if (role == 'child') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildSettingsScreen()));
    } else if (role == 'supervisor') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SupervisorSettingsScreen()));
    }
  }
}
