



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
     String? profilePictureBase64= "";
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
       profilePictureBase64=decodedToken['profilePicture'];
     });

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
             color:AppColors.peachPink,
            ),

//             child: Padding(
//               padding: EdgeInsets.symmetric(
//                   horizontal: MediaQuery.of(context).size.width * 0.04),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   crossAxisAlignment: CrossAxisAlignment.center, 
//                  children: [
//                   Transform.translate(
//            offset: const Offset(0, 10), // move down by 8 pixels
//         child:  Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//              crossAxisAlignment: CrossAxisAlignment.center,
//             children: [



//    PopupMenuButton<String>(
//   onSelected: (String value) {
//     setState(() {
//       // store selected value if needed
//       selectedValue = value;
//     });

//     if (value == 'myProfile') {
//       // navigate to profile page
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ProfilePage(userId: userId!),
//         ),
//       );
//     } else if (value == 'LogOut') {
//       // clear token and go to sign-in
//       SharedPreferences.getInstance().then((prefs) {
//         prefs.remove('token');
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => SignInScreen()),
//         );
//       });
//     }
//   },
//   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//     const PopupMenuItem<String>(
//       value: 'myProfile',
//       child: Text("My Profile"),
//     ),
//     const PopupMenuItem<String>(
//       value: 'LogOut',
//       child: Text("Log Out"),
//     ),
//   ],
//     color: AppColors.bgSoftPinkLight, // <-- change background color here
//     offset: const Offset(0, 50), // <-- moves the menu down by 40 pixels

//   child: CircleAvatar(
//     radius: 25,
//     backgroundColor: Colors.grey[300],
//     backgroundImage: (profilePictureBase64 != null &&
//             profilePictureBase64!.isNotEmpty)
//         ? MemoryImage(base64Decode(profilePictureBase64!))
//         : null,
//     child: (profilePictureBase64 == null ||
//             profilePictureBase64!.isEmpty)
//         ? const Icon(Icons.person, color: Colors.white)
//         : null,
//   ),
// ),


//    SizedBox(width: 15), // space between image & text

//     Text(
//       widget.title,
//       style: TextStyle(
//         color: Colors.white,
//         fontSize: 23,
//         fontWeight: FontWeight.bold,
//       ),
//     ),
//       //  ),
//   ],
// )
// ),

//                 const SizedBox(width: 10),

//                   // Logo on the right
//                   Image.asset(
//                     'assets/images/logo.png',
//                     fit: BoxFit.contain,
//                     width: MediaQuery.of(context).size.width * 0.25,
//                   ),
//                 ],
//               ),
//             ),
       


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
                      builder: (context) => ProfilePage(userId: userId!),
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
              color: AppColors.bgSoftPinkLight,
              offset: const Offset(0, 50),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey[300],
                backgroundImage: (profilePictureBase64 != null &&
                        profilePictureBase64!.isNotEmpty)
                    ? MemoryImage(base64Decode(profilePictureBase64!))
                    : null,
                child: (profilePictureBase64 == null ||
                        profilePictureBase64!.isEmpty)
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
                  color: Colors.white,
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
                    color: AppColors.peachPink,
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
                      onTap: () {},
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
                    navItem(
                      icon: Icons.chat_outlined,
                      label: "Messages",
                      color: Colors.white,
                      onTap: () {},
                      iconSize: MediaQuery.of(context).size.width * 0.09,
                    ),
                    navItem(
                      icon: Icons.settings_outlined,
                      label: "Settings",
                      color: Colors.white,
                      onTap: () {},
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
                      AppColors.bgWarmPink,
                      AppColors.bgWarmPinkDark
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bgWarmPinkDark,
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
