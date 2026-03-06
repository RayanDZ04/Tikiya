import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/event_service.dart';
import '../services/payment_service.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';
import '../main.dart' show ticketsRefreshTrigger;

/// Thrown when the user is not authenticated and tries to load tickets.
class _AuthRequiredException implements Exception {
  const _AuthRequiredException();
}

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen>
    with WidgetsBindingObserver {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  late Future<_TicketsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    ticketsRefreshTrigger.addListener(_onPaymentSuccess);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ticketsRefreshTrigger.removeListener(_onPaymentSuccess);
    super.dispose();
  }

  /// Recharge automatiquement quand l'app revient au premier plan
  /// (ex: l'utilisateur revient du navigateur externe après paiement).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _future = _load());
    }
  }

  void _onPaymentSuccess() => setState(() => _future = _load());

  Future<_TicketsData> _load() async {
    final sess = SessionStore.I.session.value;
    if (sess == null) {
      throw const _AuthRequiredException();
    }
    final List<TicketModel> tickets;
    try {
      tickets = await PaymentService().myTickets();
    } catch (e) {
      if (e.toString().contains('401')) {
        await SessionStore.I.clear();
        throw const _AuthRequiredException();
      }
      rethrow;
    }
    List<EventModel> events = [];
    try {
      events = await EventService().fetchAll();
    } catch (_) {}
    final eventMap = {for (final e in events) e.id: e};

    // Seuls les billets payés sont affichés
    final paidOnly = tickets.where((t) => t.status == 'paid').toList();

    // Group tickets by eventId — keep insertion order
    final grouped = <String, List<TicketModel>>{};
    for (final t in paidOnly) {
      grouped.putIfAbsent(t.eventId, () => []).add(t);
    }
    final groups = grouped.entries
        .map((e) => _TicketGroup(event: eventMap[e.key], tickets: e.value))
        .toList();

    return _TicketsData(groups: groups);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionStore.I.session.value;

    return Scaffold(
      backgroundColor: bleuProfond,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_num,
                          color: bleuCyan, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'Mes Billets',
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session?.email ?? '',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── Content ───────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: FutureBuilder<_TicketsData>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: bleuCyan),
                      );
                    }
                    if (snap.hasError) {
                      final isAuth = snap.error is _AuthRequiredException ||
                          snap.error.toString().contains('401');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAuth ? Icons.lock_outline : Icons.wifi_off_outlined,
                                color: const Color(0xFFB0BEC5),
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isAuth
                                    ? 'Connectez-vous pour voir vos billets.'
                                    : 'Impossible de charger vos billets.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  color: const Color(0xFF607D8B),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isAuth)
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                  icon: const Icon(Icons.login),
                                  label: const Text('Se connecter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bleuCyan,
                                    foregroundColor: Colors.white,
                                  ),
                                )
                              else
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _future = _load()),
                                  child: const Text('Réessayer'),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    final data = snap.data!;
                    if (data.groups.isEmpty) {
                      return _EmptyState(
                          onBrowse: () =>
                              Navigator.pushReplacementNamed(context, '/'));
                    }

                    return RefreshIndicator(
                      onRefresh: () async =>
                          setState(() => _future = _load()),
                      color: bleuCyan,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
                        itemCount: data.groups.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 20),
                        itemBuilder: (ctx, i) {
                          final group = data.groups[i];
                          return _GroupedTicketCard(group: group);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(current: 'tickets'),
    );
  }
}

// ── Data models ────────────────────────────────────────────────────────────────

class _TicketGroup {
  final EventModel? event;
  final List<TicketModel> tickets;
  _TicketGroup({required this.event, required this.tickets});

  String get eventId => tickets.first.eventId;
  int get totalCount => tickets.length;
  List<TicketModel> get paidTickets =>
      tickets.where((t) => t.status == 'paid').toList();
  int get paidCount => paidTickets.length;

  /// Overall status : paid if at least one paid, else first ticket's status.
  String get dominantStatus {
    if (tickets.any((t) => t.status == 'paid')) return 'paid';
    if (tickets.any((t) => t.status == 'pending')) return 'pending';
    return tickets.first.status;
  }

  int get unitAmount => tickets.first.amount;
}

class _TicketsData {
  final List<_TicketGroup> groups;
  const _TicketsData({required this.groups});
}

// ── Grouped ticket card ────────────────────────────────────────────────────────

class _GroupedTicketCard extends StatelessWidget {
  const _GroupedTicketCard({required this.group});

