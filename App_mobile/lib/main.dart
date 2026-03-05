import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/register_orga_screen.dart';
import 'services/session_store.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SessionStore.I.loadLocale();
  FlutterNativeSplash.remove();

  const Color statusBarColor = Color(0xFF0B1C3E);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: statusBarColor,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: statusBarColor,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      primaryColor: const Color(0xFF0B1C3E),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B1C3E)),
      scaffoldBackgroundColor: const Color(0xFF0B1C3E),
      textTheme: GoogleFonts.montserratTextTheme(),
    );

    return ValueListenableBuilder<Locale?>(
      valueListenable: SessionStore.I.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: baseTheme.copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF0B1C3E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
            '/register-role': (context) => const RoleSelectionScreen(),
            '/register': (context) => const RegisterScreen(),
            '/register-orga': (context) => const RegisterOrgaScreen(),
          },
        );
      },
    );
  }
}

