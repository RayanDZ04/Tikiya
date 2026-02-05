import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/events_screen.dart';
import 'screens/help_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/orga_entry_screen.dart';
import 'screens/participant_home_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/session_store.dart';

class TikiyaWebApp extends StatelessWidget {
  final SessionStore _sessionStore = SessionStore();
  final AuthService _authService = AuthService(ApiClient());

  TikiyaWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tikiya',
      theme: AppTheme.build(),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => SplashScreen(sessionStore: _sessionStore),
        '/': (_) => const HomeScreen(),
        '/landing': (_) => const LandingScreen(),
        '/events': (_) => const EventsScreen(),
        '/help': (_) => const HelpScreen(),
        '/login': (_) => LoginScreen(authService: _authService, sessionStore: _sessionStore),
        '/register': (_) => RegisterScreen(authService: _authService, sessionStore: _sessionStore),
        '/participant': (_) => ParticipantHomeScreen(sessionStore: _sessionStore),
        '/orga': (_) => OrgaEntryScreen(sessionStore: _sessionStore),
      },
    );
  }
}
