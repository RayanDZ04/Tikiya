import 'package:flutter/material.dart';

import '../services/session_store.dart';
import '../widgets/top_navigation_bar.dart';

class ParticipantHomeScreen extends StatelessWidget {
  final SessionStore sessionStore;

  const ParticipantHomeScreen({super.key, required this.sessionStore});

  Future<void> _logout(BuildContext context) async {
    await sessionStore.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopNavigationBar(
                    trailing: OutlinedButton(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Expanded(
                    child: Center(
                      child: Text('Bienvenue ! (participant)', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
