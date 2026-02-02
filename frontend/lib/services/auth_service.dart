// lib/services/auth_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://172.20.10.4:5000/api"; // emulator
  static const String _tokenKey = "auth_token";
  static const String _userKey = "auth_user"; // JSON encoded user

  // SIGNUP
  static Future<Map<String, dynamic>?> signup(String username, String password, String displayName) async {
    final url = Uri.parse("$baseUrl/signup");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password, "display_name": displayName}),
    );
    if (res.statusCode == 201) {
      final data = jsonDecode(res.body);
      await _saveTokenAndUser(data["token"], data["user"]);
      return data["user"];
    } else {
      print("Signup failed: ${res.statusCode} ${res.body}");
      return null;
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/login");
    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveTokenAndUser(data["token"], data["user"]);
      return data["user"];
    } else {
      print("Login failed: ${res.statusCode} ${res.body}");
      return null;
    }
  }

  static Future<void> _saveTokenAndUser(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(_userKey);
    if (u == null) return null;
    return jsonDecode(u);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    final user = jsonDecode(userJson);
    return user["display_name"] ?? user["username"];
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
