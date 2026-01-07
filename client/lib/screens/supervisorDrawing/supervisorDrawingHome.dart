import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/supervisorDrawing/searchExternalImages.dart';
import 'package:bright_minds/screens/supervisorDrawing/myDrawingActivities.dart';


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
        backgroundColor: AppColors.bgWarmPink,
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
          color: AppColors.bgWarmPinkLight,
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
