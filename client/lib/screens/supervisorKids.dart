import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';


class SupervisorKidsScreen extends StatefulWidget {
  const SupervisorKidsScreen({super.key});

  @override
  State<SupervisorKidsScreen> createState() => _SupervisorKidsState();
  }

class _SupervisorKidsState extends State<SupervisorKidsScreen> {
  List kids=[];
  List filteredKids = []; // Kids filtered by search
   TextEditingController searchController = TextEditingController();

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.122:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }
void fetchAllKidsForSupervisor() async {

SharedPreferences pref= await SharedPreferences.getInstance();
String? token= pref.getString('token');
if (token==null){
  print("no token found");
  return;
}
  Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
  String userId= decodedToken['id'];
 var response = await http.get(Uri.parse('${getBackendUrl()}/api/users/kidsForSupervisor/$userId'),
 headers:{
  "Authorization": "Bearer $token",
  "Content-Type": "application/json"});
 if (response.statusCode==200){
  final data = jsonDecode(response.body);
  setState((){
    kids=data is List ? data : data['users'] ?? [];
    filteredKids = kids; // Initially show all kids
      });
}else {
  print('Failed to load kids: ${response.statusCode}');  
}
}

 void filterKids(String query) {
    List results = [];
    if (query.isEmpty) {
      results = kids; // Show all if search is empty
    } else {
      results = kids
          .where((kid) =>
              kid['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredKids = results;
    });
  }
@override
void initState(){
  super.initState();
  fetchAllKidsForSupervisor();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisor Kids'),
      ),
       body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: filterKids, // Calls filterKids on each input
            ),
          ),

          // List of kids
          Expanded(
            child: ListView.builder(
              itemCount: filteredKids.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredKids[index]['name']),
                  subtitle: Text('Age: ${filteredKids[index]['age']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}