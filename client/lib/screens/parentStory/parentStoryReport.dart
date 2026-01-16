import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/storyTimeApi.dart';

class ParentStoryTimeReportScreen extends StatefulWidget {
  const ParentStoryTimeReportScreen({super.key});

  @override
  State<ParentStoryTimeReportScreen> createState() => _ParentStoryTimeReportScreenState();
}

class _ParentStoryTimeReportScreenState extends State<ParentStoryTimeReportScreen> {
  final _api = StoryTimeApi();

  bool _loading = true;
  String? _error;

  int _rangeDays = 7;

  List<Map<String, dynamic>> _histogram = []; // [{date, minutes}]
  List<Map<String, dynamic>> _stories = [];   // [{title,totalMinutes,latestReview...}]

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null) {
        setState(() {
          _loading = false;
          _error = "No token found. Please login again.";
        });
        return;
      }

      final report = await _api.getParentStoryTimeReport(token: token, rangeDays: _rangeDays);

      final hist = (report["histogram"] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final stories = (report["stories"] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _histogram = hist;
        _stories = stories;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ---------- Helpers ----------
  String _formatDateLabel(String yyyyMMdd) {
    try {
      final dt = DateTime.parse(yyyyMMdd);
      return DateFormat("MM/dd").format(dt);
    } catch (_) {
      return yyyyMMdd;
    }
  }

  double _maxMinutes() {
    double maxV = 0;
    for (final h in _histogram) {
      final m = (h["minutes"] ?? 0).toDouble();
      if (m > maxV) maxV = m;
    }
    return maxV == 0 ? 10 : maxV;
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "approved":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      case "published":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE0E0),
        elevation: 0,
        title: const Text("Story Writing Report"),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _RangeSelector(
                          value: _rangeDays,
                          onChanged: (v) async {
                            setState(() => _rangeDays = v);
                            await _load();
                          },
                        ),
                        const SizedBox(height: 12),

                        _SectionCard(
                          title: "Histogram (minutes per day)",
                          child: _histogram.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text("No story writing time in this range."),
                                )
                              : SizedBox(
                                  height: 240,
                                  child: _HistogramChart(
                                    histogram: _histogram,
                                    maxY: _maxMinutes(),
                                    labelBuilder: _formatDateLabel,
                                  ),
                                ),
                        ),

                        const SizedBox(height: 12),

                        _SectionCard(
                          title: "Stories Summary",
                          child: _stories.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text("No stories found in this range."),
                                )
                              : Column(
                                  children: _stories.map((s) {
                                    final title = (s["title"] ?? "Untitled").toString();
                                    final mins = (s["totalMinutes"] ?? 0).toString();
                                    final status = s["status"]?.toString();

                                    final latestReview = s["latestReview"];
                                    String reviewText = "No supervisor review yet";
                                    String? reviewDate;

                                    if (latestReview != null && latestReview is Map) {
                                      final rating = latestReview["rating"];
                                      final comment = latestReview["comment"];
                                      final supName = latestReview["supervisorName"];
                                      final createdAt = latestReview["createdAt"];

                                      final stars = (rating == null) ? "" : "⭐" * (rating as int);
                                      reviewText = "${supName ?? "Supervisor"}: $stars ${comment ?? ""}".trim();

                                      if (createdAt != null) {
                                        reviewDate = createdAt.toString();
                                      }
                                    }

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.black12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF7D6D6),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.menu_book_rounded, color: Colors.black87),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _statusColor(status).withOpacity(0.12),
                                                        borderRadius: BorderRadius.circular(999),
                                                        border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                                                      ),
                                                      child: Text(
                                                        status ?? "unknown",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: _statusColor(status),
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text("Writing time: $mins min", style: const TextStyle(color: Colors.black87)),
                                                const SizedBox(height: 6),
                                                Text(
                                                  reviewText,
                                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (reviewDate != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Reviewed at: ${reviewDate!}",
                                                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ---------------- UI pieces ----------------

class _RangeSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RangeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range_rounded, color: Color(0xFFD97B83)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Range",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 7, child: Text("Last 7 days")),
              DropdownMenuItem(value: 14, child: Text("Last 14 days")),
              DropdownMenuItem(value: 30, child: Text("Last 30 days")),
            ],
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }
}

class _HistogramChart extends StatelessWidget {
  final List<Map<String, dynamic>> histogram;
  final double maxY;
  final String Function(String yyyyMMdd) labelBuilder;

  const _HistogramChart({
    required this.histogram,
    required this.maxY,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final bars = <BarChartGroupData>[];

    for (int i = 0; i < histogram.length; i++) {
      final m = (histogram[i]["minutes"] ?? 0).toDouble();
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: m,
              width: 14,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: BarChart(
        BarChartData(
          maxY: maxY + 2,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= histogram.length) return const SizedBox();
                  final dateStr = (histogram[idx]["date"] ?? "").toString();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labelBuilder(dateStr), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: bars,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97B83),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
