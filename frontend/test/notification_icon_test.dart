import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final drawable = File('android/app/src/main/res/drawable/ic_stat_notification.xml');

  test('the notification small icon is a white-on-transparent vector', () {
    final xml = drawable.readAsStringSync();
    expect(xml, contains('<vector'));
    // every colour is white or fully transparent (Android tints the icon)
    final colours = RegExp(r'#[0-9A-Fa-f]{6,8}').allMatches(xml).map((m) => m.group(0)!.toUpperCase()).toSet();
    expect(colours.difference({'#FFFFFF', '#00000000'}), isEmpty);
    expect(colours, contains('#FFFFFF'));
  });

  test('the service uses that drawable and it survives resource shrinking', () {
    final dart = File('lib/services/notification_service.dart').readAsStringSync();
    expect(dart, contains("'ic_stat_notification'"));
    expect(dart, isNot(contains('@mipmap/ic_launcher')));
    expect(dart, contains('icon: _smallIcon'));
    final keep = File('android/app/src/main/res/raw/keep.xml').readAsStringSync();
    expect(keep, contains('@drawable/ic_stat_notification'));
  });
}
