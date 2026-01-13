import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/l10n.dart';
import '../../models/orga_event.dart';
import '../../services/orga_events_service.dart';
import '../../services/session_store.dart';
import '../../widgets/bottom_nav.dart';

class OrgaEventsScreen extends StatefulWidget {
  const OrgaEventsScreen({super.key});

  @override
  State<OrgaEventsScreen> createState() => _OrgaEventsScreenState();
}

class _OrgaEventsScreenState extends State<OrgaEventsScreen> {
  final _service = OrgaEventsService();

  Future<void> _confirmDelete(BuildContext context, OrgaEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Supprimer'),
          content: Text('Supprimer "${e.title}" ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
          ],
        );
      },
    );

    if (ok == true) {
      await _service.deleteEvent(e.id);
      if (!mounted) return;
      setState(() {});
    }
  }

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
            return Stack(
              children: [
                SingleChildScrollView(
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
                        Text('Mes événements', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: bleuProfond)),
                        const SizedBox(height: 16),

                        if (snap.connectionState == ConnectionState.waiting)
                          const Center(child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator()))
                        else if (session == null)
                          Text('Connecte-toi pour voir tes événements.', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600))
                        else if (snap.hasError)
                          Text('Erreur: ${snap.error}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: const Color(0xFFB00020)))
                        else if (events.isEmpty)
                          Text('Aucun événement', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600))
                        else
                          Column(
                            children: [
                              for (final e in events)
                                _eventRow(
                                  e,
                                  onView: () => Navigator.pushNamed(context, '/orga/event', arguments: e.id),
                                  onEdit: () => Navigator.pushNamed(context, '/orga/event/edit', arguments: e.id).then((_) => setState(() {})),
                                  onDelete: () => _confirmDelete(context, e),
                                ),
                            ],
                          ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 88,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          onPressed: () => Navigator.pushNamed(context, '/orga/event/new').then((_) => setState(() {})),
                          backgroundColor: bleuCyan,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 6),
                        Text('Créer un event', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuCyan)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'orga'),
    );
  }
}

Widget _eventRow(OrgaEvent e, {required VoidCallback onView, required VoidCallback onEdit, required VoidCallback onDelete}) {
  const bleuProfond = Color(0xFF1A237E);
  return Container(
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
          decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.event, color: bleuProfond),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond)),
              const SizedBox(height: 4),
              Text('${e.city} · ${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, color: const Color(0xFF2E3A44))),
            ],
          ),
        ),
        TextButton(onPressed: onView, child: Text('Voir', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond))),
        TextButton(onPressed: onEdit, child: Text('Modifier', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond))),
        TextButton(onPressed: onDelete, child: Text('Supprimer', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: const Color(0xFFB00020)))),
      ],
    ),
  );
}
