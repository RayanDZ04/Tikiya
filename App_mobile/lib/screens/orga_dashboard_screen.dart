import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/event_service.dart';
import '../services/payment_service.dart';
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

  void _showEventDetail(BuildContext context, EventModel event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventDetailSheet(event: event),
    );
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
                              (e) => _RecentEventRow(
                                event: e,
                                onDetail: () => _showEventDetail(context, e),
                              ),
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
  const _RecentEventRow({required this.event, required this.onDetail});
  final EventModel event;
  final VoidCallback onDetail;

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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDetail,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bleuProfond,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Détail',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Event detail bottom sheet ──────────────────────────────────────────────────
class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({required this.event});
  final EventModel event;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color vert = Color(0xFF66BB6A);
  static const Color orange = Color(0xFFFFA726);

  late Future<EventTicketStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = PaymentService().eventStats(widget.event.id);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return FutureBuilder<EventTicketStats>(
      future: _statsFuture,
      builder: (context, snap) {
        final int sold = snap.data?.sold ?? 0;
        final int capacity = event.capacity;
        final int remaining = (capacity - sold).clamp(0, capacity);
        final double fillRate = capacity > 0 ? sold / capacity : 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            // ── Drag handle ───────────────────────────────────────────────
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
            const SizedBox(height: 20),

            // ── Titre ─────────────────────────────────────────────────────
            Text(
              event.title,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: bleuProfond,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${event.eventDate.day.toString().padLeft(2, '0')}/'
              '${event.eventDate.month.toString().padLeft(2, '0')}/'
              '${event.eventDate.year}'
              '${event.location.isNotEmpty ? ' · ${event.location}' : ''}',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: bleuProfond.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),

            // ── Donut chart ───────────────────────────────────────────────
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _DonutPainter(
                    fillRate: fillRate,
                    filledColor: bleuCyan,
                    emptyColor: const Color(0xFFE8EDF5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(fillRate * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: bleuProfond,
                          ),
                        ),
                        Text(
                          'remplissage',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: bleuProfond.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Stat cards ────────────────────────────────────────────────
            Row(
              children: [
                _DetailStat(
                  icon: Icons.confirmation_num_outlined,
                  value: '$sold',
                  label: 'Billets vendus',
                  color: bleuCyan,
                ),
                const SizedBox(width: 12),
                _DetailStat(
                  icon: Icons.event_seat_outlined,
                  value: '$remaining',
                  label: 'Billets restants',
                  color: vert,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _DetailStat(
                  icon: Icons.people_outline,
                  value: '$capacity',
                  label: 'Capacité totale',
                  color: bleuProfond,
                ),
                const SizedBox(width: 12),
                _DetailStat(
                  icon: Icons.attach_money,
                  value: event.price > 0
                      ? '${event.price.toStringAsFixed(0)} DZD'
                      : 'Gratuit',
                  label: 'Prix / billet',
                  color: orange,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Barre de remplissage ──────────────────────────────────────
            Text(
              'Taux de remplissage',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: bleuProfond,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fillRate.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [bleuProfond, bleuCyan],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$sold vendus',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: bleuProfond.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  '$capacity places',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: bleuProfond.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),

            if (event.price > 0 && sold > 0) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bleuProfond,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Revenus générés',
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${(event.price * sold).toStringAsFixed(0)} DZD',
                      style: GoogleFonts.montserrat(
                        color: bleuCyan,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );     // DraggableScrollableSheet
      },   // FutureBuilder builder
    );     // FutureBuilder
  }
}

// ── Detail stat tile ───────────────────────────────────────────────────────────
class _DetailStat extends StatelessWidget {
  const _DetailStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  static const Color bleuProfond = Color(0xFF0B1C3E);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: bleuProfond,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: bleuProfond.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Donut chart painter ────────────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fillRate,
    required this.filledColor,
    required this.emptyColor,
  });
  final double fillRate;
  final Color filledColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;
    const strokeWidth = 22.0;
    const startAngle = -1.5708; // -π/2 (top)

    final bgPaint = Paint()
      ..color = emptyColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = LinearGradient(
        colors: [filledColor, filledColor.withValues(alpha: 0.6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Background arc (full circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.2832,
      false,
      bgPaint,
    );

    // Foreground arc (fill rate)
    if (fillRate > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        6.2832 * fillRate,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fillRate != fillRate;
}
