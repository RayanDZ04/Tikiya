import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/orga_event.dart';
import '../../services/orga_events_service.dart';

class OrgaEventFormScreen extends StatefulWidget {
  const OrgaEventFormScreen({super.key, this.eventId});
  final String? eventId; // null => create

  @override
  State<OrgaEventFormScreen> createState() => _OrgaEventFormScreenState();
}

class _OrgaEventFormScreenState extends State<OrgaEventFormScreen> {
  final _service = OrgaEventsService();

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _city = TextEditingController();
  final _venue = TextEditingController();
  final _price = TextEditingController(text: '2500');
  final _max = TextEditingController(text: '100');
  final _location = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = 'rap';

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final e = await _service.getEvent(widget.eventId!);
      _title.text = e.title;
      _city.text = e.city;
      _venue.text = e.venue;
      _price.text = e.price.toStringAsFixed(0);
      _max.text = e.maxParticipants.toString();
      _location.text = e.location ?? '';
      _description.text = e.description ?? '';
      _date = e.date;
      _category = e.category.isNotEmpty ? e.category : 'rap';
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final draft = OrgaEventDraft(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        date: _date,
        city: _city.text.trim(),
        venue: _venue.text.trim(),
        category: _category,
        price: double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
        maxParticipants: int.tryParse(_max.text) ?? 0,
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      );

      final isCreate = widget.eventId == null;
      final saved = isCreate
          ? await _service.createEvent(draft)
          : await _service.updateEvent(widget.eventId!, draft);

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushNamed(context, '/orga/event', arguments: saved.id);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _venue.dispose();
    _price.dispose();
    _max.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bleuProfond = Color(0xFF1A237E);
    const bleuCyan = Color(0xFF00ACC1);

    final isEdit = widget.eventId != null;

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        child: SingleChildScrollView(
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
                Text(isEdit ? 'Modifier l’événement' : 'Créer un événement',
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: bleuProfond)),
                const SizedBox(height: 14),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: const Color(0xFFB00020))),
                  ),

                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field('Nom de l’événement', _title, validator: _req),
                      const SizedBox(height: 10),
                      _dateField(onPick: _pickDate, date: _date),
                      const SizedBox(height: 10),
                      _field('Nombre max de participants', _max, keyboard: TextInputType.number, validator: _posInt),
                      const SizedBox(height: 10),
                      _field('Ville', _city, validator: _req),
                      const SizedBox(height: 10),
                      _field('Salle', _venue, validator: _req),
                      const SizedBox(height: 10),
                      _categoryField(value: _category, onChanged: (v) => setState(() => _category = v)),
                      const SizedBox(height: 10),
                      _field('Prix (DA)', _price, keyboard: TextInputType.number, validator: _posNum),
                      const SizedBox(height: 10),
                      _field('Localisation', _location),
                      const SizedBox(height: 10),
                      _textarea('Description', _description),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: bleuCyan, foregroundColor: Colors.white),
                          onPressed: _loading ? null : _save,
                          child: Text('Enregistrer', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: bleuProfond, side: const BorderSide(color: bleuCyan, width: 1.5)),
                          onPressed: _loading ? null : () => Navigator.pop(context),
                          child: Text('Annuler', style: GoogleFonts.montserrat(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requis' : null;
String? _posNum(String? v) {
  final x = double.tryParse((v ?? '').replaceAll(',', '.'));
  if (x == null || x <= 0) return 'Invalide';
  return null;
}

String? _posInt(String? v) {
  final x = int.tryParse((v ?? '').trim());
  if (x == null || x <= 0) return 'Invalide';
  return null;
}

Widget _field(String label, TextEditingController c, {TextInputType? keyboard, String? Function(String?)? validator}) {
  return TextFormField(
    controller: c,
    keyboardType: keyboard,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
  );
}

Widget _textarea(String label, TextEditingController c) {
  return TextFormField(
    controller: c,
    maxLines: 3,
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
  );
}

Widget _dateField({required VoidCallback onPick, required DateTime date}) {
  final yyyy = date.year.toString().padLeft(4, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  return InkWell(
    onTap: onPick,
    borderRadius: BorderRadius.circular(8),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: 'Date',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      child: Row(
        children: [
          Expanded(child: Text('$yyyy-$mm-$dd')),
          const Icon(Icons.calendar_month),
        ],
      ),
    ),
  );
}

Widget _categoryField({required String value, required ValueChanged<String> onChanged}) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    items: const [
      DropdownMenuItem(value: 'rap', child: Text('Musique (rap)')),
      DropdownMenuItem(value: 'culture', child: Text('Culture')),
      DropdownMenuItem(value: 'divertissement', child: Text('Divertissement')),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
    decoration: InputDecoration(
      labelText: 'Catégorie',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
  );
}
