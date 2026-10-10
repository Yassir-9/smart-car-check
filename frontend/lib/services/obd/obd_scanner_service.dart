import '../../models/obd_scan_result.dart';
import 'elm327_protocol.dart';
import 'obd_transport.dart';

class ObdScanSummary {
  const ObdScanSummary({
    required this.result,
    required this.engineCodeCount,
    required this.transmissionCodeCount,
    required this.transmissionReachable,
  });

  final ObdScanResult result;
  final int engineCodeCount;
  final int transmissionCodeCount;
  final bool transmissionReachable;
}

class ObdScannerService {
  ObdScannerService({required this.transport, Elm327Protocol? protocol})
      : protocol = protocol ?? Elm327Protocol(transport);

  final ObdTransport transport;
  final Elm327Protocol protocol;

  bool get isConnected => transport.isConnected;
  ObdDevice? get connectedDevice => transport.connectedDevice;

  Future<bool> isAvailable() => transport.isAvailable();
  Future<List<ObdDevice>> discoverDevices() => transport.discoverDevices();

  Future<void> connect(ObdDevice device) async {
    await transport.connect(device);
    try {
      await protocol.initialize();
    } catch (_) {
      await transport.disconnect();
      rethrow;
    }
  }

  Future<ObdScanSummary> scan({String? vehicleId}) async {
    final discovered = await protocol.discoverResponderHeaders();
    final requestHeaders = discovered
        .map((h) => int.tryParse(h.substring(2), radix: 16))
        .whereType<int>()
        .where((id) => id >= 0xE8)
        .map((id) => '7E${((id - 8) & 0x0F).toRadixString(16).toUpperCase()}')
        .toSet();
    requestHeaders.addAll(const {'7E0', '7E1'});
    final engine = await _readHeaders(requestHeaders);
    if (engine.ambiguous) {
      throw const ObdScanException(
        'تعذر إتمام الفحص بسبب اتصال غير مستقر. أعد المحاولة.',
      );
    }

    var transmission = const Elm327ReadResult(
      codes: <String>[],
      reachable: false,
      ambiguous: false,
    );
    if (!requestHeaders.contains('7E1')) {
      try {
        transmission = await _readAllModes('7E1');
      } catch (_) {
        // Some vehicles/adapters do not expose a transmission ECU.
      }
    }
    await protocol.restoreFunctionalHeader();
    final codes = <String>{...engine.codes, ...transmission.codes}.toList();
    final mergedDtcs = mergeObdDtcs(<ObdDtc>[...engine.dtcs, ...transmission.dtcs]);
    final result = ObdScanResult(
      codes: List<String>.unmodifiable(codes),
      deviceName: transport.connectedDevice?.name,
      transportType: transport.type,
      vehicleId: vehicleId,
      timestamp: DateTime.now(),
      connectionMetadata: <String, String>{
        'transmissionEcu': transmission.reachable ? 'available' : 'unavailable',
        'scanCoverage': 'generic_obd_accessible',
      },
      dtcs: mergedDtcs,
    );
    return ObdScanSummary(
      result: result,
      engineCodeCount: engine.codes.length,
      transmissionCodeCount: transmission.codes.length,
      transmissionReachable: transmission.reachable,
    );
  }

  Future<Elm327ReadResult> _readAllModes(String header) async {
    final codes = <String>[];
    final dtcs = <ObdDtc>[];
    var reachable = false;
    var ambiguous = false;
    for (final mode in const ['03', '07', '0A']) {
      final result = await protocol.readDtcForHeader(header, mode: mode);
      codes.addAll(result.codes);
      dtcs.addAll(result.codes.map((code) => ObdDtc(code: code, status: _statusForMode(mode), responderHeader: header)));
      reachable = reachable || result.reachable;
      ambiguous = ambiguous || result.ambiguous;
    }
    return Elm327ReadResult(
      codes: codes.toSet().toList(),
      dtcs: dtcs,
      reachable: reachable,
      ambiguous: ambiguous && codes.isEmpty,
    );
  }

  Future<Elm327ReadResult> _readHeaders(Iterable<String> headers) async {
    // ELM327 has one shared command/response buffer; scan headers serially.
    final results = <Elm327ReadResult>[];
    for (final header in headers) {
      results.add(await _readAllModes(header));
    }
    return Elm327ReadResult(
      codes: results.expand((r) => r.codes).toSet().toList(),
      dtcs: results.expand((r) => r.dtcs).toList(),
      reachable: results.any((r) => r.reachable),
      ambiguous: results.every((r) => r.ambiguous),
    );
  }

  String _statusForMode(String mode) => switch (mode) {
        '07' => 'pending',
        '0A' => 'permanent',
        _ => 'stored',
      };

  Future<void> clearCodes() => protocol.clearDtcCodes();
  Future<void> disconnect() => transport.disconnect();

  Future<void> dispose() async {
    await protocol.dispose();
    await transport.dispose();
  }
}

class ObdScanException implements Exception {
  const ObdScanException(this.message);
  final String message;
  @override
  String toString() => message;
}
