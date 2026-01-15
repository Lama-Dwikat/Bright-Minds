import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/childDrawing/childDrawingCanvas.dart';
import 'package:bright_minds/screens/childDrawing/colorByNumberPlayScreen.dart';

class ChildDrawingActivitiesByTypeScreen extends StatelessWidget {
  final String type; // expected: coloring | tracing | colorByNumber | surpriseColor
  final String title;
  final List allActivities;

  const ChildDrawingActivitiesByTypeScreen({
    super.key,
    required this.type,
    required this.title,
    required this.allActivities,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = allActivities.where((a) {
      final t = (a["type"] ?? "").toString();
      return t == type;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgWarmPink,
        title: Text(
          title,
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w900),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Text(
                "No activities found",
                style: GoogleFonts.robotoSlab(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final activity = filtered[index];

                final imageUrl = (activity["imageUrl"] ?? "").toString();
                final activityTitle = (activity["title"] ?? "Activity").toString();
                final activityId = (activity["_id"] ?? "").toString();
                final actualType = (activity["type"] ?? "").toString();

                return InkWell(
                  onTap: () {
                    // ✅ decide by actual activity type (NOT the screen type)
                    if (actualType == "colorByNumber") {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ColorByNumberPlayScreen(activityId: activityId),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChildDrawingCanvasScreen(
                          activityId: activityId,
                          imageUrl: imageUrl,
                          title: activityTitle,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            imageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 180,
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activityTitle,
                                  style: GoogleFonts.robotoSlab(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
