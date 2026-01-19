

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

class _HomeAdminState extends State<HomeAdmin>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ====== Data ======
  List supervisors = [];
  List kids = [];
  List parents = [];
  List admins = [];
  List videos = [];
  List games = [];
  List drawings = [];
  List stories = [];
  List challenges = [];
  String userId = "";

  Map<String, dynamic> categoriesDistr = {};
  List<Map<String, dynamic>> topVideos = [];
  List<Map<String, dynamic>> topGames = [];

  // Totals
  int totalUsers = 0;
  int totalKids = 0;
  int totalParents = 0;
  int totalSupervisors = 0;
  int totalAdmins = 0;
  int totalVideos = 0;
  int totalGames = 0;
  int totalDrawings = 0;
  int totalStories = 0;
  int totalChallenges = 0;
  int totalViews = 0;
  int totalPublished = 0;  
  int totalPlaylists = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    getUserId().then((_) {
      fetchAllData();
    });
  }

  String getBackendUrl() {

    if (kIsWeb)
    // return "http://192.168.1.63:3000";
    return "http://localhost:3000";

    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }



  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    if (token == null) return;
    final decoded = JwtDecoder.decode(token);
    userId = decoded['id'];
  }

  Future<void> fetchAllData() async {
    try {
      // ===== Users =====
      final resKids = await http.get(Uri.parse('${getBackendUrl()}/api/users/role/child'));
      final resParents =
          await http.get(Uri.parse('${getBackendUrl()}/api/users/role/parent'));
      final resSupervisors =
          await http.get(Uri.parse('${getBackendUrl()}/api/users/role/supervisor'));
      final resAdmins =
          await http.get(Uri.parse('${getBackendUrl()}/api/users/getAdmins/'));

      if (resKids.statusCode == 200) kids = jsonDecode(resKids.body);
      if (resParents.statusCode == 200) parents = jsonDecode(resParents.body);
      if (resSupervisors.statusCode == 200) supervisors = jsonDecode(resSupervisors.body);
      if (resAdmins.statusCode == 200) admins = jsonDecode(resAdmins.body);

      totalKids = kids.length;
      totalParents = parents.length;
      totalSupervisors = supervisors.length;
      totalAdmins = admins.length;
      totalUsers = totalKids + totalParents + totalSupervisors + totalAdmins;

      // ===== Content =====
      final resVideos = await http.get(Uri.parse('${getBackendUrl()}/api/videos/getAllVideos'));
      final resGames = await http.get(Uri.parse('${getBackendUrl()}/api/game/getAllGames'));
      final resDrawings =
          await http.get(Uri.parse('${getBackendUrl()}/api/drawings/getAll'));
      final resStories = await http.get(Uri.parse('${getBackendUrl()}/api/story/all'));
      final resChallenges =
          await http.get(Uri.parse('${getBackendUrl()}/api/challenges/getAll'));

      if (resVideos.statusCode == 200) videos = jsonDecode(resVideos.body);
      if (resGames.statusCode == 200) games = jsonDecode(resGames.body);
      if (resDrawings.statusCode == 200) drawings = jsonDecode(resDrawings.body);
      if (resStories.statusCode == 200) stories = jsonDecode(resStories.body);
      if (resChallenges.statusCode == 200) challenges = jsonDecode(resChallenges.body);

      totalVideos = videos.length;
      totalGames = games.length;
      totalDrawings = drawings.length;
      totalStories = stories.length;
      totalChallenges = challenges.length;


        // ===== Total Published Videos =====
    int publishedCount = 0;
    for (var ageGroup in ['5-8', '9-12']) {
      final resPublished = await http.get(Uri.parse('${getBackendUrl()}/api/videos/getPublishedVideos/$ageGroup'));
      if (resPublished.statusCode == 200) {
        final list = jsonDecode(resPublished.body);
          publishedCount += (list.length as int);
      }
    }
    totalPublished = publishedCount;

     // ===== Total Playlists =====
  
    int playlistCount = 0;
    for (var kid in kids) {
      final resPlaylist = await http.get(Uri.parse('${getBackendUrl()}/api/playlists/getAllPlaylists'));
      if (resPlaylist.statusCode == 200) {
        final playlist = jsonDecode(resPlaylist.body);
        print("this is playlist: $playlist");
        playlistCount += (playlist.length as int);


      }
    }
    totalPlaylists = playlistCount;

      // ===== Top Content =====
      topVideos = List<Map<String, dynamic>>.from(videos)
        ..sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
      if (topVideos.length > 5) topVideos = topVideos.sublist(0, 5);

     // ===== Top Games (from backend top 4 played games) =====
final resTopGames = await http.get(Uri.parse('${getBackendUrl()}/api/game/getTopPlayedGames'));
if (resTopGames.statusCode == 200) {
  topGames = List<Map<String, dynamic>>.from(jsonDecode(resTopGames.body));

  // Ensure it has a title field for chart
  for (var game in topGames) {
    if (!game.containsKey('title')) {
      game['title'] = game['name'] ?? 'Unknown Game';
    }
  }
}

      // ===== Categories Distribution (Videos) =====
      Map<String, int> distr = {};
      for (var v in videos) {
        String cat = v['category'] ?? 'Other';
        distr[cat] = (distr[cat] ?? 0) + 1;
      }
      categoriesDistr = distr;

      setState(() {});
    } catch (e) {
      print("❌ Error fetching data: $e");
    }
  }

  Future<void> updateCvStatus(String id, String newStatus) async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.put(
      Uri.parse('${getBackendUrl()}/api/users/updateCvStatus/$id'),
      headers: {
        "Content-Type": "application/json",
       // "Authorization": "Bearer $token",
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
       // "Authorization": "Bearer $token",
      },
      body: jsonEncode({"ageGroup": newAgeGroup}),
    );

    if (response.statusCode != 200) {
      print("Failed to update age group: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Admin Home",
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color.fromARGB(255, 200, 141, 21),
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: "Dashboard"),
              Tab(text: "Users"),
              Tab(text: "Analytics"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                _buildUsersTab(),
              
                _buildAnalyticsTab(),
              ],
            ),
          )
        ],
      ),
    );
  }

  // =================== Tabs ===================

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
      children: [
  _buildStatCard(Icons.people, "Total Users", totalUsers.toString(), AppColors.goldenYellow),

  _buildStatCard(Icons.child_care, "Kids", totalKids.toString(), AppColors.goldenYellow),

  _buildStatCard(Icons.family_restroom, "Parents", totalParents.toString(),
      AppColors.goldenYellow), // ✅ NEW

  _buildStatCard(Icons.supervised_user_circle, "Supervisors", totalSupervisors.toString(),
      AppColors.goldenYellow),

  _buildStatCard(Icons.admin_panel_settings, "Admins", totalAdmins.toString(),
      AppColors.goldenYellow),

  _buildStatCard(Icons.videocam, "Videos", totalVideos.toString(), AppColors.goldenYellow),
  _buildStatCard(Icons.videogame_asset, "Games", totalGames.toString(), AppColors.goldenYellow),
  _buildStatCard(Icons.brush, "Drawings", totalDrawings.toString(), AppColors.goldenYellow),
  _buildStatCard(Icons.book, "Stories", totalStories.toString(), AppColors.goldenYellow),
  _buildStatCard(Icons.flag, "Challenges", totalChallenges.toString(), AppColors.goldenYellow),
],

      ),
    );
  }
