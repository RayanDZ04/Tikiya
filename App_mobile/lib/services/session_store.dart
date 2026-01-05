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
}

class SessionStore {
  static final SessionStore I = SessionStore._();
  SessionStore._();

  static const String _prefsLocaleKey = 'app_locale';

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

  void setSession(UserSession? s) => session.value = s;
  void clear() => session.value = null;
}
