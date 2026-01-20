






// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:syncfusion_flutter_charts/charts.dart';
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;


// // Replace with your actual AppColors
// class AppColors {
//   static const goldenYellow = Color(0xFFFFC107);
//   static const textAccent = Colors.black87;
// }

// class TotalAnalytics extends StatefulWidget {
//   final List videos;
//   final List games;

//   TotalAnalytics({Key? key, required this.videos, required this.games})
//       : super(key: key);

//   @override
//   State<TotalAnalytics> createState() => _TotalAnalyticsState();
// }

// class _TotalAnalyticsState extends State<TotalAnalytics> {
//   Map<String, dynamic> categoriesDistr = {};
//   List<Map<String, dynamic>> topVideos = [];
//   List<Map<String, dynamic>> topGames = [];
//   int totalVideos = 0;
//   int totalGames = 0;
//   int totalViews = 0;
//   int totalPublished = 0;
//   List playlists = [];
//   int totalPlaylists = 0;

//   bool loading = true;



//   String getBackendUrl() {
//     if (kIsWeb) return "http://192.168.1.74:3000";
//     if (Platform.isAndroid) return "http://10.0.2.2:3000";
//     if (Platform.isIOS) return "http://localhost:3000";
//     return "http://localhost:3000";
//   }

//   @override
//   void initState() {
//     super.initState();
//       fetchPlaylists();  
//     _initializeAnalytics();
//   }

//   Future<void> fetchPlaylists() async {
//   try {
//     final response = await http.get(
//       Uri.parse('${getBackendUrl()}/api/playlists/getAllPlaylists'),
//       headers: {
//         'Content-Type': 'application/json',
//       },
//     );

//     if (response.statusCode == 200) {
//       final List data = jsonDecode(response.body);

//       setState(() {
//         playlists = data;
//         totalPlaylists = data.length; // ✅ THIS IS WHAT YOU WANT
//       });
//     } else {
//       debugPrint('Failed to load playlists');
//     }
//   } catch (e) {
//     debugPrint('Error fetching playlists: $e');
//   }
// }


//   Future<void> _initializeAnalytics() async {
//     // ===== Videos Stats =====
//     totalVideos = widget.videos.length;
//     totalViews = widget.videos.fold<int>(
//         0, (sum, v) => sum + ((v['views'] ?? 0) as int));
//     totalPublished = widget.videos.where((v) => v['isPublished'] == true).length;
//     totalPlaylists = widget.videos
//     .map((v) => v['playlistId'])
//     .toSet()
//     .length;

//     topVideos = List<Map<String, dynamic>>.from(widget.videos)
//       ..sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
//     if (topVideos.length > 5) topVideos = topVideos.sublist(0, 5);

//     // ===== Games Stats =====
//     try {
//       final resTopGames =
//           await http.get(Uri.parse('${getBackendUrl()}/api/game/getTopPlayedGames'));
//       if (resTopGames.statusCode == 200) {
//         topGames = List<Map<String, dynamic>>.from(jsonDecode(resTopGames.body));
//         for (var game in topGames) {
//           if (!game.containsKey('title')) {
//             game['title'] = game['name'] ?? 'Unknown Game';
//           }
//         }
//       }
//       totalGames = widget.games.length;
//     } catch (e) {
//       topGames = [];
//     }

//     // ===== Categories Distribution =====
//     Map<String, int> distr = {};
//     for (var v in widget.videos) {
//       String cat = v['category'] ?? 'Other';
//       distr[cat] = (distr[cat] ?? 0) + 1;
//     }
//     categoriesDistr = distr;

//     setState(() {
//       loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (loading) return const Center(child: CircularProgressIndicator());

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "View insights and performance metrics",
//             style: TextStyle(color: AppColors.textAccent, fontSize: 16),
//           ),
//           const SizedBox(height: 16),

//           // ===== Stats Cards =====
//           Center(
//             child: Wrap(
//               spacing: 16,
//               runSpacing: 16,
//               children: [
//                 _buildStatCard(Icons.videocam, 'Total Videos', totalVideos.toString(),
//                     const Color.fromARGB(255, 216, 155, 139)),
//                 _buildStatCard(Icons.video_library, 'Published Videos', totalPublished.toString(),
//                     const Color.fromARGB(255, 216, 155, 139)),
//                 _buildStatCard(Icons.play_arrow, 'Total Playlists', totalPlaylists.toString(),
//                     const Color.fromARGB(255, 216, 155, 139)),
//                 _buildStatCard(Icons.remove_red_eye, 'Total Views', totalViews.toString(),
//                     const Color.fromARGB(255, 216, 155, 139)),
//                 _buildStatCard(Icons.videogame_asset, 'Total Games', totalGames.toString(),
//                     const Color.fromARGB(255, 216, 155, 139)),
//               ],
//             ),
//           ),
//           const SizedBox(height: 32),

