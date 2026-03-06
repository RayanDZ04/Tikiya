import 'package:flutter/foundation.dart';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final String id;
  final String email;
  final String? username;
  final String? role;
  final String accessToken;
  final String? refreshToken;

  const UserSession({
    required this.id,
    required this.email,
    this.username,
    this.role,
    required this.accessToken,
    this.refreshToken,
  });

  UserSession copyWith({
    String? id,
    String? email,
    String? username,
    String? role,
    String? accessToken,
    String? refreshToken,
  }) {
    return UserSession(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      role: role ?? this.role,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
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
  static const String _prefsSessionToken = 'session_access_token';
  static const String _prefsSessionRefresh = 'session_refresh_token';

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

  /// Persists session to SharedPreferences and sets it in memory.
  Future<void> setSession(UserSession? s) async {
    session.value = s;
    final prefs = await SharedPreferences.getInstance();
    if (s == null) {
      await prefs.remove(_prefsSessionId);
      await prefs.remove(_prefsSessionEmail);
      await prefs.remove(_prefsSessionUsername);
      await prefs.remove(_prefsSessionRole);
      await prefs.remove(_prefsSessionToken);
      await prefs.remove(_prefsSessionRefresh);
    } else {
      await prefs.setString(_prefsSessionId, s.id);
      await prefs.setString(_prefsSessionEmail, s.email);
      if (s.username != null) await prefs.setString(_prefsSessionUsername, s.username!);
      if (s.role != null) await prefs.setString(_prefsSessionRole, s.role!);
      await prefs.setString(_prefsSessionToken, s.accessToken);
      if (s.refreshToken != null) await prefs.setString(_prefsSessionRefresh, s.refreshToken!);
    }
  }

  /// Loads a previously persisted session from SharedPreferences.
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsSessionToken);
    final id = prefs.getString(_prefsSessionId);
    final email = prefs.getString(_prefsSessionEmail);
    if (token == null || token.isEmpty || id == null || email == null) return;
    session.value = UserSession(
      id: id,
      email: email,
      username: prefs.getString(_prefsSessionUsername),
      role: prefs.getString(_prefsSessionRole),
      accessToken: token,
      refreshToken: prefs.getString(_prefsSessionRefresh),
    );
  }

  Future<void> clear() async {
    session.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsSessionId);
    await prefs.remove(_prefsSessionEmail);
    await prefs.remove(_prefsSessionUsername);
    await prefs.remove(_prefsSessionRole);
    await prefs.remove(_prefsSessionToken);
    await prefs.remove(_prefsSessionRefresh);
  }
}
