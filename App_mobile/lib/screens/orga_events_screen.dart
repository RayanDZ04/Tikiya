import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/l10n.dart';
import '../services/event_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';

class OrgaEventsScreen extends StatefulWidget {
  const OrgaEventsScreen({super.key});

  @override
  State<OrgaEventsScreen> createState() => _OrgaEventsScreenState();
}

class _OrgaEventsScreenState extends State<OrgaEventsScreen> {
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

  Future<void> _showCreateDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateEventSheet(onCreated: () {
        Navigator.pop(ctx, true);
      }),
    );
    if (result == true) _reload();
  }

  Future<void> _showEditDialog(EventModel event) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _EditEventSheet(
        event: event,
        onUpdated: () => Navigator.pop(ctx, true),
      ),
    );
    if (result == true) _reload();
  }

  Future<void> _confirmDelete(EventModel event) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.title, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Text(l10n.eventDeleteConfirm, style: GoogleFonts.montserrat()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: GoogleFonts.montserrat()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: blanc,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await EventService().delete(event.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.eventDeleteSuccess, style: GoogleFonts.montserrat()),
            backgroundColor: bleuCyan,
          ),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
            // ── Title + refresh ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 8, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.orgaEventsTitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _reload,
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
                            style: GoogleFonts.montserrat(color: Colors.white.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    itemBuilder: (context, i) => _EventManageCard(
                      event: events[i],
                      onDelete: () => _confirmDelete(events[i]),
                      onEdit: () => _showEditDialog(events[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: bleuCyan,
        foregroundColor: blanc,
        icon: const Icon(Icons.add),
        label: Text(l10n.orgaCreateEvent,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        onPressed: _showCreateDialog,
      ),
      bottomNavigationBar: const BottomNav(current: 'orga'),
    );
  }
}

// ── Manage card with edit + delete buttons ───────────────────────────────────────
class _EventManageCard extends StatelessWidget {
  const _EventManageCard({
    required this.event,
    required this.onDelete,
    required this.onEdit,
  });
  final EventModel event;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

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
                            Text(event.location,
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
                        const SizedBox(height: 3),
                        Text('${event.price.toStringAsFixed(0)} DZD',
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: bleuCyan, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: bleuCyan),
                      tooltip: 'Modifier',
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: bleuProfond.withValues(alpha: 0.5)),
                      tooltip: 'Supprimer',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Create event bottom sheet ──────────────────────────────────────────────────
class _CreateEventSheet extends StatefulWidget {
  const _CreateEventSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color blanc = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  File? _pickedImage;
  bool _uploading = false;
  bool _loading = false;
  String _selectedCategory = 'musique';

  static const List<Map<String, String>> _categories = [
    {'value': 'musique',        'label': 'Musique'},
    {'value': 'culture',        'label': 'Culture'},
    {'value': 'divertissement', 'label': 'Divertissement'},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: bleuProfond, secondary: bleuCyan),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 18, minute: 0),
    );
    final t = time ?? const TimeOfDay(hour: 18, minute: 0);
    final dt = DateTime(picked.year, picked.month, picked.day, t.hour, t.minute);
    // Convertir en UTC pour RFC3339 valide
    _dateCtrl.text = dt.toUtc().toIso8601String();
  }

  Future<void> _pickImage() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (result == null) return;
    setState(() => _pickedImage = File(result.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // 1. Upload l'image si une a été choisie
      String? coverUrl;
      if (_pickedImage != null) {
        setState(() => _uploading = true);
        coverUrl = await EventService().uploadImage(_pickedImage!);
        if (mounted) setState(() => _uploading = false);
      }
      // 2. Créer l'événement
      await EventService().create(
        title: _titleCtrl.text.trim(),
        eventDate: _dateCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        price: _priceCtrl.text.trim().isEmpty ? null : double.tryParse(_priceCtrl.text.trim()),
        capacity: _capacityCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_capacityCtrl.text.trim()),
        coverUrl: coverUrl,
        category: _selectedCategory,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.eventCreateSuccess,
                style: GoogleFonts.montserrat()),
            backgroundColor: bleuCyan,
          ),
        );
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.orgaCreateEvent,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: bleuProfond,
                ),
              ),
              const SizedBox(height: 20),
              // ── Catégorie ─────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: bleuProfond,
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down, color: bleuCyan),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c['value'],
                              child: Row(
                                children: [
                                  Icon(
                                    c['value'] == 'musique'
                                        ? Icons.music_note
                                        : c['value'] == 'culture'
                                            ? Icons.museum
                                            : Icons.celebration,
                                    color: bleuCyan,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(c['label']!,
                                      style: GoogleFonts.montserrat(fontSize: 14)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _titleCtrl,
                label: l10n.eventTitleLabel,
                validator: (v) => (v == null || v.isEmpty) ? l10n.eventTitleRequired : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: _inputDeco(l10n.eventDateLabel),
                validator: (v) => (v == null || v.isEmpty) ? l10n.eventDateRequired : null,
              ),
              const SizedBox(height: 14),
              _buildField(controller: _locationCtrl, label: l10n.eventLocationLabel),
              const SizedBox(height: 14),
              _buildField(
                controller: _descCtrl,
                label: l10n.eventDescriptionLabel,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _priceCtrl,
                      label: l10n.eventPriceLabel,
                      keyboard: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _capacityCtrl,
                      label: l10n.eventCapacityLabel,
                      keyboard: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Image de couverture ─────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _pickedImage != null ? bleuCyan : Colors.grey.shade300,
                      width: _pickedImage != null ? 2 : 1,
                    ),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(
                            _pickedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 36, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Ajouter une image',
                              style: GoogleFonts.montserrat(
                                  color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                        ),
                ),
              ),
              if (_pickedImage != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _pickedImage = null),
                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                    label: Text('Supprimer',
                        style: GoogleFonts.montserrat(
                            color: Colors.red, fontSize: 12)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bleuProfond,
                    foregroundColor: blanc,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: (_loading || _uploading)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _uploading ? 'Envoi image...' : 'Création...',
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          ],
                        )
                      : Text(
                          l10n.confirm,
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bleuCyan, width: 1.5),
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: _inputDeco(label),
      validator: validator,
      style: GoogleFonts.montserrat(),
    );
  }
}

