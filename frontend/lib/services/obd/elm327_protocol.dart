import 'dart:async';

import '../../models/obd_scan_result.dart';
import 'obd_transport.dart';

class Elm327ReadResult {
  const Elm327ReadResult({
    required this.codes,
    this.dtcs = const <ObdDtc>[],
    required this.reachable,
    required this.ambiguous,
  });

  final List<String> codes;
  final List<ObdDtc> dtcs;
  final bool reachable;
  final bool ambiguous;
}

class Elm327Protocol {
  Elm327Protocol(
    this.transport, {
    this.resetDelay = const Duration(milliseconds: 800),
    this.commandDelay = const Duration(milliseconds: 400),
    this.responseDelay = const Duration(milliseconds: 3000),
  });

  final ObdTransport transport;
  final Duration resetDelay;
  final Duration commandDelay;
  final Duration responseDelay;
  StreamSubscription<List<int>>? _subscription;
  String _buffer = '';
  final List<Map<String, dynamic>> transcript = <Map<String, dynamic>>[];

  Future<void> initialize() async {
    _subscription ??= transport.input.listen(
      (data) => _buffer += String.fromCharCodes(data),
    );
    await transport.write('ATZ\r');
    await Future<void>.delayed(resetDelay);
    await transport.write('ATE0\r');
    await Future<void>.delayed(commandDelay);
  }

  Future<List<String>> discoverResponderHeaders() async {
    _buffer = '';
    await transport.write('ATSH7DF\r');
    await Future<void>.delayed(commandDelay);
    await transport.write('0100\r');
    await Future<void>.delayed(responseDelay);
    final headers = RegExp(r'(?:^|\s)(7E[8-9A-F])(?:\s|$)', caseSensitive: false, multiLine: true).allMatches(_buffer)
        .map((m) => m.group(1)!.toUpperCase()).toSet().toList();
    transcript.add({'timestamp': DateTime.now().toIso8601String(), 'command': '0100', 'responders': headers});
    return headers;
  }

