import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:bright_minds/screens/childStory/readOnlyStoryPage.dart'; 

class ChildNotificationsScreen extends StatefulWidget {
  const ChildNotificationsScreen({super.key});

  @override
  State<ChildNotificationsScreen> createState() =>
      _ChildNotificationsScreenState();
}

class _ChildNotificationsScreenState extends State<ChildNotificationsScreen> {
  List _notifications = [];
  bool _isLoading = true;

  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.122:3000"; // أو localhost حسبك
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${getBackendUrl()}/api/notifications/my'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print("🔔 Notifications response: ${response.body}");

    if (response.statusCode == 200) {
  final data = jsonDecode(response.body); 

  setState(() {
    _notifications = data; 
    _isLoading = false;
  });
}
 else {
        print("❌ Error loading notifications: ${response.body}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("⚠ Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsSeen(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      await http.put(
        Uri.parse('${getBackendUrl()}/api/notifications/$notificationId/seen'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      setState(() {
        _notifications = _notifications.map((n) {
          if (n['_id'] == notificationId) {
            n['seen'] = true;
          }
          return n;
        }).toList();
      });
    } catch (e) {
      print("⚠ Error marking as seen: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alerts"),
        backgroundColor: const Color(0xFFEBA1AB),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text("No notifications yet 💤"),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final String message = notif['message'] ?? '';
                    final String? storyId = notif['storyId'];
                    final bool seen = notif['seen'] ?? false;

                    // لو عندنا createdAt
                    String timeText = '';
                    if (notif['createdAt'] != null) {
                      final dt = DateTime.tryParse(notif['createdAt']);
                      if (dt != null) {
                        timeText =
                            '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          Icons.notifications,
                          color: seen ? Colors.grey : Colors.redAccent,
                        ),
                        title: Text(message),
                        subtitle:
                            timeText.isNotEmpty ? Text(timeText) : null,
                        trailing: !seen
                            ? const Icon(Icons.circle,
                                color: Colors.red, size: 10)
                            : null,
                        onTap: storyId == null
                            ? null
                            : () async {
                                // علمه كمقروء (اختياري)
                                await _markAsSeen(notif['_id']);

                                // افتح القصة
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReadOnlyStoryPage(
                                      storyId: storyId,
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                ),
    );
  }
}
