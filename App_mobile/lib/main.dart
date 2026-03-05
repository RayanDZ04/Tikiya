import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:app_links/app_links.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/register_orga_screen.dart';
import 'screens/orga_events_screen.dart';
import 'screens/orga_account_screen.dart';
import 'screens/orga_dashboard_screen.dart';
import 'screens/tickets_screen.dart';
import 'services/session_store.dart';
import 'widgets/payment_result_dialog.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Incrémenté chaque fois qu'un paiement réussit — la page billets écoute ceci.
final ValueNotifier<int> ticketsRefreshTrigger = ValueNotifier(0);

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SessionStore.I.loadLocale();
  await SessionStore.I.loadSession();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    // Warm-start : l'app \u00e9tait en arri\u00e8re-plan
    _appLinks.uriLinkStream.listen(_handleDeepLink);
    // Cold-start : l'app a \u00e9t\u00e9 ouverte via le deep link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'tikiya' || uri.host != 'payment') return;

    final isSuccess = uri.pathSegments.isNotEmpty &&
        uri.pathSegments.last == 'success';
    final ticketId = uri.queryParameters['ticket'];

    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    if (isSuccess) ticketsRefreshTrigger.value++;

    showPaymentResultDialog(
      ctx,
      success: isSuccess,
      ticketId: ticketId,
    );
  }

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
          navigatorKey: navigatorKey,
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
            '/orga': (context) => const OrgaEventsScreen(),
            '/account': (context) => const OrgaAccountScreen(),
            '/dashboard': (context) => const OrgaDashboardScreen(),
            '/tickets': (context) => const TicketsScreen(),
          },
        );
      },
    );
  }
}


