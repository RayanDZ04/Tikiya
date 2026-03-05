import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'session_store.dart';

class EventModel {
  final String id;
  final String organizerId;
  final String title;
  final String description;
  final String location;
  final DateTime eventDate;
  final double price;
  final int capacity;
  final String? coverUrl;
  final String category;
  final DateTime createdAt;

  EventModel({
    required this.id,
    required this.organizerId,
    required this.title,
    required this.description,
    required this.location,
    required this.eventDate,
    required this.price,
    required this.capacity,
    this.coverUrl,
    required this.category,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id: j['id'] as String,
        organizerId: j['organizer_id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        location: (j['location'] as String?) ?? '',
        eventDate: DateTime.parse(j['event_date'] as String),
        price: (j['price'] as num).toDouble(),
        capacity: (j['capacity'] as int?) ?? 0,
        coverUrl: j['cover_url'] as String?,
        category: (j['category'] as String?) ?? 'musique',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class EventService {
  EventService({String? baseUrl}) : _baseUrl = baseUrl ?? _default;
  static const String _default = 'http://10.0.2.2:8080';
  final String _baseUrl;

  Map<String, String> get _authHeaders {
    final token = SessionStore.I.session.value?.accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /events — all events (public)
  Future<List<EventModel>> fetchAll() async {
    final res = await http.get(Uri.parse('$_baseUrl/events'));
    _check(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /events/my — organizer's events (authenticated)
  Future<List<EventModel>> fetchMine() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/events/my'),
      headers: _authHeaders,
    );
    _check(res);
    final list = jsonDecode(res.body) as List;
    return list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// POST /events — create event (organizer)
  Future<EventModel> create({
    required String title,
    required String eventDate,
    String? description,
    String? location,
    double? price,
    int? capacity,
    String? coverUrl,
    String category = 'musique',
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'event_date': eventDate,
      'category': category,
      if (description != null && description.isNotEmpty) 'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      if (price != null) 'price': price,
      if (capacity != null) 'capacity': capacity,
      if (coverUrl != null) 'cover_url': coverUrl,
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/events'),
      headers: _authHeaders,
      body: jsonEncode(body),
    );
    _check(res);
    return EventModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// POST /upload — upload an image, returns its public URL
  Future<String> uploadImage(File file) async {
    final token = SessionStore.I.session.value?.accessToken ?? '';
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload'));
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _check(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  /// DELETE /events/:id
  Future<void> delete(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/events/$id'),
      headers: _authHeaders,
    );
    _check(res);
  }

  void _check(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}
