import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/l10n.dart';
import '../services/event_service.dart';
import '../services/payment_service.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';

// ── In-memory auction store (lives for the full app session) ──────────────────

/// Public model – accessible from tickets_screen.dart
class AuctionEntry {
  final String id;
  final String sellerId;
  final String sellerEmail;
  final String ticketId;
  final String concertTitle;
  final int startingPrice;
  int currentBid;
  int bidCount;
  bool sold;

  AuctionEntry({
    required this.id,
    required this.sellerId,
    required this.sellerEmail,
    required this.ticketId,
    required this.startingPrice,
    required this.currentBid,
    this.concertTitle = '',
    this.bidCount = 0,
    this.sold = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerId': sellerId,
        'sellerEmail': sellerEmail,
        'ticketId': ticketId,
        'concertTitle': concertTitle,
        'startingPrice': startingPrice,
        'currentBid': currentBid,
        'bidCount': bidCount,
        'sold': sold,
      };

  factory AuctionEntry.fromJson(Map<String, dynamic> j) => AuctionEntry(
        id: j['id'] as String,
        sellerId: j['sellerId'] as String,
        sellerEmail: j['sellerEmail'] as String,
        ticketId: j['ticketId'] as String,
        concertTitle: (j['concertTitle'] as String?) ?? '',
        startingPrice: j['startingPrice'] as int,
        currentBid: j['currentBid'] as int,
        bidCount: (j['bidCount'] as int?) ?? 0,
        sold: (j['sold'] as bool?) ?? false,
      );
}

// ── Persistence helpers ───────────────────────────────────────────────────────
const _kAuctionStoreKey = 'tikiya_auction_store_v1';

/// Charge le store depuis SharedPreferences (appelé au démarrage).
Future<void> loadAuctionStore() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kAuctionStoreKey);
  if (raw != null) {
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => AuctionEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      auctionStore.value = list;
    } catch (_) {}
  }
}

/// Sauvegarde le store dans SharedPreferences.
Future<void> saveAuctionStore() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
      _kAuctionStoreKey, jsonEncode(auctionStore.value.map((e) => e.toJson()).toList()));
}

/// Global in-memory store – persists across navigations within the same session.
final ValueNotifier<List<AuctionEntry>> auctionStore =
    ValueNotifier([]);

/// IDs des billets actuellement en vente (non vendus).
Set<String> get listedTicketIds =>
    auctionStore.value.where((a) => !a.sold).map((a) => a.ticketId).toSet();

/// Solde Tikiya Cash d'un utilisateur = somme des ventes confirmées (sold).
int tikiyaCashBalance(String userId) => auctionStore.value
    .where((a) => a.sold && a.sellerId == userId)
    .fold(0, (sum, a) => sum + a.currentBid);

// ── Screen ─────────────────────────────────────────────────────────────────────

class MarketScreen extends StatefulWidget {
  /// When provided, the sell sheet opens automatically pre-selecting this ticket.
  const MarketScreen({super.key, this.preselectTicketId});
  final String? preselectTicketId;

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color bgLight = Color(0xFFF4F7FC);

