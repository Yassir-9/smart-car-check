import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/obd_session_service.dart';
import '../models/car_model.dart';
import 'dtc_reference_screen.dart';
import '../services/car_service.dart';

class ObdConnectScreen extends StatefulWidget {
  const ObdConnectScreen({super.key});

  @override
  State<ObdConnectScreen> createState() => _ObdConnectScreenState();
}

class _ObdConnectScreenState extends State<ObdConnectScreen> {
  final FlutterBlueClassic _bluetooth =
      FlutterBlueClassic(usesFineLocation: true);

  List<BluetoothDevice> _pairedDevices = [];
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<Uint8List>? _dataSub;
  String _buffer = '';

  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isReading = false;
  bool _isClearing = false;
  String _statusMessage =
      'اضغط "بحث عن أجهزة" لعرض الأجهزة المقترنة ببلوتوث جهازك';
  List<String> _dtcCodes = [];
  CarModel? _activeCar;

  @override
  void initState() {
    super.initState();
    if (ObdSessionService.hasSavedData) {
      _dtcCodes = List.from(ObdSessionService.lastCodes);
      _statusMessage =
          'نتيجة آخر فحص محفوظة (${_dtcCodes.length} كود) — أعد الاتصال للفحص من جديد';
    }
    _loadActiveCar();
  }

  Future<void> _loadActiveCar() async {
    try {
      final cars = await CarService.loadCars();
      final activeId = await CarService.getActiveCarId();
      if (cars.isNotEmpty) {
        _activeCar = cars.firstWhere(
          (c) => c.id == activeId,
          orElse: () => cars.first,
        );
      }
    } catch (e) {
      _activeCar = null;
    }
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _connection?.dispose();
    super.dispose();
  }

  Future<void> _scanPairedDevices() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'جاري البحث...';
    });
    try {
      final devices = await _bluetooth.bondedDevices ?? [];
      setState(() {
        _pairedDevices = devices;
        _statusMessage = devices.isEmpty
            ? 'ما لقينا أجهزة مقترنة. أول قرن جهاز OBD من إعدادات البلوتوث بجوالك، ثم أعد المحاولة.'
            : 'اختر جهاز OBD من القائمة (اسمه عادة يحتوي OBD أو ELM)';
      });
    } catch (e) {
      setState(() => _statusMessage = 'تعذر البحث عن الأجهزة: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _onDataReceived(Uint8List data) {
    _buffer += String.fromCharCodes(data);
  }

  Future<void> _connectTo(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
      _statusMessage = 'جاري الاتصال بـ ${device.name}...';
    });
    try {
      final connection = await _bluetooth.connect(device.address);
      if (connection == null || !connection.isConnected) {
        throw Exception('فشل الاتصال بالجهاز');
      }
      _connection = connection;
      _buffer = '';
      _dataSub = connection.input?.listen(_onDataReceived);

      connection.writeString('ATZ\r');
      await Future.delayed(const Duration(milliseconds: 800));
      connection.writeString('ATE0\r');
      await Future.delayed(const Duration(milliseconds: 400));

      setState(() {
        _connectedDevice = device;
        _statusMessage = '✅ متصل بجهاز ${device.name}';
      });
    } catch (e) {
      setState(() => _statusMessage = 'فشل الاتصال: $e');
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  List<String> _parseDtcResponse(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\r\n>]'), ' ').trim();
    final bytes = cleaned
        .split(RegExp(r'\s+'))
        .where((b) => RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(b))
        .map((b) => int.parse(b, radix: 16))
        .toList();

    final startIndex = bytes.indexOf(0x43);
    if (startIndex == -1) return [];

    final dataBytes = bytes.sublist(startIndex + 1);
    const letters = ['P', 'C', 'B', 'U'];
    final codes = <String>[];
    for (int i = 0; i + 1 < dataBytes.length; i += 2) {
      final b1 = dataBytes[i];
      final b2 = dataBytes[i + 1];
      if (b1 == 0 && b2 == 0) continue;
      final letter = letters[(b1 >> 6) & 0x03];
      final digit2 = (b1 >> 4) & 0x03;
      final digit3 = (b1 & 0x0F).toRadixString(16).toUpperCase();
      final digit4 = ((b2 >> 4) & 0x0F).toRadixString(16).toUpperCase();
      final digit5 = (b2 & 0x0F).toRadixString(16).toUpperCase();
      codes.add('$letter$digit2$digit3$digit4$digit5');
    }
    return codes;
  }

