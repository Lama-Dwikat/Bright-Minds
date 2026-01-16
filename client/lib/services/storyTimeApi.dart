import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class StoryTimeApi {
  String getBackendUrl() {
    if (kIsWeb) return "http://192.168.1.63:3000";
    if (Platform.isAndroid) return "http://10.0.2.2:3000";
    if (Platform.isIOS) return "http://localhost:3000";
    return "http://localhost:3000";
  }

  Future<Map<String, dynamic>> getParentStoryTimeReport({
    required String token,
    int rangeDays = 7,
  }) async {
    final url = Uri.parse("${getBackendUrl()}/api/parent/storyTime/report?rangeDays=$rangeDays");

    final resp = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(resp.body);

    if (resp.statusCode != 200) {
      throw Exception(data["message"] ?? "Failed to load report");
    }

    return data["data"] as Map<String, dynamic>;
  }
}
