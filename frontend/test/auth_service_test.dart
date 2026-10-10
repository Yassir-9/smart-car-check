import 'package:car_ai_diagnosis/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Saudi phone normalization', () {
    const normalized = '+966551234567';

    for (final input in const [
      '0551234567',
      '551234567',
      '966551234567',
      '+966551234567',
      '00966551234567',
    ]) {
      test('$input becomes E.164', () {
        expect(AuthService.normalizeSaudiPhone(input), normalized);
      });
    }

    test('rejects an invalid Saudi mobile number', () {
      expect(AuthService.normalizeSaudiPhone('12345'), isNull);
    });
  });
}
