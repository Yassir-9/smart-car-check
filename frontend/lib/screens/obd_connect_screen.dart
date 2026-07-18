import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

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

  Future<void> _readDtcCodes() async {
    setState(() {
      _isReading = true;
      _statusMessage = 'جاري قراءة أكواد الأعطال...';
      _buffer = '';
    });
    try {
      _connection?.writeString('03\r');
      await Future.delayed(const Duration(seconds: 2));
      final codes = _parseDtcResponse(_buffer);
      setState(() {
        _dtcCodes = codes;
        _statusMessage = codes.isEmpty
            ? 'ما فيه أكواد أعطال محفوظة حاليًا ✅'
            : 'تم العثور على ${codes.length} كود عطل';
      });
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
      _connection?.writeString('04\r');
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _dtcCodes = [];
        _statusMessage = '✅ تم مسح جميع أكواد الأعطال بنجاح';
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ربط جهاز OBD-II')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBDEFB)),
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
              const SizedBox(height: 16),
              if (_dtcCodes.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _dtcCodes.length,
                    itemBuilder: (context, index) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber,
                            color: Colors.orange),
                        title: Text(
                          _dtcCodes[index],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
