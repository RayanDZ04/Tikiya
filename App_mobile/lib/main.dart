import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'services/session_store.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.I.loadLocale();

  const Color statusBarColor = Color(0xFF0D47A1);
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
      primaryColor: const Color(0xFF0D47A1),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1)),
      scaffoldBackgroundColor: const Color(0xFF0D47A1),
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
              backgroundColor: Color(0xFF0D47A1),
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
            '/register': (context) => const RegisterScreen(),
          },
        );
      },
    );
  }
}

