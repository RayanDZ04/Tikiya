import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() {
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tikiya',
      theme: baseTheme.copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}

