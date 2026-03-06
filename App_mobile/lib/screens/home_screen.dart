import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n.dart';
import '../services/session_store.dart';
import '../services/event_service.dart';
import '../services/payment_service.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';
import 'orga_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _filtersOpen = false;
  late Future<List<EventModel>> _eventsFuture;
  String _activeFilter = '';

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventService().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    // Dispatch organizer to their dedicated home
    final session = SessionStore.I.session.value;
    if (session != null && session.role == 'organisateur') {
      return const OrgaHomeScreen();
    }

    final l10n = context.l10n;
    const Color bleuProfond = Color(0xFF0B1C3E);
    const Color bleuCyan = Color(0xFF00ACC1);
    const Color grisClair = Color(0xFFF5F7FA);
    const Color blanc = Colors.white;
    const Color grisFonce = Color(0xFF2E3A44);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header full-width
            Container(
              decoration: BoxDecoration(
                color: bleuProfond,
                boxShadow: const [BoxShadow(color: Color(0x121A237E), blurRadius: 16, offset: Offset(0, 2))],
                border: const Border(bottom: BorderSide(color: bleuCyan, width: 4)),
              ),
              padding: const EdgeInsets.only(top: 76, bottom: 56),
              child: Stack(
                children: [
                  // Top-left: prénom/pseudo si connecté, sinon bouton S'inscrire
                  Positioned(
                    left: 16,
                    top: 0,
                    child: ValueListenableBuilder<UserSession?>(
                      valueListenable: SessionStore.I.session,
                      builder: (context, session, _) {
                        if (session == null) {
                          return TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/register-role'),
                            style: TextButton.styleFrom(
                              foregroundColor: blanc,
                              textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
                            ),
                            child: Text(l10n.authRegister),
                          );
                        }
                        final display = (session.username?.isNotEmpty ?? false)
                            ? session.username!
                            : session.email.split('@').first;
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Text(
                            display,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: blanc,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Top-right: langue uniquement
                  const Positioned(
                    right: 16,
                    top: 0,
                    child: LanguageSwitch(foregroundColor: blanc),
                  ),
                  // Centered title + search + filters toggle
                  Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: l10n.appTitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: blanc,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              TextSpan(
                                text: '!',
                                style: GoogleFonts.montserrat(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF00ACC1),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.homeTagline,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00ACC1),
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        // Search bar (shorter width)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
                          constraints: const BoxConstraints(maxWidth: 360),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 52,
                          decoration: BoxDecoration(
                            color: blanc,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: bleuCyan, width: 1.5),
                            boxShadow: const [BoxShadow(color: Color(0x141A237E), blurRadius: 12, offset: Offset(0, 2))],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  style: TextStyle(fontSize: 16, height: 1.0),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                    border: InputBorder.none,
                                    hintText: l10n.homeSearchHint,
                                  ),
                                ),
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(color: grisFonce, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: const Icon(Icons.search, size: 22, color: bleuCyan),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => setState(() => _filtersOpen = !_filtersOpen),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(color: grisFonce, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.tune, size: 20, color: bleuCyan),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Filters only when toggled
                        if (_filtersOpen)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE3E8EF)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(11, 28, 62, 0.10),
                                  blurRadius: 24,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.tune, color: bleuCyan, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      l10n.homeFiltersTitle,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: bleuProfond,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => setState(() => _filtersOpen = false),
                                      child: Text(
                                        l10n.homeFiltersClose,
                                        style: GoogleFonts.montserrat(
                                          color: bleuCyan,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final cat in [
                                    {'value': '', 'label': 'Tous'},
                                    {'value': 'musique', 'label': l10n.filterMusic},
                                    {'value': 'culture', 'label': l10n.filterCulture},
                                    {'value': 'divertissement', 'label': l10n.filterEntertainment},
                                  ])
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _activeFilter = cat['value']!;
                                        _filtersOpen = false;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _activeFilter == cat['value'] ? bleuProfond : grisClair,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _activeFilter == cat['value'] ? bleuProfond : const Color(0xFFE3E8EF),
                                          ),
                                        ),
                                        child: Text(
                                          cat['label']!,
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _activeFilter == cat['value'] ? Colors.white : bleuProfond,
                                          ),
                                        ),
                                      ),
                                    ),
                                ]),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Events by category ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<EventModel>>(
                future: _eventsFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1))),
                    );
                  }
                  final all = snap.data ?? [];
                  final filtered = _activeFilter.isEmpty
                      ? all
                      : all.where((e) => e.category == _activeFilter).toList();

                  if (filtered.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          l10n.homeNoContentYet,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF0B1C3E).withValues(alpha: 0.4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }

                  // Group by category
                  final categories = _activeFilter.isNotEmpty
                      ? [_activeFilter]
                      : ['musique', 'culture', 'divertissement'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final cat in categories) ...[
                        () {
                          final evts = filtered.where((e) => e.category == cat).toList();
                          if (evts.isEmpty) return const SizedBox.shrink();
                          final catLabel = cat == 'musique'
                              ? l10n.filterMusic
                              : cat == 'culture'
                                  ? l10n.filterCulture
                                  : l10n.filterEntertainment;
                          final catIcon = cat == 'musique'
                              ? Icons.music_note
                              : cat == 'culture'
                                  ? Icons.museum
                                  : Icons.celebration;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(children: [
                                Icon(catIcon, color: const Color(0xFF00ACC1), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  catLabel,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1C3E),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  clipBehavior: Clip.none,
                                  itemCount: evts.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                                  itemBuilder: (ctx, i) => GestureDetector(
                                    onTap: () => _showEventDetail(ctx, evts[i]),
                                    child: _ParticipantEventCard(event: evts[i]),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        }(),
                      ],
                    ],
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

// ── Show event detail + buy ticket ────────────────────────────────────────────
void _showEventDetail(BuildContext context, EventModel event) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EventDetailSheet(event: event),
  );
}

