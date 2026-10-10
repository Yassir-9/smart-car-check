import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmation),
        content: Text(l10n.deleteMaintenanceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.maintenanceHistoryFor(widget.car.label))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? Center(child: Text(l10n.noMaintenanceHistory))
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
                                    Text('${r.cost} ${l10n.sarShort}',
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
                              if (r.notes != null && r.notes!.isNotEmpty) ...[
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
                                    children: [
                                      const Icon(Icons.receipt_long_outlined,
                                          size: 16, color: Color(0xFF1E3A5F)),
                                      const SizedBox(width: 4),
                                      Text(l10n.viewInvoice,
                                          style: const TextStyle(
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
