import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bright_minds/theme/colors.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  // linking new child
  final _emailCtrl = TextEditingController();
  bool _linking = false;

  // loading
  bool _loadingProfile = true;
  bool _loadingKids = true;

  // auth
  String? _token;
  String? _parentId;

  // parent profile
  Map<String, dynamic>? _parent;
  Uint8List? _parentAvatarBytes;

  // kids list
  List _kids = [];

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
    _parentId = decoded["id"]?.toString();

    await _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _fetchParentProfile(),
      _fetchKids(),
    ]);
  }

  Future<void> _fetchParentProfile() async {
    if (_token == null || _parentId == null) return;

    setState(() => _loadingProfile = true);
    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/users/getme/$_parentId"),
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
          _parent = data;
          _parentAvatarBytes = bytes;
        });
      } else {
        _snack("Failed to load profile (${resp.statusCode})");
      }
    } catch (_) {
      _snack("Error loading profile");
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _fetchKids() async {
    if (_token == null) return;

    setState(() => _loadingKids = true);
    try {
      final resp = await http.get(
        Uri.parse("${getBackendUrl()}/api/users/my-kids"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (resp.statusCode == 200) {
        setState(() {
          _kids = jsonDecode(resp.body) ?? [];
        });
      } else {
        setState(() => _kids = []);
        _snack("Failed to load kids (${resp.statusCode})");
      }
    } catch (_) {
      setState(() => _kids = []);
      _snack("Error loading kids");
    } finally {
      setState(() => _loadingKids = false);
    }
  }

  // ✅ edit name/email for parent
  Future<void> _editParentField(String field, String label) async {
    if (_token == null || _parentId == null) return;

    final controller = TextEditingController(text: (_parent?[field] ?? "").toString());

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
        Uri.parse("${getBackendUrl()}/api/users/updateprofile/$_parentId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({field: updated}),
      );

      if (resp.statusCode == 200) {
        setState(() {
          _parent ??= {};
          _parent![field] = updated;
        });
        _snack("Updated ✅");
      } else {
        _snack("Failed to update ($field)");
      }
    } catch (_) {
      _snack("Error updating");
    }
  }

  Future<void> _linkChildByEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack("Please enter child email");
      return;
    }
    if (_token == null) {
      _snack("You are not logged in");
      return;
    }

    setState(() => _linking = true);
    try {
      final resp = await http.post(
        Uri.parse("${getBackendUrl()}/api/users/link-child-by-email"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({"childEmail": email}),
      );

      final data = jsonDecode(resp.body);

      if (resp.statusCode == 200) {
        _snack("Linked ✅");
        _emailCtrl.clear();
        await _fetchKids();
      } else {
        _snack(data["error"]?.toString() ?? "Failed");
      }
    } catch (_) {
      _snack("Error linking child");
    } finally {
      setState(() => _linking = false);
    }
  }

  // ✅ unlink child (remove from parent)
  Future<void> _unlinkChild(String childId, String childName) async {
    if (_token == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove child?"),
        content: Text("Do you want to remove $childName from your linked kids?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove")),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final resp = await http.post(
        Uri.parse("${getBackendUrl()}/api/users/unlink-child"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({"childId": childId}),
      );

      if (resp.statusCode == 200) {
        _snack("Removed ✅");
        await _fetchKids();
      } else {
        final data = jsonDecode(resp.body);
        _snack(data["error"]?.toString() ?? "Failed to remove");
      }
    } catch (_) {
      _snack("Error removing child");
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 52,
      backgroundColor: Colors.white,
      backgroundImage: (_parentAvatarBytes != null) ? MemoryImage(_parentAvatarBytes!) : null,
      child: (_parentAvatarBytes == null)
          ? Text(
              (_parent?["name"] ?? "P").toString().substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.bgWarmPink),
            )
          : null,
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    required VoidCallback onEdit,
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
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.blue),
            tooltip: "Edit",
          )
        ],
      ),
    );
  }

  Widget _kidCard(Map kid) {
    final id = (kid["_id"] ?? "").toString();
    final name = (kid["name"] ?? "Kid").toString();
    final email = (kid["email"] ?? "").toString();
    final ageGroup = (kid["ageGroup"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.peachPink.withOpacity(0.25),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "K",
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.bgBlushRoseDark),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) Text(email),
            if (ageGroup.isNotEmpty)
              Text("Age Group: $ageGroup", style: const TextStyle(color: Colors.black54)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _unlinkChild(id, name),
          tooltip: "Remove",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parentName = (_parent?["name"] ?? "Loading...").toString();
    final parentEmail = (_parent?["email"] ?? "").toString();

    return Scaffold(
      backgroundColor: AppColors.bgSoftPinkLight,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppColors.peachPink,
        actions: [
          IconButton(
            onPressed: () async {
              await _loadAll();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // top header (avatar)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.peachPink,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  _loadingProfile ? const CircularProgressIndicator() : _avatar(),
                  const SizedBox(height: 10),
                  Text(
                    parentName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // editable info
            _infoRow(
              title: "Name",
              value: parentName,
              onEdit: () => _editParentField("name", "Name"),
            ),
            const SizedBox(height: 12),
            _infoRow(
              title: "Email",
              value: parentEmail.isEmpty ? "—" : parentEmail,
              onEdit: () => _editParentField("email", "Email"),
            ),

            const SizedBox(height: 18),

            // kids section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("My Kids", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_loadingKids) const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 10),

            if (!_loadingKids && _kids.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: const Text("No kids linked yet."),
              )
            else
              Column(
                children: _kids.map((k) => _kidCard(Map<String, dynamic>.from(k))).toList(),
              ),

            const SizedBox(height: 18),

            // link new child
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add another child", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Child email",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _linking ? null : _linkChildByEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bgWarmPink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _linking
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Link"),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Note: child must be registered first.", style: TextStyle(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
