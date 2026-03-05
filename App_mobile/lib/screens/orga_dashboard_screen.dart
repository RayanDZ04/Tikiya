import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/event_service.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';

class OrgaDashboardScreen extends StatefulWidget {
  const OrgaDashboardScreen({super.key});

  @override
  State<OrgaDashboardScreen> createState() => _OrgaDashboardScreenState();
}

class _OrgaDashboardScreenState extends State<OrgaDashboardScreen> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color blanc = Colors.white;

  late Future<List<EventModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = EventService().fetchMine();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = SessionStore.I.session.value;

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
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
                    ]),
                  ),
                  const LanguageSwitch(foregroundColor: Colors.white),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: bleuCyan),
                    );
                  }
                  final events = snap.data ?? [];
                  final now = DateTime.now();
                  final upcoming = events.where((e) => e.eventDate.isAfter(now)).toList();
                  final past = events.where((e) => e.eventDate.isBefore(now)).toList();
                  final totalRevenue = events.fold<double>(0, (sum, e) => sum + e.price * e.capacity);

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 20),

                      // ── Welcome ──────────────────────────────────────────
                      Text(
                        l10n.dashboardWelcome,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: blanc.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session?.email.split('@').first ?? '',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: blanc,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Stats grid ───────────────────────────────────────
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.event_note,
                            value: '${events.length}',
                            label: l10n.dashboardTotalEvents,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.upcoming,
                            value: '${upcoming.length}',
                            label: l10n.dashboardUpcoming,
                            accent: bleuCyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.history,
                            value: '${past.length}',
                            label: l10n.dashboardPast,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.attach_money,
                            value: '${totalRevenue.toStringAsFixed(0)} DZD',
                            label: l10n.dashboardRevenue,
                            accent: const Color(0xFF66BB6A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Recent events ────────────────────────────────────
                      if (events.isNotEmpty) ...[
                        Text(
                          l10n.dashboardRecent,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: blanc,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...events.take(3).map(
                              (e) => _RecentEventRow(event: e),
                            ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'dashboard'),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.accent,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color? accent;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Colors.white;
    return Expanded(
      child: SizedBox(
        height: 125,
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x440B1C3E), blurRadius: 12, offset: Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color == Colors.white ? bleuProfond : color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: bleuProfond,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: bleuProfond.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ], // inner Column
            ),
          ], // outer Column
        ),
        ), // Container
      ), // SizedBox
    );
  }
}

// ── Recent event row ───────────────────────────────────────────────────────────
class _RecentEventRow extends StatelessWidget {
  const _RecentEventRow({required this.event});
  final EventModel event;

  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color bleuProfond = Color(0xFF0B1C3E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x330B1C3E), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bleuCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: bleuCyan, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: bleuProfond,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.eventDate.day.toString().padLeft(2, '0')}/'
                  '${event.eventDate.month.toString().padLeft(2, '0')}/'
                  '${event.eventDate.year}'
                  '${event.location.isNotEmpty ? ' · ${event.location}' : ''}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: bleuProfond.withValues(alpha: 0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (event.price > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bleuCyan,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${event.price.toStringAsFixed(0)} DZD',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
