import 'package:flutter/foundation.dart';

import '../../models/obd_scan_result.dart';
import 'android_classic_obd_transport.dart';
import 'ble_obd_transport.dart';
import 'obd_transport.dart';
import 'unsupported_obd_transport.dart';

typedef ObdTransportBuilder = ObdTransport Function();

class ObdTransportFactory {
  ObdTransportFactory({
    ObdCapabilities? capabilities,
    ObdTransportBuilder? classicBuilder,
    ObdTransportBuilder? bleBuilder,
    ObdTransportBuilder? wifiBuilder,
  })  : capabilities = capabilities ?? platformCapabilities(),
        _classicBuilder = classicBuilder ?? AndroidClassicObdTransport.new,
        _bleBuilder = bleBuilder ?? BleObdTransport.new,
        _wifiBuilder = wifiBuilder ?? WifiObdTransport.new;

  final ObdCapabilities capabilities;
  final ObdTransportBuilder _classicBuilder;
  final ObdTransportBuilder _bleBuilder;
  final ObdTransportBuilder _wifiBuilder;

  static ObdCapabilities platformCapabilities() => ObdCapabilities(
        classicAvailable:
            !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
        bleAvailable: !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS),
      );

  List<ObdTransportType> availableTypes(ObdCapabilities detected) => [
        if (detected.classicAvailable) ObdTransportType.androidClassic,
        if (detected.bleAvailable) ObdTransportType.ble,
        if (detected.wifiAvailable) ObdTransportType.wifi,
      ];

  ObdTransport create([ObdTransportType? preferred]) {
    final selected = preferred ?? _bestAvailableType();
    if (!capabilities.supports(selected)) {
      return const UnsupportedObdTransport();
    }
    return switch (selected) {
      ObdTransportType.androidClassic => _classicBuilder(),
      ObdTransportType.ble => _bleBuilder(),
      ObdTransportType.wifi => _wifiBuilder(),
      ObdTransportType.unsupported => const UnsupportedObdTransport(),
    };
  }

  Future<ObdCapabilities> detectCapabilities() async {
    Future<bool> detect(
        bool declaredAvailable, ObdTransportBuilder builder) async {
      if (!declaredAvailable) return false;
      final transport = builder();
      try {
        return await transport.isAvailable();
      } catch (_) {
        return false;
      } finally {
        await transport.dispose();
      }
    }

    return ObdCapabilities(
      classicAvailable:
          await detect(capabilities.classicAvailable, _classicBuilder),
      bleAvailable: await detect(capabilities.bleAvailable, _bleBuilder),
      wifiAvailable: await detect(capabilities.wifiAvailable, _wifiBuilder),
    );
  }

  ObdTransportType _bestAvailableType() {
    if (capabilities.classicAvailable) {
      return ObdTransportType.androidClassic;
    }
    if (capabilities.bleAvailable) return ObdTransportType.ble;
    if (capabilities.wifiAvailable) return ObdTransportType.wifi;
    return ObdTransportType.unsupported;
  }
}
