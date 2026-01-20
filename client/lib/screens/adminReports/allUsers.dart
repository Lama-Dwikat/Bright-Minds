


import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/screens/adminReports/userPage.dart';

class AllUsersPage extends StatefulWidget {
  final List admins;
  final List parents;
  final List kids;
  final List supervisors;

  const AllUsersPage({
    super.key,
    required this.admins,
    required this.parents,
    required this.kids,
    required this.supervisors,
  });

  @override
  State<AllUsersPage> createState() => _AllUsersPageState();
}

class _AllUsersPageState extends State<AllUsersPage> {
  late List admins;
  late List parents;
  late List kids;
  late List supervisors;

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? ageGroup;
  XFile? cvFile;

  String? token;

  final Map<String, bool> _expandedRole = {
  "Kids": false,
  "Parents": false,
  "Supervisors": false,
  "Admins": false,
};


  @override
  void initState() {
    super.initState();
    admins = [...widget.admins];
    parents = [...widget.parents];
    kids = [...widget.kids];
    supervisors = [...widget.supervisors];
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
  }

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildRoleSection("Kids", kids),
          _buildRoleSection("Parents", parents),
          _buildRoleSection("Supervisors", supervisors),
          _buildRoleSection("Admins", admins),
        ],
      ),
    );
  }

