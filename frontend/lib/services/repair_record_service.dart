import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/repair_record.dart';
import 'notification_service.dart';
import 'repair_verification_service.dart';

class RepairRecordService {
  static CollectionReference<Map<String, dynamic>> get _ref {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('لا يوجد مستخدم مسجل الدخول');
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('repairs');
  }

  static Future<void> create(RepairRecord record) =>
      _ref.doc(record.repairId).set(record.toJson());
  static Future<List<RepairRecord>> list(String vehicleId) async =>
      (await _ref.where('vehicleId', isEqualTo: vehicleId).get())
          .docs
          .map((doc) => RepairRecord.fromJson(doc.data()))
          .where((record) => !record.isDeleted)
          .toList();
  static Future<void> update(RepairRecord record) =>
      _ref.doc(record.repairId).set(
          record.copyWith(updatedAt: DateTime.now()).toJson(),
          SetOptions(merge: true));
  static Future<void> softDelete(String repairId) => _ref.doc(repairId).set({
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String()
      }, SetOptions(merge: true)).then((_) => NotificationService.cancelRepairVerificationReminder(repairId));

  static Future<bool> hasVerification(String repairId) async {
    return (await RepairVerificationService.readByRepairId(repairId)).isNotEmpty;
  }
}
