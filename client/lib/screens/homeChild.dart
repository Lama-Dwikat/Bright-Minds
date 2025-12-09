import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/screens/videosKids.dart';
import 'package:bright_minds/screens/childStory/childStory.dart';
import 'package:bright_minds/screens/childStory/childPublishedStoriesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/screens/childStory/childBadgesScreen.dart';

class HomeChild extends StatefulWidget {
  const HomeChild({super.key});

  @override
  _HomeChildState createState() => _HomeChildState();
}

class _HomeChildState extends State<HomeChild> {
  String childName = "";

  @override
  void initState() {
    super.initState();
    _loadChildName();
  }

  Future<void> _loadChildName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      childName = prefs.getString("name") ?? "Kid";
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ⭐ Dynamic greeting
            Text(
              "Hi, $childName! 👋",
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB66A6A), // peach red
              ),
            ),
            Text(
              "Ready for a fun learning day?",
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: const Color(0xFF5C4B51),
              ),
            ),

            const SizedBox(height: 24),

            // ✨ Quote box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6C9), // peach beige
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(
                    "✨ Quote of the Day ✨",
                    style: GoogleFonts.robotoSlab(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFAD5E5E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      "Be happy today, tomorrow, and forever — you deserve it! 🌸",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoSlab(
                        fontSize: 16,
                        color: const Color(0xFF5C4B51),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 🔸 Menu buttons
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              children: [
                _mainButton(
                  label: "Stories",
                  imagePath: "assets/images/story2.png",
                  color: const Color(0xFFFFD9C0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const StoryKidsScreen()),
                    );
                  },
                ),
                _mainButton(
                  label: "Videos",
                  imagePath: "assets/images/video.png",
                  color: const Color(0xFFE6C8D5),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VideosKidScreen()),
                    );
                  },
                ),
                _mainButton(
                  label: "Games",
                  imagePath: "assets/images/Games.png",
                  color: const Color(0xFFEFD8D8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryKidsScreen()),
                    );
                  },
                ),
                _mainButton(
                  label: "Drawing",
                  imagePath: "assets/images/Drawing.png",
                  color: const Color(0xFFF9E2CE),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StoryKidsScreen()),
                    );
                  },
                ),
              ],
            ),


            const SizedBox(height: 25),

InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChildPublishedStoriesScreen(),
      ),
    );
  },
  borderRadius: BorderRadius.circular(20),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFD8C4), // peach
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.menu_book_rounded,
            color: Color(0xFF6E4A4A), size: 38),

        const SizedBox(width: 10),

        Text(
          "Published Kids Stories",
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4A4A),
          ),
        ),
      ],
    ),
  ),
),

const SizedBox(height: 30),


InkWell(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildBadgesScreen(childName: "Hiba"), // بدّلي الاسم
      ),
    );
  },
  borderRadius: BorderRadius.circular(20),
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE7C8), // soft peach gold
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFF6E4A4A),
          size: 38,
        ),

        const SizedBox(width: 10),

        Text(
          "My Badges",
          style: GoogleFonts.poppins(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6E4A4A),
          ),
        ),
      ],
    ),
  ),
),


            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // 🌼 styled button component
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
                height: 90,
                width: 90,
                fit: BoxFit.contain,
              )
            else if (icon != null)
              Icon(icon, size: 48, color: const Color(0xFF8F5F5F)),

            const SizedBox(height: 10),

            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6F4C4C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
