import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/session_store.dart';

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, this.current});
  final String? current; // route key: 'home','tickets','market','orga','profile','login'

  static const Color bleuProfon = Color(0xFF1A237E);
  static const Color grisClair = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = SessionStore.I.session.value;
    final role = session?.role ?? '';
    final isLogged = session != null;

    List<_NavItem> items = [
      _NavItem('home', l10n.navHome, Icons.home, onTap: () => Navigator.pushReplacementNamed(context, '/')),
    ];
    if (!isLogged || role != 'organisateur') {
      items.add(
        _NavItem('tickets', l10n.navTickets, Icons.confirmation_num,
            onTap: () => Navigator.pushReplacementNamed(context, '/tickets')),
      );
    }
    if (isLogged && role == 'participant') {
      items.add(
        _NavItem('market', l10n.navMarket, Icons.storefront,
            onTap: () => Navigator.pushReplacementNamed(context, '/market')),
      );
    }
    if (isLogged && role == 'organisateur') {
      items.add(
        _NavItem('orga', l10n.navOrga, Icons.event,
            onTap: () => Navigator.pushReplacementNamed(context, '/orga')),
      );
    }
    items.add(
      _NavItem(
        isLogged ? 'profile' : 'login',
        isLogged ? l10n.navProfile : l10n.navLogin,
        Icons.person,
          onTap: () => Navigator.pushReplacementNamed(context, isLogged ? '/profile' : '/login')),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFFFFF),
        border: Border(top: BorderSide(color: grisClair, width: 1.5)),
        boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.06), blurRadius: 16, offset: Offset(0, -4))],
      ),
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final it in items)
            _NavButton(
              label: it.label,
              icon: it.icon,
              active: current == it.key,
              onTap: it.onTap,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String key;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _NavItem(this.key, this.label, this.icon, {required this.onTap});
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  static const Color bleuProfon = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final color = bleuProfon;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