// ── Edit event bottom sheet ────────────────────────────────────────────────────
class _EditEventSheet extends StatefulWidget {
  const _EditEventSheet({required this.event, required this.onUpdated});
  final EventModel event;
  final VoidCallback onUpdated;

  @override
  State<_EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<_EditEventSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color blanc = Colors.white;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();

  // Séparation affichage / valeur ISO pour la date
  String _isoDate = '';
  File? _pickedImage;
  String? _existingCoverUrl;
  bool _uploading = false;
  bool _loading = false;
  String _selectedCategory = 'musique';

  static const List<Map<String, String>> _categories = [
    {'value': 'musique',        'label': 'Musique'},
    {'value': 'culture',        'label': 'Culture'},
    {'value': 'divertissement', 'label': 'Divertissement'},
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl.text = e.title;
    _locationCtrl.text = e.location;
    _descCtrl.text = e.description;
    _priceCtrl.text = e.price > 0 ? e.price.toStringAsFixed(0) : '';
    _capacityCtrl.text = e.capacity > 0 ? e.capacity.toString() : '';
    _existingCoverUrl = e.coverUrl;
    _selectedCategory = _categories.any((c) => c['value'] == e.category)
        ? e.category
        : 'musique';
    // Affichage lisible de la date
    _isoDate = e.eventDate.toUtc().toIso8601String();
    final d = e.eventDate.toLocal();
    _dateCtrl.text =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
        '  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = widget.event.eventDate.toLocal();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: bleuProfond, secondary: bleuCyan),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    final t = time ?? TimeOfDay(hour: initial.hour, minute: initial.minute);
    final dt = DateTime(picked.year, picked.month, picked.day, t.hour, t.minute);
    _isoDate = dt.toUtc().toIso8601String();
    setState(() {
      _dateCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}'
          '  ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickImage() async {
    final result = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (result == null) return;
    setState(() => _pickedImage = File(result.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? coverUrl = _existingCoverUrl;
      if (_pickedImage != null) {
        setState(() => _uploading = true);
        coverUrl = await EventService().uploadImage(_pickedImage!);
        if (mounted) setState(() => _uploading = false);
      }
      await EventService().update(
        id: widget.event.id,
        title: _titleCtrl.text.trim(),
        eventDate: _isoDate,
        description: _descCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        price: _priceCtrl.text.trim().isEmpty ? null : double.tryParse(_priceCtrl.text.trim()),
        capacity: _capacityCtrl.text.trim().isEmpty
            ? null
            : int.tryParse(_capacityCtrl.text.trim()),
        coverUrl: coverUrl,
        category: _selectedCategory,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Événement modifié !', style: GoogleFonts.montserrat()),
            backgroundColor: bleuCyan,
          ),
        );
        widget.onUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(), style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Modifier l\'événement',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: bleuProfond,
                ),
              ),
              const SizedBox(height: 20),
              // Catégorie
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    style: GoogleFonts.montserrat(fontSize: 14, color: bleuProfond),
                    icon: const Icon(Icons.keyboard_arrow_down, color: bleuCyan),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                    items: _categories
                        .map((c) => DropdownMenuItem(
                              value: c['value'],
                              child: Row(children: [
                                Icon(
                                  c['value'] == 'musique'
                                      ? Icons.music_note
                                      : c['value'] == 'culture'
                                          ? Icons.museum
                                          : Icons.celebration,
                                  color: bleuCyan, size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(c['label']!, style: GoogleFonts.montserrat(fontSize: 14)),
                              ]),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _titleCtrl,
                label: 'Titre',
                validator: (v) => (v == null || v.isEmpty) ? 'Titre requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                decoration: _inputDeco('Date et heure'),
                validator: (v) => (v == null || v.isEmpty) ? 'Date requise' : null,
              ),
              const SizedBox(height: 14),
              _buildField(controller: _locationCtrl, label: 'Lieu'),
              const SizedBox(height: 14),
              _buildField(controller: _descCtrl, label: 'Description', maxLines: 3),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildField(
                      controller: _priceCtrl,
                      label: 'Prix (DZD)',
                      keyboard: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      controller: _capacityCtrl,
                      label: 'Capacité',
                      keyboard: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Image de couverture
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (_pickedImage != null || _existingCoverUrl != null)
                          ? bleuCyan
                          : Colors.grey.shade300,
                      width: (_pickedImage != null || _existingCoverUrl != null) ? 2 : 1,
                    ),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover),
                        )
                      : _existingCoverUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.network(
                                _existingCoverUrl!.replaceFirst(
                                    'http://localhost', 'http://10.0.2.2'),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    size: 36, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('Changer l\'image',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                ),
              ),
              if (_pickedImage != null || _existingCoverUrl != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() {
                      _pickedImage = null;
                      _existingCoverUrl = null;
                    }),
                    icon: const Icon(Icons.close, size: 14, color: Colors.red),
                    label: Text('Supprimer l\'image',
                        style: GoogleFonts.montserrat(color: Colors.red, fontSize: 12)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bleuCyan,
                    foregroundColor: blanc,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: (_loading || _uploading)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _uploading ? 'Envoi image...' : 'Modification...',
                              style: GoogleFonts.montserrat(fontSize: 14),
                            ),
                          ],
                        )
                      : Text(
                          'Enregistrer les modifications',
                          style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: Colors.grey[600]),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: bleuCyan, width: 1.5),
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: _inputDeco(label),
      validator: validator,
      style: GoogleFonts.montserrat(),
    );
  }
}
