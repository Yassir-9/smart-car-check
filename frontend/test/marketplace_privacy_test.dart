import 'dart:io';

import 'package:car_ai_diagnosis/models/part_listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public part payload remains usable without sellerPhone', () {
    final part = PartListing.fromJson({
      'id': 'part-1',
      'partName': 'Brake pad',
      'carBrand': 'Nissan',
      'carModel': 'Maxima',
      'ownerId': 'seller-1',
    });

    expect(part.sellerPhone, isEmpty);
    expect(part.partName, 'Brake pad');
  });

  test(
      'marketplace retrieves contact explicitly and seller dashboard uses mine',
      () {
    final partsSource =
        File('lib/screens/parts_screen.dart').readAsStringSync();
    final sellerSource =
        File('lib/screens/seller_dashboard_screen.dart').readAsStringSync();
    final homeSource = File('lib/screens/home_screen.dart').readAsStringSync();
    final pdfSource = File('lib/services/pdf_service.dart').readAsStringSync();

    expect(partsSource, contains("Uri.parse('\$baseUrl/\${part.id}/contact')"));
    expect(partsSource, contains('l10n.contactSignInRequired'));
    expect(partsSource, isNot(contains('_callSeller(part.sellerPhone)')));
    expect(partsSource, isNot(contains('callSeller(part.sellerPhone)')));
    expect(sellerSource, contains("Uri.parse('\$baseUrl/parts/mine')"));
    expect(homeSource, contains("ApiConfig.apiUri('/parts/\$partId/contact')"));
    expect(homeSource, isNot(contains("tel:\${p['sellerPhone']}")));
    expect(pdfSource, isNot(contains("p['sellerPhone']")));
  });
}
