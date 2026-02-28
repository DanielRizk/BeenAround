import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../export/user_data_file_transfer.dart';

class AuthUser {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? profilePicPath;

  AuthUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.profilePicPath,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      username: json['username'],
      email: json['email'],
      profilePicPath: json['profile_pic_path'],
    );
  }
}

class AuthController {
  static const String baseUrl = "http://192.168.0.100:8000";
  static const _storage = FlutterSecureStorage();

  static AuthUser? currentUser;

  static Future<void> saveToken(String token) async {
    await _storage.write(key: "access_token", value: token);
  }

  static Future<String?> getToken() async {
    return _storage.read(key: "access_token");
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: "access_token");
  }

  static Future<void> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "username": identifier,
        "password": password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Invalid credentials");
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

    final token = data['access_token'];
    if (token is! String || token.isEmpty) {
      throw Exception("Login failed: missing access token");
    }
    await saveToken(token);

    // ✅ New: import export payload if present (new server behavior)
    final export = data['export'];
    if (export is Map) {
      // Option A (simple): re-encode only the export block to JSON and import from string
      final exportJson = jsonEncode(Map<String, dynamic>.from(export));
      await UserDataFileTransfer.importFromJsonString(exportJson);

      // Note: your importer clears SharedPreferences. If saveToken() uses SharedPreferences,
      // it may get wiped. So we re-save the token afterwards to be safe.
      await saveToken(token);
    }

    await fetchMe();
  }

  static Future<void> fetchMe() async {
    final token = await getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      currentUser = AuthUser.fromJson(jsonDecode(response.body));
    }
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return;

    await http.post(
      Uri.parse("$baseUrl/auth/logout"),
      headers: {"Authorization": "Bearer $token"},
    );

    await clearToken();
    currentUser = null;
  }

  static Future<void> deleteAccount() async {
    final token = await getToken();
    if (token == null) return;

    await http.delete(
      Uri.parse("$baseUrl/auth/me"),
      headers: {"Authorization": "Bearer $token"},
    );

    await clearToken();
    currentUser = null;
  }
}