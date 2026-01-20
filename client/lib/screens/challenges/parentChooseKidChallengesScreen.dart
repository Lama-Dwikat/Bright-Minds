import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';
import 'package:bright_minds/screens/challenges/parentKidWeeklyChallengesScreen.dart';

class ParentChooseKidChallengesScreen extends StatefulWidget {
  const ParentChooseKidChallengesScreen({super.key});

  @override
  State<ParentChooseKidChallengesScreen> createState() =>
      _ParentChooseKidChallengesScreenState();
}

class _ParentChooseKidChallengesScreenState
    extends State<ParentChooseKidChallengesScreen> {
  bool _loading = true;
  String? _token;
  String? _parentId;

  List<Map<String, dynamic>> _kids = [];

  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.74:3000";
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

  if (_token == null) {
    setState(() => _loading = false);
    return;
  }

  await _fetchKids();
}

 Future<void> _fetchKids() async {
  if (_token == null) return;

  setState(() => _loading = true);

  try {
    final resp = await http.get(
      Uri.parse("${getBackendUrl()}/api/users/my-kids"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_token",
      },
    );

    if (resp.statusCode == 200) {
      final List list = jsonDecode(resp.body);
      setState(() {
        _kids = list.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } else {
      setState(() => _kids = []);
    }
  } catch (_) {
    setState(() => _kids = []);
  } finally {
    setState(() => _loading = false);
  }
}

  void _openKid(Map<String, dynamic> kid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParentKidWeeklyChallengesScreen(
          kidId: kid["_id"].toString(),
          kidName: kid["name"]?.toString() ?? "Kid",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoftPinkLight,
      appBar: AppBar(
        backgroundColor: AppColors.peachPink,
        title: const Text("Choose a Child"),
        actions: [
          IconButton(
            onPressed: _fetchKids,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _kids.isEmpty
              ? const Center(
                  child: Text("No kids found."),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _kids.length,
                  itemBuilder: (_, i) {
                    final kid = _kids[i];
                    final name = kid["name"]?.toString() ?? "Kid";
                    final email = kid["email"]?.toString() ?? "";

                    return InkWell(
                      onTap: () => _openKid(kid),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.peachPink.withOpacity(0.22),
                              child: const Icon(Icons.child_care),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  if (email.isNotEmpty)
                                    Text(email,
                                        style: const TextStyle(
                                            color: Colors.black54)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
