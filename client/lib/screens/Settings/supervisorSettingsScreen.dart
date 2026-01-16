import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bright_minds/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupervisorSettingsScreen extends StatefulWidget {
  const SupervisorSettingsScreen({super.key});

  @override
  State<SupervisorSettingsScreen> createState() =>
      _SupervisorSettingsScreenState();
}

class _SupervisorSettingsScreenState extends State<SupervisorSettingsScreen> {
  bool _loading = true;

  String? _token;
  String? _id;

  Map<String, dynamic>? _user;
  Uint8List? _avatarBytes;

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    return "http://localhost:3000";
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token");
    if (_token == null) return;

    final decoded = JwtDecoder.decode(_token!);
    _id = decoded["id"]?.toString();

    await _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_token == null || _id == null) return;

    setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/users/getme/$_id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);

        Uint8List? bytes;
        final picBytes = data?["profilePicture"]?["data"]?["data"];
        if (picBytes != null && picBytes is List) {
          bytes = Uint8List.fromList(List<int>.from(picBytes));
        }

        setState(() {
          _user = data;
          _avatarBytes = bytes;
        });
      } else {
        _snack("Failed to load profile (${resp.statusCode})");
      }
    } catch (_) {
      _snack("Error loading profile");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _editField(String field, String label) async {
    if (_token == null || _id == null) return;

    final controller =
        TextEditingController(text: (_user?[field] ?? "").toString());

    final updated = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit $label"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $label"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (updated == null || updated.isEmpty) return;

    try {
      final resp = await http.put(
        Uri.parse("${getBackendUrl()}/api/users/updateprofile/$_id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({field: updated}),
      );

      if (resp.statusCode == 200) {
        setState(() {
          _user ??= {};
          _user![field] = updated;
        });
        _snack("Updated ✅");
      } else {
        _snack("Failed to update");
      }
    } catch (_) {
      _snack("Error updating");
    }
  }

  Future<void> _viewCv() async {
    if (_token == null) return;

    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/users/my-cv"),
        headers: {"Authorization": "Bearer $_token"},
      );

      if (resp.statusCode == 200) {
        final bytes = resp.bodyBytes;

        final dir = await getTemporaryDirectory();
        final file = File("${dir.path}/my_cv.pdf");
        await file.writeAsBytes(bytes, flush: true);

        await OpenFilex.open(file.path);
      } else if (resp.statusCode == 404) {
        _snack("No CV uploaded");
      } else {
        _snack("Failed to load CV (${resp.statusCode})");
      }
    } catch (_) {
      _snack("Error opening CV");
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _avatar() {
    final name = (_user?["name"] ?? "S").toString();
    return CircleAvatar(
      radius: 52,
      backgroundColor: Colors.white,
      backgroundImage: (_avatarBytes != null) ? MemoryImage(_avatarBytes!) : null,
      child: (_avatarBytes == null)
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : "S",
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.bgWarmPink,
              ),
            )
          : null,
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: "Edit",
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (_user?["name"] ?? "Loading...").toString();
    final email = (_user?["email"] ?? "—").toString();
    final ageGroup = (_user?["ageGroup"] ?? "—").toString();
    final cvStatus = (_user?["cvStatus"] ?? "pending").toString();

    return Scaffold(
      backgroundColor: AppColors.bgSoftPinkLight,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.peachPink,
        actions: [
          IconButton(onPressed: _loadProfile, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.peachPink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        _avatar(),
                        const SizedBox(height: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _infoRow(
                    title: "Name",
                    value: name,
                    onEdit: () => _editField("name", "Name"),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
                    title: "Email",
                    value: email,
                    onEdit: () => _editField("email", "Email"),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(title: "Age Group", value: ageGroup),
                  const SizedBox(height: 12),
                  _infoRow(title: "CV Status", value: cvStatus.toUpperCase()),

                  const SizedBox(height: 18),

                  // CV Card (View only)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "My CV",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _viewCv,
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text("View CV"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bgWarmPink,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "CV was uploaded during registration and cannot be edited here.",
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
