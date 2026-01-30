import 'package:flutter/material.dart';

import '../services/session_store.dart';

class SplashScreen extends StatefulWidget {
  final SessionStore sessionStore;

  const SplashScreen({super.key, required this.sessionStore});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await widget.sessionStore.user();
    if (!mounted) return;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/');
      return;
    }

    if (user.role == 'organizer' || user.role == 'organisateur') {
      Navigator.of(context).pushReplacementNamed('/orga');
    } else {
      Navigator.of(context).pushReplacementNamed('/participant');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
