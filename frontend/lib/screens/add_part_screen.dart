import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../data/car_models_data.dart';
import '../models/part_listing.dart';

class AddPartScreen extends StatefulWidget {
  final PartListing? existingPart;

  const AddPartScreen({super.key, this.existingPart});

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  static const String baseUrl =
      'https://car-ai-backend-7gpb.onrender.com/api/parts';

  static const List<String> _brands = [
    'تويوتا', 'هوندا', 'نيسان', 'هيونداي', 'كيا', 'فورد', 'شيفروليه',
    'مرسيدس', 'بي إم دبليو', 'أودي', 'لكزس', 'مازدا', 'ميتسوبيشي',
    'جيب', 'جي إم سي', 'دودج', 'إنفينيتي', 'سوزوكي', 'فولكس فاجن', 'أخرى',
  ];

  final _partNameController = TextEditingController();
  final _customModelController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _oemController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedBrand = _brands.first;
  String? _selectedModel;
  bool _isSubmitting = false;
  String? _errorText;
  Uint8List? _partImage;
  String? _existingImageBase64;

  bool get _isEditing => widget.existingPart != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPart;
    if (existing != null) {
      _partNameController.text = existing.partName;
      _priceController.text = existing.price ?? '';
      _phoneController.text = existing.sellerPhone;
      _notesController.text = existing.notes ?? '';
      _oemController.text = existing.oemNumber ?? '';
      _existingImageBase64 = existing.imageBase64;
      if (_brands.contains(existing.carBrand)) {
        _selectedBrand = existing.carBrand;
      }
      final models = CarModelsData.modelsByBrand[_selectedBrand] ?? const <String>[];
      if (models.contains(existing.carModel)) {
        _selectedModel = existing.carModel;
      } else {
        _customModelController.text = existing.carModel;
      }
    }
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
        setState(() {
          _partImage = bytes;
          _existingImageBase64 = null;
        });
      }
    } catch (e) {
      // تجاهل
    }
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _customModelController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _oemController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final modelsForBrand =
        CarModelsData.modelsByBrand[_selectedBrand] ?? const <String>[];
    final model = modelsForBrand.isEmpty
        ? _customModelController.text.trim()
        : (_selectedModel ?? '');

    if (_partNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        model.isEmpty) {
      setState(() => _errorText = 'عبّي اسم القطعة والموديل ورقم الجوال');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final uri = _isEditing
          ? Uri.parse('$baseUrl/${widget.existingPart!.id}')
          : Uri.parse(baseUrl);
      String? imagePayload;
      if (_partImage != null) {
        imagePayload = base64Encode(_partImage!);
      } else if (_existingImageBase64 != null) {
        imagePayload = _existingImageBase64;
      }

      final body = jsonEncode({
        'partName': _partNameController.text.trim(),
        'carBrand': _selectedBrand,
        'carModel': model,
        'price': _priceController.text.trim().isEmpty
            ? null
            : _priceController.text.trim(),
        'sellerPhone': _phoneController.text.trim(),
        'notes': _notesController.text.trim(),
        'oemNumber': _oemController.text.trim().isEmpty
            ? null
            : _oemController.text.trim(),
        'imageBase64': imagePayload,
      });
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final response = _isEditing
          ? await http.put(uri, headers: headers, body: body)
          : await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _errorText = 'خطأ من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = CarModelsData.modelsByBrand[_selectedBrand] ?? const <String>[];
    if (models.isNotEmpty && !models.contains(_selectedModel)) {
      _selectedModel = models.first;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'تعديل القطعة' : 'إضافة قطعة للبيع')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اسم القطعة', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _partNameController,
              decoration: const InputDecoration(hintText: 'مثال: حامل مساند خلفي'),
            ),
            const SizedBox(height: 16),
            const Text('الشركة المصنعة', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedBrand,
              isExpanded: true,
              items: _brands
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBrand = val);
              },
            ),
            const SizedBox(height: 16),
            const Text('الموديل', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            models.isEmpty
                ? TextField(
                    controller: _customModelController,
                    decoration: const InputDecoration(hintText: 'اكتب اسم الموديل'),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: _selectedModel,
                    isExpanded: true,
                    items: models
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedModel = val),
                  ),
            const SizedBox(height: 16),
            const Text('السعر (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'مثال: 300'),
            ),
            const SizedBox(height: 16),
            const Text('رقم جوالك للتواصل', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '05XXXXXXXX'),
            ),
            const SizedBox(height: 16),
            const Text('ملاحظات (اختياري)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'حالة القطعة، إلخ'),
            ),
            const SizedBox(height: 16),
            const Text('رقم القطعة الأصلي OEM (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _oemController,
              decoration: const InputDecoration(hintText: 'مثال: 97128A5000'),
            ),
            const SizedBox(height: 16),
            const Text('صورة القطعة (اختياري)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            _partImage != null
                ? Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_partImage!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _partImage = null),
                        icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close,
                                color: Colors.white, size: 16)),
                      ),
                    ],
                  )
                : (_existingImageBase64 != null
                    ? Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                                base64Decode(_existingImageBase64!),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _existingImageBase64 = null),
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
                        label: const Text('إرفاق صورة القطعة'),
                      )),
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
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? 'حفظ التعديلات' : 'نشر القطعة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
