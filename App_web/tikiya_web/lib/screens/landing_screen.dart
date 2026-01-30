import 'package:flutter/material.dart';

import '../app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/ticket_logo.webp',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Tikiya',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Billets, événements, contrôle — tout en un.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      child: const Text('Se connecter'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/register'),
                      child: const Text("S'inscrire"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Avant connexion, l'espace est identique. Après, on te redirige selon ton rôle.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
