import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../models/obd_scan_result.dart';
import '../services/car_service.dart';
import '../services/obd/obd_scanner_service.dart';
import '../services/obd/ble_characteristic_selector.dart';
import '../services/obd/obd_transport.dart';
import '../services/obd/obd_transport_factory.dart';
import '../services/obd_session_service.dart';
import 'dtc_reference_screen.dart';

class ObdConnectScreen extends StatefulWidget {
  const ObdConnectScreen({super.key});
  @override
  State<ObdConnectScreen> createState() => _ObdConnectScreenState();
}

class _ObdConnectScreenState extends State<ObdConnectScreen> {
  final ObdTransportFactory _factory = ObdTransportFactory();
  ObdScannerService? _scanner;
  List<ObdTransportType> _transportTypes = const [];
  ObdTransportType? _selectedTransport;
  List<ObdDevice> _devices = const [];
  List<String> _codes = const [];
  CarModel? _activeCar;
  bool _available = false;
  bool _scanning = false;
  bool _connecting = false;
  bool _reading = false;
  bool _clearing = false;
  String _status = '';
  bool _initialStatusLocalized = false;

  @override
  void initState() {
    super.initState();
    final saved = ObdSessionService.lastResult;
    if (saved != null) {
      _codes = List<String>.from(saved.codes);
    }
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialStatusLocalized) return;
    final l10n = AppLocalizations.of(context);
    _status = ObdSessionService.lastResult == null
        ? l10n.checkingObdCapability
        : l10n.savedObdScan(_codes.length);
    _initialStatusLocalized = true;
  }

  Future<void> _initialize() async {
    await Future.wait<void>([_loadCar(), _loadCapability()]);
  }

  Future<void> _loadCar() async {
    try {
      final cars = await CarService.loadCars();
      final activeId = await CarService.getActiveCarId();
      if (cars.isNotEmpty) {
        _activeCar = cars.firstWhere(
          (car) => car.id == activeId,
          orElse: () => cars.first,
        );
      }
    } catch (_) {
      _activeCar = null;
    }
  }

  Future<void> _loadCapability() async {
    final l10n = AppLocalizations.of(context);
    final capabilities = await _factory.detectCapabilities();
    final types = _factory.availableTypes(capabilities);
    final preferred = types.contains(ObdTransportType.androidClassic)
        ? ObdTransportType.androidClassic
        : (types.isEmpty ? null : types.first);
    if (preferred != null) await _selectTransport(preferred, updateUi: false);
    if (!mounted) return;
    setState(() {
      _transportTypes = types;
      _available = types.isNotEmpty;
      if (types.isEmpty) {
        _status = l10n.obdDirectUnavailable;
      } else if (!ObdSessionService.hasSavedData) {
        _status = l10n.findPairedObd;
      }
    });
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  Future<void> _selectTransport(ObdTransportType type,
      {bool updateUi = true}) async {
    final l10n = AppLocalizations.of(context);
    await _scanner?.dispose();
    _scanner = ObdScannerService(transport: _factory.create(type));
    _selectedTransport = type;
    _devices = const [];
    if (updateUi && mounted) {
      setState(() {
        _status = type == ObdTransportType.ble
            ? l10n.findNearbyObd
            : l10n.findPairedObd;
      });
    }
  }

  Future<void> _discover() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _scanning = true;
      _status = l10n.searching;
    });
    try {
      final devices = await _scanner!.discoverDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _status = devices.isEmpty
            ? (_selectedTransport == ObdTransportType.ble
                ? l10n.noNearbyObd
                : l10n.noPairedObd)
            : l10n.chooseObdDevice;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status = l10n.obdSearchFailed);
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(ObdDevice device) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _connecting = true;
      _status = l10n.connectingToDevice(device.name);
    });
    try {
      await _scanner!.connect(device);
      if (mounted)
        setState(() => _status = l10n.connectedToDevice(device.name));
    } on BleCharacteristicSelectionException catch (error) {
      if (mounted) setState(() => _status = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _status = l10n.obdConnectionFailed);
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _scan() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _reading = true;
      _status = l10n.readingEngineTransmissionCodes;
    });
    try {
      final summary = await _scanner!.scan(vehicleId: _activeCar?.id);
      ObdSessionService.save(summary.result);
      final note = summary.transmissionReachable
          ? ''
          : ' (${l10n.transmissionModuleUnavailable})';
      if (!mounted) return;
      setState(() {
        _codes = summary.result.codes;
        _status = _codes.isEmpty
            ? '${l10n.noStoredFaultCodes}$note'
            : '${l10n.faultCodesFound(_codes.length, summary.engineCodeCount, summary.transmissionCodeCount)}$note';
      });
    } catch (error) {
      if (mounted) setState(() => _status = error.toString());
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCodesTitle),
        content: Text(l10n.clearCodesConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmClear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _clearing = true;
      _status = l10n.clearingCodes;
    });
    try {
      await _scanner!.clearCodes();
      ObdSessionService.clear();
      if (mounted) {
        setState(() {
          _codes = const [];
          _status = l10n.codesCleared;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _status = l10n.clearCodesFailed);
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _disconnect() async {
    final l10n = AppLocalizations.of(context);
    await _scanner!.disconnect();
    if (!mounted) return;
    setState(() =>
        _status = _codes.isEmpty ? l10n.disconnected : l10n.disconnectedSaved);
  }

  Future<void> _searchParts(String code) async {
    final l10n = AppLocalizations.of(context);
    final query = Uri.encodeComponent(
      '${_activeCar?.brand ?? ''} ${_activeCar?.model ?? ''} ${_activeCar?.year ?? ''} قطعة غيار كود عطل $code'
          .trim(),
    );
    final uri = Uri.parse('https://www.google.com/search?q=$query&tbm=shop');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.searchLinkFailed)),
      );
    }
  }

  Future<void> _copyObdTranscript() async {
    final entries =
        _scanner?.protocol.transcript ?? const <Map<String, dynamic>>[];
    final text = entries
        .map((entry) => [
              '[${entry['timestamp'] ?? ''}]',
              'HEADER: ${entry['requestHeader'] ?? ''}',
              'COMMAND: ${entry['command'] ?? ''}',
              'RAW: ${entry['raw'] ?? ''}',
              'RESPONDERS: ${entry['responders'] ?? entry['detectedResponders'] ?? ''}',
              'PARSED: ${entry['codes'] ?? ''}',
            ].join('\n'))
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).obdTranscriptCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final connected = _scanner?.connectedDevice;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.obdConnectTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.dtcGuide,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const DtcReferenceScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _statusCard(),
            const SizedBox(height: 16),
            if (_transportTypes.length > 1 && connected == null) ...[
              Text(l10n.chooseConnectionMethod,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ..._transportTypes.map(_transportCard),
              const SizedBox(height: 8),
            ],
            if (!_available)
              _unavailableCard()
            else if (connected == null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanning ? null : _discover,
                  icon: _scanning
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth_searching),
                  label: Text(_selectedTransport == ObdTransportType.ble
                      ? l10n.searchNearbyDevices
                      : l10n.showPairedDevices),
                ),
              ),
              const SizedBox(height: 12),
              ..._devices.map(_deviceCard),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.bluetooth_connected,
                    color: Colors.green,
                  ),
                  title: Text(connected.name),
                  subtitle: Text(l10n.connected),
                  trailing: TextButton(
                    onPressed: _disconnect,
                    child: Text(l10n.disconnect),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _reading ? null : _scan,
                    icon: _reading
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(l10n.readCodes),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clearing ? null : _clear,
                    icon: _clearing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(l10n.clearCodes),
                  ),
                ],
              ),
            ],
            if (_codes.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.psychology_outlined),
                  label: Text(l10n.diagnoseWithCodes(_codes.length)),
                ),
              ),
              const SizedBox(height: 12),
              ..._codes.map(_codeCard),
            ],
            if (kDebugMode && _scanner != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copyObdTranscript,
                icon: const Icon(Icons.copy_all_outlined),
                label: Text(l10n.copyObdTranscript),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFC9A876).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(_status)),
          ],
        ),
      );

  Widget _unavailableCard() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.bluetooth_disabled_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    AppLocalizations.of(context).obdUnavailableAlternative),
              ),
            ],
          ),
        ),
      );

  Widget _deviceCard(ObdDevice device) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name),
          subtitle: Text(_selectedTransport == ObdTransportType.ble
              ? AppLocalizations.of(context).nearbyDevice
              : AppLocalizations.of(context).pairedDevice),
          trailing: _connecting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chevron_left),
          onTap: _connecting ? null : () => _connect(device),
        ),
      );

  Widget _transportCard(ObdTransportType type) {
    final selected = _selectedTransport == type;
    final ble = type == ObdTransportType.ble;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardColor,
      child: ListTile(
        minVerticalPadding: 12,
        leading: Icon(ble ? Icons.bluetooth_searching : Icons.bluetooth),
        title: Text(ble
            ? 'Bluetooth LE'
            : AppLocalizations.of(context).classicBluetooth),
        subtitle: Text(ble
            ? AppLocalizations.of(context).bleDescription
            : AppLocalizations.of(context).classicBluetoothDescription),
        trailing: Icon(selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded),
        onTap: selected ? null : () => _selectTransport(type),
      ),
    );
  }

  Widget _codeCard(String code) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: Text(
            code,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.search),
            tooltip: AppLocalizations.of(context).findRequiredPart,
            onPressed: () => _searchParts(code),
          ),
        ),
      );
}
