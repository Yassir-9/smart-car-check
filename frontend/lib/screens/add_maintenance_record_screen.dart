import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/maintenance_record.dart';
import '../services/maintenance_record_service.dart';
import '../models/maintenance_reminder.dart';
import '../services/maintenance_service.dart';
import '../data/maintenance_categories_data.dart';

class AddMaintenanceRecordScreen extends StatefulWidget {
  final String carId;

  const AddMaintenanceRecordScreen({super.key, required this.carId});

  @override
  State<AddMaintenanceRecordScreen> createState() =>
      _AddMaintenanceRecordScreenState();
}

class _AddMaintenanceRecordScreenState
    extends State<AddMaintenanceRecordScreen> {
  final _workTypeController = TextEditingController();
  final _mileageController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _workshopController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  DateTime _date = DateTime.now();
  String _selectedCategory = MaintenanceCategoriesData.categories.first;
  Uint8List? _invoiceImage;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _workTypeController.dispose();
    _mileageController.dispose();
    _partNumberController.dispose();
    _workshopController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 60,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _invoiceImage = bytes);
      }
    } catch (e) {
      // تجاهل
    }
  }

  Future<void> _submit() async {
    if (_workTypeController.text.trim().isEmpty) {
      setState(() => _errorText = 'اكتب نوع العمل');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final record = MaintenanceRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        carId: widget.carId,
        workType: _workTypeController.text.trim(),
        workshop: _workshopController.text.trim().isEmpty
            ? null
            : _workshopController.text.trim(),
        date: _date,
        cost: _costController.text.trim().isEmpty
            ? null
            : _costController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        invoiceImageBase64:
            _invoiceImage != null ? base64Encode(_invoiceImage!) : null,
        category: _selectedCategory,
        mileageAtService: _mileageController.text.trim().isEmpty
            ? null
            : _mileageController.text.trim(),
        partNumber: _partNumberController.text.trim().isEmpty
            ? null
            : _partNumberController.text.trim(),
      );
      await MaintenanceRecordService.addRecord(record);

      if (MaintenanceCategoriesData.hasAutoReminder(_selectedCategory)) {
        final intervalDays =
            MaintenanceCategoriesData.intervalDays[_selectedCategory] ?? 0;
        final nextDue = _date.add(Duration(days: intervalDays));
        final reminders = await MaintenanceService.loadReminders();
        reminders.add(MaintenanceReminder(
          id: '${DateTime.now().millisecondsSinceEpoch}_auto',
          title: 'موعد $_selectedCategory القادم',
          dueDate: nextDue,
          notes: 'تم إنشاؤه تلقائياً بعد تسجيل صيانة',
        ));
        await MaintenanceService.saveReminders(reminders);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorText = 'تعذر الحفظ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة سجل صيانة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('نوع الصيانة',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              isExpanded: true,
              items: MaintenanceCategoriesData.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                    if (_workTypeController.text.trim().isEmpty) {
                      _workTypeController.text = val;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('وصف العمل (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _workTypeController,
              decoration:
                  const InputDecoration(hintText: 'مثال: تغيير الزيت + الفلتر'),
            ),
            const SizedBox(height: 16),
            const Text('الكيلومترات عند الصيانة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'مثال: 85000'),
            ),
            const SizedBox(height: 16),
            const Text('رقم القطعة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _partNumberController,
              decoration: const InputDecoration(hintText: 'مثال: 90915-YZZD4'),
            ),
            const SizedBox(height: 16),
            const Text('الورشة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _workshopController,
              decoration: const InputDecoration(hintText: 'اسم الورشة'),
            ),
            const SizedBox(height: 16),
            const Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2015),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('تغيير'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('التكلفة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'مثال: 250'),
            ),
            const SizedBox(height: 16),
            const Text('ملاحظات (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'تفاصيل إضافية'),
            ),
            const SizedBox(height: 16),
            const Text('صورة الفاتورة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _invoiceImage != null
                ? Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_invoiceImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _invoiceImage = null),
                        icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                color: Colors.white, size: 16)),
                      ),
                    ],
                  )
                : OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('إرفاق صورة الفاتورة'),
                  ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('حفظ السجل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
