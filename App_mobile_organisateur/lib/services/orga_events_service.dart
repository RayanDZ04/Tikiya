import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/orga_event.dart';
import 'session_store.dart';

class OrgaEventsService {
  OrgaEventsService({String? baseUrl}) : _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'http://10.0.2.2:8080';
  final String _baseUrl;

  Map<String, String> _headers() {
    final token = SessionStore.I.session.value?.accessToken;
    if (token == null || token.isEmpty) {
      throw HttpException('Not authenticated');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  Future<List<OrgaEvent>> listEvents() async {
    final uri = Uri.parse('$_baseUrl/orga/events');
    final res = await http.get(uri, headers: _headers());
    _ensureOk(res);
    final data = jsonDecode(res.body);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => OrgaEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<OrgaEvent> getEvent(String id) async {
    final uri = Uri.parse('$_baseUrl/orga/events/$id');
    final res = await http.get(uri, headers: _headers());
    _ensureOk(res);
    return OrgaEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<OrgaEvent> createEvent(OrgaEventDraft draft) async {
    final uri = Uri.parse('$_baseUrl/orga/events');
    final res = await http.post(uri, headers: _headers(), body: jsonEncode(draft.toJson()));
    _ensureOk(res);
    return OrgaEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<OrgaEvent> updateEvent(String id, OrgaEventDraft draft) async {
    final uri = Uri.parse('$_baseUrl/orga/events/$id');
    final res = await http.put(uri, headers: _headers(), body: jsonEncode(draft.toJson()));
    _ensureOk(res);
    return OrgaEvent.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteEvent(String id) async {
    final uri = Uri.parse('$_baseUrl/orga/events/$id');
    final res = await http.delete(uri, headers: _headers());
    _ensureOk(res);
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