//           // ===== Top Videos Chart =====
//           if (topVideos.isNotEmpty)
//             _buildBarChartCard("Top 5 Videos by Views", topVideos, 'views'),

//           const SizedBox(height: 32),

//           // ===== Content by Topic =====
//           _buildContentByTopic(),

//           const SizedBox(height: 32),

//           // ===== Top Games Chart =====
//           if (topGames.isNotEmpty)
//             _buildBarChartCard("Top 4 Games by Plays", topGames, 'playCount'),

//           const SizedBox(height: 32),

//           // ===== Expandable Videos =====
//           ExpansionTile(
//             title: const Text(
//               "Videos",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             leading: const Icon(Icons.videocam),
//             children: widget.videos.isNotEmpty
//                 ? widget.videos.map<Widget>((video) {
//                     return ListTile(
//                       leading: Image.network(
//                         video['thumbnailUrl'] ?? "https://via.placeholder.com/80",
//                         width: 50,
//                         height: 50,
//                         fit: BoxFit.cover,
//                       ),
//                       title: Text(video['title'] ?? "Unknown Video"),
//                       subtitle: Text("Views: ${video['views'] ?? 0}"),
//                     );
//                   }).toList()
//                 : [const ListTile(title: Text("No videos available"))],
//           ),

//           const SizedBox(height: 16),

//           // ===== Expandable Games =====
//           ExpansionTile(
//             title: const Text(
//               "Games",
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             leading: const Icon(Icons.videogame_asset),
//             children: widget.games.isNotEmpty
//                 ? widget.games.map<Widget>((game) {
//                     return ListTile(
//                       title: Text(game['title'] ?? game['name'] ?? "Unknown Game"),
//                       subtitle: Text("Plays: ${(game['playedBy'] as List?)?.length ?? 0}"),
//                     );
//                   }).toList()
//                 : [const ListTile(title: Text("No games available"))],
//           ),
//         ],
//       ),
//     );
//   }

//   // =================== Widgets ===================

//   Widget _buildStatCard(IconData icon, String title, String value, Color color) {
//     return Container(
//       width: 150,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: 32, color: color),
//           const SizedBox(height: 8),
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 4),
//           Text(value, style: const TextStyle(fontSize: 16)),
//         ],
//       ),
//     );
//   }

//   Widget _buildBarChartCard(String title, List<Map<String, dynamic>> data, String valueKey) {
//     final chartData = data
//         .map((e) => {'label': e['title'], 'value': e[valueKey] ?? 0})
//         .toList()
//       ..sort((a, b) => b['value'].compareTo(a['value']));

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//           color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [
//         BoxShadow(color: Colors.black12, blurRadius: 8),
//       ]),
//       child: SfCartesianChart(
//         backgroundColor: Colors.transparent,
//         plotAreaBackgroundColor: Colors.white,
//         title: ChartTitle(
//             text: title,
//             alignment: ChartAlignment.near,
//             textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         primaryXAxis: CategoryAxis(
//           labelRotation: 0,
//           labelIntersectAction: AxisLabelIntersectAction.wrap,
//           majorGridLines: const MajorGridLines(width: 0),
//         ),
//         primaryYAxis: NumericAxis(
//           majorGridLines: MajorGridLines(color: Colors.grey.shade300, width: 1),
//           axisLine: const AxisLine(width: 0),
//         ),
//         tooltipBehavior: TooltipBehavior(enable: true, color: Colors.black87),
//         series: <CartesianSeries>[
//           ColumnSeries<Map<String, dynamic>, String>(
//             dataSource: chartData,
//             xValueMapper: (d, _) => d['label'],
//             yValueMapper: (d, _) => d['value'],
//             borderRadius: BorderRadius.circular(8),
//             pointColorMapper: (_, __) => AppColors.goldenYellow,
//             width: 0.7,
//             spacing: 0.2,
//             dataLabelSettings: const DataLabelSettings(isVisible: true),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContentByTopic() {
//     final total = categoriesDistr.values.fold<int>(0, (sum, v) => sum + (v as int));
//     final topicData = categoriesDistr.entries
//         .map((e) => {
//               'label': e.key,
//               'value': e.value,
//               'percent': total > 0 ? e.value / total : 0.0,
//             })
//         .toList();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Content by Topic", style: TextStyle(fontWeight: FontWeight.bold)),
//         const SizedBox(height: 8),
//         const Text("Distribution of videos across different topics",
//             style: TextStyle(color: Color.fromARGB(255, 217, 150, 18))),
//         const SizedBox(height: 16),
//         Column(
//           children: topicData.map((topic) {
//             return Padding(
//               padding: const EdgeInsets.symmetric(vertical: 8),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text("${topic['label']} ${topic['value']} videos"),
//                   const SizedBox(height: 4),
//                   LinearProgressIndicator(
//                     value: topic['percent'] as double,
//                     color: const Color.fromARGB(255, 217, 150, 18),
//                     backgroundColor: const Color.fromARGB(255, 246, 210, 137),
//                     minHeight: 8,
//                   ),
//                 ],
//               ),
//             );
//           }).toList(),
//         ),
//       ],
//     );
//   }
// }


