import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bright_minds/theme/colors.dart';

class MyDrawingActivitiesScreen extends StatefulWidget {
  const MyDrawingActivitiesScreen({super.key});

  @override
  State<MyDrawingActivitiesScreen> createState() =>
      _MyDrawingActivitiesScreenState();
}

class _MyDrawingActivitiesScreenState extends State<MyDrawingActivitiesScreen> {
  bool isLoading = true;
  List activities = [];

  // ================= BACKEND URL =================
  String getBackendUrl() {
    if (kIsWeb) {
      return "http://192.168.1.63:3000";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    } else {
      return "http://localhost:3000";
    }
  }

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  // ================= FETCH ACTIVITIES =================
  Future<void> fetchActivities() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse("${getBackendUrl()}/api/supervisor/activities");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        activities = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      debugPrint("Failed to load activities: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  }

  // ================= DEACTIVATE (TOGGLE UI) =================
  Future<void> deactivateActivity(String activityId, bool currentlyActive) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse(
      "${getBackendUrl()}/api/drawing/$activityId/deactivate",
    );

    // Snack text حسب الحالة الحالية (لأننا بنعمل Toggle)
    final String actionText = currentlyActive ? "Deactivated" : "Activated";

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Activity $actionText ✅")),
      );

      // إعادة تحميل القائمة (عشان الحالة تتحدث)
      fetchActivities();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed (${response.statusCode})")),
      );
    }
  }

  // ================= DELETE ACTIVITY =================
  Future<void> deleteActivity(String activityId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final url = Uri.parse("${getBackendUrl()}/api/drawing/$activityId");

    final response = await http.delete(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Activity deleted 🗑️")),
      );
      fetchActivities();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete (${response.statusCode})")),
      );
    }
  }

  Future<void> _confirmDelete(String activityId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Activity?"),
        content: const Text("Are you sure you want to delete this activity?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok == true) {
      deleteActivity(activityId);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Drawing Activities",
          style: GoogleFonts.robotoSlab(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.bgWarmPink,
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: fetchActivities,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? _buildEmpty()
              : _buildList(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        "No drawing activities yet",
        style: GoogleFonts.robotoSlab(fontSize: 16),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];

        final bool isActive = activity["isActive"] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.bgWarmPinkLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  activity["imageUrl"],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // INFO
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity["title"] ?? "",
                      style: GoogleFonts.robotoSlab(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Type: ${activity["type"]}",
                      style: GoogleFonts.robotoSlab(fontSize: 14),
                    ),
                    Text(
                      "Age Group: ${activity["ageGroup"]}",
                      style: GoogleFonts.robotoSlab(fontSize: 14),
                    ),
                    const SizedBox(height: 10),

                    // STATUS + ACTIONS
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? Color.fromARGB(255, 235, 178, 177) : Color(0xFFCCA6A5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? "Active" : "Inactive",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // ✅ Toggle Deactivate / Activate (نفس endpoint)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isActive ? Colors.redAccent : Colors.green,
                          ),
                          onPressed: () =>
                              deactivateActivity(activity["_id"], isActive),
                          icon: Icon(isActive ? Icons.block : Icons.check),
                          label: Text(isActive ? "Deactivate" : "Activate"),
                        ),

                        const SizedBox(width: 8),

                        TextButton.icon(
                          onPressed: () => _confirmDelete(activity["_id"]),
                          icon: const Icon(Icons.delete, color: Colors.black87),
                          label: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
