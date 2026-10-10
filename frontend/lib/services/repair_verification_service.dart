import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/repair_verification.dart';

class RepairVerificationService {
  static CollectionReference<Map<String, dynamic>> get _ref => FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('repair_verifications');
  static Future<void> create(RepairVerificationRecord record) => _ref.doc(record.verificationId).set(record.toJson());
  static Future<List<RepairVerificationRecord>> readByRepairId(String id) async => (await _ref.where('repairId', isEqualTo: id).get()).docs.map((d) => RepairVerificationRecord.fromJson(d.data())).toList();
  static Future<List<RepairVerificationRecord>> readByVehicleId(String id) async => (await _ref.where('vehicleId', isEqualTo: id).get()).docs.map((d) => RepairVerificationRecord.fromJson(d.data())).toList();
}
