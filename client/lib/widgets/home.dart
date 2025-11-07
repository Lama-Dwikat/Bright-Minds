import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bright_minds/widgets/navItem.dart';




class homePage extends StatelessWidget {
  const homePage({super.key, this.child});
      final Widget? child;


  @override
  Widget build(BuildContext context) {

    const Color primaryPurple = Color(0xFF9182FA);
    //const Color whiteColor = Colors.white;
   // final Color inactiveColor = Colors.grey.shade600;
    return Scaffold(
      appBar: PreferredSize(
     //   preferredSize: const Size.fromHeight(100),
       preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.07), // 12% of screen height
        child: AppBar(
        backgroundColor: primaryPurple,
        automaticallyImplyLeading: false,
       flexibleSpace: 
       //Padding(
     //   padding: EdgeInsets.only(left:16,top:14),
       Align (
          alignment: Alignment.bottomLeft,
          child: 
            Image.asset(
              'assets/images/logo.png',
              fit:BoxFit.contain,
               width: MediaQuery.of(context).size.width * 0.25, // 35% of screen width
            ),
        )
     // ),
      ),
      ),
       body:Stack(
        children:[
  
      
    if (child != null)
      SafeArea(
        child: SingleChildScrollView(
          child: child,
        ),
      ),
       ],
       ),
bottomNavigationBar: SizedBox(
  //height: 83, 
  height:MediaQuery.of(context).size.height * 0.1, // 10% of screen height
  child: Stack(
    clipBehavior: Clip.none, 
    alignment: Alignment.center,
    children: [
      
      Container(
      height: MediaQuery.of(context).size.height * 0.09, // slightly less than SizedBox
        decoration: BoxDecoration(
          color: primaryPurple,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
          boxShadow: [
            BoxShadow(
              color: primaryPurple,
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          //padding: const EdgeInsets.symmetric(horizontal: 15.0),
           padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04, // 4% of width
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              navItem(
                icon: Icons.emoji_events_outlined,
                label: "Competitions",
                color: Colors.white,
                onTap: () {},
                iconSize: MediaQuery.of(context).size.width * 0.09, // scale icon  
               // iconSize: 40, 
              ),
               navItem(
                icon: Icons.notifications_none,
                label: "Alerts",
                color: Colors.white,
                onTap: () {},
               // iconSize: 45,
                iconSize: MediaQuery.of(context).size.width * 0.1,
              ),

              const SizedBox(width: 29),
              navItem(
                icon: Icons.chat_outlined,
                label: "Messages",
                color: Colors.white,
                onTap: () {},
               // iconSize: 40,
                iconSize: MediaQuery.of(context).size.width * 0.09,
              ),
              
              navItem(
                icon: Icons.settings_outlined,
                label: "Settings",
                color: Colors.white,
                onTap: () {},
               // iconSize: 40,
                iconSize: MediaQuery.of(context).size.width * 0.09,
              ),
            ],
          ),
        ),
      ),

      // Central Home Button
      Positioned(
      //  top: -30, // رفعه أكثر للأعلى
        top: -MediaQuery.of(context).size.height * 0.02, // 4% above the bar
        child: Container(
        //  width: 75,
         // height: 75,
          width: MediaQuery.of(context).size.width * 0.17, // 15% of screen width
          height: MediaQuery.of(context).size.width * 0.17, // keep square
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                  Color.fromRGBO(255, 255, 255, 0.95), // equivalent to white.withOpacity(0.95)
                Color.fromRGBO(255, 255, 255, 0.7),  // equivalent to white.withOpacity(0.7)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 139, 32, 205).withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: IconButton(
            icon: const Icon(Icons.home_rounded),
           // iconSize: 50, // أكبر وأوضح
            iconSize: MediaQuery.of(context).size.width * 0.1, // scale icon
            color: primaryPurple,
            onPressed: () {},
          ),
        ),
      ),
    ],
  ),
),
    
 );

  }   


  } 


