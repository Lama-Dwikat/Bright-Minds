import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/screens/childStory/childStory.dart';


class HomeChild extends StatefulWidget {
  const HomeChild({super.key});

  @override
  _HomeChildState createState() => _HomeChildState();
}

class _HomeChildState extends State<HomeChild> {
  @override
  Widget build(BuildContext context) {
    return HomePage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "  Hi, Hiba! 👋",
              style: GoogleFonts.poppins(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 36, 11, 144),
              ),
            ),
            Text(
              "   Ready to play and learn today?",
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: const Color.fromARGB(255, 42, 51, 69),
              ),
            ),
            const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(146, 255, 244, 91),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
              child: Column(
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
       /* Image.asset(
          "assets/images/energy.png",
          height: 50,
          width: 50,
          fit: BoxFit.contain,
        ),*/
        const SizedBox(width: 16), 
        Text(
          "The Quote of the Day",
          style: GoogleFonts.robotoSlab(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 36, 11, 144),
          ),
        ),
      ],
    ),

  

    Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 248, 249, 211),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(12),
      child: Text(
        "Be happy today, tomorrow, and beyond. Don't disappoint yourself!",
        textAlign: TextAlign.center,
        style: GoogleFonts.robotoSlab(
          fontSize: 16,
          color: const Color.fromARGB(255, 42, 51, 69),
        ),
      ),
    ),
  ],
),
              ),

            const SizedBox(height: 8),
            

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
                  color: Colors.lightBlue[100]!,
                  onTap: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryKidsScreen()));},

                ),
                _mainButton(
                  label: "Videos",
                 // icon: Icons.ondemand_video_rounded,
                 imagePath: "assets/images/video.png",
                  color:  Colors.orange[100]!,
                   onTap: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryKidsScreen()));},

                ),
                _mainButton(
                  label: "Games",
                 // icon: Icons.videogame_asset_rounded,
                 imagePath: "assets/images/Games.png",
                  color: Colors.green[100]!,
                 onTap: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryKidsScreen()));},

                ),
                _mainButton(
                  label: "Drawing",
                 // icon: Icons.brush_rounded,
                 imagePath: "assets/images/Drawing.png",
                  color: Colors.pink[100]!,
                  onTap: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => StoryKidsScreen()));},

                ),
                
              ],
            ),

            const SizedBox(height: 36),

           /*
            Container(
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 34),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Achievements",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                             color: const Color.fromARGB(255, 36, 11, 144),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "You have written 3 stories and drawn 2 pictures!",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                             color: const Color.fromARGB(255, 36, 11, 144),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Recent Works",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.indigo[900],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Top story of the week: Adventures of Abby!",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
*/
            const SizedBox(height: 30),
          ],
        ),
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
              height: 120,
              width: 120,
              fit: BoxFit.contain,
            )
          else if (icon != null)
            Icon(icon, size: 48, color: Colors.indigo[900]),

          const SizedBox(height: 10),

          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              //color: const Color.fromARGB(255, 255, 251, 251),
               color: const Color.fromARGB(255, 36, 11, 144),
            ),
          ),
        ],
      ),
    ),
  );
}
}