Widget _buildRoleSection(String role, List users) {
  final bool isExpanded = _expandedRole[role] ?? false;

  return SizedBox(
    width: MediaQuery.of(context).size.width,
    child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER (click to expand / collapse)
          InkWell(
            onTap: () {
              setState(() {
                _expandedRole[role] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Text(
                    role,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add,
                        color: Color.fromARGB(255, 159, 133, 3)),
                    onPressed: () => _showAddUserDialog(role),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // USERS (only when expanded)
          if (isExpanded)
            ...(users.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text("No users found"),
                    )
                  ]
                : users.map((u) => _buildUserCard(u, role)).toList()),
        ],
      ),
    ),
  );
}
Future<void> _deleteUser(String id, String role) async {
  if (token == null) return;

  final res = await http.delete(
    Uri.parse('${getBackendUrl()}/api/users/deleteme/$id'),
    headers: {
      "Authorization": "Bearer $token",
    },
  );

  if (res.statusCode == 200 || res.statusCode == 204) {
    setState(() {
      if (role == "Kids") kids.removeWhere((u) => u['_id'] == id);
      if (role == "Parents") parents.removeWhere((u) => u['_id'] == id);
      if (role == "Supervisors") supervisors.removeWhere((u) => u['_id'] == id);
      if (role == "Admins") admins.removeWhere((u) => u['_id'] == id);
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to delete user")),
    );
  }
}



  Widget _buildUserCard(Map user, String role) {
  String? supervisorAgeGroup = user['ageGroup'];
  String? supervisorCvStatus = user['cvStatus'];
  String? kidAgeGroup = user['ageGroup'];

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserPage(user: user)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// NAME + DELETE ICON
            Row(
              children: [
                Expanded(
                  child: Text(
                    user['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color.fromARGB(255, 213, 181, 21)),
                  onPressed: () {
                    _deleteUser(user['_id'], role);
                  },
                ),
              ],
            ),

            const SizedBox(height: 4),
            Text(user['email']),
            const SizedBox(height: 6),

            /// KIDS AGE GROUP
            if (role == "Kids" && kidAgeGroup != null)
              Text("Age Group: $kidAgeGroup"),

            /// SUPERVISOR CONTROLS
            if (role == "Supervisors")
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: supervisorAgeGroup,
                      decoration:
                          const InputDecoration(labelText: "Age Group"),
                      items: const [
                        DropdownMenuItem(value: "5-8", child: Text("5-8")),
                        DropdownMenuItem(value: "9-12", child: Text("9-12")),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          _updateAgeGroup(user['_id'], v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: supervisorCvStatus,
                      decoration:
                          const InputDecoration(labelText: "CV Status"),
                      items: const [
                        DropdownMenuItem(
                            value: "pending", child: Text("Pending")),
                        DropdownMenuItem(
                            value: "approved", child: Text("Approved")),
                        DropdownMenuItem(
                            value: "rejected", child: Text("Rejected")),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          _updateCvStatus(user['_id'], v);
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

void _showAddUserDialog(String role) {
  nameController.clear();
  emailController.clear();
  passwordController.clear();
  ageGroup = null;
  cvFile = null;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Add $role"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _input(nameController, "Name"),
              _input(emailController, "Email"),
              _input(passwordController, "Password", obscure: true),
              if (role == "Kids") _kidsFields(),
              if (role == "Supervisors") _supervisorFields(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            // Map role to backend key
            String backendRole = role.toLowerCase();
            if (role == "Kids") backendRole = "child";
            if (role == "Supervisors") backendRole = "supervisor";
            if (role == "Admins") backendRole = "admin";
            if (role == "Parents") backendRole = "parents";

            _submitUser(backendRole);
          },
          child: const Text("Add"),
        ),
      ],
    ),
  );
}


  Widget _kidsFields() {
    return DropdownButtonFormField<String>(
      value: ageGroup,
      decoration: const InputDecoration(labelText: "Age Group"),
      items: const [
        DropdownMenuItem(value: "5-8", child: Text("5-8")),
        DropdownMenuItem(value: "9-12", child: Text("9-12")),
      ],
      validator: (v) => v == null ? "Required" : null,
      onChanged: (v) => setState(() => ageGroup = v),
    );
  }

  Widget _supervisorFields() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ElevatedButton.icon(
        onPressed: pickCV,
        icon: const Icon(Icons.upload_file),
        label: Text(cvFile == null ? "Upload CV" : "CV Selected"),
      ),
    );
  }

  Widget _input(TextEditingController c, String label,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        validator: (v) => v!.isEmpty ? "Required" : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }


  Future<void> _updateAgeGroup(String id, String value) async {
    if (token == null) return;
    final res = await http.put(
      Uri.parse('${getBackendUrl()}/api/users/addAgeGroup/$id'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"ageGroup": value}),
    );
    if (res.statusCode == 200) {
      setState(() {
        supervisors.firstWhere((u) => u['_id'] == id)['ageGroup'] = value;
      });
    }
  }

  Future<void> _updateCvStatus(String id, String value) async {
    if (token == null) return;
    final res = await http.put(
      Uri.parse('${getBackendUrl()}/api/users/updateCvStatus/$id'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"status": value}),
    );
    if (res.statusCode == 200) {
      setState(() {
        supervisors.firstWhere((u) => u['_id'] == id)['cvStatus'] = value;
      });
    }
  }

  Future<void> pickCV() async {
    final XTypeGroup pdf = XTypeGroup(label: 'PDF', extensions: ['pdf']);
    cvFile = await openFile(acceptedTypeGroups: [pdf]);
    setState(() {});
  }




  Future<void> _submitUser(String role) async {
    if (!_formKey.currentState!.validate()) return;
    if (token == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Token not loaded")));
      return;
    }

    String? cvBase64;
    if (cvFile != null) {
      cvBase64 = base64Encode(await cvFile!.readAsBytes());
    }

    final body = {
      "name": nameController.text,
      "email": emailController.text,
      "password": passwordController.text,
      "role": role.toLowerCase(),
      "ageGroup": ageGroup,
      "cv": cvBase64,
      "cvStatus": role == "supervisor" ? "pending" : null,
    };

    final res = await http.post(
      Uri.parse('${getBackendUrl()}/api/users/createUser'),
      headers: {
        "Content-Type": "application/json",
      //  "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 201) {
      final newUser = jsonDecode(res.body);
      setState(() {
        if (role == "child") kids.add(newUser);
        if (role == "parent") parents.add(newUser);
        if (role == "supervisor") supervisors.add(newUser);
        if (role == "admin") admins.add(newUser);
      });
      Navigator.pop(context);
    } else {
      final err = jsonDecode(res.body);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err['error'] ?? 'Error')));
    }
  }
}