// =================== UPDATED DESIGN ONLY ===================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppColors {
  static const goldenYellow = Color(0xFFFFC107);
  static const textAccent = Colors.black87;
}

class TotalAnalytics extends StatefulWidget {
  final List videos;
  final List games;

  TotalAnalytics({Key? key, required this.videos, required this.games})
      : super(key: key);

  @override
  State<TotalAnalytics> createState() => _TotalAnalyticsState();
}

class _TotalAnalyticsState extends State<TotalAnalytics> {
  Map<String, dynamic> categoriesDistr = {};
  List<Map<String, dynamic>> topVideos = [];
  List<Map<String, dynamic>> topGames = [];
  int totalVideos = 0;
  int totalGames = 0;
  int totalViews = 0;
  int totalPublished = 0;
  List playlists = [];
  int totalPlaylists = 0;

  bool loading = true;
  bool showVideos = true; // toggle between videos and games

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
    _initializeAnalytics();
  }

  Future<void> fetchPlaylists() async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/playlists/getAllPlaylists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          playlists = data;
          totalPlaylists = data.length;
        });
      } else {
        debugPrint('Failed to load playlists');
      }
    } catch (e) {
      debugPrint('Error fetching playlists: $e');
    }
  }

  Future<void> _initializeAnalytics() async {
    // ===== Videos Stats =====
    totalVideos = widget.videos.length;
    totalViews = widget.videos.fold<int>(
        0, (sum, v) => sum + ((v['views'] ?? 0) as int));
    totalPublished = widget.videos.where((v) => v['isPublished'] == true).length;
    totalPlaylists =
        widget.videos.map((v) => v['playlistId']).toSet().length;

    topVideos = List<Map<String, dynamic>>.from(widget.videos)
      ..sort((a, b) => (b['views'] ?? 0).compareTo(a['views'] ?? 0));
    if (topVideos.length > 5) topVideos = topVideos.sublist(0, 5);

    // ===== Games Stats =====
    try {
      final resTopGames =
          await http.get(Uri.parse('${getBackendUrl()}/api/game/getTopPlayedGames'));
      if (resTopGames.statusCode == 200) {
        topGames = List<Map<String, dynamic>>.from(jsonDecode(resTopGames.body));
        for (var game in topGames) {
          if (!game.containsKey('title')) {
            game['title'] = game['name'] ?? 'Unknown Game';
          }
        }
      }
      totalGames = widget.games.length;
    } catch (e) {
      topGames = [];
    }

    // ===== Categories Distribution =====
    Map<String, int> distr = {};
    for (var v in widget.videos) {
      String cat = v['category'] ?? 'Other';
      distr[cat] = (distr[cat] ?? 0) + 1;
    }
    categoriesDistr = distr;

    setState(() {
      loading = false;
    });
  }

  int _getTotalPlayers() {
  int total = 0;
  for (var game in widget.games) {
    total += (game['playedBy'] as List?)?.length ?? 0;
  }
  return total;
}

int _getTotalPublishedGames() {
  int total = 0;
  for (var game in widget.games) {
    if (game['isPublished'] == true) total++;
  }
  return total;
}