  final _TicketGroup group;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  Color get _statusColor {
    switch (group.dominantStatus) {
      case 'paid':
        return const Color(0xFF43A047);
      case 'pending':
        return const Color(0xFFFFA726);
      default:
        return const Color(0xFFEF5350);
    }
  }

  String get _statusLabel {
    if (group.dominantStatus == 'paid') {
      return group.totalCount > 1 ? 'Confirmé' : 'Confirmé';
    }
    if (group.dominantStatus == 'pending') return 'En attente';
    if (group.dominantStatus == 'failed') return 'Échoué';
    return 'Annulé';
  }

  IconData get _categoryIcon {
    switch (group.event?.category) {
      case 'musique':
        return Icons.music_note;
      case 'culture':
        return Icons.museum;
      default:
        return Icons.celebration;
    }
  }

  void _openQr(BuildContext context) {
    if (group.paidTickets.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _QrSlideDialog(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = group.event;
    final dateStr = event != null
        ? '${event.eventDate.day.toString().padLeft(2, '0')}/'
              '${event.eventDate.month.toString().padLeft(2, '0')}/'
              '${event.eventDate.year}'
        : group.tickets.first.createdAt.toLocal().toString().substring(0, 10);

    final hasPaid = group.paidCount > 0;
    final firstPaid =
        hasPaid ? group.paidTickets.first : null;

    return GestureDetector(
      onTap: hasPaid ? () => _openQr(context) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x180B1C3E),
              blurRadius: 24,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // ── Top colored band ──────────────────────────────────────
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasPaid
                        ? [bleuProfond, bleuCyan]
                        : [const Color(0xFFB0BEC5), const Color(0xFFCFD8DC)],
                  ),
                ),
              ),
              // ── Main body ─────────────────────────────────────────────
              SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left: event info ────────────────────────────────
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(18, 16, 12, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: bleuCyan.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_categoryIcon,
                                      size: 11, color: bleuCyan),
                                  const SizedBox(width: 4),
                                  Text(
                                    event?.category.toUpperCase() ??
                                        'ÉVÉNEMENT',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: bleuCyan,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Event title
                            Text(
                              event?.title ?? 'Événement',
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: bleuProfond,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            // Date
                            _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                text: dateStr),
                            if (event != null &&
                                event.location.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              _InfoRow(
                                  icon: Icons.place_outlined,
                                  text: event.location),
                            ],
                            const Spacer(),
                            const SizedBox(height: 12),
                            // Amount / count
                            if (group.totalCount > 1) ...[
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          bleuCyan.withValues(alpha: 0.14),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${group.totalCount} billets',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: bleuCyan,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '/ 5 max',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      color: bleuProfond
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${group.totalCount} × ${group.unitAmount} DZD',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: bleuProfond
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ] else ...[
                              Text(
                                group.unitAmount > 0
                                    ? '${group.unitAmount} DZD'
                                    : 'Gratuit',
                                style: GoogleFonts.montserrat(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: bleuProfond,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // ── Perforated divider ────────────────────────────────
                    _PerforatedDivider(statusColor: _statusColor),
                    // ── Right: QR / count ─────────────────────────────────
                    SizedBox(
                      width: 120,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _statusLabel,
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // QR area
                            if (firstPaid != null) ...[
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: bleuProfond.withValues(
                                              alpha: 0.08),
                                          width: 1),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(9),
                                      child: QrImageView(
                                        data: _qrData(firstPaid),
                                        version: QrVersions.auto,
                                        size: 86,
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF0B1C3E),
                                        ),
                                        dataModuleStyle:
                                            const QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: Color(0xFF0B1C3E),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Count badge overlay when multiple QRs
                                  if (group.paidCount > 1)
                                    Container(
                                      margin: const EdgeInsets.all(2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: bleuCyan,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '1/${group.paidCount}',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 8,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                group.paidCount > 1
                                    ? 'Glisser les QR'
                                    : 'Appuyer pour agrandir',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 8,
                                  color:
                                      bleuProfond.withValues(alpha: 0.35),
                                ),
                              ),
                            ] else ...[
                              Container(
                                width: 86,
                                height: 86,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.lock_outline,
                                    color: bleuProfond.withValues(
                                        alpha: 0.25),
                                    size: 28),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Bottom: ticket ref / method ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: bleuProfond.withValues(alpha: 0.03),
                  border: Border(
                    top: BorderSide(
                        color: bleuProfond.withValues(alpha: 0.07),
                        width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.confirmation_num_outlined,
                        size: 12,
                        color: bleuProfond.withValues(alpha: 0.35)),
                    const SizedBox(width: 6),
                    Text(
                      'N° ${group.tickets.first.id.substring(0, 8).toUpperCase()}',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: bleuProfond.withValues(alpha: 0.4),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      group.tickets.first.paymentMethod?.toUpperCase() ??
                          '',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: bleuCyan.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _qrData(TicketModel t) =>
      '{"id":"${t.id}","event":"${t.eventId}","status":"${t.status}"}';
}
// ── Info row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF90A4AE)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: const Color(0xFF0B1C3E).withValues(alpha: 0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Perforated divider (physical ticket effect) ────────────────────────────────
class _PerforatedDivider extends StatelessWidget {
  const _PerforatedDivider({required this.statusColor});
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      child: CustomPaint(
        painter: _PerforationPainter(statusColor: statusColor),
      ),
    );
  }
}

class _PerforationPainter extends CustomPainter {
  const _PerforationPainter({required this.statusColor});
  final Color statusColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-circles cut out of left and right edge
    final bgPaint = Paint()..color = const Color(0xFFF4F7FC);
    canvas.drawCircle(Offset(size.width / 2, 0), 10, bgPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height), 10, bgPaint);

    // Dashed vertical line
    final dashPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashH = 5.0;
    const gapH = 5.0;
    double y = 20;
    while (y < size.height - 20) {
      canvas.drawLine(
          Offset(size.width / 2, y), Offset(size.width / 2, y + dashH), dashPaint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) => false;
}

// ── QR full screen dialog ──────────────────────────────────────────────────────

// ── QR slide dialog (PageView swipeable) ─────────────────────────────────────
class _QrSlideDialog extends StatefulWidget {
  const _QrSlideDialog({required this.group});
  final _TicketGroup group;

  @override
  State<_QrSlideDialog> createState() => _QrSlideDialogState();
}

class _QrSlideDialogState extends State<_QrSlideDialog> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  late final PageController _ctrl;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _qrData(TicketModel t) =>
      '{"id":"${t.id}","event":"${t.eventId}","status":"${t.status}"}';

  @override
  Widget build(BuildContext context) {
    final tickets = widget.group.paidTickets;
    final event = widget.group.event;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 40, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header band ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [bleuProfond, Color(0xFF1A3A70)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_num, color: bleuCyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event?.title ?? 'Mes billets',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${event.eventDate.day.toString().padLeft(2, '0')}'
                            '/${event.eventDate.month.toString().padLeft(2, '0')}'
                            '/${event.eventDate.year}'
                            '${event.location.isNotEmpty ? ' · ${event.location}' : ''}',
                            style: GoogleFonts.montserrat(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (tickets.length > 1)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bleuCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_page + 1}/${tickets.length}',
                        style: GoogleFonts.montserrat(
                          color: bleuCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            // ── PageView of QR codes ──────────────────────────────────────
            SizedBox(
              height: 320,
              child: PageView.builder(
                controller: _ctrl,
                itemCount: tickets.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, index) {
                  final t = tickets[index];
                  final shortId = t.id.substring(0, 8).toUpperCase();
                  final fullId = t.id.toUpperCase();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: bleuProfond.withValues(alpha: 0.1),
                                width: 1.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: QrImageView(
                            data: _qrData(t),
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0B1C3E),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0B1C3E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: bleuProfond.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'N° $shortId',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: bleuProfond,
                                  letterSpacing: 3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                fullId,
                                style: GoogleFonts.montserrat(
                                  fontSize: 7,
                                  color: bleuProfond.withValues(alpha: 0.3),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ── Dots indicator ────────────────────────────────────────────
            if (tickets.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    tickets.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? bleuCyan
                            : bleuProfond.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
            // ── Amount + status row ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF43A047), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Confirmé',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF43A047),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tickets[_page].amount > 0
                        ? '${tickets[_page].amount} DZD'
                        : 'Gratuit',
                    style: GoogleFonts.montserrat(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: bleuProfond,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1C3E).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_num_outlined,
                size: 46,
                color: Color(0xFF00ACC1),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun billet',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0B1C3E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore acheté de billet.\nDécouvrez les événements disponibles.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: const Color(0xFF607D8B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.search, color: Colors.white),
              label: Text(
                'Voir les événements',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0B1C3E),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
