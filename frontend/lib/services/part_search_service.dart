import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustedPartSupplier {
  final String name;
  final Uri Function(String query) buildUrl;
  const TrustedPartSupplier(this.name, this.buildUrl);
}

String buildPartSearchQuery({required String part, required String make, required String model, required int year, String? trim, String? obdCode}) {
  return [make, model, year.toString(), if (trim != null && trim.trim().isNotEmpty) trim.trim(), part, if (obdCode != null && obdCode.trim().isNotEmpty) obdCode.trim()].join(' ');
}

class PartSearchService {
  static final suppliers = <TrustedPartSupplier>[
    TrustedPartSupplier('SPEERO / سبيرو', (_) => Uri.parse('https://speero.net/')),
  ];

  static Future<void> openSupplier(TrustedPartSupplier supplier, String query) async {
    final uri = supplier.buildUrl(query);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Unable to open trusted supplier');
    }
  }
}
