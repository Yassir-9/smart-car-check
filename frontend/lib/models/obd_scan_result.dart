enum ObdTransportType { androidClassic, ble, wifi, unsupported }

class ObdDtc {
  const ObdDtc({required this.code, required this.status, this.responderHeader, this.module, this.source = 'generic', this.statuses = const <String>{}});
  final String code;
  final String status;
  final String? responderHeader;
  final String? module;
  final String source;
  final Set<String> statuses;
  Map<String, dynamic> toJson() => {'code': code, 'status': status, 'statuses': statuses.isEmpty ? [status] : statuses.toList(), 'responderHeader': responderHeader, 'module': module, 'source': source};
}

List<ObdDtc> mergeObdDtcs(Iterable<ObdDtc> input) {
  final merged = <String, ObdDtc>{};
  for (final dtc in input) {
    final key = dtc.code;
    final prior = merged[key];
    if (prior == null) {
      merged[key] = dtc;
    } else {
      merged[key] = ObdDtc(
        code: dtc.code,
        status: prior.status,
        statuses: {...prior.statuses, prior.status, dtc.status, ...dtc.statuses},
        responderHeader: prior.responderHeader,
        module: prior.module,
        source: prior.source,
      );
    }
  }
  return merged.values.toList();
}

class ObdScanResult {
  const ObdScanResult({
    required this.codes,
    required this.transportType,
    required this.timestamp,
    this.deviceName,
    this.vehicleId,
    this.connectionMetadata = const <String, String>{},
    this.dtcs = const <ObdDtc>[],
  });

  final List<String> codes;
  final String? deviceName;
  final ObdTransportType transportType;
  final String? vehicleId;
  final DateTime timestamp;
  final Map<String, String> connectionMetadata;
  final List<ObdDtc> dtcs;

  ObdScanResult copyWith({String? vehicleId}) => ObdScanResult(
        codes: List<String>.unmodifiable(codes),
        deviceName: deviceName,
        transportType: transportType,
        vehicleId: vehicleId ?? this.vehicleId,
        timestamp: timestamp,
        connectionMetadata:
            Map<String, String>.unmodifiable(connectionMetadata),
        dtcs: List<ObdDtc>.unmodifiable(dtcs),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'codes': codes,
        'deviceName': deviceName,
        'transportType': transportType.name,
        'vehicleId': vehicleId,
        'timestamp': timestamp.toIso8601String(),
        'connectionMetadata': connectionMetadata,
        'dtcs': dtcs.map((d) => d.toJson()).toList(),
      };

  factory ObdScanResult.fromJson(Map<String, dynamic> json) => ObdScanResult(
        codes: List<String>.from(json['codes'] as List? ?? const []),
        deviceName: json['deviceName'] as String?,
        transportType: ObdTransportType.values.firstWhere(
          (value) => value.name == json['transportType'],
          orElse: () => ObdTransportType.unsupported,
        ),
        vehicleId: json['vehicleId'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        connectionMetadata: Map<String, String>.from(
          json['connectionMetadata'] as Map? ?? const {},
        ),
      );
}
