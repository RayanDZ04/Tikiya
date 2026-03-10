import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';
import '../widgets/settings_sheet.dart';
import 'market_screen.dart' show AuctionEntry, auctionStore, tikiyaCashBalance;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                      if (SessionStore.I.session.value?.role == 'organisateur')
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

                  final display = (session.username?.isNotEmpty ?? false)
                      ? session.username!
                      : session.email.split('@').first;
                  final initial = display.isNotEmpty
                      ? display[0].toUpperCase()
                      : '?';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // ── Avatar ───────────────────────────────────────
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [bleuCyan, Color(0xFF0077A8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: bleuCyan.withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.montserrat(
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                color: blanc,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ── Nom affiché ──────────────────────────────────
                        Text(
                          display,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: blanc,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // ── Email ────────────────────────────────────────
                        Text(
                          session.email,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: blanc.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Badge rôle ───────────────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: bleuCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: bleuCyan.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            l10n.navProfile.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              color: bleuCyan,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Carte infos ──────────────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: blanc,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x440B1C3E),
                                  blurRadius: 16,
                                  offset: Offset(0, 6)),
                            ],
                          ),
                          child: Column(
                            children: [
                              _InfoRow(
                                icon: Icons.person_outline,
                                label: l10n.profilePseudo,
                                value: display,
                              ),
                              Divider(
                                  height: 24,
                                  color: bleuProfond.withValues(alpha: 0.1)),
                              _InfoRow(
                                icon: Icons.email_outlined,
                                label: l10n.emailLabel,
                                value: session.email,
                              ),
                              Divider(
                                  height: 24,
                                  color: bleuProfond.withValues(alpha: 0.1)),
                              _ActionRow(
                                icon: Icons.settings_outlined,
                                label: l10n.profileSettings,
                                onTap: () => showSettingsSheet(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Tikiya Cash (participants uniquement) ────────
                        if (session.role == 'participant' ||
                            session.role == 'client')
                          ValueListenableBuilder<List<AuctionEntry>>(
                            valueListenable: auctionStore,
                            builder: (_, __, ___) {
                              final balance =
                                  tikiyaCashBalance(session.id);
                              final sales = auctionStore.value
                                  .where((a) =>
                                      a.sold &&
                                      a.sellerId == session.id)
                                  .toList();
                              return _TikiyaCashCard(
                                  balance: balance, sales: sales);
                            },
                          ),
                        const SizedBox(height: 20),

                        // ── Bouton déconnexion ───────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                            onPressed: () => SessionStore.I.clear(),
                          ),
                        ),

                        const SizedBox(height: 16),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'organisateur':
        return 'Organisateur';
      case 'participant':
        return 'Participant';
      default:
        return role.isEmpty ? 'Visiteur' : role;
    }
  }
}

// ── Info row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bleuCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: bleuCyan),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: bleuProfond.withValues(alpha: 0.4),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: bleuProfond,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Action row (tap) ───────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bleuCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: bleuCyan),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: bleuProfond,
              ),
            ),
          ),
          Icon(Icons.chevron_right,
              size: 18, color: bleuProfond.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}

// ── Tikiya Cash card ───────────────────────────────────────────────────────────

class _TikiyaCashCard extends StatelessWidget {
  const _TikiyaCashCard({required this.balance, required this.sales});
  final int balance;
  final List<AuctionEntry> sales;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color gold = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1C3E), Color(0xFF1A3A70)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x440B1C3E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bleuCyan.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: gold.withValues(alpha: 0.4), width: 1),
                        ),
                        child: const Icon(Icons.account_balance_wallet,
                            color: gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tikiya Cash',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          'DZD',
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white60,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Balance ─────────────────────────────────────────
                  Text(
                    '${balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} DZD',
                    style: GoogleFonts.montserrat(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (balance > 0)
                    Text(
                      '${sales.length} vente${sales.length > 1 ? 's' : ''} réalisée${sales.length > 1 ? 's' : ''}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: gold.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  // ── Transactions list ──────────────────────────────
                  if (sales.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    const SizedBox(height: 12),
                    ...sales.map((s) {
                      final shortId =
                          s.ticketId.substring(0, 8).toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFF43A047)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.arrow_downward,
                                  color: Color(0xFF66BB6A), size: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Billet N° $shortId vendu',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '+${s.currentBid} DZD',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF66BB6A),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
