

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/theme/colors.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  List supervisors = [];
  String userId = "";
  int totalViews = 0;
  int totalVideos = 0;
  int totalPlaylists = 0;
  int totalPublished = 0;
  Map<String, dynamic> categoriesDistr = {};
  List<Map<String, dynamic>> topVideos = [];

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchSupervisors() async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/users/role/supervisor'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          supervisors = data is List ? data : data['users'] ?? [];
        });
      } else {
        print('Failed to load supervisors: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching supervisors: $e");
    }
  }

  Future<void> updateCvStatus(String id, String newStatus) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.put(
      Uri.parse('${getBackendUrl()}/api/users/updateCvStatus/$id'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"status": newStatus}),
    );

    if (response.statusCode != 200) {
      print("Failed to update CV status: ${response.statusCode}");
    }
  }

  Future<void> updateAgeGroup(String id, String newAgeGroup) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.put(
      Uri.parse('${getBackendUrl()}/api/users/addAgeGroup/$id'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"ageGroup": newAgeGroup}),
    );

    if (response.statusCode != 200) {
      print("Failed to update age group: ${response.statusCode}");
    }
  }

  Future<void> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;
    final decoded = JwtDecoder.decode(token);
    userId = decoded['id'];
  }

  Future<void> fetchAllAnalytics() async {
    try {
      // Total views
      var resViews = await http.get(
          Uri.parse('${getBackendUrl()}/api/videos/getViewsNumbers/null'),
          headers: {"Content-Type": "application/json"});
      if (resViews.statusCode == 200) totalViews = jsonDecode(resViews.body);

      // Total videos
      var resTotalVideos = await http.get(
          Uri.parse('${getBackendUrl()}/api/videos/getTotalVideos/null'),
          headers: {"Content-Type": "application/json"});
      if (resTotalVideos.statusCode == 200)
        totalVideos = jsonDecode(resTotalVideos.body);

      // Total published videos
      var resPublished = await http.get(
          Uri.parse('${getBackendUrl()}/api/videos/getVideosNumbers/null'),
          headers: {"Content-Type": "application/json"});
      if (resPublished.statusCode == 200)
        totalPublished = jsonDecode(resPublished.body);

      // Total playlists
      var resPlaylists = await http.get(
          Uri.parse('${getBackendUrl()}/api/playlists/getPlaylistsNumbers/null'),
          headers: {"Content-Type": "application/json"});
      if (resPlaylists.statusCode == 200)
        totalPlaylists = jsonDecode(resPlaylists.body);

      // Top videos
      var resTop = await http.get(
          Uri.parse('${getBackendUrl()}/api/videos/getTopViews/null'),
          headers: {"Content-Type": "application/json"});
      if (resTop.statusCode == 200)
        topVideos = (jsonDecode(resTop.body) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

      // Videos distribution
      var resDistr = await http.get(
          Uri.parse('${getBackendUrl()}/api/videos/getVideosDistribution/null'),
          headers: {"Content-Type": "application/json"});
      if (resDistr.statusCode == 200) {
        final distrData = jsonDecode(resDistr.body) as List;
        categoriesDistr = {for (var item in distrData) item['category']: item['count']};
      }

      setState(() {});
    } catch (e) {
      print("❌ Error fetching analytics: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    getUserId().then((_) {
      fetchSupervisors();
      fetchAllAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Admin Home",
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("View insights and performance metrics",
                style: TextStyle(color: AppColors.bgBlushRoseVeryDark)),
            const SizedBox(height: 16),

            // ===== Stats Cards =====
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(Icons.videocam, 'Total Videos', totalVideos.toString(),
                      '', AppColors.peachPinkDark),
                  _buildStatCard(Icons.video_library, 'Published Videos',
                      totalPublished.toString(), '', AppColors.peachPinkDark),
                  _buildStatCard(Icons.play_arrow, 'Total Playlists',
                      totalPlaylists.toString(), '', AppColors.peachPinkDark),
                  _buildStatCard(Icons.remove_red_eye, 'Total Views',
                      totalViews.toString(), '', AppColors.peachPinkDark),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ===== Top Videos Chart =====
            _buildBarChartCard('Top 5 Videos by Views', topVideos),

            const SizedBox(height: 32),

            // ===== Content Distribution =====
            _buildContentByTopic(),

            const SizedBox(height: 32),

            // ===== Supervisors List =====
            const Text("Supervisors", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            supervisors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: supervisors.map((supervisor) {
                      String cvStatus = supervisor['cvStatus'] ?? 'pending';
                      String ageGroup = supervisor['ageGroup'] ?? '5-8';
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(supervisor['name'] ?? 'No Name',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(supervisor['email'] ?? 'No Email'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Text("CV Status: "),
                                  DropdownButton<String>(
                                    value: cvStatus,
                                    items: const [
                                      DropdownMenuItem(
                                          value: "pending", child: Text("Pending")),
                                      DropdownMenuItem(
                                          value: "approved", child: Text("Approved")),
                                      DropdownMenuItem(
                                          value: "rejected", child: Text("Rejected")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => supervisor['cvStatus'] = val);
                                        updateCvStatus(supervisor['_id'], val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Text("Age Group: "),
                                  DropdownButton<String>(
                                    value: ageGroup,
                                    items: const [
                                      DropdownMenuItem(value: "5-8", child: Text("5-8")),
                                      DropdownMenuItem(value: "9-12", child: Text("9-12")),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => supervisor['ageGroup'] = val);
                                        updateAgeGroup(supervisor['_id'], val);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  // =================== Widgets ===================

  Widget _buildStatCard(
      IconData icon, String title, String value, String change, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(change, style: const TextStyle(fontSize: 12, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(String title, List<Map<String, dynamic>> data) {
    final chartData = data
        .map((video) => {'label': video['title'], 'value': video['views']})
        .toList()
      ..sort((a, b) => b['value'].compareTo(a['value']));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8),
      ]),
      child: SfCartesianChart(
        backgroundColor: Colors.transparent,
        plotAreaBackgroundColor: Colors.white,
        title: ChartTitle(
            text: title,
            alignment: ChartAlignment.near,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        primaryXAxis: CategoryAxis(
          labelRotation: 0,
          labelIntersectAction: AxisLabelIntersectAction.wrap,
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(color: Colors.grey.shade300, width: 1),
          axisLine: const AxisLine(width: 0),
        ),
        tooltipBehavior: TooltipBehavior(enable: true, color: Colors.black87),
        series: <CartesianSeries>[
          ColumnSeries<Map<String, dynamic>, String>(
            dataSource: chartData,
            xValueMapper: (d, _) => d['label'],
            yValueMapper: (d, _) => d['value'],
            borderRadius: BorderRadius.circular(8),
            pointColorMapper: (_, __) => AppColors.peachPinkVeryDark,
            width: 0.7,
            spacing: 0.2,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildContentByTopic() {
    final total = categoriesDistr.values.fold<int>(0, (sum, v) => sum + (v as int));
    final topicData = categoriesDistr.entries
        .map((e) => {
              'label': e.key,
              'value': e.value,
              'percent': total > 0 ? e.value / total : 0.0,
            })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Content by Topic", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Distribution of videos across different topics",
            style: TextStyle(color: AppColors.peachPinkVeryDark)),
        const SizedBox(height: 16),
        Column(
          children: topicData.map((topic) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${topic['label']} ${topic['value']} videos"),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: topic['percent'] as double,
                    color: AppColors.peachPinkVeryDark,
                    backgroundColor: AppColors.peachPinkLight,
                    minHeight: 8,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
