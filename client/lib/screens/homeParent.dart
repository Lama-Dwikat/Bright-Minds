
import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/widgets/home.dart';
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




class HomeParent extends StatefulWidget{
  const HomeParent({super.key});
@override
 State<HomeParent>createState()=>_HomeParentState();
}
class _HomeParentState extends State<HomeParent>{
String userId="";
List kids=[];
List videoHistory=[];
  Map<String, List> videoHistoryByKid = {};
  Map<String, List> dailyWatchByKid = {};

  String getBackendUrl() {
  if (kIsWeb) {
    // For web, use localhost or network IP
   // return "http://localhost:5000";
    return "http://localhost:3000";

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



Future <void> getKids() async{
try{
final response= await http.get(Uri.parse('${getBackendUrl()}/api/users/getParentKids/$userId'),
headers:{"Content-Type":"application/json"},);
  
  if(response.statusCode==200){
    setState((){
   kids=jsonDecode(response.body);});
  } else {
    print("Failed to fetch kids: ${response.statusCode} ${response.body}");
    }
}catch(err){
     print("❌ Error fetching kids: $err");
}

}


// Future <void> getKidHistory() async{
// try{
//  String kidId=kids[0]['userId'];
// final response= await http.get(Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
// headers:{"Content-Type":"application/json"},);
  
//   if(response.statusCode==200){
//     setState((){
//    videoHistory=jsonDecode(response.body);});
//   } else {
//     print("Failed to fetch kids: ${response.statusCode} ${response.body}");
//     }
// }catch(err){
//      print("❌ Error fetching kids: $err");
// }

// }



   Future<void> getKidVideoHistory(String kidId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/history/getHistory/$kidId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List history = jsonDecode(response.body);

        List detailedHistory = history.map((item) {
          final video = item['videoId'];
          if (video == null) return null;

          return {
            "title": video['title'] ?? "Unknown",
            "thumbnailUrl": video['thumbnailUrl'] ?? "",
            "watchedAt": item['watchedAt'] ?? "",
            "durationWatched": item['durationWatched'] ?? 0,
          };
        }).where((element) => element != null).toList();

        setState(() {
          videoHistoryByKid[kidId] = detailedHistory;
        });
      } else {
        print("Failed to fetch video history: ${response.statusCode}");
      }
    } catch (err) {
      print("❌ Error fetching video history for kid: $err");
    }
  }

  Future<void> getKidDailyWatch(String kidId) async {
    try {
      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/dailywatch/getUserWatchRecord/$kidId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        List dailyWatch = jsonDecode(response.body);

        setState(() {
          dailyWatchByKid[kidId] = dailyWatch.map((record) {
            return {
              "date": record['date'] ?? "",
              "dailyWatchMin": record['dailyWatchMin'] ?? 0,
              "limitWatchMin": record['limitWatchMin'] ?? 0,
            };
          }).toList();
        });
      } else {
        print("Failed to fetch daily watch: ${response.statusCode}");
      }
    } catch (err) {
      print("❌ Error fetching daily watch for kid: $err");
    }
  }

  @override
  void initState() {
    super.initState();
    getUserId().then((_) => getKids());
  }

  @override
  Widget build(BuildContext context) {
    getKidVideoHistory("690f4c9884457c43ccd10f07");
    getKidDailyWatch("690f4c9884457c43ccd10f07");
    return HomePage(
      title:"Home",
      child: kids.isEmpty
          ? const Center(child: Text("No kids found"))
          : ListView.builder(
              itemCount: kids.length,
              itemBuilder: (context, index) {
                final kid = kids[index];
                final kidId = kid['userId'] ?? kid['_id'];
                final videoHistory = videoHistoryByKid[kidId] ?? [];
                final dailyWatch = dailyWatchByKid[kidId] ?? [];

                return ExpansionTile(
                  title: Text(kid['name'] ?? "Unknown Kid"),
                  children: [
                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Video History",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    ...videoHistory.map((video) => ListTile(
                          leading: (video['thumbnailUrl'] ?? "").isNotEmpty
                              ? Image.network(video['thumbnailUrl'],
                                  width: 60, fit: BoxFit.cover)
                              : const Icon(Icons.video_library),
                          title: Text(video['title'] ?? "Unknown"),
                          subtitle: Text(
                              "Watched at: ${video['watchedAt'] != "" ? DateTime.parse(video['watchedAt']).toLocal() : "Unknown"}\nDuration: ${video['durationWatched'].toStringAsFixed(2)} min"),
                        )),

                    const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Daily Watch Records",
                            style: TextStyle(fontWeight: FontWeight.bold))),
                    ...dailyWatch.map((record) => ListTile(
                          title: Text(
                              "Date: ${record['date'] != "" ? DateTime.parse(record['date']).toLocal().toString().split(' ')[0] : "Unknown"}"),
                          subtitle: Text(
                              "Watched: ${record['dailyWatchMin'].toStringAsFixed(2)} min / Limit: ${record['limitWatchMin']} min"),
                        )),
                  ],
                );
              },
            ),
    );
  }
}