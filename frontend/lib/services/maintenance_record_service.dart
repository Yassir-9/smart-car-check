import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_record.dart';

class MaintenanceRecordService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _recordsRef {
    final uid = _uid;
    if (uid == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('maintenance_records');
  }

  static Future<List<MaintenanceRecord>> loadRecords({String? carId}) async {
    final snapshot = await _recordsRef.get();
    var records = snapshot.docs
        .map((doc) => MaintenanceRecord.fromJson(doc.data()))
        .toList();
    if (carId != null) {
      records = records.where((r) => r.carId == carId).toList();
    }
    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
  }

  static Future<void> addRecord(MaintenanceRecord record) async {
    await _recordsRef.doc(record.id).set(record.toJson());
  }

  static Future<void> deleteRecord(String id) async {
    await _recordsRef.doc(id).delete();
  }
}
