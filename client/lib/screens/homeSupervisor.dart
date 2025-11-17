import 'package:bright_minds/screens/supervisorKids.dart';
import 'package:bright_minds/screens/supervisorVideo.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeSupervisor extends StatefulWidget {
  const HomeSupervisor({super.key});

  @override
  _HomeSupervisorState createState() => _HomeSupervisorState();
}

class _HomeSupervisorState extends State<HomeSupervisor> {
  final List<TodoItem> _todos = [
    TodoItem(title: "Finish homework"),
    TodoItem(title: "Read a book"),
    TodoItem(title: "Play outside"),
  ];

  @override
  Widget build(BuildContext context) {
    return homePage(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quote box
              Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 247, 247, 168),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      "The Quote of the Day",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Row with 50/50 split: To-Do List | Statistics
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // To-Do List
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.lightBlue[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 200, // fixed height
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "To-Do List",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: _todos.map((todo) {
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    todo.title,
                                    style: GoogleFonts.robotoSlab(
                                      fontSize: 16,
                                    ),
                                  ),
                                  value: todo.isDone,
                                  activeColor: Colors.blue,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      todo.isDone = value!;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Statistics Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      height: 200, // fixed height
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Statistics",
                            style: GoogleFonts.robotoSlab(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView(
                              children: [
                                _buildStatBox(
                                  color: Colors.lightBlue[100]!,
                                  icon: Icons.child_care,
                                  number: 25,
                                  label: "Total Kids",
                                ),
                                _buildStatBox(
                                  color: Colors.green[100]!,
                                  icon: Icons.sports_esports,
                                  number: 10,
                                  label: "Games Created",
                                ),
                                _buildStatBox(
                               color: Colors.orange[100]!,
                               icon: Icons.video_library,
                                number: 10,
                               label: "Videos Added",
                               ),
                                _buildStatBox(
                                  color: Colors.pink[100]!,
                                  icon: Icons.emoji_events,
                                  number: 6,
                                  label: "Challenges Created",
                                ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2x2 grid of smaller square buttons
            // 2x2 grid of smaller square buttons
      Column(
     children: [
      Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSquareButton(
          label: "Videos",
          icon: Icons.video_library,
          color: Colors.orange[200]!,
          onPressed: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorVideosScreen()));},
        ),
        const SizedBox(width: 16),
        _buildSquareButton(
          label: "Drawing",
          icon: Icons.brush,
          color: Colors.pink[200]!,
       onPressed: () {  Navigator.push(context, MaterialPageRoute(builder: (context) => SupervisorKidsScreen()));},
 
        ),
      ],
    ),
    const SizedBox(height: 16),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSquareButton(
          label: "Games",
          icon: Icons.videogame_asset,
          color: Colors.lightGreen[200]!,
          onPressed: () {},
        ),
        const SizedBox(width: 16),
        _buildSquareButton(
          label: "Stories",
          icon: Icons.book,
          color: Colors.blue[200]!,
          onPressed: () {},
        ),
      ],
    ),
  ],
),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required Color color,
    required IconData icon,
    required int number,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Colors.black87),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$number",
                style: GoogleFonts.robotoSlab(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.robotoSlab(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildSquareButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return SizedBox(
    width: 195,  // smaller width
    height: 140, // smaller height
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.robotoSlab(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

}

// Model class for To-Do items
class TodoItem {
  String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}
