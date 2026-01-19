import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/supervisorDrawing/searchExternalImages.dart';
import 'package:bright_minds/screens/supervisorDrawing/myDrawingActivities.dart';
import 'package:bright_minds/screens/supervisorDrawing/supervisorKidsDrawings.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SupervisorDrawingHome extends StatelessWidget {
  const SupervisorDrawingHome({super.key});

  double _maxWidth(double w) {
    if (!kIsWeb) return w;
    if (w >= 1400) return 900;
    if (w >= 1100) return 820;
    if (w >= 900) return 760;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamYellow,
      appBar: AppBar(
        title: Text(
          "Drawing Activities",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.warmHoneyYellow,
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: _maxWidth(c.maxWidth)),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCard(
                      context,
                      title: "Search & Add Drawings",
                      subtitle: "Search coloring, tracing, color-by-number images",
                      icon: Icons.search,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchExternalImagesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      context,
                      title: "My Drawing Activities",
                      subtitle: "View drawings you added",
                      icon: Icons.collections,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyDrawingActivitiesScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      context,
                      title: "Kids Drawings Review",
                      subtitle: "Review kids' drawings, add comments & ratings",
                      icon: Icons.brush_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SupervisorKidsDrawingsScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.pastelYellow.withOpacity(0.9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.pastelYellow.withOpacity(0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 30, color: Colors.black),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}










/*import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/supervisorDrawing/searchExternalImages.dart';
import 'package:bright_minds/screens/supervisorDrawing/myDrawingActivities.dart';
import 'package:bright_minds/screens/supervisorDrawing/supervisorKidsDrawings.dart';


class SupervisorDrawingHome extends StatelessWidget {
  const SupervisorDrawingHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Drawing Activities",
          style: GoogleFonts.robotoSlab(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.warmHoneyYellow,
      ),
     body: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      _buildCard(
        context,
        title: "Search & Add Drawings",
        subtitle: "Search coloring, tracing, color-by-number images",
        icon: Icons.search,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchExternalImagesScreen(),
            ),
          );
        },
      ),
      const SizedBox(height: 16),

      _buildCard(
        context,
        title: "My Drawing Activities",
        subtitle: "View drawings you added",
        icon: Icons.collections,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyDrawingActivitiesScreen(),
            ),
          );
        },
      ),
      const SizedBox(height: 16),

      // 🔥 الكرت الجديد: Kids Drawings Review
      _buildCard(
        context,
        title: "Kids Drawings Review",
        subtitle: "Review kids' drawings, add comments & ratings",
        icon: Icons.brush_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const SupervisorKidsDrawingsScreen(),
            ),
          );
        },
      ),
    ],
  ),
),

    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.pastelYellow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.robotoSlab(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.robotoSlab(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/