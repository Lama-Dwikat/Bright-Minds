import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/theme/colors.dart';
import 'package:intl/intl.dart';

class ChildSettingsScreen extends StatefulWidget {
  const ChildSettingsScreen({super.key});

  @override
  State<ChildSettingsScreen> createState() => _ChildSettingsScreenState();
}

class _ChildSettingsScreenState extends State<ChildSettingsScreen> {
  bool _loading = true;

  String? _token;
  String? _childId;

  Map<String, dynamic>? _child;
  Uint8List? _childAvatarBytes;

  Map<String, dynamic>? _parent;
  Map<String, dynamic>? _supervisor;

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
    _childId = decoded["id"]?.toString();

    await _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await _fetchChildProfile();
    await _fetchParentAndSupervisor();
    setState(() => _loading = false);
  }

  Future<void> _fetchChildProfile() async {
    if (_token == null || _childId == null) return;

    final resp = await http.get(
      Uri.parse("${getBackendUrl()}/api/users/getme/$_childId"),
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
        _child = data;
        _childAvatarBytes = bytes;
      });
    }
  }

  Future<void> _fetchParentAndSupervisor() async {
    if (_token == null) return;

    final parentId = _child?["parentId"]?.toString();
    final supervisorId = _child?["supervisorId"]?.toString();

    // fetch parent if exists
    if (parentId != null && parentId.isNotEmpty) {
      try {
        final resp = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getme/$parentId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token",
          },
        );
        if (resp.statusCode == 200) {
          setState(() => _parent = jsonDecode(resp.body));
        }
      } catch (_) {}
    } else {
      setState(() => _parent = null);
    }

    // fetch supervisor if exists
    if (supervisorId != null && supervisorId.isNotEmpty) {
      try {
        final resp = await http.get(
          Uri.parse("${getBackendUrl()}/api/users/getme/$supervisorId"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $_token",
          },
        );
        if (resp.statusCode == 200) {
          setState(() => _supervisor = jsonDecode(resp.body));
        }
      } catch (_) {}
    } else {
      setState(() => _supervisor = null);
    }
  }

  Future<void> _editChildField(String field, String label) async {
    if (_token == null || _childId == null) return;

    final controller = TextEditingController(text: (_child?[field] ?? "").toString());

    final updated = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Edit $label"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Enter new $label"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
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
        Uri.parse("${getBackendUrl()}/api/users/updateprofile/$_childId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({field: updated}),
      );

      if (resp.statusCode == 200) {
        setState(() {
          _child ??= {};
          _child![field] = updated;
        });
        _snack("Updated ✅");
      } else {
        _snack("Failed to update");
      }
    } catch (_) {
      _snack("Error updating");
    }
  }
String _formatDob(dynamic dob) {
  try {
    if (dob == null) return "—";
    final d = DateTime.parse(dob.toString());
    return DateFormat("yyyy-MM-dd").format(d);
  } catch (_) {
    return "—";
  }
}

Future<void> _editDob() async {
  if (_token == null || _childId == null) return;

  DateTime initial = DateTime.now().subtract(const Duration(days: 365 * 8));
  try {
    final raw = _child?["age"];
    if (raw != null) initial = DateTime.parse(raw.toString());
  } catch (_) {}

  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime.now(),
  );

  if (picked == null) return;

  try {
    final resp = await http.put(
      Uri.parse("${getBackendUrl()}/api/users/updateprofile/$_childId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
      body: jsonEncode({"age": picked.toIso8601String()}),
    );

    if (resp.statusCode == 200) {
      setState(() {
        _child ??= {};
        _child!["age"] = picked.toIso8601String();
      });
      _snack("Birth date updated ✅");
    } else {
      _snack("Failed to update birth date");
    }
  } catch (_) {
    _snack("Error updating birth date");
  }
}

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _avatar(String fallbackLetter, Uint8List? bytes) {
    return CircleAvatar(
      radius: 52,
      backgroundColor: Colors.white,
      backgroundImage: (bytes != null) ? MemoryImage(bytes) : null,
      child: (bytes == null)
          ? Text(
              fallbackLetter.toUpperCase(),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.bgWarmPink),
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
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: "Edit",
            )
        ],
      ),
    );
  }

  Widget _personCard({
    required String title,
    required Map<String, dynamic>? person,
    required IconData icon,
  }) {
    final name = person?["name"]?.toString() ?? "N/A";
    final email = person?["email"]?.toString() ?? "N/A";

    return Container(
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.peachPink.withOpacity(0.25),
            child: Icon(icon, color: AppColors.bgBlushRoseDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(email, style: const TextStyle(color: Colors.black54)),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childName = (_child?["name"] ?? "Loading...").toString();
    final childEmail = (_child?["email"] ?? "—").toString();
final dobText = _formatDob(_child?["age"]);

    return Scaffold(
      backgroundColor: AppColors.bgSoftPinkLight,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.peachPink,
        actions: [
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.peachPink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        _avatar(childName.isNotEmpty ? childName[0] : "C", _childAvatarBytes),
                        const SizedBox(height: 10),
                        Text(
                          childName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // editable child info
                  _infoRow(
                    title: "Name",
                    value: childName,
                    onEdit: () => _editChildField("name", "Name"),
                  ),
                  const SizedBox(height: 12),
                  _infoRow(
  title: "Email",
  value: childEmail,
),
//const SizedBox(height: 12),
const SizedBox(height: 12),
_infoRow(
  title: "Birth Date",
  value: dobText,
  onEdit: _editDob,
),

                  const SizedBox(height: 18),

                  // parent + supervisor
                  _personCard(
                    title: "Parent",
                    person: _parent,
                    icon: Icons.family_restroom,
                  ),
                  const SizedBox(height: 12),
                  _personCard(
                    title: "Supervisor",
                    person: _supervisor,
                    icon: Icons.school,
                  ),
                ],
              ),
            ),
    );
  }
}
