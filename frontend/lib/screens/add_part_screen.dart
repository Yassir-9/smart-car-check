import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import '../data/car_models_data.dart';
import '../models/part_listing.dart';
import '../l10n/app_localizations.dart';
import '../utils/localized_vehicle_text.dart';

class AddPartScreen extends StatefulWidget {
  final PartListing? existingPart;

  const AddPartScreen({super.key, this.existingPart});

  @override
  State<AddPartScreen> createState() => _AddPartScreenState();
}

class _AddPartScreenState extends State<AddPartScreen> {
  static String get baseUrl => '${ApiConfig.apiBaseUrl}/parts';

  static const List<String> _brands = [
    'تويوتا',
    'هوندا',
    'نيسان',
    'هيونداي',
    'كيا',
    'فورد',
    'شيفروليه',
    'مرسيدس',
    'بي إم دبليو',
    'أودي',
    'لكزس',
    'مازدا',
    'ميتسوبيشي',
    'جيب',
    'جي إم سي',
    'دودج',
    'إنفينيتي',
    'سوزوكي',
    'فولكس فاجن',
    'أخرى',
  ];

  final _partNameController = TextEditingController();
  final _customModelController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _oemController = TextEditingController();
  final _partBrandController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedBrand = _brands.first;
  String? _selectedModel;
  String _selectedCondition = 'مستعملة';
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
      _partBrandController.text = existing.partBrand ?? '';
      if (existing.condition == 'جديدة' || existing.condition == 'مستعملة') {
        _selectedCondition = existing.condition!;
      }
      _existingImageBase64 = existing.imageBase64;
      if (_brands.contains(existing.carBrand)) {
        _selectedBrand = existing.carBrand;
      }
      final models =
          CarModelsData.modelsByBrand[_selectedBrand] ?? const <String>[];
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
    _partBrandController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final modelsForBrand =
        CarModelsData.modelsByBrand[_selectedBrand] ?? const <String>[];
    final model = modelsForBrand.isEmpty
        ? _customModelController.text.trim()
        : (_selectedModel ?? '');

    if (_partNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        model.isEmpty) {
      setState(() => _errorText = l10n.requiredPartFields);
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
        'condition': _selectedCondition,
        'partBrand': _partBrandController.text.trim().isEmpty
            ? null
            : _partBrandController.text.trim(),
        'locale': locale,
      });
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'X-App-Locale': locale,
      };
      final response = _isEditing
          ? await http.put(uri, headers: headers, body: body)
          : await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(
            () => _errorText = l10n.serverErrorStatus(response.statusCode));
      }
    } catch (e) {
      setState(() => _errorText = l10n.serverConnectionFailed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final models =
        CarModelsData.modelsByBrand[_selectedBrand] ?? const <String>[];
    if (models.isNotEmpty && !models.contains(_selectedModel)) {
      _selectedModel = models.first;
    }

    return Scaffold(
      appBar:
          AppBar(title: Text(_isEditing ? l10n.editPart : l10n.addPartForSale)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.partName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _partNameController,
              decoration: InputDecoration(hintText: l10n.partNameHint),
            ),
            const SizedBox(height: 16),
            Text(l10n.compatibleVehicleBrand,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedBrand,
              isExpanded: true,
              items: _brands
                  .map((b) =>
                      DropdownMenuItem(value: b, child: Text(l10n.carBrand(b))))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBrand = val);
              },
            ),
            const SizedBox(height: 16),
            Text(l10n.partCondition,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'جديدة', label: Text(l10n.newPart)),
                ButtonSegment(value: 'مستعملة', label: Text(l10n.usedPart)),
              ],
              selected: {_selectedCondition},
              onSelectionChanged: (val) =>
                  setState(() => _selectedCondition = val.first),
            ),
            const SizedBox(height: 16),
            Text(l10n.partManufacturerOptional,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _partBrandController,
              decoration: InputDecoration(hintText: l10n.partManufacturerHint),
            ),
            const SizedBox(height: 16),
            Text(l10n.carModel,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            models.isEmpty
                ? TextField(
                    controller: _customModelController,
                    decoration: InputDecoration(hintText: l10n.carModelName),
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
            Text(l10n.priceOptional,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: '300'),
            ),
            const SizedBox(height: 16),
            Text(l10n.sellerPhone,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '05XXXXXXXX'),
            ),
            const SizedBox(height: 16),
            Text(l10n.notesOptional,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.partNotesHint),
            ),
            const SizedBox(height: 16),
            Text(l10n.oemNumberOptional,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _oemController,
              decoration: const InputDecoration(hintText: '97128A5000'),
            ),
            const SizedBox(height: 16),
            Text(l10n.partImageOptional,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        label: Text(l10n.attachPartImage),
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(_isEditing ? l10n.saveChanges : l10n.publishPart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
