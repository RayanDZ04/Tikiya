import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Production API URL, injected at build time via
/// `--dart-define=API_BASE_URL=https://api.tikiya.net`.
/// Empty in dev builds → falls back to the local per-platform defaults below.
const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

/// Returns the correct API base URL depending on the current platform.
///
/// - Release builds  → the value passed via --dart-define=API_BASE_URL=...
/// - Android emulator (dev) → 10.0.2.2  (routes to host machine)
/// - Linux / macOS / Windows / Web (dev) → localhost
String get apiBaseUrl {
  if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
  if (kIsWeb) return 'http://localhost:8080';
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

/// Fixes any URL returned by the API so it works on the current platform.
///
/// On Android emulator, the API may return localhost URLs which need
/// to be rewritten to 10.0.2.2. On other platforms, 10.0.2.2 must be
/// rewritten to localhost.
String fixApiUrl(String url) {
  // In release builds pointing at a real host, the localhost/10.0.2.2 rewriting
  // is irrelevant and would corrupt production URLs — leave them untouched.
  if (_apiBaseUrlOverride.isNotEmpty) return url;
  final isAndroid = !kIsWeb && Platform.isAndroid;
  if (isAndroid) {
    return url.replaceFirst('http://localhost', 'http://10.0.2.2');
  }
  return url.replaceFirst('http://10.0.2.2', 'http://localhost');
}