  List<String> parseDtcResponse(String raw) {
    final normalized = raw.replaceAll(RegExp(r'SEARCHING\.\.\.|BUS INIT[^\r\n]*|STOPPED|NO DATA|OK|>', caseSensitive: false, multiLine: true), ' ');
    const letters = <String>['P', 'C', 'B', 'U'];
    final codes = <String>{};
    final isoPayloads = <String, List<int>>{};
    final isoExpected = <String, int>{};
    final isoNext = <String, int>{};
    final isoBroken = <String>{};
    final markers = RegExp(r'(?<![0-9A-Fa-f])(43|47|4A)(?![0-9A-Fa-f])', caseSensitive: false).allMatches(normalized).toList();
    for (var markerIndex = 0; markerIndex < markers.length; markerIndex++) {
      final marker = markers[markerIndex];
      final end = markerIndex + 1 < markers.length ? markers[markerIndex + 1].start : normalized.length;
      final tail = normalized.substring(marker.end, end);
      final tokens = tail.split(RegExp(r'\s+')).where((v) => RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(v));
      final dataBytes = tokens.map((v) => int.parse(v, radix: 16)).toList();
      for (var index = 0; index + 1 < dataBytes.length; index += 2) {
      final first = dataBytes[index];
      final second = dataBytes[index + 1];
      if (first == 0 && second == 0) continue;
      final letter = letters[(first >> 6) & 0x03];
      final digit2 = (first >> 4) & 0x03;
      final digit3 = (first & 0x0F).toRadixString(16).toUpperCase();
      final digit4 = ((second >> 4) & 0x0F).toRadixString(16).toUpperCase();
      final digit5 = (second & 0x0F).toRadixString(16).toUpperCase();
      codes.add('$letter$digit2$digit3$digit4$digit5');
      }
    }
    // Reassemble common ISO-TP frames independently by responder/header.
    for (final line in normalized.split(RegExp(r'[\r\n]+'))) {
      final headerMatch = RegExp(r'(7E[89A-F])', caseSensitive: false).firstMatch(line);
      final header = headerMatch?.group(1)?.toUpperCase() ?? 'legacy';
      final bytes = RegExp(r'(?<![0-9A-Fa-f])(?:[0-9A-Fa-f]{2})(?![0-9A-Fa-f])').allMatches(line)
          .map((m) => int.parse(m.group(0)!, radix: 16)).toList();
      if (bytes.isEmpty) continue;
      final pci = bytes[0];
      final type = pci >> 4;
      if (type == 0) {
        final length = pci & 0x0F;
        if (bytes.length > 1) isoPayloads[header] = bytes.sublist(1, 1 + length.clamp(0, bytes.length - 1));
      } else if (type == 1 && bytes.length >= 2) {
        isoExpected[header] = ((pci & 0x0F) << 8) | bytes[1];
        isoPayloads[header] = bytes.sublist(2);
        isoNext[header] = 0;
      } else if (type == 2 && bytes.length >= 2 && !isoBroken.contains(header)) {
        final sequence = pci & 0x0F;
        if (isoNext[header] != sequence || !isoPayloads.containsKey(header)) {
          isoBroken.add(header);
        } else {
          isoPayloads[header]!.addAll(bytes.sublist(1));
          isoNext[header] = (sequence + 1) & 0x0F;
        }
      }
    }
    for (final entry in isoPayloads.entries) {
      final expected = isoExpected[entry.key];
      if (isoBroken.contains(entry.key) || (expected != null && entry.value.length < expected)) continue;
      final payload = expected == null ? entry.value : entry.value.take(expected).toList();
      for (var i = 0; i + 1 < payload.length; i += 2) {
        final first = payload[i], second = payload[i + 1];
        if (first == 0 && second == 0) continue;
        codes.add('${letters[(first >> 6) & 3]}${(first >> 4) & 3}${(first & 15).toRadixString(16).toUpperCase()}${(second >> 4).toRadixString(16).toUpperCase()}${(second & 15).toRadixString(16).toUpperCase()}');
      }
    }
    return codes.toList();
  }

  Future<Elm327ReadResult> readDtcForHeader(String header, {String mode = '03'}) async {
    var result = const Elm327ReadResult(
      codes: <String>[],
      reachable: true,
      ambiguous: true,
    );
    for (var attempt = 0; attempt < 2; attempt++) {
      _buffer = '';
      await transport.write('ATSH$header\r');
      await Future<void>.delayed(commandDelay);
      _buffer = '';
      await transport.write('$mode\r');
      await Future<void>.delayed(responseDelay);
      final raw = _buffer;
      transcript.add({'timestamp': DateTime.now().toIso8601String(), 'command': mode, 'requestHeader': header, 'raw': raw, 'codes': parseDtcResponse(raw)});
      final upper = raw.toUpperCase();
      final codes = parseDtcResponse(raw);
      final unreachable = upper.contains('UNABLE TO CONNECT');
      final confirmedEmpty = upper.contains('NO DATA');
      final ambiguous = codes.isEmpty &&
          !unreachable &&
          !confirmedEmpty &&
          raw.trim().length < 6;
      result = Elm327ReadResult(
        codes: codes,
        dtcs: codes.map((code) => ObdDtc(code: code, status: _statusForMode(mode), source: 'generic')).toList(),
        reachable: !unreachable,
        ambiguous: ambiguous,
      );
      if (!ambiguous) break;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return result;
  }

  String _statusForMode(String mode) => switch (mode) {
        '07' => 'pending',
        '0A' => 'permanent',
        _ => 'stored',
      };

  Future<void> restoreFunctionalHeader() async {
    await transport.write('ATSH7DF\r');
    await Future<void>.delayed(commandDelay);
  }

  Future<void> clearDtcCodes() async {
    await restoreFunctionalHeader();
    await transport.write('04\r');
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
