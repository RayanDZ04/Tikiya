import 'package:flutter/foundation.dart';

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

  final ValueNotifier<UserSession?> session = ValueNotifier<UserSession?>(null);

  void setSession(UserSession? s) => session.value = s;
  void clear() => session.value = null;
}
