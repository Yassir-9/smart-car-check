import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../data/car_models_data.dart';
import '../models/maintenance_reminder.dart';
import '../services/maintenance_service.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
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

  List<CarModel> _cars = [];
  String? _activeCarId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cars = await CarService.loadCars();
    final activeId = await CarService.getActiveCarId();
    setState(() {
      _cars = cars;
      _activeCarId = activeId ?? (cars.isNotEmpty ? cars.first.id : null);
      _isLoading = false;
    });
  }

  Future<void> _selectCar(String id) async {
    await CarService.setActiveCarId(id);
    setState(() => _activeCarId = id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteCar(String id) async {
    if (_cars.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب إبقاء سيارة واحدة على الأقل')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف السيارة'),
        content: const Text('هل تريد حذف هذه السيارة من قائمتك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cars.removeWhere((c) => c.id == id));
    await CarService.saveCars(_cars);

    if (_activeCarId == id && _cars.isNotEmpty) {
      _activeCarId = _cars.first.id;
      await CarService.setActiveCarId(_activeCarId!);
    }
    setState(() {});
  }

  Future<void> _addOrEditCar({CarModel? existing}) async {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(
        currentYear - 1989, (i) => currentYear - i);

    String selectedBrand = existing != null && _brands.contains(existing.brand)
        ? existing.brand
        : (existing != null ? 'أخرى' : _brands.first);
    final customBrandController = TextEditingController(
      text: existing != null && !_brands.contains(existing.brand)
          ? existing.brand
          : '',
    );
    final brandModelsInit =
        CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
    String selectedModel = existing != null && brandModelsInit.contains(existing.model)
        ? existing.model
        : 'أخرى';
    final modelController = TextEditingController(
      text: existing != null && !brandModelsInit.contains(existing.model)
          ? existing.model
          : '',
    );
    int selectedYear = existing?.year ?? currentYear;
    final vinController = TextEditingController(text: existing?.vin ?? '');
    final engineController =
        TextEditingController(text: existing?.engineType ?? '');
    final transmissionController =
        TextEditingController(text: existing?.transmissionType ?? '');
    DateTime? insuranceExpiry = existing?.insuranceExpiry;
    DateTime? registrationExpiry = existing?.registrationExpiry;
    DateTime? inspectionExpiry = existing?.inspectionExpiry;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? 'إضافة سيارة جديدة' : 'تعديل السيارة'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الشركة المصنعة',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedBrand,
                  isExpanded: true,
                  items: _brands
                      .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedBrand = val);
                    }
                  },
                ),
                if (selectedBrand == 'أخرى') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: customBrandController,
                    decoration: const InputDecoration(
                        labelText: 'اكتب اسم الشركة المصنعة'),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('الموديل',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final models =
                      CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
                  if (models.isEmpty) {
                    return TextField(
                      controller: modelController,
                      decoration:
                          const InputDecoration(labelText: 'اكتب اسم الموديل'),
                    );
                  }
                  final dropdownItems = [...models, 'أخرى'];
                  if (!dropdownItems.contains(selectedModel)) {
                    selectedModel = dropdownItems.first;
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedModel,
                        isExpanded: true,
                        items: dropdownItems
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedModel = val);
                          }
                        },
                      ),
                      if (selectedModel == 'أخرى') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: modelController,
                          decoration: const InputDecoration(
                              labelText: 'اكتب اسم الموديل'),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 12),
                const Text('سنة الصنع',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  isExpanded: true,
                  items: years
                      .map((y) => DropdownMenuItem(
                          value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedYear = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text('رقم الهيكل VIN (اختياري)',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: vinController),
                const SizedBox(height: 12),
                const Text('نوع المحرك (اختياري)',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: engineController),
                const SizedBox(height: 12),
                const Text('نوع القير (اختياري)',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                TextField(controller: transmissionController),
                const SizedBox(height: 16),
                _buildExpiryDateRow(
                  label: 'انتهاء الاستمارة',
                  value: registrationExpiry,
                  context: context,
                  onChanged: (d) =>
                      setDialogState(() => registrationExpiry = d),
                ),
                const SizedBox(height: 12),
                _buildExpiryDateRow(
                  label: 'انتهاء التأمين',
                  value: insuranceExpiry,
                  context: context,
                  onChanged: (d) =>
                      setDialogState(() => insuranceExpiry = d),
                ),
                const SizedBox(height: 12),
                _buildExpiryDateRow(
                  label: 'انتهاء الفحص الدوري',
                  value: inspectionExpiry,
                  context: context,
                  onChanged: (d) =>
                      setDialogState(() => inspectionExpiry = d),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final modelsForBrand =
                    CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
                final modelValue = modelsForBrand.isEmpty
                    ? modelController.text.trim()
                    : (selectedModel == 'أخرى'
                        ? modelController.text.trim()
                        : selectedModel);
                if (modelValue.isEmpty) return;
                if (selectedBrand == 'أخرى' &&
                    customBrandController.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final brand = selectedBrand == 'أخرى'
        ? customBrandController.text.trim()
        : selectedBrand;
    final brandModelsFinal =
        CarModelsData.modelsByBrand[selectedBrand] ?? const <String>[];
    final model = brandModelsFinal.isEmpty
        ? modelController.text.trim()
        : (selectedModel == 'أخرى'
            ? modelController.text.trim()
            : selectedModel);
    final year = selectedYear;

    final savedCar = CarModel(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      brand: brand,
      model: model,
      year: year,
      vin: vinController.text.trim().isEmpty ? null : vinController.text.trim(),
      engineType: engineController.text.trim().isEmpty
          ? null
          : engineController.text.trim(),
      transmissionType: transmissionController.text.trim().isEmpty
          ? null
          : transmissionController.text.trim(),
      insuranceExpiry: insuranceExpiry,
      registrationExpiry: registrationExpiry,
      inspectionExpiry: inspectionExpiry,
    );

    if (existing != null) {
      final index = _cars.indexWhere((c) => c.id == existing.id);
      if (index != -1) {
        _cars[index] = savedCar;
      }
    } else {
      _cars.add(savedCar);
      _activeCarId ??= savedCar.id;
    }

    await CarService.saveCars(_cars);
    await _syncExpiryReminders(savedCar);
    setState(() {});
  }

  Future<void> _syncExpiryReminders(CarModel car) async {
    final reminders = await MaintenanceService.loadReminders();
    reminders.removeWhere((r) =>
        r.id == '${car.id}_registration' ||
        r.id == '${car.id}_insurance' ||
        r.id == '${car.id}_inspection');

    if (car.registrationExpiry != null) {
      reminders.add(MaintenanceReminder(
        id: '${car.id}_registration',
        title: 'انتهاء الاستمارة - ${car.label}',
        dueDate: car.registrationExpiry!,
      ));
    }
    if (car.insuranceExpiry != null) {
      reminders.add(MaintenanceReminder(
        id: '${car.id}_insurance',
        title: 'انتهاء التأمين - ${car.label}',
        dueDate: car.insuranceExpiry!,
      ));
    }
    if (car.inspectionExpiry != null) {
      reminders.add(MaintenanceReminder(
        id: '${car.id}_inspection',
        title: 'انتهاء الفحص الدوري - ${car.label}',
        dueDate: car.inspectionExpiry!,
      ));
    }

    await MaintenanceService.saveReminders(reminders);
  }

  Widget _buildExpiryDateRow({
    required String label,
    required DateTime? value,
    required BuildContext context,
    required void Function(DateTime?) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value == null
              ? '$label: غير محدد'
              : '$label: ${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 13),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
            );
            if (picked != null) onChanged(picked);
          },
          child: const Text('تحديد'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياراتي'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _cars.length,
                itemBuilder: (context, index) {
                  final car = _cars[index];
                  final isActive = car.id == _activeCarId;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF1E3A5F)
                            : Colors.grey.shade200,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.directions_car_filled,
                          color: const Color(0xFF1E3A5F),
                        ),
                      ),
                      title: Text(
                        car.label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      subtitle: isActive
                          ? const Text('السيارة النشطة حالياً',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF1E3A5F)))
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: Colors.grey),
                            onPressed: () => _addOrEditCar(existing: car),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 20, color: Colors.grey),
                            onPressed: () => _deleteCar(car.id),
                          ),
                        ],
                      ),
                      onTap: () => _selectCar(car.id),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditCar(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة سيارة', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A5F),
      ),
    );
  }
}
