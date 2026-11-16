import 'package:car_ai_diagnosis/config/feature_flags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unfinished features are hidden by default', () {
    expect(FeatureFlags.subscriptionEnabled, isFalse);
    expect(FeatureFlags.marketplaceEnabled, isFalse);
  });
}
