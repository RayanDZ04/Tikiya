import 'package:flutter/material.dart';

import '../ui/auth_layout.dart';
import '../l10n/app_localizations.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TikiyaLogo(),
          const SizedBox(height: 12),
          Text(
            l10n.t('landing_tagline'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushNamed('/login'),
            child: Text(l10n.t('cta_login')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/register'),
            child: Text(l10n.t('cta_register')),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('landing_note'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
