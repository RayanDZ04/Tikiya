import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(statusCode=$statusCode, message=$message)';
}

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl;
    final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final resp = await _client.post(
      _uri(path),
      headers: {
        'Content-Type': 'application/json',
        ...?headers,
      },
      body: jsonEncode(body),
    );

    final text = resp.body;
    Map<String, dynamic> json;
    try {
      json = (text.isEmpty ? <String, dynamic>{} : jsonDecode(text)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Réponse invalide du serveur', statusCode: resp.statusCode);
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = (json['message'] ?? json['error'] ?? 'Erreur serveur').toString();
      throw ApiException(msg, statusCode: resp.statusCode);
    }

    return json;
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final resp = await _client.get(
      _uri(path),
      headers: {
        'Accept': 'application/json',
        ...?headers,
      },
    );

    final text = resp.body;
    dynamic json;
    try {
      json = (text.isEmpty ? null : jsonDecode(text));
    } catch (_) {
      throw ApiException('Réponse invalide du serveur', statusCode: resp.statusCode);
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      final msg = (json is Map)
          ? (json['message'] ?? json['error'] ?? 'Erreur serveur').toString()
          : 'Erreur serveur';
      throw ApiException(msg, statusCode: resp.statusCode);
    }

    return json;
  }
}
