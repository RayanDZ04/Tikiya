import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/l10n.dart';
import '../../models/orga_event.dart';
import '../../services/orga_events_service.dart';
import '../../services/session_store.dart';
import '../../widgets/bottom_nav.dart';

class OrgaPanelScreen extends StatefulWidget {
  const OrgaPanelScreen({super.key});

  @override
  State<OrgaPanelScreen> createState() => _OrgaPanelScreenState();
}

class _OrgaPanelScreenState extends State<OrgaPanelScreen> {
  final _service = OrgaEventsService();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const bleuProfond = Color(0xFF1A237E);
    const bleuCyan = Color(0xFF00ACC1);

    final session = SessionStore.I.session.value;

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        child: FutureBuilder<List<OrgaEvent>>(
          future: session == null ? Future.value([]) : _service.listEvents(),
          builder: (context, snap) {
            final events = snap.data ?? const <OrgaEvent>[];
            final eventsCount = events.length;
            final ticketsSold = 0;
            final revenue = 0.0;
            final occupancy = 0;
            final recent = events.take(3).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 35, 126, 0.10), blurRadius: 24, offset: Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: l10n.appTitle,
                            style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w700, color: bleuProfond),
                          ),
                          TextSpan(
                            text: '!',
                            style: GoogleFonts.montserrat(fontSize: 26, fontWeight: FontWeight.w800, color: bleuCyan),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Panel organisateur',
                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: bleuProfond),
                    ),
                    const SizedBox(height: 16),

                    _statsGrid(
                      bleuProfond: bleuProfond,
                      bleuCyan: bleuCyan,
                      events: eventsCount,
                      ticketsSold: ticketsSold,
                      occupancy: occupancy,
                      revenue: revenue,
                    ),

                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _actionButton(
                          label: 'Créer un événement',
                          onTap: () => Navigator.pushNamed(context, '/orga/event/new'),
                        ),
                        _actionButton(
                          label: 'Mes événements',
                          onTap: () => Navigator.pushReplacementNamed(context, '/orga'),
                        ),
                        _actionButton(
                          label: 'Paramètres',
                          onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Événements récents',
                      style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: bleuProfond),
                    ),
                    const SizedBox(height: 10),
                    if (snap.connectionState == ConnectionState.waiting)
                      const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    else if (session == null)
                      Text('Connecte-toi pour voir tes événements.', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600))
                    else if (snap.hasError)
                      Text('Erreur: ${snap.error}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: const Color(0xFFB00020)))
                    else if (recent.isEmpty)
                      Text('Aucun événement', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600))
                    else
                      Column(
                        children: [
                          for (final e in recent)
                            _recentItem(
                              title: e.title,
                              subtitle: '${e.city} · ${_fmtDate(e.date)}',
                              onTap: () => Navigator.pushNamed(context, '/orga/event', arguments: e.id),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'home'),
    );
  }
}

Widget _statsGrid({
  required Color bleuProfond,
  required Color bleuCyan,
  required int events,
  required int ticketsSold,
  required int occupancy,
  required double revenue,
}) {
  Widget card({required String label, required String value, String? foot}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bleuCyan, width: 1.5),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(26, 35, 126, 0.08), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2E3A44))),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: bleuProfond)),
          if (foot != null) ...[
            const SizedBox(height: 6),
            Text(foot, style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E3A44))),
          ],
        ],
      ),
    );
  }

  return LayoutBuilder(
    builder: (context, c) {
      final isWide = c.maxWidth >= 520;
      return GridView.count(
        crossAxisCount: isWide ? 4 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          card(label: 'Événements', value: '$events'),
          card(label: 'Billets vendus', value: '$ticketsSold', foot: '+0%'),
          card(label: 'Remplissage', value: '$occupancy%', foot: '—'),
          card(label: 'Revenus', value: '${revenue.toStringAsFixed(0)} DA', foot: '≈ 0 DA/billet'),
        ],
      );
    },
  );
}

Widget _actionButton({required String label, required VoidCallback onTap}) {
  const bleuProfond = Color(0xFF1A237E);
  const bleuCyan = Color(0xFF00ACC1);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bleuCyan, width: 1.5),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 172, 193, 0.08), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond)),
    ),
  );
}

Widget _recentItem({required String title, required String subtitle, required VoidCallback onTap}) {
  const bleuProfond = Color(0xFF1A237E);
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.event, color: bleuProfond),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: const Color(0xFF2E3A44))),
              ],
            ),
          ),
          Text('Voir', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond)),
        ],
      ),
    ),
  );
}

String _fmtDate(DateTime d) {
  final yyyy = d.year.toString().padLeft(4, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}
