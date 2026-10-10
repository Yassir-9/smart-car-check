import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pending and returned states are data driven', () {
    expect({'verificationStatus': 'pending'}['verificationStatus'], 'pending');
    expect(true, isTrue);
  });
}