// ── Event detail sheet with payment ───────────────────────────────────────────
class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({required this.event});
  final EventModel event;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  bool _loading = false;
  String? _error;
  String _paymentMethod = 'edahabia';

  static String _fixUrl(String url) =>
      url.replaceFirst('http://localhost', 'http://10.0.2.2');

  Future<void> _startPayment() async {
    final session = SessionStore.I.session.value;
    if (session == null) {
      setState(() => _error = 'Connectez-vous pour acheter un billet.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await PaymentService().createCheckout(
        eventId: widget.event.id,
        paymentMethod: _paymentMethod,
      );
      final uri = Uri.parse(result.checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() => _error = 'Impossible d\'ouvrir le navigateur.');
      }
    } catch (e) {
      final msg = e.toString();
      // Extract backend detail if present (e.g. 5-ticket limit)
      String display = 'Erreur lors du paiement.';
      if (msg.contains('"detail":"')) {
        final start = msg.indexOf('"detail":"') + 10;
        final end = msg.indexOf('"', start);
        if (end > start) display = msg.substring(start, end);
      } else if (msg.contains('Impossible')) {
        display = msg;
      }
      setState(() => _error = display);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Cover image
                    if (event.coverUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _fixUrl(event.coverUrl!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _a, _b) => Container(
                            height: 180,
                            color: const Color(0xFFF0F4FF),
                            child: const Center(
                              child: Icon(Icons.image_outlined,
                                  color: Color(0xFFB0BEC5), size: 40),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      event.title,
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: bleuProfond,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Chips: location + date
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      if (event.location.isNotEmpty)
                        _InfoChip(
                            icon: Icons.place_outlined,
                            label: event.location),
                      _InfoChip(
                        icon: Icons.calendar_today_outlined,
                        label:
                            '${event.eventDate.day.toString().padLeft(2, '0')}/'
                            '${event.eventDate.month.toString().padLeft(2, '0')}/'
                            '${event.eventDate.year}',
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Description
                    if (event.description.isNotEmpty) ...[
                      Text(
                        event.description,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: bleuProfond.withValues(alpha: 0.65),
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Price row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_activity_outlined,
                              color: bleuCyan, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            event.price > 0
                                ? '${event.price.toStringAsFixed(0)} DZD / billet'
                                : 'Entrée gratuite',
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: bleuProfond,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (event.price > 0) ...[
                      const SizedBox(height: 20),
                      // Payment method selector
                      Text(
                        'Moyen de paiement',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: bleuProfond,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _PaymentMethodTile(
                            label: 'EDAHABIA',
                            icon: Icons.credit_card,
                            selected: _paymentMethod == 'edahabia',
                            onTap: () =>
                                setState(() => _paymentMethod = 'edahabia'),
                          ),
                          const SizedBox(width: 10),
                          _PaymentMethodTile(
                            label: 'CIB',
                            icon: Icons.account_balance_wallet_outlined,
                            selected: _paymentMethod == 'cib',
                            onTap: () =>
                                setState(() => _paymentMethod = 'cib'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Error message
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: GoogleFonts.montserrat(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      // Buy button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _startPayment,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.payment,
                                  color: Colors.white),
                          label: Text(
                            _loading ? 'Redirection...' : 'Acheter un billet',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bleuProfond,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Paiement sécurisé via Chargily Pay',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: bleuProfond.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          label: Text(
                            'Entrée gratuite — Réserver',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF66BB6A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: const Color(0xFF00ACC1)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: const Color(0xFF0B1C3E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ]),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const bleuProfond = Color(0xFF0B1C3E);
    const bleuCyan = Color(0xFF00ACC1);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? bleuProfond : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? bleuProfond : const Color(0xFFE3E8EF),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? bleuCyan : bleuProfond, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? Colors.white : bleuProfond,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Participant event card (horizontal scroll) ─────────────────────────────────
class _ParticipantEventCard extends StatelessWidget {
  const _ParticipantEventCard({required this.event});
  final EventModel event;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  static String _fixUrl(String url) =>
      url.replaceFirst('http://localhost', 'http://10.0.2.2');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x220B1C3E), blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          SizedBox(
            height: 110,
            width: double.infinity,
            child: event.coverUrl != null
                ? Image.network(
                    _fixUrl(event.coverUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _a, _b) => Container(
                      color: const Color(0xFFF0F4FF),
                      child: const Center(
                        child: Icon(Icons.image_outlined, color: Color(0xFFB0BEC5), size: 32),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF0F4FF),
                    child: const Center(
                      child: Icon(Icons.event, color: Color(0xFF00ACC1), size: 32),
                    ),
                  ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (event.location.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.place, size: 11, color: Color(0xFF90A4AE)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          event.location,
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            color: bleuProfond.withValues(alpha: 0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${event.eventDate.day.toString().padLeft(2, '0')}/'
                        '${event.eventDate.month.toString().padLeft(2, '0')}',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          color: bleuProfond.withValues(alpha: 0.4),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: event.price > 0 ? bleuCyan : const Color(0xFF66BB6A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.price > 0
                              ? '${event.price.toStringAsFixed(0)} DZD'
                              : 'Gratuit',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
