import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../data/car_models_data.dart';
import '../models/maintenance_reminder.dart';
import '../services/maintenance_service.dart';
import '../theme/app_design_system.dart';
import '../utils/localized_vehicle_text.dart';

class CarsScreen extends StatefulWidget {
  final bool embedded;
  const CarsScreen({super.key, this.embedded = false});

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
    if (mounted && !widget.embedded) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteCar(String id) async {
    final l10n = AppLocalizations.of(context);
    if (_cars.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.keepOneCar)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteCar),
        content: Text(l10n.deleteCarConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context);
    final currentYear = DateTime.now().year;
    final years =
        List<int>.generate(currentYear - 1989, (i) => currentYear - i);

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
    String selectedModel =
        existing != null && brandModelsInit.contains(existing.model)
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
    final mileageController =
        TextEditingController(text: existing?.currentMileage?.toString() ?? '');
    DateTime? insuranceExpiry = existing?.insuranceExpiry;
    DateTime? registrationExpiry = existing?.registrationExpiry;
    DateTime? inspectionExpiry = existing?.inspectionExpiry;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(existing == null ? l10n.addNewCar : l10n.editCar),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.manufacturer,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedBrand,
                  isExpanded: true,
                  items: _brands
                      .map((b) => DropdownMenuItem(
                          value: b, child: Text(l10n.carBrand(b))))
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
                    decoration:
                        InputDecoration(labelText: l10n.manufacturerName),
                  ),
                ],
                const SizedBox(height: 12),
                Text(l10n.carModel,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final models = CarModelsData.modelsByBrand[selectedBrand] ??
                      const <String>[];
                  if (models.isEmpty) {
                    return TextField(
                      controller: modelController,
                      decoration: InputDecoration(labelText: l10n.carModelName),
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
                            .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(m == 'أخرى' ? l10n.other : m)))
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
                          decoration:
                              InputDecoration(labelText: l10n.carModelName),
                        ),
                      ],
                    ],
                  );
                }),
                const SizedBox(height: 12),
                Text(l10n.manufactureYear,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                DropdownButtonFormField<int>(
                  initialValue: selectedYear,
                  isExpanded: true,
                  items: years
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text(y.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedYear = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(l10n.vinOptional,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                TextField(controller: vinController),
                const SizedBox(height: 12),
                Text(l10n.engineTypeOptional,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                TextField(controller: engineController),
                const SizedBox(height: 12),
                Text(l10n.transmissionTypeOptional,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                TextField(controller: transmissionController),
                const SizedBox(height: 16),
                Text(l10n.currentMileageOptional,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.steel)),
                const SizedBox(height: 4),
                TextField(
                  controller: mileageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(suffixText: l10n.kmShort),
                ),
                const SizedBox(height: 16),
                _buildExpiryDateRow(
                  label: l10n.registrationExpiry,
                  value: registrationExpiry,
                  context: context,
                  onChanged: (d) =>
                      setDialogState(() => registrationExpiry = d),
                ),
                const SizedBox(height: 12),
                _buildExpiryDateRow(
                  label: l10n.insuranceExpiry,
                  value: insuranceExpiry,
                  context: context,
                  onChanged: (d) => setDialogState(() => insuranceExpiry = d),
                ),
                const SizedBox(height: 12),
                _buildExpiryDateRow(
                  label: l10n.inspectionExpiry,
                  value: inspectionExpiry,
                  context: context,
                  onChanged: (d) => setDialogState(() => inspectionExpiry = d),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final modelsForBrand =
                    CarModelsData.modelsByBrand[selectedBrand] ??
                        const <String>[];
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
              child: Text(l10n.save),
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
      currentMileage: int.tryParse(mileageController.text.trim()),
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
    final l10n = AppLocalizations.of(context);
    final reminders = await MaintenanceService.loadReminders();
    reminders.removeWhere((r) =>
        r.id == '${car.id}_registration' ||
        r.id == '${car.id}_insurance' ||
        r.id == '${car.id}_inspection');

    if (car.registrationExpiry != null) {
      reminders.add(MaintenanceReminder(
        id: '${car.id}_registration',
        title: '${l10n.registrationExpiry} - ${car.label}',
        dueDate: car.registrationExpiry!,
      ));
    }
    if (car.insuranceExpiry != null) {
      reminders.add(MaintenanceReminder(
        id: '${car.id}_insurance',
        title: '${l10n.insuranceExpiry} - ${car.label}',
        dueDate: car.insuranceExpiry!,
      ));
    }
    if (car.inspectionExpiry != null) {
      reminders.add(MaintenanceReminder(
        id: '${car.id}_inspection',
        title: '${l10n.inspectionExpiry} - ${car.label}',
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
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value == null
              ? '$label: ${l10n.notSet}'
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
          child: Text(l10n.chooseDate),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        title: Text(l10n.myCars),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _isLoading
                ? AppStateView(
                    icon: Icons.directions_car_outlined,
                    title: l10n.loadingCars,
                    loading: true)
                : _cars.isEmpty
                    ? AppStateView(
                        icon: Icons.directions_car_outlined,
                        title: l10n.addNewCar,
                        message: l10n.firstCarMessage,
                        actionLabel: l10n.addNewCar,
                        onAction: () => _addOrEditCar())
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cars.length,
                        itemBuilder: (context, index) {
                          final car = _cars[index];
                          final isActive = car.id == _activeCarId;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.accent
                                    : Theme.of(context).dividerColor,
                                width: isActive ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.midnight
                                      .withValues(alpha: 0.035),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.09),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.directions_car_filled,
                                    color: AppColors.accent),
                              ),
                              title: Text(
                                  '${l10n.carBrand(car.brand)} ${car.model} (${car.year})',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  '${car.currentMileage == null ? l10n.mileageNotRecorded : '${car.currentMileage} ${l10n.kmShort}'}${isActive ? '  •  ${l10n.activeVehicle}' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isActive
                                          ? AppColors.accent
                                          : AppColors.steel)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20, color: AppColors.steel),
                                    onPressed: () =>
                                        _addOrEditCar(existing: car),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20, color: AppColors.steel),
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditCar(),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            Text(l10n.addNewCar, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.accent,
      ),
    );
  }
}
