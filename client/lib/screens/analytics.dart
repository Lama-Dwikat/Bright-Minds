import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:bright_minds/widgets/home.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:bright_minds/theme/colors.dart';


class AnalyticsScreen extends StatefulWidget {


  AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState()=> _AnalyticState();
  }

  
class _AnalyticState extends State<AnalyticsScreen>{
Map<String,dynamic> categoriesDistr={};  

List<Map<String, dynamic>> topVideos = [];
String? userId;
int totalViews=0;
int totalVideos=0;
int totalPlaylists=0;
int totalPublished=0;


  String getBackendUrl() {
  if (kIsWeb) {
    // For web, use localhost or network IP
   // return "http://localhost:5000";
    return "http://192.168.1.63:3000";

  } else if (Platform.isAndroid) {
    // Android emulator
    return "http://10.0.2.2:3000";
  } else if (Platform.isIOS) {
    // iOS emulator
    return "http://localhost:3000";
  } else {
    // fallback
    return "http://localhost:3000";
  }
}



Future <void> getUserId() async{
  SharedPreferences prefs=await SharedPreferences.getInstance();
  String? token =prefs.getString("token");
  if(token==null)return;
  Map <String,dynamic>decodedToken= JwtDecoder.decode(token);
userId=decodedToken['id'];
}


Future <void> getTopViews()async{
try{
final response= await http.get(Uri.parse('${getBackendUrl()}/api/videos/getTopViews/$userId'),
headers:{"Content-Type":"application/json"},);
  
  if(response.statusCode==200){
    setState((){
   topVideos=(jsonDecode(response.body) as List).map((e)=>Map<String,dynamic>.from(e)).toList(); });
  } else {
    print("Failed to load top views: ${response.statusCode} ${response.body}");
    }
}catch(err){
     print("❌ Error loading videos: $err");
}
}

Future <void> videosDistribution()async{
try{
final response= await http.get(Uri.parse('${getBackendUrl()}/api/videos/getVideosDistribution/$userId'),
headers:{"Content-Type":"application/json"},);
  
  if(response.statusCode==200){
    setState((){
    categoriesDistr={ for (var item in jsonDecode(response.body))
    item['category']:item['count']};
    });;
  } else {
    print("Failed to load top views: ${response.statusCode} ${response.body}");}
}catch(err){
     print("❌ Error loading videos: $err");
}
}

// Future <void> ViewsNumbers()async{
// try{
// final response= await http.get(Uri.parse('${getBackendUrl()}/api/videos/getViewsNumbers/$userId'),
// headers:{"Content-Type":"application/json"},);
  
//   if(response.statusCode==200){
//     final data=jsonDecode(response.body);
//     print("total views : $totalViews");
//     setState((){
//     totalViews=data[0]['totalViews']??0;
//     });;
//   } else {
//     print("Failed to load top views: ${response.statusCode} ${response.body}");}
// }catch(err){
//      print("❌ Error loading videos: $err");
// }
// }
Future<void> ViewsNumbers() async {
  try {
    final response = await http.get(
      Uri.parse('${getBackendUrl()}/api/videos/getViewsNumbers/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print("total views fetched: $data");
      setState(() {
        totalViews = data ?? 0; // ✅ use data directly
      });
    } else {
      print("Failed to load total views: ${response.statusCode} ${response.body}");
    }
  } catch (err) {
    print("❌ Error loading videos: $err");
  }
}


Future <void> VideosNumbers()async{
try{
final response= await http.get(Uri.parse('${getBackendUrl()}/api/videos/getVideosNumbers/$userId'),
headers:{"Content-Type":"application/json"},);
  
  if(response.statusCode==200){
    setState((){
    totalPublished=jsonDecode(response.body);
    });;
  } else {
    print("Failed to load top views: ${response.statusCode} ${response.body}");}
}catch(err){
     print("❌ Error loading videos: $err");
}
}
Future <void> getTotalVideos()async{
try{
final response= await http.get(Uri.parse('${getBackendUrl()}/api/videos/getTotalVideos/$userId'),
headers:{"Content-Type":"application/json"},);
  
  if(response.statusCode==200){
    setState((){
    totalVideos=jsonDecode(response.body);
    });;
  } else {
    print("Failed to load top views: ${response.statusCode} ${response.body}");}
}catch(err){
     print("❌ Error loading videos: $err");
}
}

Future <void> playlistsNumbers()async{
try{
final response= await http.get(Uri.parse('${getBackendUrl()}/api/playlists/getPlaylistsNumbers/$userId'),
headers:{"Content-Type":"application/json"},);
  
  if(response.statusCode==200){
    setState((){
    totalPlaylists=jsonDecode(response.body);
    });;
  } else {
    print("Failed to load top views: ${response.statusCode} ${response.body}");}
}catch(err){
     print("❌ Error loading videos: $err");
}
}


@override
void initState() {
  super.initState();
  getUserId().then((_) {
    getTopViews();
    videosDistribution();
    ViewsNumbers();
    VideosNumbers();
    getTotalVideos();
    playlistsNumbers();
  });
}



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "View insights and performance metrics",
                  style: TextStyle(color: AppColors.textAccent)),
              const SizedBox(height: 16),

