// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'bpm_manager.dart';

class ApiService {
  static const String baseUrl = "http://172.20.10.4:5000/api";

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    final headers = {"Content-Type": "application/json"};
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  /// Save a game result. levelDurations: list of numbers (seconds)
  static Future<bool> saveScore({
  required String game,
  required int score,
  required double totalTime,
  required List<double> levelDurations,
  required int levelReached,
}) async {
  final url = Uri.parse("$baseUrl/save_score");
  final headers = await _authHeaders();

  final bpmMgr = BpmManager.instance;

  final body = {
    "game": game,
    "score": score,
    "total_time": totalTime,
    "level_durations": levelDurations,
    "level_reached": levelReached,

    // ---- HR TELEMETRY (OPTIONAL, NULL-SAFE) ----
    "avg_bpm": bpmMgr.averageBpm,
    "baseline_bpm": bpmMgr.baselineBpm,
    "stress_level":
        bpmMgr.hasValidHrData ? bpmMgr.getStressLevel() : null,
  };

  final res = await http.post(
    url,
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 201) {
    return true;
  } else {
    print("Save score failed: ${res.statusCode} ${res.body}");
    return false;
  }
}


  /// Get this user's scores (requires Authorization header)
  static Future<List<dynamic>> getScores() async {
    final url = Uri.parse("$baseUrl/get_scores");
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      print("Get scores failed: ${res.statusCode} ${res.body}");
      return [];
    }
  }

  /// Get a compact user score history for profile
  static Future<List<dynamic>> getUserScores() async {
    final url = Uri.parse("$baseUrl/user/scores");
    final headers = await _authHeaders();
    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      print("Get user scores failed: ${res.statusCode} ${res.body}");
      return [];
    }
  }

    /// Send a handwritten symbol image to the backend EMNIST model
  static Future<Map<String, dynamic>?> predictHandwriting(String base64Image) async {
  final url = Uri.parse("$baseUrl/handwriting_predict");
  final headers = await _authHeaders();

  final body = jsonEncode({
    "image_base64": base64Image,
  });

  final res = await http.post(url, headers: headers, body: body);

  try {
    final Map<String, dynamic> data = jsonDecode(res.body);

    // Normal success
    if (res.statusCode == 200) {
      return data;
    }

    // Special case: backend detected a blank image and returns error=blank_image
    if (res.statusCode == 400 && data["error"] == "blank_image") {
      return data;
    }

    // Other errors
    print("Handwriting predict failed: ${res.statusCode} ${res.body}");
    return null;
  } catch (e) {
    print("Handwriting predict JSON decode error: $e, body=${res.body}");
    return null;
  }
}


/// ===============================
/// MNIST DIGIT VALIDATION (NEW GAME)
/// ===============================
Future<Map<String, dynamic>> validateDigit({
  required String base64Image,
  required int expectedDigit,
}) async {
  final token = await AuthService.getToken();
  if (token == null) throw Exception("Not authenticated");

  final response = await http.post(
    Uri.parse("$baseUrl/digit_validate"), // ✅ FIXED
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "image_base64": base64Image,
      "expected_digit": expectedDigit,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Digit validation failed");
  }

  return jsonDecode(response.body);
}




}
