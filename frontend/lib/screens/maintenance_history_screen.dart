import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';
import '../models/car_model.dart';
import '../services/maintenance_record_service.dart';
import 'add_maintenance_record_screen.dart';

class MaintenanceHistoryScreen extends StatefulWidget {
  final CarModel car;

  const MaintenanceHistoryScreen({super.key, required this.car});

  @override
  State<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  List<MaintenanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final records =
        await MaintenanceRecordService.loadRecords(carId: widget.car.id);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _deleteRecord(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تبي تحذف هذا السجل نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await MaintenanceRecordService.deleteRecord(id);
      _loadRecords();
    }
  }

  void _showInvoiceImage(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.memory(base64Decode(base64Image)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('سجل صيانة ${widget.car.label}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('لا يوجد سجل صيانة لهذي السيارة بعد'))
              : RefreshIndicator(
                  onRefresh: _loadRecords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final r = _records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(r.workType,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (r.cost != null)
                                    Text('${r.cost} ر.س',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold)),
                                  IconButton(
                                    onPressed: () => _deleteRecord(r.id),
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                  '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}${r.workshop != null ? ' • ${r.workshop}' : ''}',
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey)),
                              if (r.notes != null &&
                                  r.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(r.notes!,
                                    style: const TextStyle(fontSize: 13)),
                              ],
                              if (r.invoiceImageBase64 != null) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () =>
                                      _showInvoiceImage(r.invoiceImageBase64!),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.receipt_long_outlined,
                                          size: 16, color: Color(0xFF1E3A5F)),
                                      SizedBox(width: 4),
                                      Text('عرض الفاتورة',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF1E3A5F))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddMaintenanceRecordScreen(carId: widget.car.id)),
          );
          if (added == true) _loadRecords();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
