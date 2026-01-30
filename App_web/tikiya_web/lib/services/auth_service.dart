import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  final String accessToken;
  final User user;

  const AuthResult({required this.accessToken, required this.user});
}

class AuthService {
  final ApiClient _api;

  AuthService(this._api);

  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _api.postJson('/login', body: {
      'email': email,
      'password': password,
    });

    return _parseAuth(json);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final json = await _api.postJson('/register', body: {
      'email': email,
      'password': password,
      'role': role,
    });

    return _parseAuth(json);
  }

  AuthResult _parseAuth(Map<String, dynamic> json) {
    final accessToken = (json['access_token'] ?? json['token'] ?? '').toString();
    final userJson = (json['user'] ?? {}) as Map<String, dynamic>;
    final user = User.fromJson(userJson);

    if (accessToken.isEmpty) {
      throw ApiException('Token manquant dans la réponse serveur');
    }
    return AuthResult(accessToken: accessToken, user: user);
  }
}
