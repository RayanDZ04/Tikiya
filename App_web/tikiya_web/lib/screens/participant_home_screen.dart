import 'package:flutter/material.dart';

import '../services/session_store.dart';

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
      appBar: AppBar(
        title: const Text('Espace participant'),
        actions: [
          TextButton(
            onPressed: () => _logout(context),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: const Center(
        child: Text('Bienvenue ! (participant)'),
      ),
    );
  }
}
