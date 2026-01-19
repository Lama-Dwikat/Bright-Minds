import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/childDrawing/childDrawingCanvas.dart';
import 'package:bright_minds/screens/childDrawing/colorByNumberPlayScreen.dart';

class ChildDrawingActivitiesByTypeScreen extends StatelessWidget {
  final String type; // coloring | tracing | colorByNumber | surpriseColor
  final String title;
  final List allActivities;

  const ChildDrawingActivitiesByTypeScreen({
    super.key,
    required this.type,
    required this.title,
    required this.allActivities,
  });

  List _filtered() {
    return allActivities.where((a) {
      final t = (a["type"] ?? "").toString();
      return t == type;
    }).toList();
  }

  // ===================== WEB RESPONSIVE HELPERS (UI ONLY) =====================
  bool _useGrid(double w) => w >= 900; // على الويب/الشاشات الكبيرة

  double _maxContentWidth(double w) {
    if (w >= 1200) return 1100;
    if (w >= 900) return 980;
    return w;
  }

  int _gridCountForWidth(double w) {
    if (w < 900) return 2;    // مش رح ننستخدمها غالباً
    if (w < 1200) return 3;
    return 4;
  }

  double _gridCardAspect(double w) {
    // كرت مناسب: صورة + عنوان
    if (w < 1200) return 0.85;
    return 0.9;
  }

  double _imageHeightList(double w) {
    if (w < 600) return 180;
    return 210;
  }
  // ===========================================================================

  void _openActivity(BuildContext context, Map activity) {
    final imageUrl = (activity["imageUrl"] ?? "").toString();
    final activityTitle = (activity["title"] ?? "Activity").toString();
    final activityId = (activity["_id"] ?? "").toString();
    final actualType = (activity["type"] ?? "").toString();

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
  }

  Widget _card(BuildContext context, Map activity,
      {required double imageHeight, bool isGrid = false}) {
    final imageUrl = (activity["imageUrl"] ?? "").toString();
    final activityTitle = (activity["title"] ?? "Activity").toString();

    return InkWell(
      onTap: () => _openActivity(context, activity),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.warmHoneyYellow,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: imageHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: imageHeight,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.robotoSlab(
                        fontSize: isGrid ? 15.5 : 16,
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
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.warmHoneyYellow,
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
          : LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final useGrid = _useGrid(w);

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxContentWidth(w)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: useGrid
                          // =================== WEB GRID ===================
                          ? GridView.builder(
                              itemCount: filtered.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _gridCountForWidth(w),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: _gridCardAspect(w),
                              ),
                              itemBuilder: (context, index) {
                                final activity = filtered[index] as Map;
                                return _card(
                                  context,
                                  activity,
                                  imageHeight: 150,
                                  isGrid: true,
                                );
                              },
                            )
                          // =================== MOBILE LIST ===================
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final activity = filtered[index] as Map;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _card(
                                    context,
                                    activity,
                                    imageHeight: _imageHeightList(w),
                                    isGrid: false,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}










/*import 'package:flutter/material.dart';
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
        backgroundColor: AppColors.warmHoneyYellow,
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
                      color: AppColors.warmHoneyYellow,
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
*/