int _getTotalScores() {
  int total = 0;
  for (var game in widget.games) {
    final players = (game['playedBy'] as List?) ?? [];
    for (var p in players) {
      total += (p['score'] ?? 0) as int;
    }
  }
  return total;
}


  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ===== Toggle Buttons for Videos / Games =====
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildToggleButton("Videos", showVideos),
              const SizedBox(width: 16),
              _buildToggleButton("Games", !showVideos),
            ],
          ),

          const SizedBox(height: 16),

            showVideos
            ? const Text(
            "View insights and performance metrics",
            style: TextStyle(color: AppColors.textAccent, fontSize: 16),
          )

          :const Text(
            "Play insights and performance metrics",
            style: TextStyle(color: AppColors.textAccent, fontSize: 16),
          ),

          const SizedBox(height: 16),

    // ===== Section-specific Stats Cards =====
Center(
  child: Wrap(
    spacing: 16,
    runSpacing: 16,
    children: showVideos
        ? [
            _buildStatCard(Icons.videocam, 'Total Videos', totalVideos.toString(),
                const Color.fromARGB(255, 231, 195, 77)),
            _buildStatCard(Icons.video_library, 'Published Videos', totalPublished.toString(),
                const Color.fromARGB(255, 231, 195, 77)),
            _buildStatCard(Icons.play_arrow, 'Total Playlists', totalPlaylists.toString(),
                const Color.fromARGB(255, 231, 195, 77)),
            _buildStatCard(Icons.remove_red_eye, 'Total Views', totalViews.toString(),
                const Color.fromARGB(255, 231, 195, 77)),
          ]
        : [
            _buildStatCard(Icons.videogame_asset, 'Total Games', totalGames.toString(),
                const Color.fromARGB(255, 231, 195, 77)),
            _buildStatCard(Icons.person, 'Total Players', _getTotalPlayers().toString(),
                const Color.fromARGB(255, 231, 195, 77)),
            _buildStatCard(Icons.check_circle, 'Published Games', _getTotalPublishedGames().toString(),
                const Color.fromARGB(255, 231, 195, 77)),
            _buildStatCard(Icons.score, 'Total Scores', _getTotalScores().toString(),
                const Color.fromARGB(255, 231, 195, 77)),
          ],
  ),
),


          const SizedBox(height: 32),

          // ===== Animated Section: Shows Either Videos Analytics or Games Analytics =====
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: showVideos
                ? _buildVideosAnalyticsSection()
                : _buildGamesAnalyticsSection(),
          ),
        ],
      ),
    );
  }

  // =================== Sections ===================

  Widget _buildVideosAnalyticsSection() {
    return Column(
      key: const ValueKey('videos-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Videos Chart
        if (topVideos.isNotEmpty)
          _buildBarChartCard("Top 5 Videos by Views", topVideos, 'views'),
        const SizedBox(height: 32),

        // Content by Topic
        _buildContentByTopic(),
        const SizedBox(height: 32),

        // Expandable Videos List
        ExpansionTile(
          title: const Text(
            "Videos",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          leading: const Icon(Icons.videocam),
          children: widget.videos.isNotEmpty
              ? widget.videos.map<Widget>((video) {
                  return ListTile(
                    leading: Image.network(
                      video['thumbnailUrl'] ?? "https://via.placeholder.com/80",
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(video['title'] ?? "Unknown Video"),
                    subtitle: Text("Views: ${video['views'] ?? 0}"),
                  );
                }).toList()
              : [const ListTile(title: Text("No videos available"))],
        ),
      ],
    );
  }

  Widget _buildGamesAnalyticsSection() {
    return Column(
      key: const ValueKey('games-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Games Chart
        if (topGames.isNotEmpty)
          _buildBarChartCard("Top 4 Games by Plays", topGames, 'playCount'),
        const SizedBox(height: 32),

        // Expandable Games List
 // ===== Expandable Games =====
ExpansionTile(
  title: const Text(
    "Games",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
  leading: const Icon(Icons.videogame_asset),
  children: widget.games.isNotEmpty
      ? widget.games.map<Widget>((game) {
          final playCount = (game['playedBy'] as List?)?.length ?? 0;
          final totalScore = (game['playedBy'] as List?)
                  ?.fold<int>(0, (sum, p) => sum + ((p['score'] ?? 0) as int)) ??
              0;
          return ListTile(
            title: Text( game['name'] ?? "Unknown Game"),
            subtitle: Text(
                "Plays: $playCount | Total Score: $totalScore | Theme: ${game['theme'] ?? 'N/A'}"),
          );
        }).toList()
      : [const ListTile(title: Text("No games available"))],
),

      ],
    );
  }

  // =================== Widgets ===================

  Widget _buildToggleButton(String title, bool active) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? AppColors.goldenYellow : Colors.grey.shade300,
        foregroundColor: active ? Colors.black : Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        setState(() {
          showVideos = title == "Videos";
        });
      },
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
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
