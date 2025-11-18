import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bright_minds/widgets/navItem.dart';
import 'package:bright_minds/theme/colors.dart'; // <<< أضيفي هذا

class homePage extends StatelessWidget {
  const homePage({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // ✨ بدل اللون البنفسجي الغامق
    const Color primaryPurple = AppColors.lavenderPurple; 

    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(MediaQuery.of(context).size.height * 0.07),
        child: AppBar(
          backgroundColor: AppColors.bgLavender, // 💜 باكجراوند بنفسجي فاتح
          automaticallyImplyLeading: false,
          flexibleSpace: Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              width: MediaQuery.of(context).size.width * 0.25,
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          if (child != null)
            SafeArea(
              child: SingleChildScrollView(child: child),
            ),
        ],
      ),

      // ============================
      // ⭐ Bottom Navigation Bar
      // ============================
      bottomNavigationBar: SizedBox(
        height: MediaQuery.of(context).size.height * 0.1,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.09,
              decoration: BoxDecoration(
                // 🎨 خلفية البوتوم بار بتدرج لطيف
                gradient: AppColors.bgLavenderToSoftPink,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lavenderPurple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.04,
                ),
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
                      onTap: () {},
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

            // =============== Home Button ===============
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.02,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.17,
                height: MediaQuery.of(context).size.width * 0.17,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  // 🎨 Gradient جديد لطيف
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.bgSoftPinkVeryLight,
                      AppColors.bgLavenderLight,
                    ],
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lavenderPurpleDark.withOpacity(0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: IconButton(
                  icon: const Icon(Icons.home_rounded),

                  // 💜 لون أيقونة الهوم
                  iconSize: MediaQuery.of(context).size.width * 0.1,
                  color: AppColors.lavenderPurpleDark,

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
