import 'dart:convert';
import 'package:http/http.dart' as http;

class StoryService {
  static const String baseUrl = "http://10.0.2.2:3000/api/stories";

  /// 🔍 Search child-friendly stories
  static Future<List<dynamic>> searchStories(String query, String token) async {
    final url = Uri.parse("$baseUrl/external/search?q=$query");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Search failed: ${response.body}");
    }
  }

  /// 📥 Import story into system
  static Future<Map<String, dynamic>> importStory(
          String externalId, String ageGroup, String source, String token) async {

    /** 🔧 1) Normalize externalId → Always send as String */
    final id = externalId.toString();

    final url = Uri.parse("$baseUrl/import");

    /** 🔧 2) Call backend */
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "externalId":externalId.toString(),
        "ageGroup": ageGroup,
        "source": source,
      }),
    );

    /** 🔧 3) Decode backend response safely */
    dynamic res;
    try {
      res = jsonDecode(response.body);
    } catch (_) {
      res = {"error": "Invalid server response"};
    }

    /** 🔧 4) Standard output format */
    if (response.statusCode == 201) {
      return {
        "success": true,
        "message": "Story Imported Successfully 🎉",
        "data": res,
      };
    } else {
      return {
        "success": false,
        "message": res["error"] ?? "Import failed — try again",
      };
    }
  }
}
