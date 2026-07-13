import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/car_model.dart';

class CarService {
  static const String _carsKey = 'saved_cars';
  static const String _activeCarKey = 'active_car_id';

  static Future<List<CarModel>> loadCars() async {
    try {
      print('CarService: بدء استدعاء getInstance');
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 5));
      print('CarService: getInstance نجح');

      final raw = prefs.getString(_carsKey);
      print('CarService: raw = $raw');

      if (raw == null || raw.isEmpty) {
        final defaultCar = CarModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          brand: 'تويوتا',
          model: 'كامري',
          year: 2022,
        );
        await saveCars([defaultCar]);
        await setActiveCarId(defaultCar.id);
        print('CarService: تم إنشاء سيارة افتراضية');
        return [defaultCar];
      }
      final List<dynamic> list = jsonDecode(raw);
      print('CarService: تم فك تشفير القائمة، العدد = ${list.length}');
      return list.map((e) => CarModel.fromJson(e)).toList();
    } catch (e, stack) {
      print('CarService ERROR: $e');
      print('CarService STACK: $stack');
      rethrow;
    }
  }

  static Future<void> saveCars(List<CarModel> cars) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(cars.map((c) => c.toJson()).toList());
    await prefs.setString(_carsKey, raw);
  }

  static Future<String?> getActiveCarId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeCarKey);
  }

  static Future<void> setActiveCarId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeCarKey, id);
  }
}
