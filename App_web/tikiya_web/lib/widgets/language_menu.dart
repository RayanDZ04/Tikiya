import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';

class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode.toUpperCase();

    return PopupMenuButton<Locale>(
      tooltip: 'Language',
      onSelected: (locale) => localeController.setLocale(locale),
      itemBuilder: (context) => const [
        PopupMenuItem(value: Locale('fr'), child: Text('Français')),
        PopupMenuItem(value: Locale('en'), child: Text('English')),
        PopupMenuItem(value: Locale('ar'), child: Text('العربية')),
      ],
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.language, size: 16, color: Colors.white),
        label: Text(
          current,
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
