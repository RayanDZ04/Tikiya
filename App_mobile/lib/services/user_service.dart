import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

class UserService {
  static final String _baseUrl = apiBaseUrl;

  String? get _token => SessionStore.I.session.value?.accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Modifie le mot de passe. Lance une exception avec le message d'erreur si ça échoue.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/me/password'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode != 204) {
      final body = _tryJson(res.body);
      throw body?['detail'] ?? body?['message'] ?? 'Erreur serveur';
    }
  }

  /// Modifie l'adresse email. Lance une exception avec le message d'erreur si ça échoue.
  Future<void> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/me/email'),
      headers: _headers,
      body: jsonEncode({
        'current_password': currentPassword,
        'new_email': newEmail,
      }),
    );
    if (res.statusCode != 204) {
      final body = _tryJson(res.body);
      throw body?['detail'] ?? body?['message'] ?? 'Erreur serveur';
    }
  }

  /// Modifie le pseudo. Lance une exception avec le message d'erreur si ça échoue.
  Future<void> changeUsername({required String username}) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/me/username'),
      headers: _headers,
      body: jsonEncode({'username': username}),
    );
    if (res.statusCode != 204) {
      final body = _tryJson(res.body);
      throw body?['detail'] ?? body?['message'] ?? 'Erreur serveur';
    }
  }

  Map<String, dynamic>? _tryJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
