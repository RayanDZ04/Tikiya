import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final String id;
  final String email;
  final String? username;
  final String? role;
  final String accessToken;
  final String? refreshToken;
  final bool emailVerified;

  const UserSession({
    required this.id,
    required this.email,
    this.username,
    this.role,
    required this.accessToken,
    this.refreshToken,
    this.emailVerified = false,
  });

  UserSession copyWith({
    String? id,
    String? email,
    String? username,
    String? role,
    String? accessToken,
    String? refreshToken,
    bool? emailVerified,
  }) {
    return UserSession(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}

class SessionStore {
  static final SessionStore I = SessionStore._();
  SessionStore._();

  static const String _prefsLocaleKey = 'app_locale';
  static const String _prefsSessionId = 'session_id';
  static const String _prefsSessionEmail = 'session_email';
  static const String _prefsSessionUsername = 'session_username';
  static const String _prefsSessionRole = 'session_role';
  static const String _prefsSessionEmailVerified = 'session_email_verified';

  // Tokens live in the OS-backed secure store (Keystore/Keychain), never in
  // plaintext SharedPreferences.
  static const String _secureAccessToken = 'session_access_token';
  static const String _secureRefreshToken = 'session_refresh_token';

  // Legacy plaintext keys (pre-secure-storage builds). If present, we wipe them
  // and force a one-time re-login rather than trusting plaintext tokens.
  static const String _legacyPrefsToken = 'session_access_token';
  static const String _legacyPrefsRefresh = 'session_refresh_token';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final ValueNotifier<UserSession?> session = ValueNotifier<UserSession?>(null);

  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsLocaleKey);
    if (code == null || code.isEmpty) return;
    locale.value = Locale(code);
  }

  Future<void> setLocale(Locale? l) async {
    locale.value = l;
    final prefs = await SharedPreferences.getInstance();
    if (l == null) {
      await prefs.remove(_prefsLocaleKey);
    } else {
      await prefs.setString(_prefsLocaleKey, l.languageCode);
    }
  }

  /// Persists session: metadata in SharedPreferences, tokens in secure storage.
  Future<void> setSession(UserSession? s) async {
    session.value = s;
    final prefs = await SharedPreferences.getInstance();
    if (s == null) {
      await prefs.remove(_prefsSessionId);
      await prefs.remove(_prefsSessionEmail);
      await prefs.remove(_prefsSessionUsername);
      await prefs.remove(_prefsSessionRole);
      await prefs.remove(_prefsSessionEmailVerified);
      await _secure.delete(key: _secureAccessToken);
      await _secure.delete(key: _secureRefreshToken);
    } else {
      await prefs.setString(_prefsSessionId, s.id);
      await prefs.setString(_prefsSessionEmail, s.email);
      if (s.username != null) await prefs.setString(_prefsSessionUsername, s.username!);
      if (s.role != null) await prefs.setString(_prefsSessionRole, s.role!);
      await prefs.setBool(_prefsSessionEmailVerified, s.emailVerified);
      await _secure.write(key: _secureAccessToken, value: s.accessToken);
      if (s.refreshToken != null) {
        await _secure.write(key: _secureRefreshToken, value: s.refreshToken!);
      } else {
        await _secure.delete(key: _secureRefreshToken);
      }
    }
  }

  /// Loads a previously persisted session.
  ///
  /// If a legacy plaintext token is still sitting in SharedPreferences (from a
  /// build before secure storage), we wipe everything and treat the user as
  /// logged out — a deliberate one-time re-login so no plaintext token is
  /// trusted going forward.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();

    final legacyToken = prefs.getString(_legacyPrefsToken);
    if (legacyToken != null) {
      await _clearLegacyPlaintext(prefs);
      return; // force re-login
    }

    final token = await _secure.read(key: _secureAccessToken);
    final id = prefs.getString(_prefsSessionId);
    final email = prefs.getString(_prefsSessionEmail);
    if (token == null || token.isEmpty || id == null || email == null) return;

    session.value = UserSession(
      id: id,
      email: email,
      username: prefs.getString(_prefsSessionUsername),
      role: prefs.getString(_prefsSessionRole),
      accessToken: token,
      refreshToken: await _secure.read(key: _secureRefreshToken),
      emailVerified: prefs.getBool(_prefsSessionEmailVerified) ?? false,
    );
  }

  Future<void> _clearLegacyPlaintext(SharedPreferences prefs) async {
    await prefs.remove(_legacyPrefsToken);
    await prefs.remove(_legacyPrefsRefresh);
    await prefs.remove(_prefsSessionId);
    await prefs.remove(_prefsSessionEmail);
    await prefs.remove(_prefsSessionUsername);
    await prefs.remove(_prefsSessionRole);
    await prefs.remove(_prefsSessionEmailVerified);
  }

  Future<void> clear() async {
    session.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsSessionId);
    await prefs.remove(_prefsSessionEmail);
    await prefs.remove(_prefsSessionUsername);
    await prefs.remove(_prefsSessionRole);
    await prefs.remove(_prefsSessionEmailVerified);
    await _secure.delete(key: _secureAccessToken);
    await _secure.delete(key: _secureRefreshToken);
  }
}
