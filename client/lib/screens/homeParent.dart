
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

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
          // --- Date picker button ---
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => pickDate(context),
                  child: Text(selectedDate != null
                      ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                      : "Select date"),
                ),
                if (selectedDate != null)
                  IconButton(
                      onPressed: () {
                        setState(() {
                          selectedDate = null; // clear filter
                        });
                      },
                      icon: const Icon(Icons.clear)),
              ],
            ),
          ),
          Expanded(
            child: kids.isEmpty
                ? const Center(child: Text("No kids found"))
                : ListView.builder(
                    itemCount: kids.length,
                    itemBuilder: (context, index) {
                      final kid = kids[index];
                      final kidId = kid['_id'];
                      final kidHistory = videoHistoryByKid[kidId] ?? [];
                      final kidDailyWatch = dailyWatchByKid[kidId] ?? [];

                      // Filter by selected date
                      final filteredHistory = kidHistory
                          .where((h) =>
                              h['watchedAt'] != null &&
                              isSameDate(h['watchedAt']))
                          .toList();

                      final filteredDailyWatch = kidDailyWatch
                          .where((r) =>
                              r['date'] != null &&
                              isSameDate(r['date']))
                          .toList();

                      return ExpansionTile(
                        title: Text(kid['name'] ?? "Unknown Kid"),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Video History",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (filteredHistory.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("No history for this date"),
                            ),
                          ...filteredHistory.map((historyItem) {
                            final video = historyItem['videoId'];
                            return ListTile(
                              leading: (video != null &&
                                      video['thumbnailUrl'] != null)
                                  ? Image.network(
                                      video['thumbnailUrl'],
                                      width: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.video_library),
                              title: Text(video?['title'] ?? "Unknown"),
                              subtitle: Text(
                                  "Watched at: ${historyItem['watchedAt'] != null ? DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(historyItem['watchedAt']).toLocal()) : "Unknown"}\nDuration: ${(historyItem['durationWatched'] ?? 0).toStringAsFixed(2)} min"),
                            );
                          }).toList(),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Daily Watch Records",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (filteredDailyWatch.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("No daily watch for this date"),
                            ),
                          ...filteredDailyWatch.map((record) => ListTile(
                                title: Text(
                                    "Date: ${record['date'] != "" ? DateFormat('yyyy-MM-dd').format(DateTime.parse(record['date']).toLocal()) : "Unknown"}"),
                                subtitle: Text(
                                    "Watched: ${(record['dailyWatchMin'] ?? 0).toStringAsFixed(2)} min / Limit: ${record['limitWatchMin'] ?? 0} min"),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
