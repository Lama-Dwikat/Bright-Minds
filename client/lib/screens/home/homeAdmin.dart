

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
import 'package:bright_minds/screens/adminReports/allUsers.dart';
import 'package:bright_minds/screens/adminReports/analytics.dart';



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
  int totalPublishedStories = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getUserId().then((_) {
      fetchAllData();
    });
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
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

 /* Future<void> fetchAllData() async {
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
      final resDrawings =await http.get(Uri.parse('${getBackendUrl()}/api/drawings/getAll'));
      final resStories = await http.get(Uri.parse('${getBackendUrl()}/api/story/all'));
      final resChallenges = await http.get(Uri.parse('${getBackendUrl()}/api/challenges/getAll'));
      final resPlaylist = await http.get(Uri.parse('${getBackendUrl()}/api/playlists/getPlaylistsNumbers/null'));
      final resViews = await http.get(Uri.parse('${getBackendUrl()}/api/videos/getViewsNumbers/null'));


      if (resVideos.statusCode == 200) videos = jsonDecode(resVideos.body);
      if (resGames.statusCode == 200) games = jsonDecode(resGames.body);
      if (resDrawings.statusCode == 200) drawings = jsonDecode(resDrawings.body);
      if (resStories.statusCode == 200) stories = jsonDecode(resStories.body);
      if (resChallenges.statusCode == 200) challenges = jsonDecode(resChallenges.body);
      if (resPlaylist.statusCode == 200)  totalPlaylists = jsonDecode(resPlaylist.body); 
      if (resViews.statusCode == 200) totalViews = jsonDecode(resViews.body);
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

  
 

  
    
    


     setState(() {});
    } catch (e) {
      print("❌ Error fetching data: $e");
    }


 
  }
*/
Future<void> fetchAllData() async {
  try {
    final token = await getToken();
    if (token == null) {
      print("❌ No token in SharedPreferences");
      return;
    }

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    // ===== Users =====
    final resKids = await http.get(
      Uri.parse('${getBackendUrl()}/api/users/role/child'),
      headers: headers,
    );
    final resParents = await http.get(
      Uri.parse('${getBackendUrl()}/api/users/role/parent'),
      headers: headers,
    );
    final resSupervisors = await http.get(
      Uri.parse('${getBackendUrl()}/api/users/role/supervisor'),
      headers: headers,
    );
    final resAdmins = await http.get(
      Uri.parse('${getBackendUrl()}/api/users/getAdmins/'),
      headers: headers,
    );

    if (resKids.statusCode == 200) {
      kids = jsonDecode(resKids.body);
    } else {
      print("❌ kids error ${resKids.statusCode}: ${resKids.body}");
    }

    if (resParents.statusCode == 200) {
      parents = jsonDecode(resParents.body);
    } else {
      print("❌ parents error ${resParents.statusCode}: ${resParents.body}");
    }

    if (resSupervisors.statusCode == 200) {
      supervisors = jsonDecode(resSupervisors.body);
    } else {
      print("❌ supervisors error ${resSupervisors.statusCode}: ${resSupervisors.body}");
    }

    if (resAdmins.statusCode == 200) {
      admins = jsonDecode(resAdmins.body);
    } else {
      print("❌ admins error ${resAdmins.statusCode}: ${resAdmins.body}");
    }

    totalKids = kids.length;
    totalParents = parents.length;
    totalSupervisors = supervisors.length;
    totalAdmins = admins.length;
    totalUsers = totalKids + totalParents + totalSupervisors + totalAdmins;

    // ===== Content =====
    final resVideos = await http.get(
      Uri.parse('${getBackendUrl()}/api/videos/getAllVideos'),
      headers: headers,
    );
    final resGames = await http.get(
      Uri.parse('${getBackendUrl()}/api/game/getAllGames'),
      headers: headers,
    );
    final resDrawings = await http.get(
      Uri.parse('${getBackendUrl()}/api/drawings/getAll'),
      headers: headers,
    );
    final resStories = await http.get(
      Uri.parse('${getBackendUrl()}/api/story/all'),
      headers: headers,
    );
    final resChallenges = await http.get(
      Uri.parse('${getBackendUrl()}/api/challenges/getAll'),
      headers: headers,
    );
    final resPlaylist = await http.get(
      Uri.parse('${getBackendUrl()}/api/playlists/getPlaylistsNumbers/null'),
      headers: headers,
    );
    final resViews = await http.get(
      Uri.parse('${getBackendUrl()}/api/videos/getViewsNumbers/null'),
      headers: headers,
    );

    if (resVideos.statusCode == 200) {
      videos = jsonDecode(resVideos.body);
    } else {
      print("❌ videos error ${resVideos.statusCode}: ${resVideos.body}");
    }

    if (resGames.statusCode == 200) {
      games = jsonDecode(resGames.body);
    } else {
      print("❌ games error ${resGames.statusCode}: ${resGames.body}");
    }

    if (resDrawings.statusCode == 200) {
      drawings = jsonDecode(resDrawings.body);
    } else {
      print("❌ drawings error ${resDrawings.statusCode}: ${resDrawings.body}");
    }

    if (resStories.statusCode == 200) {
      stories = jsonDecode(resStories.body);
    } else {
      print("❌ stories error ${resStories.statusCode}: ${resStories.body}");
    }

    if (resChallenges.statusCode == 200) {
      challenges = jsonDecode(resChallenges.body);
    } else {
      print("❌ challenges error ${resChallenges.statusCode}: ${resChallenges.body}");
    }

    if (resPlaylist.statusCode == 200) {
      totalPlaylists = jsonDecode(resPlaylist.body);
    } else {
      print("❌ playlists error ${resPlaylist.statusCode}: ${resPlaylist.body}");
    }

    if (resViews.statusCode == 200) {
      totalViews = jsonDecode(resViews.body);
    } else {
      print("❌ views error ${resViews.statusCode}: ${resViews.body}");
    }

    totalVideos = videos.length;
    totalGames = games.length;
    totalDrawings = drawings.length;
    totalStories = stories.length;
    totalChallenges = challenges.length;

    // ===== Total Published Videos =====
    int publishedCount = 0;
    for (var ageGroup in ['5-8', '9-12']) {
      final resPublished = await http.get(
        Uri.parse('${getBackendUrl()}/api/videos/getPublishedVideos/$ageGroup'),
        headers: headers,
      );

      if (resPublished.statusCode == 200) {
        final list = jsonDecode(resPublished.body);
        publishedCount += (list.length as int);
      } else {
        print("❌ published videos ($ageGroup) error ${resPublished.statusCode}: ${resPublished.body}");
      }
    }
    totalPublished = publishedCount;


    // ===== admin Drawings Count =====
final resDrawingCount = await http.get(
  Uri.parse('${getBackendUrl()}/api/admin/activities/count'),
  headers: headers,
);
print("📌 published count drawing status: ${resDrawingCount.statusCode}");
print("📌 published count drawing body: ${resDrawingCount.body}");

if (resDrawingCount.statusCode == 200) {
  totalDrawings = jsonDecode(resDrawingCount.body)["count"] ?? 0;
}

    // ===== Weekly Plans Count =====

final resWeeklyPlansCount = await http.get(
  Uri.parse('${getBackendUrl()}/api/challenges/weekly-plans/count'),
  headers: headers,
);

print("📌 weekly plans count status: ${resWeeklyPlansCount.statusCode}");
print("📌 weekly plans count body: ${resWeeklyPlansCount.body}");

if (resWeeklyPlansCount.statusCode == 200) {
  final data = jsonDecode(resWeeklyPlansCount.body);
  totalChallenges = data["count"] ?? 0; //   
} else {
  totalChallenges = 0;
}




    // ===== Published Stories Count =====
    final resPublishedStoriesCount = await http.get(
      Uri.parse('${getBackendUrl()}/api/story/published/count'),
      headers: headers,
    );
print("📌 published count status: ${resPublishedStoriesCount.statusCode}");
print("📌 published count body: ${resPublishedStoriesCount.body}");

    if (resPublishedStoriesCount.statusCode == 200) {
      final data = jsonDecode(resPublishedStoriesCount.body);
      totalPublishedStories = data["count"] ?? 0;
    } else {
      print("❌ published stories count error ${resPublishedStoriesCount.statusCode}: ${resPublishedStoriesCount.body}");
      totalPublishedStories = 0;
    }

    setState(() {});
  } catch (e) {
    print("❌ Error fetching data: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Admin Home",
      child: Column(
        children: [
          Center(
           child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: const Color.fromARGB(255, 200, 141, 21),
             labelStyle: const TextStyle(
             fontSize: 18,        
              fontWeight: FontWeight.bold,
                   ),
            unselectedLabelColor: Colors.black54,
            tabs: const [
              Tab(text: "Dashboard"),
              Tab(text: "Users"),
              Tab(text: "Analytics"),
            ],
          ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(),
                AllUsersPage(supervisors: supervisors,kids: kids, parents: parents, admins: admins,),
              
               TotalAnalytics(videos:videos,games:games),
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
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 3100, // keeps dashboard centered on web
        ),
        child: Wrap(
          alignment: WrapAlignment.center, // ⭐ IMPORTANT
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(Icons.people, "Total Users", totalUsers.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.child_care, "Kids", totalKids.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.family_restroom, "Parents", totalParents.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.supervised_user_circle, "Supervisors", totalSupervisors.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.admin_panel_settings, "Admins", totalAdmins.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.videocam, "Videos", totalVideos.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.videogame_asset, "Games", totalGames.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.brush, "Drawings", totalDrawings.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.book, "Stories", totalPublishedStories.toString(), const Color.fromARGB(255, 234, 166, 32)),
            _buildStatCard(Icons.flag, "Challenges", totalChallenges.toString(), const Color.fromARGB(255, 234, 166, 32)),
          ],
        ),
      ),
    ),
  );
}
    }






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

