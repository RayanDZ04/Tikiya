import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/orga_event.dart';
import '../../services/orga_events_service.dart';

class OrgaEventDetailScreen extends StatefulWidget {
  const OrgaEventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  State<OrgaEventDetailScreen> createState() => _OrgaEventDetailScreenState();
}

class _OrgaEventDetailScreenState extends State<OrgaEventDetailScreen> {
  final _service = OrgaEventsService();

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteEvent(id);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bleuProfond = Color(0xFF1A237E);
    const bleuCyan = Color(0xFF00ACC1);

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        child: FutureBuilder<OrgaEvent>(
          future: _service.getEvent(widget.eventId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur: ${snap.error}', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              );
            }
            final e = snap.data!;
            final capacity = e.maxParticipants;
            final sold = 0;
            final used = 0;
            final cancelled = 0;
            final remaining = capacity - sold;
            final occupancy = capacity > 0 ? ((sold / capacity) * 100).round() : 0;
            final revenue = e.price * sold;

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
                    Text(e.title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: bleuProfond)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _kpi('Places totales', '$capacity'),
                        _kpi('Vendues', '$sold'),
                        _kpi('Restantes', '${remaining < 0 ? 0 : remaining}'),
                        _kpi('Remplissage', '$occupancy%'),
                        _kpi('Prix', '${e.price.toStringAsFixed(0)} DA'),
                        _kpi('Chiffre d’affaires', '${revenue.toStringAsFixed(0)} DA'),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e.city} · ${e.venue}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: bleuProfond)),
                          const SizedBox(height: 6),
                          Text('Date: ${_fmtDate(e.date)}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                          Text('Catégorie: ${e.category}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                          if ((e.location ?? '').isNotEmpty)
                            Text('Localisation: ${e.location}', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    if ((e.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('Description', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: bleuProfond)),
                      const SizedBox(height: 6),
                      Text(e.description!.trim(), style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                    ],

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pushNamed(context, '/orga/event/edit', arguments: e.id).then((_) => setState(() {})),
                            style: OutlinedButton.styleFrom(foregroundColor: bleuProfond, side: const BorderSide(color: bleuCyan, width: 1.5)),
                            child: Text('Modifier', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _delete(e.id),
                            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB00020), side: const BorderSide(color: Color(0xFFB00020), width: 1.5)),
                            child: Text('Supprimer', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Retour', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, color: bleuProfond)),
                      ),
                    ),

                    const SizedBox(height: 10),
                    Text('Billets: valides ${sold - used}, utilisés $used, annulés $cancelled',
                        style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF2E3A44))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _kpi(String label, String value) {
  const bleuProfond = Color(0xFF1A237E);
  const bleuCyan = Color(0xFF00ACC1);
  return Container(
    width: 160,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: bleuCyan, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2E3A44))),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: bleuProfond)),
      ],
    ),
  );
}

String _fmtDate(DateTime d) {
  final yyyy = d.year.toString().padLeft(4, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}
