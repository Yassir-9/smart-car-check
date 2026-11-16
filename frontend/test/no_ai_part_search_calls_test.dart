import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// The AI part-search endpoints are switched off on the server. Guard that no screen or
// service the app can reach still calls them (the dead legacy screens are excluded).
void main() {
  test('only the unreachable legacy screens mention the AI part-search endpoints', () {
    const legacy = {'home_screen.dart', 'dashboard_screen.dart'};
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final name = entity.uri.pathSegments.last;
      if (legacy.contains(name)) continue;
      final text = entity.readAsStringSync();
      if (text.contains('external-search') || text.contains('/obd/part-search')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty);
  });
}
