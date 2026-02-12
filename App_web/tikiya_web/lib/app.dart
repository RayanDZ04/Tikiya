import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/orga_entry_screen.dart';
import 'screens/orga_needs_screen.dart';
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Tikiya',
          theme: AppTheme.build(),
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale == null) return supportedLocales.first;
            for (final supported in supportedLocales) {
              if (supported.languageCode == deviceLocale.languageCode) return supported;
            }
            return supportedLocales.first;
          },
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => SplashScreen(sessionStore: _sessionStore),
            '/': (_) => const HomeScreen(),
            '/landing': (_) => const LandingScreen(),
            '/events': (_) => const EventsScreen(),
            '/login': (_) => LoginScreen(authService: _authService, sessionStore: _sessionStore),
            '/register': (_) => RegisterScreen(authService: _authService, sessionStore: _sessionStore),
            '/orga-login': (_) => LoginScreen(
                  authService: _authService,
                  sessionStore: _sessionStore,
                  isOrganizerMode: true,
                ),
            '/orga-register': (_) => RegisterScreen(
                  authService: _authService,
                  sessionStore: _sessionStore,
                  isOrganizerMode: true,
                ),
            '/orga-needs': (_) => const OrgaNeedsScreen(),
            '/participant': (_) => const ParticipantHomeScreen(),
            '/orga': (_) => OrgaEntryScreen(sessionStore: _sessionStore),
          },
        );
      },
    );
  }
}