  late final TabController _tabCtrl;
  bool _loadingTickets = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.preselectTicketId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openSellSheet(preselectId: widget.preselectTicketId),
      );
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<List<TicketModel>> _loadMyPaidTickets() async {
    final all = await PaymentService().myTickets();
    // Exclude tickets already listed in the shop
    final listed = listedTicketIds;
    return all
        .where((t) => t.status == 'paid' && !listed.contains(t.id))
        .toList();
  }

  void _openSellSheet({String? preselectId}) async {
    setState(() => _loadingTickets = true);
    List<TicketModel> tickets = [];
    Map<String, EventModel> eventsMap = {};
    try {
      tickets = await _loadMyPaidTickets();
      final events = await EventService().fetchAll();
      eventsMap = {for (final e in events) e.id: e};
    } catch (_) {}
    setState(() => _loadingTickets = false);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SellSheet(
        tickets: tickets,
        preselectId: preselectId,
        eventsMap: eventsMap,
        onList: _handleList,
      ),
    );
  }

  void _handleList(TicketModel ticket, int price, String concertTitle) {
    final session = SessionStore.I.session.value!;
    final now = DateTime.now();
    auctionStore.value = [
      ...auctionStore.value,
      AuctionEntry(
        id: '${now.millisecondsSinceEpoch}',
        sellerId: session.id,
        sellerEmail: session.email,
        ticketId: ticket.id,
        concertTitle: concertTitle,
        startingPrice: price,
        currentBid: price,
        bidCount: 0,
        sold: false,
      ),
    ];
    saveAuctionStore();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.shopTicketListed,
            style: GoogleFonts.montserrat()),
        backgroundColor: const Color(0xFF43A047),
      ),
    );
    _tabCtrl.animateTo(1); // → Mes ventes
  }

  void _openBidSheet(AuctionEntry auction) {
    showDialog(
      context: context,
      builder: (_) => _BidDialog(
        auction: auction,
        onBid: (amount) {
          // Mark as sold and credit the seller: first confirmed bid wins
          final updated = auctionStore.value.map((a) {
            if (a.id == auction.id) {
              a.currentBid = amount;
              a.bidCount++;
              a.sold = true;
            }
            return a;
          }).toList();
          auctionStore.value = [...updated];
          saveAuctionStore();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.shopBidPlaced,
                  style: GoogleFonts.montserrat()),
              backgroundColor: bleuCyan,
            ),
          );
        },
      ),
    );
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
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: bleuCyan, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.shopTitle,
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
                    context.l10n.shopSubtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── TabBar ─────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: bleuCyan,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700, fontSize: 12),
                      unselectedLabelStyle: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w500, fontSize: 12),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(text: context.l10n.shopTabShop),
                        Tab(text: context.l10n.shopTabMine),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: bgLight,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ValueListenableBuilder<List<AuctionEntry>>(
                  valueListenable: auctionStore,
                  builder: (ctx, auctions, _) {
                    final myId = session?.id ?? '';
                    // Shop = billets des AUTRES utilisateurs non vendus
                    final others = auctionStore.value
                        .where((a) => !a.sold && a.sellerId != myId)
                        .toList();
                    final mine =
                        auctionStore.value.where((a) => a.sellerId == myId).toList();

                    return TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _ShopTab(
                          auctions: others,
                          myId: myId,
                          onBid: _openBidSheet,
                        ),
                        _MyListingsTab(
                          auctions: mine,
                          onCancel: (a) {
                            auctionStore.value = auctionStore.value
                                .where((e) => e.id != a.id)
                                .toList();
                            saveAuctionStore();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      // ── FAB (Mes ventes uniquement) ───────────────────────────────────────
      floatingActionButton: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (_, __) {
          if (_tabCtrl.index != 1) return const SizedBox.shrink();
          return _loadingTickets
              ? FloatingActionButton(
                  onPressed: null,
                  backgroundColor: bleuCyan,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  ),
                )
              : FloatingActionButton.extended(
                  onPressed: () => _openSellSheet(),
                  backgroundColor: bleuCyan,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.sell_outlined),
                  label: Text(
                    context.l10n.shopSellFab,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
                  ),
                );
        },
      ),
      bottomNavigationBar: const BottomNav(current: 'market'),
    );
  }
}

// ── Shop Tab (billets des autres utilisateurs) ─────────────────────────────────

