import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';

class ParentKidWeeklyChallengesScreen extends StatefulWidget {
  final String kidId;
  final String kidName;

  const ParentKidWeeklyChallengesScreen({
    super.key,
    required this.kidId,
    required this.kidName,
  });

  @override
  State<ParentKidWeeklyChallengesScreen> createState() =>
      _ParentKidWeeklyChallengesScreenState();
}

class _ParentKidWeeklyChallengesScreenState
    extends State<ParentKidWeeklyChallengesScreen> {
  String? _token;

  bool _loading = true;

  DateTime _weekStart = _startOfWeekSaturday(DateTime.now());

  Map<String, dynamic>? _kid; // {name,email,_id}
  Map<String, dynamic>? _plan;
  List<Map<String, dynamic>> _progress = [];

  String getBackendUrl() {
    if (kIsWeb) 
    //return "http://192.168.1.63:3000";
    return "http://localhost:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  // Saturday start
  static DateTime _startOfWeekSaturday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final int saturday = DateTime.saturday; // 6
    int diff = d.weekday - saturday;
    if (diff < 0) diff += 7;
    final start = d.subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day);
  }

  List<String> _dayLabels() =>
      const ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];

  DateTime _dayDate(int i) => _weekStart.add(Duration(days: i));

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }
    await _fetchWeek();
  }

  Future<void> _fetchWeek() async {
    if (_token == null) return;

    setState(() => _loading = true);

    try {
      final weekStartStr = DateFormat("yyyy-MM-dd").format(_weekStart);

      final url = Uri.parse(
  "${getBackendUrl()}/api/challenges/parent/kid-week?kidId=${widget.kidId}&weekStart=$weekStartStr",
);


      final resp = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );
print("PARENT WEEK STATUS: ${resp.statusCode}");
print("PARENT WEEK BODY: ${resp.body}");

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        setState(() {
          _kid = data["kid"] is Map ? Map<String, dynamic>.from(data["kid"]) : null;
          _plan = data["plan"];
          _progress = (data["progress"] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      } else {
        setState(() {
          _kid = null;
          _plan = null;
          _progress = [];
        });

        final msg = _tryJson(resp.body)?["error"]?.toString();
        _snack(msg ?? "Failed (${resp.statusCode})");
      }
    } catch (e) {
      setState(() {
        _kid = null;
        _plan = null;
        _progress = [];
      });
      _snack("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Map<String, dynamic>? _tryJson(String s) {
    try {
      final x = jsonDecode(s);
      if (x is Map<String, dynamic>) return x;
      if (x is Map) return x.map((k, v) => MapEntry(k.toString(), v));
      return null;
    } catch (_) {
      return null;
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isDone(int dayIndex) {
    final p = _progress.where((x) => x["dayIndex"] == dayIndex).toList();
    if (p.isEmpty) return false;
    return p.first["done"] == true;
  }

  int _doneCount() {
    int c = 0;
    for (int i = 0; i < 7; i++) {
      if (_isDone(i)) c++;
    }
    return c;
  }

  // template for dayIndex from populated plan.days.templateId
  Map<String, dynamic>? _templateForDay(int dayIndex) {
    final days = _plan?["days"];
    if (days is! List) return null;

    final match = days.firstWhere(
      (d) => (d["dayIndex"] ?? -1) == dayIndex,
      orElse: () => null,
    );

    if (match == null) return null;

    final t = match["templateId"];
    if (t is Map) return Map<String, dynamic>.from(t);
    return null;
  }

  Color _catChipBg(String cat) {
    switch (cat) {
      case "religious":
        return AppColors.textSecondary.withOpacity(0.18);
      case "reading":
        return AppColors.peachPink.withOpacity(0.18);
      case "health":
        return Colors.green.withOpacity(0.14);
      case "sport":
        return Colors.blue.withOpacity(0.14);
      case "behavior":
        return Colors.orange.withOpacity(0.14);
      case "art":
        return Colors.pink.withOpacity(0.14);
      case "nature":
        return Colors.teal.withOpacity(0.14);
      default:
        return Colors.grey.withOpacity(0.14);
    }
  }

  Widget _categoryChip(String cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _catChipBg(cat),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        cat,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _kidHeaderCard() {
    final name = _kid?["name"]?.toString() ?? widget.kidName;
    final email = _kid?["email"]?.toString() ?? "";

    final done = _doneCount();
    final percent = done / 7.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.warmHoneyYellow.withOpacity(0.22),
                child: const Icon(Icons.child_care, color: AppColors.warmHoneyYellow),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (email.isNotEmpty)
                      Text(email, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text("Completed: $done / 7", style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.black.withOpacity(0.06),
              color: AppColors.warmHoneyYellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayProgressCard(int dayIndex) {
    final date = _dayDate(dayIndex);
    final label = _dayLabels()[dayIndex];

    final t = _templateForDay(dayIndex);

    final title = (t?["title"] ?? "No challenge").toString();
    final cat = (t?["category"] ?? "—").toString();
    final sticker = (t?["sticker"] ?? "🎯").toString();

    final done = _isDone(dayIndex);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? AppColors.creamYellow : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? AppColors.softSunYellow : Colors.black12,
          width: done ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softSunYellow.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(sticker, style: const TextStyle(fontSize: 24)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "$label • ${DateFormat("MM/dd").format(date)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (t != null) _categoryChip(cat),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? AppColors.warmHoneyYellow : Colors.black38,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      done ? "Done ✅" : "Not done yet",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: done ? AppColors.warmHoneyYellow : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWeek() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _weekStart,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2035, 12, 31),
      helpText: "Pick any date (week starts Saturday automatically)",
    );

    if (picked == null) return;

    setState(() {
      _weekStart = _startOfWeekSaturday(picked);
    });

    await _fetchWeek();
  }

  @override
  Widget build(BuildContext context) {
    final weekTitle =
        "Week: ${DateFormat("yyyy-MM-dd").format(_weekStart)} → ${DateFormat("yyyy-MM-dd").format(_weekStart.add(const Duration(days: 6)))}";

    return Scaffold(
      backgroundColor: AppColors.creamYellow,
      appBar: AppBar(
        backgroundColor: AppColors.softSunYellow,
        title: Text("${widget.kidName} • Progress"),
        actions: [
          IconButton(
            onPressed: _pickWeek,
            icon: const Icon(Icons.date_range),
            tooltip: "Change week",
          ),
          IconButton(
            onPressed: _fetchWeek,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // week title
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.10),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            weekTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.star, color: AppColors.warmHoneyYellow),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _kidHeaderCard(),

                  const SizedBox(height: 12),

                  Expanded(
                    child: _plan == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.softSunYellow.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(Icons.inbox_outlined, size: 38),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "No plan assigned for this week.",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Ask the supervisor to assign weekly challenges 😊",
                                  style: TextStyle(color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.warmHoneyYellow,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: _fetchWeek,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Refresh"),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: 7,
                            itemBuilder: (_, i) => _dayProgressCard(i),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
