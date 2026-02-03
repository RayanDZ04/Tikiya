import 'package:flutter/material.dart';

import '../ui/auth_layout.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TikiyaLogo(),
          const SizedBox(height: 12),
          Text(
            'Billets, événements, contrôle — tout en un.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            child: const Text("S'inscrire"),
          ),
          const SizedBox(height: 16),
          Text(
            "Avant connexion, l'espace est identique. Après, on te redirige selon ton rôle.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
