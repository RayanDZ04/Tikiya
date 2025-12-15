import 'dart:convert';
import 'package:http/http.dart' as http;
import 'session_store.dart';

class AuthService {
  AuthService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'http://10.0.2.2:8080';
  final String _baseUrl;

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final uri = Uri.parse('$_baseUrl/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _captureSession(data);
    return data;
  }

  Future<Map<String, dynamic>> register({required String email, required String password}) async {
    final uri = Uri.parse('$_baseUrl/register');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _captureSession(data);
    return data;
  }

  Future<Map<String, dynamic>> loginWithGoogleIdToken(String idToken) async {
    final uri = Uri.parse('$_baseUrl/auth/google/mobile');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _captureSession(data);
    return data;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  void _captureSession(Map<String, dynamic> data) {
    final user = (data['user'] as Map?) ?? (data['data'] as Map?) ?? {};
    final tokens = (data['tokens'] as Map?) ?? {};
    final session = UserSession(
      id: (user['id'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      username: (user['username'] ?? user['name'])?.toString(),
      role: (user['role'] ?? '').toString(),
      accessToken: (tokens['access_token'] ?? tokens['accessToken'] ?? '').toString(),
      refreshToken: (tokens['refresh_token'] ?? tokens['refreshToken'])?.toString(),
    );
    SessionStore.I.setSession(session);
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