Future<Map<String, dynamic>> _readDtcForHeader(String header) async {
    Map<String, dynamic> result = {'codes': <String>[], 'reachable': true, 'ambiguous': true};

    for (int attempt = 0; attempt < 2; attempt++) {
      _buffer = '';
      _connection?.writeString('ATSH$header\r');
      await Future.delayed(const Duration(milliseconds: 600));
      _buffer = '';
      _connection?.writeString('03\r');
      await Future.delayed(const Duration(milliseconds: 3000));
      final raw = _buffer;
      final upper = raw.toUpperCase();
      final codes = _parseDtcResponse(raw);
      final unableToConnect = upper.contains('UNABLE TO CONNECT');
      final confirmedEmpty = upper.contains('NO DATA');
      final ambiguous = codes.isEmpty && !unableToConnect && !confirmedEmpty && raw.trim().length < 6;

      result = {
        'codes': codes,
        'reachable': !unableToConnect,
        'ambiguous': ambiguous,
      };

      if (!ambiguous) break;
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return result;
  }

  Future<void> _readDtcCodes() async {
    setState(() {
      _isReading = true;
      _statusMessage = 'جاري قراءة أكواد المحرك...';
      _buffer = '';
    });
    try {
      final engineResult = await _readDtcForHeader('7E0');
      final engineAmbiguous = engineResult['ambiguous'] as bool;

      if (engineAmbiguous) {
        setState(() {
          _statusMessage = 'تعذر إتمام الفحص (اتصال غير مستقر) — النتيجة السابقة محفوظة، أعد المحاولة';
        });
        return;
      }

      final engineCodes = List<String>.from(engineResult['codes']);

      setState(() => _statusMessage = 'جاري قراءة أكواد ناقل الحركة (القير)...');
      List<String> transmissionCodes = [];
      bool transmissionReachable = true;
      try {
        final transResult = await _readDtcForHeader('7E1');
        transmissionCodes = List<String>.from(transResult['codes']);
        transmissionReachable = transResult['reachable'] as bool;
      } catch (_) {
        transmissionCodes = [];
        transmissionReachable = false;
      }

      _connection?.writeString('ATSH7DF\r');
      await Future.delayed(const Duration(milliseconds: 400));

      final combined = <String>{...engineCodes, ...transmissionCodes}.toList();
      final transNote = !transmissionReachable
          ? ' (وحدة القير غير متاحة على هذا الجهاز/السيارة)'
          : '';
      setState(() {
        _dtcCodes = combined;
        _statusMessage = combined.isEmpty
            ? 'ما فيه أكواد أعطال محفوظة حاليًا ✅ (محرك وقير)$transNote'
            : 'تم العثور على ${combined.length} كود (محرك: ${engineCodes.length}، قير: ${transmissionCodes.length})$transNote';
      });
      ObdSessionService.save(combined, _connectedDevice?.name);
    } catch (e) {
      setState(() => _statusMessage = 'خطأ بقراءة الأكواد: $e');
    } finally {
      setState(() => _isReading = false);
    }
  }
  Future<void> _clearDtcCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد المسح'),
        content: const Text(
            'هل أنت متأكد من مسح جميع أكواد الأعطال المحفوظة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('نعم، امسح'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
      _statusMessage = 'جاري مسح الأكواد...';
      _buffer = '';
    });
    try {
      _connection?.writeString('ATSH7DF\r');
      await Future.delayed(const Duration(milliseconds: 300));
      _connection?.writeString('04\r');
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _dtcCodes = [];
        _statusMessage = '✅ تم مسح جميع أكواد الأعطال بنجاح';
      });
      ObdSessionService.clear();
    } catch (e) {
      setState(() => _statusMessage = 'خطأ بمسح الأكواد: $e');
    } finally {
      setState(() => _isClearing = false);
    }
  }

  Future<void> _disconnect() async {
    await _dataSub?.cancel();
    _connection?.dispose();
    setState(() {
      _connection = null;
      _connectedDevice = null;
      _dtcCodes = [];
      _statusMessage = 'تم قطع الاتصال';
    });
  }

  Future<void> _openFreeSearch(String code) async {
    final brand = _activeCar?.brand ?? '';
    final model = _activeCar?.model ?? '';
    final year = _activeCar?.year.toString() ?? '';
    final query = Uri.encodeComponent('$brand $model $year قطعة غيار كود عطل $code'.trim());
    final uri = Uri.parse('https://www.google.com/search?q=$query&tbm=shop');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح رابط البحث')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ربط جهاز OBD-II'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: 'دليل أكواد الأعطال',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DtcReferenceScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A876).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC9A876).withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1E3A5F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_statusMessage,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_connectedDevice == null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanPairedDevices,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.bluetooth_searching),
                  label: const Text('بحث عن أجهزة مقترنة'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _pairedDevices.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        itemCount: _pairedDevices.length,
                        itemBuilder: (context, index) {
                          final d = _pairedDevices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.bluetooth),
                              title: Text(d.name ?? 'جهاز غير معروف'),
                              subtitle: Text(d.address),
                              trailing: _isConnecting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.chevron_left),
                              onTap:
                                  _isConnecting ? null : () => _connectTo(d),
                            ),
                          );
                        },
                      ),
              ),
            ] else ...[
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.bluetooth_connected,
                      color: Colors.green),
                  title: Text(_connectedDevice!.name ?? 'جهاز OBD'),
                  subtitle: const Text('متصل'),
                  trailing: TextButton(
                    onPressed: _disconnect,
                    child: const Text('قطع الاتصال'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isReading ? null : _readDtcCodes,
                      icon: _isReading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search),
                      label: const Text('قراءة الأكواد'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isClearing ? null : _clearDtcCodes,
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: _isClearing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline),
                      label: const Text('مسح الأكواد'),
                    ),
                  ),
                ],
              ),
            ],
          const SizedBox(height: 16),
          if (_dtcCodes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _dtcCodes.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC9A876).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_amber_rounded,
                          color: Color(0xFFC9A876), size: 18),
                    ),
                    title: Text(
                      _dtcCodes[index],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace'),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF1E3A5F)),
                      tooltip: 'ابحث عن القطعة المطلوبة',
                      onPressed: () => _openFreeSearch(_dtcCodes[index]),
                    ),
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }
}
