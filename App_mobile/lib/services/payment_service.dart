import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'session_store.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class CheckoutResult {
  final String ticketId;
  final String checkoutUrl;

  const CheckoutResult({required this.ticketId, required this.checkoutUrl});

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
        ticketId: j['ticket_id'] as String,
        checkoutUrl: j['checkout_url'] as String,
      );
}

class TicketModel {
  final String id;
  final String eventId;
  final String checkoutId;
  final String status; // pending | paid | failed | canceled
  final int amount;
  final String currency;
  final String? paymentMethod;
  final DateTime createdAt;

  const TicketModel({
    required this.id,
    required this.eventId,
    required this.checkoutId,
    required this.status,
    required this.amount,
    required this.currency,
    this.paymentMethod,
    required this.createdAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> j) => TicketModel(
        id: j['id'] as String,
        eventId: j['event_id'] as String,
        checkoutId: j['checkout_id'] as String,
        status: j['status'] as String,
        amount: j['amount'] as int,
        currency: (j['currency'] as String?) ?? 'dzd',
        paymentMethod: j['payment_method'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  bool get isPaid => status == 'paid';
}

class EventTicketStats {
  final String eventId;
  final int sold;
  final int revenue;

  const EventTicketStats({
    required this.eventId,
    required this.sold,
    required this.revenue,
  });

  factory EventTicketStats.fromJson(Map<String, dynamic> j) => EventTicketStats(
        eventId: j['event_id'] as String,
        sold: (j['sold'] as int?) ?? 0,
        revenue: (j['revenue'] as int?) ?? 0,
      );
}

/// Aggregated live stats over all of an organizer's events.
class OrganizerSummary {
  final int events;
  final int totalSold;
  final int totalRevenue;
  final int totalCapacity;
  final int estimatedRevenue;

  const OrganizerSummary({
    required this.events,
    required this.totalSold,
    required this.totalRevenue,
    required this.totalCapacity,
    required this.estimatedRevenue,
  });

  /// Share of seats actually sold, 0..1.
  double get fillRate => totalCapacity > 0 ? totalSold / totalCapacity : 0.0;

  factory OrganizerSummary.fromJson(Map<String, dynamic> j) => OrganizerSummary(
        events: (j['events'] as int?) ?? 0,
        totalSold: (j['total_sold'] as int?) ?? 0,
        totalRevenue: (j['total_revenue'] as int?) ?? 0,
        totalCapacity: (j['total_capacity'] as int?) ?? 0,
        estimatedRevenue: (j['estimated_revenue'] as int?) ?? 0,
      );
}

// ─── Service ──────────────────────────────────────────────────────────────────

class PaymentService {
  PaymentService({String? baseUrl}) : _baseUrl = baseUrl ?? _default;
  static final String _default = apiBaseUrl;
  final String _baseUrl;

  Map<String, String> get _authHeaders {
    final token = SessionStore.I.session.value?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('PaymentService error ${res.statusCode}: ${res.body}');
    }
  }

  /// POST /payments/checkout
  /// Creates a Chargily checkout and returns the checkout URL.
  Future<CheckoutResult> createCheckout({
    required String eventId,
    String paymentMethod = 'edahabia',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/payments/checkout'),
      headers: _authHeaders,
      body: jsonEncode({
        'event_id': eventId,
        'payment_method': paymentMethod,
      }),
    );
    _check(res);
    return CheckoutResult.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// GET /payments/my — list current user's tickets
  Future<List<TicketModel>> myTickets() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/payments/my'),
      headers: _authHeaders,
    );
    _check(res);
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => TicketModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /payments/event/:eventId — sold tickets count for an event
  Future<EventTicketStats> eventStats(String eventId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/payments/event/$eventId'),
      headers: _authHeaders,
    );
    _check(res);
    return EventTicketStats.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// GET /payments/mine/summary — live aggregated stats for the organizer.
  Future<OrganizerSummary> organizerSummary() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/payments/mine/summary'),
      headers: _authHeaders,
    );
    _check(res);
    return OrganizerSummary.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
}
