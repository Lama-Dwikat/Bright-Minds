import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:bright_minds/screens/parentDrawing/parentDrawingReport.dart';
import 'package:bright_minds/screens/parentStory/parentStoryReport.dart';

import 'package:bright_minds/screens/parentDrawing/parentKidsDrawings.dart';

class HomeParent extends StatefulWidget {
  const HomeParent({super.key});

  @override
  State<HomeParent> createState() => _HomeParentState();
}

class _HomeParentState extends State<HomeParent> {
  String userId = "";
  List kids = [];

  Map<String, List> videoHistoryByKid = {};
  Map<String, List> dailyWatchByKid = {};

  DateTime? selectedDate; // <-- selected date for filtering

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) return;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    userId = decodedToken['id'];
    print("Parent userId = $userId");
  }

  Future<void> getKids() async {
    if (userId.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/users/getParentKids/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        kids = jsonDecode(response.body);
        setState(() {});
        print("Kids loaded: $kids");

        // Load each kid's history and daily watch
        for (var kid in kids) {
          final kidId = kid['_id'];
          await getKidHistory(kidId);
          await getKidDailyWatch(kidId);
        }
      } else {
        print("Failed to fetch kids");
      }
    } catch (err) {
      print("❌ Error fetching kids: $err");
    }
  }

  Future<void> getKidHistory(String kidId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List history = jsonDecode(response.body);
        videoHistoryByKid[kidId] = history;
        setState(() {});
      }
    } catch (err) {
      print("❌ Error fetching history: $err");
    }
  }

  Future<void> getKidDailyWatch(String kidId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/dailywatch/getUserWatchRecord/$kidId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List records = jsonDecode(response.body);

        dailyWatchByKid[kidId] = records.map((r) {
          return {
            "date": r['date'] ?? "",
            "dailyWatchMin": r['dailyWatchMin'] ?? 0,
            "limitWatchMin": r['limitWatchMin'] ?? 0,
          };
        }).toList();

        setState(() {});
      }
    } catch (err) {
      print("❌ Error fetching daily watch: $err");
    }
  }

  // --- Pick a date ---
  Future<void> pickDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2023),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // --- Check if history/daily watch matches selected date ---
  bool isSameDate(String dateStr) {
    if (selectedDate == null) return true;
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return date.year == selectedDate!.year &&
          date.month == selectedDate!.month &&
          date.day == selectedDate!.day;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    getUserId().then((_) => getKids());
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Home",
      child: Column(
        children: [
          // 🔹 زر يفتح شاشة رسومات الأطفال
        // 🎨 Drawing section cards (Report + Kids Drawings)
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
  child: Column(
    children: [
      _buildParentActionCard(
        context,
        title: "Drawing Report",
        subtitle: "Histogram by days + time per drawing",
        icon: Icons.bar_chart_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentDrawingReportScreen(),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      _buildParentActionCard(
        context,
        title: "Kids Drawings",
        subtitle: "View drawings submitted by your kids",
        icon: Icons.brush_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ParentKidsDrawingsScreen(),
            ),
          );
        },
      ),
      const SizedBox(height: 12),
_buildParentActionCard(
  context,
  title: "Story Writing Report",
  subtitle: "Histogram + stories + supervisor review",
  icon: Icons.menu_book_rounded,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ParentStoryTimeReportScreen(),
      ),
    );
  },
),
    ],
  ),
),

    _buildParentActionCard(
      context,
      title: "Video Watching Report",
      subtitle: "View watch history & limits",
      icon: Icons.video_library_rounded,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentVideoReportScreen(),
          ),
        );}
    )


        ],
      ),
    );
  }
}
Widget _buildParentActionCard(
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 236, 209, 145), // pink soft
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: Colors.black87),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    ),
  );
}


// class ParentVideoReportScreen extends StatefulWidget {
//   const ParentVideoReportScreen({super.key});

//   @override
//   State<ParentVideoReportScreen> createState() =>
//       _ParentVideoReportScreenState();
// }

// class _ParentVideoReportScreenState extends State<ParentVideoReportScreen> {
//   String parentId = "";

//   List kids = [];
//   Map<String, List> videoHistoryByKid = {};
//   Map<String, List> dailyWatchByKid = {};

//   DateTime? selectedDate;

//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.63:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     return "http://localhost:3000";
//   }

//   @override
//   void initState() {
//     super.initState();
//     loadParentAndKids();
//   }

//   Future<void> loadParentAndKids() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token");
//     if (token == null) return;

//     final decoded = JwtDecoder.decode(token);
//     parentId = decoded['id'];

//     await getKids();
//   }

//   Future<void> getKids() async {
//     final res = await http.get(
//       Uri.parse('${getBackendUrl()}/api/users/getParentKids/$parentId'),
//     );

//     if (res.statusCode == 200) {
//       kids = jsonDecode(res.body);
//       setState(() {});

//       for (var kid in kids) {
//         final id = kid['_id'];
//         await getKidHistory(id);
//         await getKidDailyWatch(id);
//       }
//     }
//   }

//   Future<void> getKidHistory(String kidId) async {
//     final res = await http.get(
//       Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
//     );

//     if (res.statusCode == 200) {
//       videoHistoryByKid[kidId] = jsonDecode(res.body);
//       setState(() {});
//     }
//   }

//   Future<void> getKidDailyWatch(String kidId) async {
//     final res = await http.get(
//       Uri.parse('${getBackendUrl()}/api/dailywatch/getUserWatchRecord/$kidId'),
//     );

