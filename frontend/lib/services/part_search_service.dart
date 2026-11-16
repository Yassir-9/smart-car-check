import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

/// A store the backend allows ("allow-list" in backend/config/partnerStores.js).
class PartStore {
  const PartStore(this.key, this.name);
  final String key;
  final String name;
}

final RegExp _latinLetter = RegExp(r'[A-Za-z]');

String _collapse(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// The text to search a store with, taken from the AI part name.
///
/// * If a Latin (English) term sits inside parentheses, only that term is used:
///   "شمعات احتراق (Spark Plugs)" -> "Spark Plugs". With several, the first wins;
///   with nested parentheses the outer one wins and the inner ones are dropped.
/// * Otherwise the name is used as is, minus the parentheses themselves.
/// * Empty or blank input gives an empty string.
String searchTermFromPartName(String name) {
  final groups = <String>[];
  final buffer = StringBuffer();
  var depth = 0;
  for (final unit in name.runes) {
    final ch = String.fromCharCode(unit);
    if (ch == '(') {
      if (depth == 0) buffer.clear();
      depth++;
      if (depth > 1) buffer.write(' ');
    } else if (ch == ')') {
      if (depth == 0) continue;
      depth--;
      if (depth == 0) {
        groups.add(buffer.toString());
      } else {
        buffer.write(' ');
      }
    } else if (depth > 0) {
      buffer.write(ch);
    }
  }
  for (final group in groups) {
    if (_latinLetter.hasMatch(group)) {
      // keep only the Latin text of the group (nested parentheses already flattened)
      return _collapse(group);
    }
  }
  return _collapse(name.replaceAll(RegExp(r'[()]'), ' '));
}

/// Text the user's search is built from: vehicle make/model/year and the part name.
/// Never a VIN, a user id or the engine type.
String buildPartSearchQuery({
  required String part,
  required String make,
  required String model,
  required int year,
}) =>
    [make, model, year.toString(), part]
        .where((s) => s.trim().isNotEmpty)
        .join(' ');

class PartSearchService {
  /// Asks the backend which stores are available. `null` means the feature is off
  /// (404) or the server could not be reached: the caller falls back to a general
  /// web search instead of failing.
  static Future<List<PartStore>?> Function() storesLoader = _loadStores;

  /// Opens a link outside the app. Replaceable in tests.
  static Future<bool> Function(Uri uri) launcher = _launch;

  static Future<List<PartStore>?> _loadStores() async {
    try {
      final response = await http
          .get(ApiConfig.rootUri('/go/stores'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final raw = decoded is Map ? decoded['stores'] : null;
      if (raw is! List) return null;
      return raw
          .whereType<Map>()
          .where((s) => s['key'] is String && s['name'] is String)
          .map((s) => PartStore(s['key'] as String, s['name'] as String))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Unable to open link');
      return false;
    }
  }

  /// The redirector URL: only the store key and four plain-text fields.
  static Uri storeUri(
    String storeKey, {
    required String part,
    required String make,
    required String model,
    required int year,
  }) =>
      ApiConfig.rootUri('/go/$storeKey').replace(queryParameters: {
        'part': part,
        'make': make,
        'model': model,
        'year': year.toString(),
      });

  static Uri generalSearchUri(String query) =>
      Uri.https('www.google.com', '/search', {'q': query});
}
