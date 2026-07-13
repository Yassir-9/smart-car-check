import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';

class CarsScreen extends StatefulWidget {
  const CarsScreen({super.key});

  @override
  State<CarsScreen> createState() => _CarsScreenState();
}

class _CarsScreenState extends State<CarsScreen> {
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
    final brandController = TextEditingController(text: existing?.brand ?? '');
    final modelController = TextEditingController(text: existing?.model ?? '');
    final yearController =
        TextEditingController(text: existing?.year.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(existing == null ? 'إضافة سيارة جديدة' : 'تعديل السيارة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: brandController,
              decoration: const InputDecoration(labelText: 'الشركة المصنعة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'الموديل'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سنة الصنع'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (brandController.text.trim().isEmpty ||
                  modelController.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final brand = brandController.text.trim();
    final model = modelController.text.trim();
    final year = int.tryParse(yearController.text.trim()) ?? 2020;

    if (existing != null) {
      final index = _cars.indexWhere((c) => c.id == existing.id);
      if (index != -1) {
        _cars[index] =
            CarModel(id: existing.id, brand: brand, model: model, year: year);
      }
    } else {
      final newCar = CarModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: brand,
        model: model,
        year: year,
      );
      _cars.add(newCar);
      _activeCarId ??= newCar.id;
    }

    await CarService.saveCars(_cars);
    setState(() {});
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
                          color: Colors.black.withOpacity(0.05),
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
                          color: const Color(0xFF1E3A5F).withOpacity(0.1),
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
        icon: const Icon(Icons.add),
        label: const Text('إضافة سيارة'),
        backgroundColor: const Color(0xFF1E3A5F),
      ),
    );
  }
}
