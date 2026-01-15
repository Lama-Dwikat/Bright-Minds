/*import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class DrawingApi {
  final String baseUrl;
  DrawingApi({required this.baseUrl});

  String get _apiBase {
    final b = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return b.endsWith('/api') ? b : '$b/api';
  }
// inside DrawingApi

Future<Map<String, dynamic>> submitDrawingImage({
  required String token,
  required String activityId,
  required Uint8List pngBytes,
  bool autoSubmit = true,
}) async {
  final url = Uri.parse("$_apiBase/drawing/submitImage");

  final body = jsonEncode({
    "activityId": activityId,
    "drawingImage": base64Encode(pngBytes), // raw base64
    "autoSubmit": autoSubmit,
  });

  final resp = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: body,
  );

  final data = jsonDecode(resp.body);

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    return data;
  } else {
    throw Exception(data["error"] ?? "submitDrawingImage failed");
  }
}

  Future<Map<String, dynamic>> generateColorByNumber({
    required String token,
    required String q,
    required int regionsCount,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/generateColorByNumber');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "q": q,
        "regionsCount": regionsCount,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to generate color by number");
    }
  }

  Future<Map<String, dynamic>> getActivityById({
    required String token,
    required String activityId,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/activity/$activityId');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to load activity");
    }
  }

  Future<Map<String, dynamic>> updateColorByNumberLegend({
    required String token,
    required String activityId,
    required List<Map<String, dynamic>> legend,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/colorByNumber/$activityId/legend');

    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"legend": legend}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to update legend");
    }
  }

  // =========================
  // ✅ Color-by-number Progress (Child)
  // =========================

  Future<Map<String, dynamic>?> getMyColorByNumberProgress({
    required String token,
    required String activityId,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/color-by-number/progress/$activityId');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 404) return null;

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to load progress");
    }
  }

  Future<void> saveColorByNumberProgressBulk({
    required String token,
    required String activityId,
    required Map<String, String> filled,
  }) async {
    final url =
        Uri.parse('$_apiBase/drawing/color-by-number/progress/$activityId/bulk');

    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"filled": filled}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Bulk save failed: ${res.statusCode} ${res.body}");
    }
  }

  // (اختياري) إذا بدك endpoint ثاني مستقبلاً
  Future<void> upsertSingleFill({
    required String token,
    required String activityId,
    required int number,
    required String colorHex,
  }) async {
    final url =
        Uri.parse('$_apiBase/drawing/color-by-number/progress/$activityId/fill');

    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "number": number,
        "colorHex": colorHex,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Upsert fill failed: ${res.statusCode} ${res.body}");
    }
  }

  // =========================
  // ❌ خلي submitColorByNumberResult (png) موقوف حالياً
  // لأنه سبب الأخطاء وما بنحتاجه الآن
  // =========================
  Future<void> submitColorByNumberResult({
    required String token,
    required String activityId,
    required Uint8List pngBytes,
    required Map<String, String> filled,
  }) async {
    final url = Uri.parse("$_apiBase/color-by-number/submissions");

    final body = jsonEncode({
      "activityId": activityId,
      "imageBase64": base64Encode(pngBytes),
      "filled": filled,
    });

    final resp = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
          "submitColorByNumberResult failed: ${resp.statusCode} ${resp.body}");
    }
  }
}
*/
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class DrawingApi {
  final String baseUrl;
  DrawingApi({required this.baseUrl});

  String get _apiBase {
    final b = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return b.endsWith('/api') ? b : '$b/api';
  }

  // ✅ NEW: submit drawing image (upload + optional autoSubmit)
  Future<Map<String, dynamic>> submitDrawingImage({
    required String token,
    required String activityId,
    required Uint8List pngBytes,
    bool autoSubmit = true,
  }) async {
    final url = Uri.parse("$_apiBase/drawing/submitImage");

    final body = jsonEncode({
      "activityId": activityId,
      "drawingImage": base64Encode(pngBytes), // raw base64
      "autoSubmit": autoSubmit,
    });

    final resp = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      // إذا السيرفر رجّع نص مش JSON
      throw Exception("submitDrawingImage failed: ${resp.statusCode} ${resp.body}");
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "submitDrawingImage failed");
    }
  }

  Future<Map<String, dynamic>> generateColorByNumber({
    required String token,
    required String q,
    required int regionsCount,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/generateColorByNumber');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "q": q,
        "regionsCount": regionsCount,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to generate color by number");
    }
  }

  Future<Map<String, dynamic>> getActivityById({
    required String token,
    required String activityId,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/activity/$activityId');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to load activity");
    }
  }

  Future<Map<String, dynamic>> updateColorByNumberLegend({
    required String token,
    required String activityId,
    required List<Map<String, dynamic>> legend,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/colorByNumber/$activityId/legend');

    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"legend": legend}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to update legend");
    }
  }

  // =========================
  // ✅ Color-by-number Progress (Child)
  // =========================

  Future<Map<String, dynamic>?> getMyColorByNumberProgress({
    required String token,
    required String activityId,
  }) async {
    final url = Uri.parse('$_apiBase/drawing/color-by-number/progress/$activityId');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 404) return null;

    final data = jsonDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    } else {
      throw Exception(data["error"] ?? "Failed to load progress");
    }
  }

  Future<void> saveColorByNumberProgressBulk({
    required String token,
    required String activityId,
    required Map<String, String> filled,
  }) async {
    final url = Uri.parse(
      '$_apiBase/drawing/color-by-number/progress/$activityId/bulk',
    );

    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"filled": filled}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Bulk save failed: ${res.statusCode} ${res.body}");
    }
  }

  Future<void> upsertSingleFill({
    required String token,
    required String activityId,
    required int number,
    required String colorHex,
  }) async {
    final url = Uri.parse(
      '$_apiBase/drawing/color-by-number/progress/$activityId/fill',
    );

    final res = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "number": number,
        "colorHex": colorHex,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Upsert fill failed: ${res.statusCode} ${res.body}");
    }
  }

  // =========================
  // ⚠️ Old submit (keep if you still use it somewhere)
  // =========================
  Future<void> submitColorByNumberResult({
    required String token,
    required String activityId,
    required Uint8List pngBytes,
    required Map<String, String> filled,
  }) async {
    final url = Uri.parse("$_apiBase/color-by-number/submissions");

    final body = jsonEncode({
      "activityId": activityId,
      "imageBase64": base64Encode(pngBytes),
      "filled": filled,
    });

    final resp = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception(
        "submitColorByNumberResult failed: ${resp.statusCode} ${resp.body}",
      );
    }
  }
}