              // Stats Cards
               Center(
              child:Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                 
                _buildStatCard(Icons.videocam, 'Total Videos', totalVideos.toString(),'',  const Color.fromARGB(255, 216, 155, 139)),
                _buildStatCard(Icons.video_library, 'Published Videos', totalPublished.toString(),'',const Color.fromARGB(255, 216, 155, 139)),
                _buildStatCard(Icons.play_arrow, 'Total Playlists', totalPlaylists.toString(),'',const Color.fromARGB(255, 216, 155, 139)),
                _buildStatCard(Icons.remove_red_eye, 'Total Views', totalViews.toString(),'', const Color.fromARGB(255, 216, 155, 139)),
                  
                ],
              ),
               ),
              const SizedBox(height: 32),

              // Top Videos Bar Chart
              _buildBarChartCard('Top 5 Videos by Views', topVideos),

              const SizedBox(height: 32),

              // Content by Topic
              _buildContentByTopic(),
            ],
          ),
        ),
      ),
    );
  }


// =================== Widgets ===================

Widget _buildStatCard(
    IconData icon, String title, String value, String change, Color color) {

  return Expanded(child:Container(
    width: 150,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      // boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(change, style: const TextStyle(fontSize: 12, color: Colors.green)),
      ],
    ),
  ),
  );
}

Widget _buildBarChartCard(String title, List<Map<String, dynamic>> data) {
  // Convert topVideos backend data to 'label'/'value' for the chart
  final List<Map<String, dynamic>> chartData = data
      .map((video) => {'label': video['title'], 'value': video['views']})
      .toList();

  final sorted = List<Map<String, dynamic>>.from(chartData)
    ..sort((a, b) => b['value'].compareTo(a['value'])); // highest → lowest

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
      backgroundColor: Colors.transparent,
      plotAreaBackgroundColor: Colors.white,
      borderColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      title: ChartTitle(
        text: title,
        alignment: ChartAlignment.near,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      primaryXAxis: CategoryAxis(
        labelRotation: 0,
        labelIntersectAction: AxisLabelIntersectAction.wrap,
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          color: Colors.grey.shade300,
          width: 1,
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: Colors.black87,
        textStyle: const TextStyle(color: Colors.white),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: sorted,
          xValueMapper: (d, _) => d['label'],
          yValueMapper: (d, _) => d['value'],
          borderRadius: BorderRadius.circular(8),
          pointColorMapper: (_, __) => AppColors.textAccent,
          width: 0.7,
          spacing: 0.2,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildContentByTopic() {
  // Convert categoriesDistr Map<String,dynamic> to list of maps for progress bars
  final totalCategoryVideos =
      categoriesDistr.values.fold<int>(0, (sum, v) => sum + (v as int));

  final List<Map<String, dynamic>> topicData = categoriesDistr.entries.map((entry) {
    return {
      'label': entry.key,
      'value': entry.value,
      'percent': totalCategoryVideos > 0
          ? entry.value / totalCategoryVideos
          : 0.0, // prevent division by zero
    };
  }).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Content by Topic", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text("Distribution of videos across different topics",
          style: TextStyle(color: AppColors.textAccent)),
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
                  color: AppColors.textAccent,
                  backgroundColor: const Color.fromARGB(255, 249, 205, 194),
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
