import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentDrawingReportScreen extends StatefulWidget {
  const ParentDrawingReportScreen({super.key});

  @override
  State<ParentDrawingReportScreen> createState() =>
      _ParentDrawingReportScreenState();
}

class _ParentDrawingReportScreenState extends State<ParentDrawingReportScreen> {
  bool isLoading = true;
  List<dynamic> report = [];

  // default: last 7 days
  DateTime toDate = DateTime.now();
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 6));

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  String _fmtSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return "${s}s";
    return "${m}m ${s}s";
  }

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() => isLoading = true);

    final token = await _getToken();
    final fromStr = DateFormat("yyyy-MM-dd").format(fromDate);
    final toStr = DateFormat("yyyy-MM-dd").format(toDate);

    final url = Uri.parse(
      "${getBackendUrl()}/api/parent/drawing-report?from=$fromStr&to=$toStr",
    );

    final resp = await http.get(url, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    });

    if (!mounted) return;

    if (resp.statusCode == 200) {
      setState(() {
        report = jsonDecode(resp.body);
        isLoading = false;
      });
    } else {
      debugPrint("Report failed: ${resp.statusCode} ${resp.body}");
      setState(() => isLoading = false);
    }
  }

  // Build a simple histogram (bars) without external packages
  Widget _buildHistogram(List<dynamic> histogram) {
    if (histogram.isEmpty) {
      return const Text("No drawing time recorded in this period.");
    }

    // Normalize to last 7 days even if missing days
    final days = List.generate(7, (i) {
      final d = fromDate.add(Duration(days: i));
      return DateFormat("yyyy-MM-dd").format(d);
    });

    final Map<String, int> secByDay = {
      for (final d in days) d: 0,
    };

    for (final item in histogram) {
      final day = item["day"]?.toString();
      final sec = (item["totalSec"] ?? 0) as int;
      if (day != null && secByDay.containsKey(day)) {
        secByDay[day] = sec;
      }
    }

    final maxSec = secByDay.values.fold<int>(0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((d) {
            final sec = secByDay[d] ?? 0;
            final h = maxSec == 0 ? 0.0 : (sec / maxSec) * 120.0; // bar height
            final label = DateFormat("EEE").format(DateTime.parse(d)); // Mon/Tue...

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _fmtSec(sec),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 120,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.pink.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _openDrawingFullScreen(Map<String, dynamic> drawing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ParentDrawingFullScreen(
          title: drawing["activityTitle"] ?? "Drawing",
          imageBase64: drawing["imageBase64"],
          createdAt: drawing["createdAt"],
          durationSec: drawing["durationSec"] ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rangeText =
        "${DateFormat("d MMM").format(fromDate)} - ${DateFormat("d MMM").format(toDate)}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Drawing Report"),
        actions: [
          IconButton(
            onPressed: fetchReport,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : report.isEmpty
              ? const Center(child: Text("No kids found for this parent."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: report.length,
                  itemBuilder: (context, index) {
                    final kid = report[index];

                    final childName = kid["childName"] ?? "Child";
                    final ageGroup = kid["ageGroup"] ?? "";

                    final totalSec = kid["totalSec"] ?? 0;
                    final activitySec = kid["activitySec"] ?? 0;

                    final histogram = (kid["histogram"] as List?) ?? [];
                    final drawings = (kid["drawings"] as List?) ?? [];

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$childName ($ageGroup)",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text("Range: $rangeText"),
                            const SizedBox(height: 10),

                            // Totals
                            Row(
                              children: [
                                Expanded(
                                  child: _metricBox(
                                    "Total (Drawing)",
                                    _fmtSec(totalSec),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _metricBox(
                                    "Canvas Time",
                                    _fmtSec(activitySec),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Text(
                              "Daily Histogram (Canvas Time)",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildHistogram(histogram),

                            const SizedBox(height: 16),
                            const Text(
                              "Drawings",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            if (drawings.isEmpty)
                              const Text("No drawings in this period.")
                            else
                              ...drawings.take(10).map((d) {
                                final created = d["createdAt"] != null
                                    ? DateTime.tryParse(d["createdAt"])
                                    : null;

                                final createdText = created == null
                                    ? ""
                                    : DateFormat("d MMM yyyy, HH:mm")
                                        .format(created);

                                final sec = d["durationSec"] ?? 0;
                                final title = d["activityTitle"] ?? "Drawing";

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(title),
                                  subtitle: Text(
                                    "$createdText  •  ${_fmtSec(sec)}",
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openDrawingFullScreen(
                                      d as Map<String, dynamic>),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _metricBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ParentDrawingFullScreen extends StatelessWidget {
  final String title;
  final String imageBase64;
  final String? createdAt;
  final int durationSec;

  const _ParentDrawingFullScreen({
    required this.title,
    required this.imageBase64,
    required this.createdAt,
    required this.durationSec,
  });

  String _fmtSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    if (m == 0) return "${s}s";
    return "${m}m ${s}s";
  }

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(imageBase64);
    String subtitle = "Time: ${_fmtSec(durationSec)}";
    if (createdAt != null) {
      final dt = DateTime.tryParse(createdAt!);
      if (dt != null) {
        subtitle =
            "${DateFormat("d MMM yyyy, HH:mm").format(dt)}  •  ${_fmtSec(durationSec)}";
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 10),
          Expanded(
            child: InteractiveViewer(
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
