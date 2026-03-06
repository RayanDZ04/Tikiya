import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';

class OrgaAccountScreen extends StatelessWidget {
  const OrgaAccountScreen({super.key});

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color blanc = Colors.white;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              color: bleuProfond,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'Tikiya',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: blanc,
                        ),
                      ),
                      TextSpan(
                        text: '!',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: bleuCyan,
                        ),
                      ),
                      TextSpan(
                        text: ' pro',
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: blanc,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ]),
                  ),
                  const LanguageSwitch(foregroundColor: Colors.white),
                ],
              ),
            ),
            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: ValueListenableBuilder<UserSession?>(
                valueListenable: SessionStore.I.session,
                builder: (context, session, _) {
                  if (session == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushReplacementNamed(context, '/login');
                    });
                    return const SizedBox.shrink();
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Avatar
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: bleuProfond,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              session.email.isNotEmpty
                                  ? session.email[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.montserrat(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: blanc,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Email
                        Text(
                          session.email,
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: bleuCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l10n.orgaAccountTitle,
                            style: GoogleFonts.montserrat(
                              color: bleuCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Info card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x440B1C3E),
                                  blurRadius: 14,
                                  offset: Offset(0, 6))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: session.email,
                                foreground: bleuProfond,
                              ),
                              Divider(height: 24, color: bleuProfond.withValues(alpha: 0.15)),
                              _InfoRow(
                                icon: Icons.badge_outlined,
                                label: 'Rôle',
                                value: 'Organisateur',
                                foreground: bleuProfond,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Logout button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: Text(
                              l10n.authLogout,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            onPressed: () {
                              SessionStore.I.clear();
                              Navigator.pushReplacementNamed(context, '/');
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'profile'),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.foreground});
  final IconData icon;
  final String label;
  final String value;
  final Color? foreground;

  static const Color bleuProfond = Color(0xFF0B1C3E);

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? bleuProfond;
    final subFg = foreground != null
        ? foreground!.withValues(alpha: 0.6)
        : Colors.grey[500]!;
    return Row(
      children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: subFg,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