Widget _buildUsersTab() {
  Map<String, bool> expandedSections = {
    "Kids": false,
    "Supervisors": false,
    "Parents": false,
    "Admins": false,
  };

  return StatefulBuilder(
    builder: (context, setState) {
      List<Map<String, dynamic>> getUsersByRole(String role) {
        switch (role) {
          case "Kids":
            return kids.map((u) => Map<String, dynamic>.from(u)..['role'] = 'Kid').toList();
          case "Supervisors":
            return supervisors.map((u) => Map<String, dynamic>.from(u)..['role'] = 'Supervisor').toList();
          case "Parents":
            return parents.map((u) => Map<String, dynamic>.from(u)..['role'] = 'Parent').toList();
          case "Admins":
            return admins.map((u) => Map<String, dynamic>.from(u)..['role'] = 'Admin').toList();
          default:
            return [];
        }
      }

      Widget buildUserCard(Map<String, dynamic> user) {
        final nameController = TextEditingController(text: user['name']);
        final emailController = TextEditingController(text: user['email']);
        String ageGroup = user['ageGroup'] ?? "5-8";
        bool isEditing = false;

        return StatefulBuilder(builder: (context, setCardState) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        isEditing
                            ? TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name"))
                            : Text(user['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                        const SizedBox(height: 4),

                        // Email
                        isEditing
                            ? TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email"))
                            : Text(user['email'], style: const TextStyle(color: Colors.grey)),

                        const SizedBox(height: 4),

                        // Age group
                        if (user['role'] == "Kid")
                          isEditing
                              ? DropdownButton<String>(
                                  value: ageGroup,
                                  items: const [
                                    DropdownMenuItem(value: "5-8", child: Text("5-8")),
                                    DropdownMenuItem(value: "9-12", child: Text("9-12")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setCardState(() => ageGroup = val);
                                  },
                                )
:Text(
  "Age Group: $ageGroup",
  style: TextStyle(color: Colors.grey[700]),
),
                      ],
                    ),
                  ),

                  // Edit / Delete buttons
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          if (isEditing) {
                            // Save changes
                            final token = await getToken();
                            if (token == null) return;

                            final res = await http.put(
                              Uri.parse('${getBackendUrl()}/api/users/updateprofile/${user['_id']}'),
                              headers: {
                                "Content-Type": "application/json",
                                "Authorization": "Bearer $token",
                              },
                              body: jsonEncode({
                                "name": nameController.text,
                                "email": emailController.text,
                                if (user['role'] == "Kid") "ageGroup": ageGroup,
                              }),
                            );

                            if (res.statusCode == 200) {
                              fetchAllData();
                            } else {
                              print("Failed to update user: ${res.body}");
                            }
                          }

                          setCardState(() => isEditing = !isEditing);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final token = await getToken();
                          if (token == null) return;

                          final res = await http.delete(
                            Uri.parse('${getBackendUrl()}/api/users/deleteme/${user['_id']}'),
                           // headers: {"Authorization": "Bearer $token"},
                          );

                          if (res.statusCode == 200) fetchAllData();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      }
void showAddUserDialog(String role) {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  String ageGroup = "5-8";

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Add New $role"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            if (role == "Kids" || role == "Supervisors")
              DropdownButton<String>(
                value: ageGroup,
                items: const [
                  DropdownMenuItem(value: "5-8", child: Text("5-8")),
                  DropdownMenuItem(value: "9-12", child: Text("9-12")),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => ageGroup = val);
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () async {
            // Call your backend API to create user
          },
          child: const Text("Add User"),
        ),
      ],
    ),
  );
}
      List<Widget> buildSections() {
        return expandedSections.keys.map((role) {
          final users = getUsersByRole(role);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => expandedSections[role] = !expandedSections[role]!),
                child: Container(
                  color: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(expandedSections[role]! ? Icons.expand_less : Icons.expand_more),
                      const SizedBox(width: 8),
                      Text(role, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () => showAddUserDialog(role),
                      ),
                    ],
                  ),
                ),
              ),
              if (expandedSections[role]!)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: users.map((user) => buildUserCard(user)).toList(),
                  ),
                ),
            ],
          );
        }).toList();
      }

      return SingleChildScrollView(
        child: Column(children: buildSections()),
      );
    },
  );
}




