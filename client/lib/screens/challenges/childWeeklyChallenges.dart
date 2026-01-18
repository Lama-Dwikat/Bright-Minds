import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';

class ChildWeeklyChallengesScreen extends StatefulWidget {
  const ChildWeeklyChallengesScreen({super.key});

  @override
  State<ChildWeeklyChallengesScreen> createState() =>
      _ChildWeeklyChallengesScreenState();
}

class _ChildWeeklyChallengesScreenState extends State<ChildWeeklyChallengesScreen> {
  String? _token;
  String? _childId;

  bool _loading = true;
  bool _savingDone = false;

  DateTime _weekStart = _startOfWeekSaturday(DateTime.now());

  // backend response
  Map<String, dynamic>? _plan; // weekly plan doc
  List<Map<String, dynamic>> _progress = []; // [{dayIndex, done, doneAt}, ...]

  // ✅ Web-safe backendUrl (بدون dart:io / Platform)
  String getBackendUrl() {
    if (kIsWeb) {
      // return "http://192.168.1.63:3000";
      return "http://localhost:3000";
    }
    // موبايل/ايموليتر:
    return "http://10.0.2.2:3000";
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ✅ forbid marking future days
  bool canMarkDone(DateTime dayDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final d = DateTime(dayDate.year, dayDate.month, dayDate.day);
    return !d.isAfter(today); // today or past
  }

  static DateTime _startOfWeekSaturday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final int saturday = DateTime.saturday; // 6
    int diff = d.weekday - saturday;
    if (diff < 0) diff += 7;
    final start = d.subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day);
  }

  List<String> _dayLabels() => const ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];
  DateTime _dayDate(int i) => _weekStart.add(Duration(days: i));

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final decoded = JwtDecoder.decode(_token!);
    _childId = decoded["id"]?.toString();

    await _fetchWeek();
  }

  Future<void> _fetchWeek() async {
    if (_token == null) return;
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final weekStartStr = DateFormat("yyyy-MM-dd").format(_weekStart);
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/challenges/child/current-week?weekStart=$weekStartStr"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _plan = data["plan"];
          _progress = (data["progress"] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      } else {
        setState(() {
          _plan = null;
          _progress = [];
        });
        _snack("Failed (${resp.statusCode})");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plan = null;
        _progress = [];
      });
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isDone(int dayIndex) {
    final p = _progress.where((x) => x["dayIndex"] == dayIndex).toList();
    if (p.isEmpty) return false;
    return p.first["done"] == true;
  }

  Future<void> _markDone(int dayIndex) async {
    if (_token == null) return;
    if (_plan == null) return;

    final planId = _plan?["_id"]?.toString();
    if (planId == null || planId.isEmpty) return;

    if (!mounted) return;
    setState(() => _savingDone = true);

    try {
      final resp = await http.post(
        Uri.parse("${getBackendUrl()}/api/challenges/mark-done"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({
          "planId": planId,
          "dayIndex": dayIndex,
        }),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final updated = Map<String, dynamic>.from(jsonDecode(resp.body));
        setState(() {
          _progress.removeWhere((x) => x["dayIndex"] == dayIndex);
          _progress.add(updated);
        });
        _snack("Great job! ✅");
      } else {
        final data = _tryJson(resp.body);
        _snack(data?["error"]?.toString() ?? "Failed (${resp.statusCode})");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      if (mounted) setState(() => _savingDone = false);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // returns Map for dayIndex: {title, category, sticker}
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

  int _doneCount() {
    int c = 0;
    for (int i = 0; i < 7; i++) {
      if (_isDone(i)) c++;
    }
    return c;
  }

  Color _catChipBg(String cat) {
    switch (cat) {
      case "religious":
        return const Color.fromARGB(255, 240, 199, 152).withOpacity(0.18);
      case "reading":
        return const Color.fromARGB(255, 244, 223, 191).withOpacity(0.18);
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

  Widget _progressHeader() {
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
          const Text(
            "My Weekly To-Do",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Done: $done / 7",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.black.withOpacity(0.06),
              color: const Color.fromARGB(255, 243, 212, 192),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTodoCard(int dayIndex) {
    final date = _dayDate(dayIndex);
    final label = _dayLabels()[dayIndex];
    final t = _templateForDay(dayIndex);

    final title = (t?["title"] ?? "No challenge").toString();
    final cat = (t?["category"] ?? "—").toString();
    final sticker = (t?["sticker"] ?? "🎯").toString();

    final done = _isDone(dayIndex);

    // lock if future
    final allowed = canMarkDone(date);
    final locked = !allowed;

    // only allow tap if: has template + not done + not saving + not locked
    final canTap = (t != null) && !done && !_savingDone && !locked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? AppColors.gamesButton : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? const Color.fromARGB(255, 236, 216, 190) : Colors.black12,
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
              color: const Color.fromARGB(255, 241, 223, 197).withOpacity(0.22),
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
                    const SizedBox(width: 8),
                    if (locked)
                      const Icon(Icons.lock, size: 18, color: Colors.black45),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (done) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Completed ✅",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ] else if (locked) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Locked (not today yet) 🔒",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: canTap ? () => _markDone(dayIndex) : null,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: canTap || done ? 1.0 : 0.45,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.drawingButton.withOpacity(0.18)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: done
                    ? const Icon(Icons.check_circle,
                        color: Color.fromARGB(255, 249, 224, 190))
                    : locked
                        ? const Icon(Icons.lock_outline, color: Colors.black45)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.black45),
              ),
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

  // ✅ web center + max width
  double _maxWidth(double w) {
    if (!kIsWeb) return w;
    if (w >= 1200) return 780;
    if (w >= 900) return 720;
    return w;
  }

  @override
  Widget build(BuildContext context) {
    final weekTitle =
        "Week: ${DateFormat("yyyy-MM-dd").format(_weekStart)} → ${DateFormat("yyyy-MM-dd").format(_weekStart.add(const Duration(days: 6)))}";

    return Scaffold(
      backgroundColor: AppColors.badgesButton,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 239, 214, 186),
        title: const Text("My Challenges"),
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
          : LayoutBuilder(
              builder: (context, c) {
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _maxWidth(c.maxWidth)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
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
                                const Icon(Icons.star,
                                    color: Color.fromARGB(255, 245, 221, 188)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _progressHeader(),
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
                                            color: const Color.fromARGB(255, 233, 204, 162)
                                                .withOpacity(0.22),
                                            borderRadius: BorderRadius.circular(22),
                                          ),
                                          child: const Icon(Icons.inbox_outlined, size: 38),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "No challenges assigned for this week.",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        const Text(
                                          "Ask your supervisor to assign a weekly plan 😊",
                                          style: TextStyle(color: Colors.black54),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromARGB(255, 249, 219, 176),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(14)),
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
                                    itemBuilder: (_, i) => _dayTodoCard(i),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}










/*import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';

class ChildWeeklyChallengesScreen extends StatefulWidget {
  const ChildWeeklyChallengesScreen({super.key});

  @override
  State<ChildWeeklyChallengesScreen> createState() =>
      _ChildWeeklyChallengesScreenState();
}

class _ChildWeeklyChallengesScreenState extends State<ChildWeeklyChallengesScreen> {
  String? _token;
  String? _childId;

  bool _loading = true;
  bool _savingDone = false;

  DateTime _weekStart = _startOfWeekSaturday(DateTime.now());

  // backend response
  Map<String, dynamic>? _plan; // weekly plan doc
  List<Map<String, dynamic>> _progress = []; // [{dayIndex, done, doneAt}, ...]

  String getBackendUrl() {
    if (kIsWeb) 
    //return "http://192.168.1.63:3000";
    return "http://localhost:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ✅ NEW: forbid marking future days
  bool canMarkDone(DateTime dayDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final d = DateTime(dayDate.year, dayDate.month, dayDate.day);
    return !d.isAfter(today); // today or past
  }

  static DateTime _startOfWeekSaturday(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final int saturday = DateTime.saturday; // 6
    int diff = d.weekday - saturday;
    if (diff < 0) diff += 7;
    final start = d.subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day);
  }

  List<String> _dayLabels() => const ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"];
  DateTime _dayDate(int i) => _weekStart.add(Duration(days: i));

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token == null) {
      setState(() => _loading = false);
      return;
    }

    final decoded = JwtDecoder.decode(_token!);
    _childId = decoded["id"]?.toString();

    await _fetchWeek();
  }

  Future<void> _fetchWeek() async {
    if (_token == null) return;
    setState(() => _loading = true);

    try {
      final weekStartStr = DateFormat("yyyy-MM-dd").format(_weekStart);
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/challenges/child/current-week?weekStart=$weekStartStr"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _plan = data["plan"];
          _progress = (data["progress"] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      } else {
        setState(() {
          _plan = null;
          _progress = [];
        });
        _snack("Failed (${resp.statusCode})");
      }
    } catch (e) {
      setState(() {
        _plan = null;
        _progress = [];
      });
      _snack("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isDone(int dayIndex) {
    final p = _progress.where((x) => x["dayIndex"] == dayIndex).toList();
    if (p.isEmpty) return false;
    return p.first["done"] == true;
  }

  Future<void> _markDone(int dayIndex) async {
    if (_token == null) return;
    if (_plan == null) return;

    final planId = _plan?["_id"]?.toString();
    if (planId == null || planId.isEmpty) return;

    setState(() => _savingDone = true);

    try {
      final resp = await http.post(
        Uri.parse("${getBackendUrl()}/api/challenges/mark-done"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({
          "planId": planId,
          "dayIndex": dayIndex,
        }),
      );

      if (resp.statusCode == 200) {
        final updated = Map<String, dynamic>.from(jsonDecode(resp.body));
        setState(() {
          _progress.removeWhere((x) => x["dayIndex"] == dayIndex);
          _progress.add(updated);
        });
        _snack("Great job! ✅");
      } else {
        final data = _tryJson(resp.body);
        _snack(data?["error"]?.toString() ?? "Failed (${resp.statusCode})");
      }
    } catch (e) {
      _snack("Error: $e");
    } finally {
      setState(() => _savingDone = false);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // returns Map for dayIndex: {title, category, sticker}
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

  int _doneCount() {
    int c = 0;
    for (int i = 0; i < 7; i++) {
      if (_isDone(i)) c++;
    }
    return c;
  }

  Color _catChipBg(String cat) {
    switch (cat) {
      case "religious":
        return const Color.fromARGB(255, 240, 199, 152).withOpacity(0.18);
      case "reading":
        return const Color.fromARGB(255, 244, 223, 191).withOpacity(0.18);
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

  Widget _progressHeader() {
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
          const Text(
            "My Weekly To-Do",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Done: $done / 7",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              backgroundColor: Colors.black.withOpacity(0.06),
              color: const Color.fromARGB(255, 243, 212, 192),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayTodoCard(int dayIndex) {
    final date = _dayDate(dayIndex);
    final label = _dayLabels()[dayIndex];
    final t = _templateForDay(dayIndex);

    final title = (t?["title"] ?? "No challenge").toString();
    final cat = (t?["category"] ?? "—").toString();
    final sticker = (t?["sticker"] ?? "🎯").toString();

    final done = _isDone(dayIndex);

    // ✅ NEW: lock if future
    final allowed = canMarkDone(date);
    final locked = !allowed;

    // ✅ only allow tap if: has template + not done + not saving + not locked
    final canTap = (t != null) && !done && !_savingDone && !locked;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? AppColors.gamesButton : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? const Color.fromARGB(255, 236, 216, 190) : Colors.black12,
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
          // sticker bubble
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 241, 223, 197).withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(sticker, style: const TextStyle(fontSize: 24)),
          ),

          const SizedBox(width: 12),

          // title + chips
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
                    const SizedBox(width: 8),

                    // ✅ show lock icon for future day
                    if (locked)
                      const Icon(Icons.lock, size: 18, color: Colors.black45),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                // ✅ show status text
                if (done) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Completed ✅",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ] else if (locked) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Locked (not today yet) 🔒",
                    style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 10),

          // checkbox button
          InkWell(
            onTap: canTap ? () => _markDone(dayIndex) : null,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: canTap || done ? 1.0 : 0.45, // ✅ dim when locked/disabled
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.drawingButton.withOpacity(0.18)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: done
                    ? const Icon(Icons.check_circle, color: Color.fromARGB(255, 249, 224, 190))
                    : locked
                        ? const Icon(Icons.lock_outline, color: Colors.black45)
                        : const Icon(Icons.radio_button_unchecked, color: Colors.black45),
              ),
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
      backgroundColor: AppColors.badgesButton,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 239, 214, 186),
        title: const Text("My Challenges"),
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
                        const Icon(Icons.star, color: Color.fromARGB(255, 245, 221, 188)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _progressHeader(),

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
                                    color: const Color.fromARGB(255, 233, 204, 162).withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: const Icon(Icons.inbox_outlined, size: 38),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "No challenges assigned for this week.",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Ask your supervisor to assign a weekly plan 😊",
                                  style: TextStyle(color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 249, 219, 176),
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
                            itemBuilder: (_, i) => _dayTodoCard(i),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
*/