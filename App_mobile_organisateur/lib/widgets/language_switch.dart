import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/session_store.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, this.foregroundColor});

  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<Locale?>(
      valueListenable: SessionStore.I.locale,
      builder: (context, locale, _) {
        return PopupMenuButton<String>(
          tooltip: 'Language',
          icon: Icon(Icons.translate, color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary),
          onSelected: (value) {
            if (value == 'system') {
              SessionStore.I.setLocale(null);
              return;
            }
            SessionStore.I.setLocale(Locale(value));
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'fr', child: Text(l10n.langFrench)),
            PopupMenuItem(value: 'ar', child: Text(l10n.langArabic)),
            PopupMenuItem(value: 'en', child: Text(l10n.langEnglish)),
            const PopupMenuDivider(),
            PopupMenuItem(value: 'system', child: Text(l10n.langSystem)),
          ],
        );
      },
    );
  }
}
