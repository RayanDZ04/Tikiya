import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Returns the correct API base URL depending on the current platform.
///
/// - Android emulator  → 10.0.2.2  (routes to host machine)
/// - Linux / macOS / Windows / Web → localhost
String get apiBaseUrl {
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
  final isAndroid = !kIsWeb && Platform.isAndroid;
  if (isAndroid) {
    return url.replaceFirst('http://localhost', 'http://10.0.2.2');
  }
  return url.replaceFirst('http://10.0.2.2', 'http://localhost');
}
