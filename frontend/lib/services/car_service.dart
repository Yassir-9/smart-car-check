import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car_model.dart';

class CarService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _carsRef {
    final uid = _uid;
    if (uid == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('cars');
  }

  static DocumentReference<Map<String, dynamic>> get _userDoc {
    final uid = _uid;
    if (uid == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول');
    }
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  static Future<List<CarModel>> loadCars() async {
    final snapshot = await _carsRef.get();
    if (snapshot.docs.isEmpty) {
      final defaultCar = CarModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: 'تويوتا',
        model: 'كامري',
        year: 2022,
      );
      await saveCars([defaultCar]);
      await setActiveCarId(defaultCar.id);
      return [defaultCar];
    }
    return snapshot.docs.map((doc) => CarModel.fromJson(doc.data())).toList();
  }

  static Future<void> saveCars(List<CarModel> cars) async {
    final ref = _carsRef;
    final existing = await ref.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final car in cars) {
      batch.set(ref.doc(car.id), car.toJson());
    }
    await batch.commit();
  }

  static Future<String?> getActiveCarId() async {
    final doc = await _userDoc.get();
    return doc.data()?['activeCarId'] as String?;
  }

  static Future<void> setActiveCarId(String id) async {
    await _userDoc.set({'activeCarId': id}, SetOptions(merge: true));
  }
}
