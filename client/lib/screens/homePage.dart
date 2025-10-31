import 'package:flutter/material.dart';
import 'package:bright_minds/config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bright_minds/widgets/navItem.dart';




class homePage extends StatelessWidget {
  const homePage({super.key});

  @override
  Widget build(BuildContext context) {

    const Color primaryPurple = Color(0xFF9182FA);
    const Color whiteColor = Colors.white;
    final Color inactiveColor = Colors.grey.shade600;
    return Scaffold(
       body:Stack(
        children:[
          Image.asset(("assets/images/home2.png"), 
          fit:BoxFit.cover,
          width:double.infinity,
          height:double.infinity,
          ),
         
        ],
       ),

bottomNavigationBar: SizedBox(
  height: 83, 
  child: Stack(
    clipBehavior: Clip.none, 
    alignment: Alignment.center,
    children: [
      
      Container(
        height: 75,
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
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              navItem(
                icon: Icons.emoji_events_outlined,
                label: "Competitions",
                color: Colors.white,
                onTap: () {},
                iconSize: 40, 
              ),

                navItem(
                icon: Icons.notifications_none,
                label: "Alerts",
                color: Colors.white,
                onTap: () {},
                iconSize: 45,
              ),

              const SizedBox(width: 29),
              navItem(
                icon: Icons.chat_outlined,
                label: "Messages",
                color: Colors.white,
                onTap: () {},
                iconSize: 40,
              ),
              
              navItem(
                icon: Icons.settings_outlined,
                label: "Settings",
                color: Colors.white,
                onTap: () {},
                iconSize: 40,
              ),
            ],
          ),
        ),
      ),

      // Central Home Button
      Positioned(
        top: -30, // رفعه أكثر للأعلى
        child: Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white.withOpacity(0.7)
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
            iconSize: 50, // أكبر وأوضح
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


