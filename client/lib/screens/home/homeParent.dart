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
import 'package:syncfusion_flutter_charts/charts.dart';



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

    if (kIsWeb) 
    //return "http://192.168.1.63:3000";
    return "http://localhost:3000";

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

 const SizedBox(height: 12),
_buildParentActionCard(

      context,
      title: "Video Watching Report",
      subtitle: "View watch history & limits",
      icon: Icons.video_library_rounded,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ParentVideoReport(),
          ),
        );}
    ),

 const SizedBox(height: 12),

_buildParentActionCard(
  context,
  title: "Game Report",
  subtitle: "Daily time spent playing games",
  icon: Icons.videogame_asset_rounded,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ParentGameReportScreen(),
      ),
    );
  },
),
    ],
  ),
),

    
 

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




class ParentVideoReport extends StatefulWidget {
  const ParentVideoReport({super.key});

  @override
  State<ParentVideoReport> createState() => _ParentVideoReportState();
}

class _ParentVideoReportState extends State<ParentVideoReport> {
  String parentId = "";
  List kids = [];
  Map<String, List> videoHistoryByKid = {};
  Map<String, List> dailyWatchByKid = {};

  @override
  void initState() {
    super.initState();
    loadParentAndKids();
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }


  Future<void> loadParentAndKids() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;
    parentId = JwtDecoder.decode(token)['id'];
    await getKids();
  }

  Future<void> getKids() async {
    final res = await http.get(Uri.parse('${getBackendUrl()}/api/users/getParentKids/$parentId'));
    if (res.statusCode == 200) {
      kids = jsonDecode(res.body);
      setState(() {});
      for (var kid in kids) {
        await getKidHistory(kid['_id']);
        await getKidDailyWatch(kid['_id']);
      }
    }
  }

  Future<void> getKidHistory(String kidId) async {
    final res = await http.get(Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'));
    if (res.statusCode == 200) {
      videoHistoryByKid[kidId] = jsonDecode(res.body);
      setState(() {});
    }
  }

  Future<void> getKidDailyWatch(String kidId) async {
    final res = await http.get(Uri.parse('${getBackendUrl()}/api/dailywatch/getUserWatchRecord/$kidId'));
    if (res.statusCode == 200) {
      List records = jsonDecode(res.body);
      dailyWatchByKid[kidId] = records.map((r) => {
        "date": r['date'] ?? "",
        "dailyWatchMin": r['dailyWatchMin'] ?? 0,
        "limitWatchMin": r['limitWatchMin'] ?? 0,
      }).toList();
      setState(() {});
    }
  }
String formatDay(String isoDate) {
  final d = DateTime.parse(isoDate).toLocal();
  return DateFormat('EEE\ndd/MM').format(d);
}


String formatDayMonth(String isoDate) {
  final d = DateTime.parse(isoDate).toLocal();
  return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";
}




Widget buildDailyHistogram({
  required String title,
  required List records,
  required String valueKey, // dailyPlayMin OR dailyWatchMin
  required Color barColor,
}) {
  final List<Map<String, dynamic>> chartData = records.map((r) {
    return {
      'label': formatDayMonth(r['date']),
      'value': (r[valueKey] ?? 0).toDouble(),
    };
  }).toList();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8),
      ],
    ),
    child: SfCartesianChart(
      title: ChartTitle(
        text: title,
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          color: Colors.grey.shade300,
          width: 1,
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: Colors.black87,
        textStyle: const TextStyle(color: Colors.white),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: chartData,
          xValueMapper: (d, _) => d['label'],
          yValueMapper: (d, _) => d['value'],
          borderRadius: BorderRadius.circular(8),
          pointColorMapper: (_, __) => barColor,
          width: 0.6,
          spacing: 0.2,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}


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
    return Scaffold(
      appBar: AppBar(title: const Text("Video Report")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: kids.isEmpty
            ? const Center(child: Text("No kids found"))
            : ListView.builder(
                itemCount: kids.length,
                itemBuilder: (_, index) {
                  final kid = kids[index];
                  final history = videoHistoryByKid[kid['_id']] ?? [];
                  final histogram = buildCategoryHistogram(history);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
 Text("Kid Name: ${kid['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
const SizedBox(height: 12),

// 📊 Category histogram
Text("Category Histogram", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
const SizedBox(height: 8),
...histogram.entries.map((e) {
  return Row(
    children: [
      SizedBox(width: 100, child: Text(e.key)),
      Expanded(
        child: LinearProgressIndicator(
          value: e.value / history.length,
          minHeight: 10,
          backgroundColor: Colors.grey[200],
          color: const Color.fromARGB(255, 232, 202, 68), // ✅ same color as bars
        ),
      ),
      const SizedBox(width: 8),
      Text("${e.value}"),
    ],
  );
}).toList(),
const SizedBox(height: 16),

// 📊 Daily watch histogram
Text("Daily Watch Histogram", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
const SizedBox(height: 8),
dailyWatchByKid[kid['_id']] == null || dailyWatchByKid[kid['_id']]!.isEmpty
    ? const Text("No watch data")
    : buildDailyHistogram(
        title: "Daily Watch Time (minutes)",
        records: dailyWatchByKid[kid['_id']] ?? [],
        valueKey: "dailyWatchMin",
        barColor: const Color.fromARGB(255, 232, 202, 68),
      ),
const SizedBox(height: 12),




                          const SizedBox(height: 12),
                          // List of videos
                     ExpansionTile(
  title: const Text(
    "Video History",
    style: TextStyle(fontWeight: FontWeight.bold),
  ),
  children: [
    SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        itemBuilder: (_, i) {
          final video = history[i]['videoId'];
          return Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: video?['thumbnailUrl'] != null
                      ? Image.network(
                          video['thumbnailUrl'],
                          height: 80,
                          width: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.video_library),
                        ),
                ),
                const SizedBox(height: 6),
                Text(
                  video?['title'] ?? "",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ],
),

                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}


class ParentGameReportScreen extends StatefulWidget {
  const ParentGameReportScreen({super.key});

  @override
  State<ParentGameReportScreen> createState() => _ParentGameReportScreenState();
}

class _ParentGameReportScreenState extends State<ParentGameReportScreen> {
  String parentId = "";
  List kids = [];
  Map<String, List> dailyGameTimeByKid = {};

  @override
  void initState() {
    super.initState();
    loadParentAndKids();
  }
  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  Future<void> loadParentAndKids() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;
    parentId = JwtDecoder.decode(token)['id'];
    await getKids();
  }

  Future<void> getKids() async {
    final res = await http.get(Uri.parse('${getBackendUrl()}/api/users/getParentKids/$parentId'));
    if (res.statusCode == 200) {
      kids = jsonDecode(res.body);
      setState(() {});
      for (var kid in kids) await getKidGameData(kid['_id']);
    }
  }

Future<void> getKidGameData(String kidId) async {
  final res = await http.get(Uri.parse('${getBackendUrl()}/api/dailywatch/getUserWatchRecord/$kidId'));
  if (res.statusCode == 200) {
    List records = jsonDecode(res.body);
    dailyGameTimeByKid[kidId] = records.map((r) => {
      "date": r['date'] ?? "",
      "playMin": r['dailyPlayMin'] ?? 0,  // <-- use correct field!
    }).toList();
    setState(() {});
  }
}
String formatDay(String isoDate) {
  final d = DateTime.parse(isoDate).toLocal();
  return DateFormat('EEE\ndd/MM').format(d);
}
String formatDayMonth(String isoDate) {
  final d = DateTime.parse(isoDate).toLocal();
  return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";
}


Widget buildDailyHistogram({
  required String title,
  required List records,
  required String valueKey, // dailyPlayMin OR dailyWatchMin
  required Color barColor,
}) {
  final List<Map<String, dynamic>> chartData = records.map((r) {
    return {
      'label': formatDayMonth(r['date']),
      'value': (r[valueKey] ?? 0).toDouble(),
    };
  }).toList();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8),
      ],
    ),
    child: SfCartesianChart(
      title: ChartTitle(
        text: title,
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(fontSize: 12),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          color: Colors.grey.shade300,
          width: 1,
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.black54),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: Colors.black87,
        textStyle: const TextStyle(color: Colors.white),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: chartData,
          xValueMapper: (d, _) => d['label'],
          yValueMapper: (d, _) => d['value'],
          borderRadius: BorderRadius.circular(8),
          pointColorMapper: (_, __) => barColor,
          width: 0.6,
          spacing: 0.2,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Game Report")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: kids.isEmpty
            ? const Center(child: Text("No kids found"))
            : ListView.builder(
                itemCount: kids.length,
                itemBuilder: (_, index) {
                  final kid = kids[index];
                  final daily = dailyGameTimeByKid[kid['_id']] ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                       Text("Kid Name: ${kid['name']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
const SizedBox(height: 8),
daily.isEmpty
    ? const Text("No game data")
    : buildDailyHistogram(
        title: "Daily Game Time (minutes)",
        records: dailyGameTimeByKid[kid['_id']] ?? [],
        valueKey: "playMin",
        barColor: const Color.fromARGB(255, 222, 176, 38),
      ),





                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
