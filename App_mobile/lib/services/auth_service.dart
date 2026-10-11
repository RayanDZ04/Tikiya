import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

class AuthService {
  AuthService({String? baseUrl}) : _baseUrl = baseUrl ?? apiBaseUrl;

  final String _baseUrl;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? totpCode,
  }) async {
    final uri = Uri.parse('$_baseUrl/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        if (totpCode != null && totpCode.isNotEmpty) 'totp_code': totpCode,
      }),
    );
    if (res.statusCode == 401) {
      throw HttpException('Email ou mot de passe incorrect.');
    }
    if (res.statusCode == 403) {
      // The server returns 403 both for 2FA and for unverified email; the
      // detail field distinguishes them.
      String? detail;
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        detail = body['detail'] as String? ?? body['message'] as String?;
      } catch (_) {}
      if (detail == '2FA_REQUIRED') {
        throw TwoFactorRequiredException(email, password);
      }
      throw EmailNotVerifiedException(email);
    }
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _captureSession(data);
    return data;
  }

  // ─── 2FA (TOTP) management ───────────────────────────────────────────────

  Map<String, String> get _authHeaders {
    final token = SessionStore.I.session.value?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /me/2fa/status — whether 2FA is currently enabled.
  Future<bool> twoFactorEnabled() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/me/2fa/status'),
      headers: _authHeaders,
    );
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['enabled'] as bool? ?? false;
  }

  /// POST /me/2fa/setup — returns { otpauth_url, secret } for a pending secret.
  Future<Map<String, dynamic>> setup2fa() async {
    final res = await http.post(
      Uri.parse('$_baseUrl/me/2fa/setup'),
      headers: _authHeaders,
    );
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// POST /me/2fa/enable — confirm the pending secret with a first code.
  Future<void> enable2fa(String code) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/me/2fa/enable'),
      headers: _authHeaders,
      body: jsonEncode({'code': code}),
    );
    _ensureOk(res);
  }

  /// POST /me/2fa/disable — turn 2FA off after verifying a current code.
  Future<void> disable2fa(String code) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/me/2fa/disable'),
      headers: _authHeaders,
      body: jsonEncode({'code': code}),
    );
    _ensureOk(res);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? captchaToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/register');
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
      if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
      if (captchaToken != null && captchaToken.isNotEmpty) 'captcha_token': captchaToken,
    };
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _captureSession(data);
    return data;
  }

  Future<Map<String, dynamic>> registerOrga({
    required String email,
    required String password,
    required String company,
    required String phone,
    String? website,
    String? captchaToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/register');
    final body = <String, dynamic>{
      'email': email,
      'password': password,
      'company': company,
      'phone': phone,
      'role': 'organisateur',
      if (website != null && website.isNotEmpty) 'website': website,
      if (captchaToken != null && captchaToken.isNotEmpty) 'captcha_token': captchaToken,
    };
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _ensureOk(res);
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await _captureSession(data);
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
    await _captureSession(data);
    return data;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final detail = body['detail'] as String? ?? body['message'] as String?;
        if (detail != null && detail.isNotEmpty) {
          throw HttpException(detail);
        }
      } catch (e) {
        if (e is HttpException) rethrow;
      }
      throw HttpException('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  /// Verify the email OTP code. Throws on failure with the server error message.
  Future<void> verifyEmail({required String code}) async {
    final token = SessionStore.I.session.value?.accessToken ?? '';
    if (token.isEmpty) throw HttpException('Not authenticated');

    final res = await http.post(
      Uri.parse('$_baseUrl/email/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final detail = body['detail'] as String? ?? body['message'] as String? ?? 'Erreur inconnue';
      throw HttpException(detail);
    }
  }

  /// Ask the server to resend a new OTP to the authenticated user.
  Future<void> resendOtp() async {
    final token = SessionStore.I.session.value?.accessToken ?? '';
    if (token.isEmpty) throw HttpException('Not authenticated');

    final res = await http.post(
      Uri.parse('$_baseUrl/email/resend'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final detail = body['detail'] as String? ?? body['message'] as String? ?? 'Erreur inconnue';
      throw HttpException(detail);
    }
  }

  Future<void> _captureSession(Map<String, dynamic> data) async {
    final user = (data['user'] as Map?) ?? (data['data'] as Map?) ?? {};
    final tokens = (data['tokens'] as Map?) ?? {};
    final fn = (user['first_name'] ?? user['firstName'])?.toString();
    final ln = (user['last_name'] ?? user['lastName'])?.toString();
    String? displayName;
    if (fn != null && fn.isNotEmpty && ln != null && ln.isNotEmpty) {
      displayName = '$fn $ln';
    } else if (fn != null && fn.isNotEmpty) {
      displayName = fn;
    } else if (ln != null && ln.isNotEmpty) {
      displayName = ln;
    } else {
      displayName = (user['username'] ?? user['name'])?.toString();
    }
    final emailVerified = data['email_verified'] as bool? ??
        (user['email_verified'] as bool? ?? false);
    final session = UserSession(
      id: (user['id'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      username: displayName,
      role: (user['role'] ?? '').toString(),
      accessToken: (tokens['access_token'] ?? tokens['accessToken'] ?? '').toString(),
      refreshToken: (tokens['refresh_token'] ?? tokens['refreshToken'])?.toString(),
      emailVerified: emailVerified,
    );
    await SessionStore.I.setSession(session);
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}

/// Thrown when the server returns 403 — email not verified.
class EmailNotVerifiedException implements Exception {
  final String email;
  EmailNotVerifiedException(this.email);
  @override
  String toString() => 'Email non vérifié.';
}

/// Thrown when the server requires a 2FA code to finish login.
/// Carries the credentials so the UI can retry with the TOTP code.
class TwoFactorRequiredException implements Exception {
  final String email;
  final String password;
  TwoFactorRequiredException(this.email, this.password);
  @override
  String toString() => 'Code 2FA requis.';
}

/// CAPTCHA site key for registration, injected at build time via
/// `--dart-define=TURNSTILE_SITE_KEY=...`. Empty = CAPTCHA disabled on mobile
/// (matches the backend, which skips the check when CAPTCHA_SECRET is unset).
const String turnstileSiteKey = String.fromEnvironment('TURNSTILE_SITE_KEY');
