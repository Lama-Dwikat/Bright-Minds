
// import 'dart:convert';

// import 'package:bright_minds/widgets/home.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:io' show Platform;
// import 'package:flutter/foundation.dart' show kIsWeb;





// class HomeAdmin extends StatefulWidget{
//   const HomeAdmin({super.key});


//  @override
//   State<HomeAdmin> createState() => _HomeAdminState();
// }
// class _HomeAdminState extends State<HomeAdmin> {
//   String _dropDownItem = "pending";
//   List supervisors = [];

//   String getBackendUrl() {

//  if (kIsWeb) {
//     // For web, use localhost or network IP
//    // return "http://localhost:5000";
//     return "http://192.168.1.122:3000";

//   } else if (Platform.isAndroid) {
//     // Android emulator
//     return "http://10.0.2.2:3000";
//   } else if (Platform.isIOS) {
//     // iOS emulator
//     return "http://localhost:3000";
//   } else {
//     // fallback
//     return "http://localhost:3000";
//   }
// }
//   @override
//   void initState() {
//     super.initState();
//     fetchSupervisors(); // fetch data on load
//   }

// void fetchSupervisors() async {
//   final response = await http.get(
//     Uri.parse('${getBackendUrl()}/api/users/role/supervisor'),
//     headers: {"Content-Type": "application/json"},
//   );

//   if (response.statusCode == 200) {
//     final data = jsonDecode(response.body);
//     setState(() {
//       // If backend returns { users: [...] }, use data['users']
//       supervisors = data is List ? data : data['users'] ?? [];
//     });
//     print(supervisors);
//   } else {
//     print('Failed to load supervisors: ${response.statusCode}');
//   }
// }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Admin Home'),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: supervisors.length,
//               itemBuilder: (context, index) {
//                 final supervisor = supervisors[index];
//                 return ListTile(
//                   title: Text(supervisor['name'] ?? 'No Name'),
//                   subtitle: Text(supervisor['email'] ?? 'No Email'),
//                 );
//               },
//             ),
//           ),
//           DropdownButton<String>(
//             value: _dropDownItem,
//             items: const [
//               DropdownMenuItem(value: "pending", child: Text("Pending")),
//               DropdownMenuItem(value: "approved", child: Text("Approved")),
//               DropdownMenuItem(value: "rejected", child: Text("Rejected")),
//             ],
//             onChanged: (String? value) {
//               setState(() {
//                 _dropDownItem = value!;
//               });
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  List supervisors = [];

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.122:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }



void fetchSupervisors() async {
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
}

Future<String?> getToken() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Future<void> updateCvStatus(String id, String newStatus, BuildContext context) async {
  final token = await getToken();

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Not authorized. Please log in again.")),
    );
    return;
  }

  var response = await http.put(
    Uri.parse('${getBackendUrl()}/api/users/updateCvStatus/$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", 
    },
    body: jsonEncode({"status": newStatus}),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CV status updated to $newStatus")),
    );
  } else {
    print("Failed to update CV status: ${response.statusCode}");
    print("Response: ${response.body}");
  }
}

Future<void> updateAgeGroup(String id, String newAgeGroup, BuildContext context) async {
  final token = await getToken();

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Not authorized. Please log in again.")),
    );
    return;
  }

  var response = await http.put(
    Uri.parse('${getBackendUrl()}/api/users/addAgeGroup/$id'),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token", // ✅ added
    },
    body: jsonEncode({"ageGroup": newAgeGroup}),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Age group updated to $newAgeGroup")),
    );
  } else {
    print("Failed to update age group: ${response.statusCode}");
    print("Response: ${response.body}");
  }
}

  @override
  void initState() {
    super.initState();
    fetchSupervisors();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Home')),
      body: supervisors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: supervisors.length,
              itemBuilder: (context, index) {
                final supervisor = supervisors[index];
                String currentCvStatus = supervisor['cvStatus'] ?? 'pending';
                String currentAgeGroup = supervisor['ageGroup'] ?? '5-8';

                return Card(
                  margin: const EdgeInsets.all(8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supervisor['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(supervisor['email'] ?? 'No Email'),

                        const SizedBox(height: 10),

                        // CV Status Dropdown
                        Row(
                          children: [
                            const Text("CV Status: "),
                            DropdownButton<String>(
                              value: currentCvStatus,
                              items: const [
                                DropdownMenuItem(
                                    value: "pending", child: Text("Pending")),
                                DropdownMenuItem(
                                    value: "approved", child: Text("Approved")),
                                DropdownMenuItem(
                                    value: "rejected", child: Text("Rejected")),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    supervisors[index]['cvStatus'] = newValue;
                                  });
                                  updateCvStatus(supervisor['_id'], newValue, context);
                                }
                              },
                            ),
                          ],
                        ),

                        // Age Group Dropdown
                        Row(
                          children: [
                            const Text("Age Group: "),
                            DropdownButton<String>(
                              value: currentAgeGroup,
                              items: const [
                                DropdownMenuItem(
                                    value: "5-8", child: Text("5-8")),
                                DropdownMenuItem(
                                    value: "9-12", child: Text("9-12")),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    supervisors[index]['ageGroup'] = newValue;
                                  });
                                  updateAgeGroup(supervisor['_id'], newValue, context);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