class _ShopTab extends StatelessWidget {
  const _ShopTab({
    required this.auctions,
    required this.myId,
    required this.onBid,
  });
  final List<AuctionEntry> auctions;
  final String myId;
  final void Function(AuctionEntry) onBid;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    if (auctions.isEmpty) {
      return _EmptyShop(
        icon: Icons.storefront_outlined,
        message: 'Aucun billet en vente pour le moment',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.local_offer_outlined, size: 15, color: bleuCyan),
              const SizedBox(width: 6),
              Text(
                '${auctions.length} billet${auctions.length > 1 ? 's' : ''} disponible${auctions.length > 1 ? 's' : ''}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: bleuProfond.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            itemCount: auctions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (ctx, i) => _AuctionCard(
              auction: auctions[i],
              isOwner: false,
              onBid: () => onBid(auctions[i]),
              onCancel: null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── My Listings Tab (with Actives / Passées filter) ───────────────────────────

class _MyListingsTab extends StatefulWidget {
  const _MyListingsTab({required this.auctions, required this.onCancel});
  final List<AuctionEntry> auctions;
  final void Function(AuctionEntry) onCancel;

  @override
  State<_MyListingsTab> createState() => _MyListingsTabState();
}

class _MyListingsTabState extends State<_MyListingsTab> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final active = widget.auctions.where((a) => !a.sold).toList();
    final past   = widget.auctions.where((a) =>  a.sold).toList();
    final shown  = _showActive ? active : past;

    return Column(
      children: [
        // ── Filtre Actives / Passées ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: [
              Expanded(child: _FilterChip(
                label: 'Actives',
                count: active.length,
                selected: _showActive,
                onTap: () => setState(() => _showActive = true),
              )),
              const SizedBox(width: 10),
              Expanded(child: _FilterChip(
                label: 'Passées',
                count: past.length,
                selected: !_showActive,
                onTap: () => setState(() => _showActive = false),
              )),
            ],
          ),
        ),
        // ── Liste ────────────────────────────────────────────────────────
        Expanded(
          child: shown.isEmpty
              ? _EmptyShop(
                  icon: _showActive ? Icons.sell_outlined : Icons.history,
                  message: _showActive
                      ? 'Aucune vente active'
                      : 'Aucune vente passée',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (ctx, i) => _AuctionCard(
                    auction: shown[i],
                    isOwner: true,
                    onBid: null,
                    onCancel: (!shown[i].sold)
                        ? () => widget.onCancel(shown[i])
                        : null,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Filter Chip ────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? bleuCyan : bleuProfond.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? bleuCyan : bleuProfond.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : bleuProfond.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : bleuProfond.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : bleuProfond.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Auction Card ───────────────────────────────────────────────────────────────

class _AuctionCard extends StatelessWidget {
  const _AuctionCard({
    required this.auction,
    required this.isOwner,
    required this.onBid,
    this.onCancel,
  });
  final AuctionEntry auction;
  final bool isOwner;
  final VoidCallback? onBid;
  final VoidCallback? onCancel;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    final shortId =
        auction.ticketId.substring(0, min(8, auction.ticketId.length)).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180B1C3E),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Top gradient band ─────────────────────────────────────
            Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: auction.sold
                      ? [const Color(0xFFB0BEC5), const Color(0xFFCFD8DC)]
                      : [bleuProfond, bleuCyan],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top row: category chip + status badge ─────────────
                  Row(
                    children: [
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
                            const Icon(Icons.confirmation_num,
                                size: 10, color: bleuCyan),
                            const SizedBox(width: 4),
                            Text(
                              'ENCHÈRE',
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
                      const Spacer(),
                      if (auction.sold)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VENDU',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF43A047),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: bleuCyan.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront,
                                  size: 10, color: bleuCyan),
                              const SizedBox(width: 4),
                              Text(
                                'EN VENTE',
                                style: GoogleFonts.montserrat(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: bleuCyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // ── Concert title + Ticket ref ────────────────────────
                  if (auction.concertTitle.isNotEmpty) ...[                    Text(
                      auction.concertTitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: bleuProfond,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    'Billet N° $shortId',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: bleuProfond,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auction.sellerEmail,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: bleuProfond.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // ── Bid row + action button ───────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.shopCurrentBid,
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              color: bleuProfond.withValues(alpha: 0.45),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${auction.currentBid} DZD',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: bleuProfond,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (!isOwner && !auction.sold && onBid != null)
                        ElevatedButton.icon(
                          onPressed: onBid,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bleuCyan,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.gavel, size: 16),
                          label: Text(
                            context.l10n.shopPlaceBid,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (isOwner && !auction.sold && onCancel != null)
                        OutlinedButton.icon(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF5350),
                            side: const BorderSide(
                                color: Color(0xFFEF5350), width: 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 14),
                          label: Text(
                            'Retirer',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (isOwner && auction.sold)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 13, color: Color(0xFF43A047)),
                              const SizedBox(width: 4),
                              Text(
                                'Vendu !',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF43A047),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    auction.bidCount == 0
                        ? context.l10n.shopNoBids
                        : '${auction.bidCount} offre${auction.bidCount > 1 ? 's' : ''}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: bleuProfond.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            // ── Footer: starting price ────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: bleuProfond.withValues(alpha: 0.03),
                border: Border(
                  top: BorderSide(
                      color: bleuProfond.withValues(alpha: 0.07), width: 1),
                ),
              ),
              child: Text(
                '${context.l10n.shopStartingPrice.split(' ').first} initial : ${auction.startingPrice} DZD',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: bleuProfond.withValues(alpha: 0.35),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sell Bottom Sheet ──────────────────────────────────────────────────────────

class _SellSheet extends StatefulWidget {
  const _SellSheet({
    required this.tickets,
    required this.onList,
    required this.eventsMap,
    this.preselectId,
  });
  final List<TicketModel> tickets;
  final void Function(TicketModel ticket, int price, String concertTitle) onList;
  final Map<String, EventModel> eventsMap;
  final String? preselectId;

  @override
  State<_SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<_SellSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  TicketModel? _selected;
  final _priceCtrl = TextEditingController();
  String? _priceError;

  @override
  void initState() {
    super.initState();
    if (widget.preselectId != null) {
      _selected = widget.tickets.cast<TicketModel?>().firstWhere(
            (t) => t?.id == widget.preselectId,
            orElse: () => null,
          );
    }
    _selected ??= widget.tickets.isNotEmpty ? widget.tickets.first : null;
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
    if (price < 1) {
      setState(() => _priceError = context.l10n.shopMinPriceError);
      return;
    }
    if (_selected == null) return;
    Navigator.pop(context);
    final concertTitle = widget.eventsMap[_selected!.eventId]?.title ?? '';
    widget.onList(_selected!, price, concertTitle);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD8DC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.sell_outlined, color: bleuCyan, size: 22),
                const SizedBox(width: 8),
                Text(
                  context.l10n.shopSellFab,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: bleuProfond,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ── Ticket picker ────────────────────────────────────────────
            Text(
              context.l10n.shopChooseTicket,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: bleuProfond.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.tickets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Aucun billet payé disponible.',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    color: const Color(0xFF607D8B),
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0xFFCFD8DC), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TicketModel>(
                    value: _selected,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more, color: bleuCyan),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: bleuProfond,
                    ),
                    items: widget.tickets.map((t) {
                      final eventTitle = widget.eventsMap[t.eventId]?.title;
                      final label = eventTitle != null
                          ? '$eventTitle — N° ${t.id.substring(0, min(8, t.id.length)).toUpperCase()}'
                          : 'N° ${t.id.substring(0, min(8, t.id.length)).toUpperCase()} — ${t.amount} DZD';
                      return DropdownMenuItem(value: t, child: Text(label));
                    }).toList(),
                    onChanged: (t) => setState(() => _selected = t),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // ── Starting price ───────────────────────────────────────────
            Text(
              context.l10n.shopStartingPrice,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: bleuProfond.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: bleuProfond,
              ),
              decoration: InputDecoration(
                errorText: _priceError,
                hintText: '0',
                hintStyle: GoogleFonts.montserrat(
                  color: bleuProfond.withValues(alpha: 0.3),
                ),
                suffixText: 'DZD',
                suffixStyle: GoogleFonts.montserrat(
                  color: bleuCyan,
                  fontWeight: FontWeight.w700,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFCFD8DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFCFD8DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: bleuCyan, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() => _priceError = null),
            ),
            const SizedBox(height: 24),
            // ── Submit ───────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.tickets.isEmpty ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: bleuProfond,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      bleuProfond.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.gavel),
                label: Text(
                  context.l10n.shopListTicket,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bid Dialog ─────────────────────────────────────────────────────────────────

class _BidDialog extends StatefulWidget {
  const _BidDialog({required this.auction, required this.onBid});
  final AuctionEntry auction;
  final void Function(int amount) onBid;

  @override
  State<_BidDialog> createState() => _BidDialogState();
}

class _BidDialogState extends State<_BidDialog> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final amount = int.tryParse(_ctrl.text.trim()) ?? 0;
    if (amount <= widget.auction.currentBid) {
      setState(() => _error = context.l10n.shopMinBidError);
      return;
    }
    Navigator.pop(context);
    widget.onBid(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 80),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x280B1C3E),
              blurRadius: 40,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dialog header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [bleuProfond, Color(0xFF1A3A70)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.gavel, color: bleuCyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.shopPlaceBid,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close,
                        color: Colors.white54, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Current bid
            Row(
              children: [
                Text(
                  '${context.l10n.shopCurrentBid} :',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: bleuProfond.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.auction.currentBid} DZD',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: bleuProfond,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bid input
            Text(
              context.l10n.shopYourBid,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: bleuProfond.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: bleuProfond,
              ),
              decoration: InputDecoration(
                errorText: _error,
                hintText: '${widget.auction.currentBid + 100}',
                hintStyle: GoogleFonts.montserrat(
                  color: bleuProfond.withValues(alpha: 0.3),
                ),
                suffixText: 'DZD',
                suffixStyle: GoogleFonts.montserrat(
                  color: bleuCyan,
                  fontWeight: FontWeight.w700,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFCFD8DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFCFD8DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: bleuCyan, width: 1.5),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: bleuProfond,
                      side: BorderSide(
                          color: bleuProfond.withValues(alpha: 0.2)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.cancel,
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bleuCyan,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: Text(
                      context.l10n.confirm,
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state helper ─────────────────────────────────────────────────────────

class _EmptyShop extends StatelessWidget {
  const _EmptyShop({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1C3E).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, size: 40, color: const Color(0xFF00ACC1)),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B1C3E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
