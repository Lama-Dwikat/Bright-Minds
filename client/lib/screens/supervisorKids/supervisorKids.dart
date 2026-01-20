





import 'package:bright_minds/widgets/home.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:bright_minds/screens/supervisorKids/supervisorKidDetails.dart';
import 'package:bright_minds/theme/colors.dart';

class SupervisorKidsScreen extends StatefulWidget {
  const SupervisorKidsScreen({super.key});

  @override
  State<SupervisorKidsScreen> createState() => _SupervisorKidsState();
}

class _SupervisorKidsState extends State<SupervisorKidsScreen> {
  List<Map<String, dynamic>> kids = [];
  List<Map<String, dynamic>> filteredKids = []; // Kids filtered by search
  TextEditingController searchController = TextEditingController();

String getBackendUrl() {
  if (kIsWeb) {
    return "http://192.168.1.74:3000";

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


  @override
  void initState() {
    super.initState();
    fetchAllKidsForSupervisor();
  }

  void fetchAllKidsForSupervisor() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('token');

    if (token == null) {
      print("No token found");
      return;
    }

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String userId = decodedToken['id'];
    print("Token = '$token'");
    print("Supervisor ID = '$userId'");

    var response = await http.get(
      Uri.parse('${getBackendUrl()}/api/users/kidsForSupervisor/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print("response= $response");
      final data = jsonDecode(response.body);
      print("Raw response: ${response.body}");


      // Ensure it's a List<Map<String, dynamic>>
      List<Map<String, dynamic>> kidsList = [];
      if (data is List) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            kidsList.add(item);
          }
        }
      }

      setState(() {
        kids = kidsList;
        filteredKids = kidsList; // Initially show all kids
        print("kids = $kids");
      });
    } else {
      print('Failed to load kids: ${response.statusCode}');
    }
  }

  void filterKids(String query) {
    List<Map<String, dynamic>> results = [];
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

  int calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 0;
    DateTime dob = DateTime.parse(dobString);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    return HomePage(
      title: "Kids",
      child: Column(
        children: [
          // 🔎 Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: filterKids,
            ),
          ),

          const SizedBox(height: 10),

          // 📋 Kids List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: filteredKids.length,
              itemBuilder: (context, index) {
                final kid = filteredKids[index];
                final age = calculateAge(kid["age"]);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KidDetails(kid: kid),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color.fromARGB(255, 230, 172, 56),
                          child: Text(
                            kid["name"][0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kid["name"],
                                style: GoogleFonts.robotoSlab(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Age: $age",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
