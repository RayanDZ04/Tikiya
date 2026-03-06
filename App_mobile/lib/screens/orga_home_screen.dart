import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/event_service.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';

class OrgaHomeScreen extends StatefulWidget {
  const OrgaHomeScreen({super.key});

  @override
  State<OrgaHomeScreen> createState() => _OrgaHomeScreenState();
}

class _OrgaHomeScreenState extends State<OrgaHomeScreen> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color blanc = Colors.white;

  late Future<List<EventModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = EventService().fetchMine();
  }

  void _reload() => setState(() => _future = EventService().fetchMine());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
            // ── Title ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.orgaHomeTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // ── Events list ────────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<EventModel>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: bleuCyan),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        snap.error.toString(),
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final events = snap.data ?? [];
                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_busy, color: Colors.white.withValues(alpha: 0.3), size: 64),
                          const SizedBox(height: 12),
                          Text(
                            l10n.orgaEventsEmpty,
                            style: GoogleFonts.montserrat(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bleuCyan,
                              foregroundColor: blanc,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              l10n.orgaCreateEvent,
                              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/orga').then((_) => _reload()),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (context, i) => _EventCard(event: events[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'home'),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final EventModel event;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  static String _fixUrl(String url) =>
      url.replaceFirst('http://localhost', 'http://10.0.2.2');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x440B1C3E), blurRadius: 14, offset: Offset(0, 6))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.coverUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.network(
                  _fixUrl(event.coverUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _a, _b) => Container(
                    height: 160,
                    color: const Color(0xFFF0F0F0),
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: bleuCyan.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
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
                          fontSize: 14,
                          color: bleuProfond,
                        ),
                      ),
                      if (event.location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.place, size: 12, color: bleuProfond.withValues(alpha: 0.5)),
                            const SizedBox(width: 3),
                            Text(
                              event.location,
                              style: GoogleFonts.montserrat(
                                  fontSize: 11, color: bleuProfond.withValues(alpha: 0.6))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 12, color: bleuProfond.withValues(alpha: 0.5)),
                          const SizedBox(width: 3),
                          Text(
                            '${event.eventDate.day.toString().padLeft(2, '0')}/'
                            '${event.eventDate.month.toString().padLeft(2, '0')}/'
                            '${event.eventDate.year}',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: bleuProfond.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      if (event.price > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bleuCyan,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${event.price.toStringAsFixed(0)} DZD',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