//     if (res.statusCode == 200) {
//       dailyWatchByKid[kidId] = jsonDecode(res.body);
//       setState(() {});
//     }
//   }

//   bool isSameDate(String dateStr) {
//     if (selectedDate == null) return true;
//     final d = DateTime.parse(dateStr).toLocal();
//     return d.year == selectedDate!.year &&
//         d.month == selectedDate!.month &&
//         d.day == selectedDate!.day;
//   }

//   Future<void> pickDate() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2023),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null) {
//       setState(() => selectedDate = picked);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return HomePage(
//       title: "Video Report",
//       child: Column(
//         children: [
//           Row(
//             children: [
//               ElevatedButton(
//                 onPressed: pickDate,
//                 child: Text(
//                   selectedDate == null
//                       ? "Select date"
//                       : DateFormat('yyyy-MM-dd').format(selectedDate!),
//                 ),
//               ),
//               if (selectedDate != null)
//                 IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () => setState(() => selectedDate = null),
//                 ),
//             ],
//           ),

//           Expanded(
//             child: kids.isEmpty
//                 ? const Center(child: Text("No kids found"))
//                 : ListView.builder(
//                     itemCount: kids.length,
//                     itemBuilder: (context, index) {
//                       final kid = kids[index];
//                       final id = kid['_id'];

//                       final history =
//                           videoHistoryByKid[id]?.where((h) {
//                         return h['watchedAt'] != null &&
//                             isSameDate(h['watchedAt']);
//                       }).toList() ??
//                               [];

//                       return ExpansionTile(
//                         title: Text(kid['name']),
//                         children: history.isEmpty
//                             ? [
//                                 const Padding(
//                                   padding: EdgeInsets.all(8),
//                                   child: Text("No video activity"),
//                                 )
//                               ]
//                             : history.map((h) {
//                                 final video = h['videoId'];
//                                 return ListTile(
//                                   leading: video?['thumbnailUrl'] != null
//                                       ? Image.network(
//                                           video['thumbnailUrl'],
//                                           width: 60,
//                                           fit: BoxFit.cover,
//                                         )
//                                       : const Icon(Icons.video_library),
//                                   title: Text(video?['title'] ?? ""),
//                                   subtitle: Text(
//                                     "Watched: ${DateFormat('HH:mm').format(DateTime.parse(h['watchedAt']).toLocal())}",
//                                   ),
//                                 );
//                               }).toList(),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
class ParentVideoReportScreen extends StatefulWidget {
  const ParentVideoReportScreen({super.key});

  @override
  State<ParentVideoReportScreen> createState() =>
      _ParentVideoReportScreenState();
}

class _ParentVideoReportScreenState extends State<ParentVideoReportScreen> {
  String parentId = "";
  List kids = [];

  Map<String, List> videoHistoryByKid = {};
  DateTime? selectedDate;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    loadParentAndKids();
  }

  Future<void> loadParentAndKids() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;

    parentId = JwtDecoder.decode(token)['id'];
    await getKids();
  }

  Future<void> getKids() async {
    final res = await http.get(
      Uri.parse('${getBackendUrl()}/api/users/getParentKids/$parentId'),
    );

    if (res.statusCode == 200) {
      kids = jsonDecode(res.body);
      setState(() {});
      for (var kid in kids) {
        await getKidHistory(kid['_id']);
      }
    }
  }

  Future<void> getKidHistory(String kidId) async {
    final res = await http.get(
      Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
    );

    if (res.statusCode == 200) {
      videoHistoryByKid[kidId] = jsonDecode(res.body);
      setState(() {});
    }
  }

  bool isSameDate(String dateStr) {
    if (selectedDate == null) return true;
    final d = DateTime.parse(dateStr).toLocal();
    return d.year == selectedDate!.year &&
        d.month == selectedDate!.month &&
        d.day == selectedDate!.day;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  /// 🎯 VIDEO CATEGORY HISTOGRAM
  Map<String, int> buildCategoryHistogram(List history) {
    final Map<String, int> map = {};
    for (var h in history) {
      final category = h['videoId']?['category'] ?? 'Other';
      map[category] = (map[category] ?? 0) + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: const Text("Video Watching Report"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// 📅 DATE PICKER
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate == null
                        ? "Select date"
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                  onPressed: pickDate,
                ),
                if (selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => selectedDate = null),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: kids.isEmpty
                  ? const Center(child: Text("No kids found"))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        childAspectRatio: isWide ? 2.4 : 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: kids.length,
                      itemBuilder: (_, index) {
                        final kid = kids[index];
                        final history = (videoHistoryByKid[kid['_id']] ?? [])
                            .where((h) =>
                                h['watchedAt'] != null &&
                                isSameDate(h['watchedAt']))
                            .toList();

                        final histogram =
                            buildCategoryHistogram(history);

                        return _buildKidCard(
                          kid['name'],
                          history.length,
                          histogram,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🧒 KID CARD + HISTOGRAM
  Widget _buildKidCard(
    String name,
    int totalVideos,
    Map<String, int> histogram,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Watched videos: $totalVideos",
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 12),

          /// 📊 HISTOGRAM
          Expanded(
            child: histogram.isEmpty
                ? const Center(child: Text("No video activity"))
                : Column(
                    children: histogram.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(e.key),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: e.value / totalVideos,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text("${e.value}"),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