Widget _buildAnalyticsTab() {
  // Show loading if no data yet
  if (videos.isEmpty && games.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "View insights and performance metrics",
          style: TextStyle(color: AppColors.textAccent, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // ===== Stats Cards =====
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard(Icons.videocam, 'Total Videos', totalVideos.toString(),
                  const Color.fromARGB(255, 216, 155, 139)),
              _buildStatCard(Icons.video_library, 'Published Videos', totalPublished.toString(),
                  const Color.fromARGB(255, 216, 155, 139)),
              _buildStatCard(Icons.play_arrow, 'Total Playlists', totalPlaylists.toString(),
                  const Color.fromARGB(255, 216, 155, 139)),
              _buildStatCard(Icons.remove_red_eye, 'Total Views', totalViews.toString(),
                  const Color.fromARGB(255, 216, 155, 139)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // ===== Top Videos Chart =====
        if (topVideos.isNotEmpty)
          _buildBarChartCard("Top 5 Videos by Views", topVideos, 'views'),

        const SizedBox(height: 32),

     

        // ===== Content by Topic =====
        _buildContentByTopic(),

           // ===== Top Games Chart =====
       // ===== Top Games Chart =====
if (topGames.isNotEmpty)
  _buildBarChartCard("Top 4 Games by Plays", topGames, 'playCount'),

        const SizedBox(height: 32),
      ],
    ),
  );
}

 
  // =================== Widgets ===================

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
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
        ],
      ),
    );
  }

  Widget _buildBarChartCard(String title, List<Map<String, dynamic>> data, String valueKey) {
    final chartData = data
        .map((e) => {'label': e['title'], 'value': e[valueKey] ?? 0})
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
            pointColorMapper: (_, __) => AppColors.goldenYellow,
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
            style: TextStyle(color: Color.fromARGB(255, 217, 150, 18))),
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
                    color: const Color.fromARGB(255, 217, 150, 18),
                    backgroundColor: const Color.fromARGB(255, 246, 210, 137),
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

