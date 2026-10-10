import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car_model.dart';
import '../models/vehicle_issue.dart';
import 'notification_service.dart';

class CarHealthService {
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;
  static CollectionReference<Map<String, dynamic>> get _issues =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('vehicle_issues');
  static CollectionReference<Map<String, dynamic>> get _repairs =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('repairs');

  static Future<List<VehicleIssue>> loadIssues(String carId) async {
    final snapshot = await _issues.get();
    final items = snapshot.docs
        .map((d) => VehicleIssue.fromJson(d.data()))
        .where((i) => i.carId == carId)
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  static Future<List<Map<String, dynamic>>> loadRepairs(String carId) async {
    final snapshot = await _repairs.get();
    final items = snapshot.docs
        .map((d) => d.data())
        .where((r) => r['carId'] == carId)
        .toList();
    items.sort((a, b) =>
        (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
    return items;
  }

  static Future<VehicleIssue> recordDiagnosis(
      {required CarModel car,
      required Map<String, dynamic> diagnosis,
      required String symptoms}) async {
    final codes = List<Map<String, dynamic>>.from(
            diagnosis['obd_codes'] ?? diagnosis['obd_analysis'] ?? const [])
        .map((e) => e['code']?.toString())
        .whereType<String>()
        .toList();
    final previous = await loadIssues(car.id);
    final returned = codes.isNotEmpty &&
        previous.any((issue) =>
            issue.status == 'repaired' && issue.obdCodes.any(codes.contains));
    final severity = diagnosis['severity_code'] ?? diagnosis['severity'];
    final initialStatus = returned
        ? 'returned'
        : (severity == 'high' || severity == 'critical'
            ? 'repair_needed'
            : 'new');
    final id = diagnosis['diagnosis_id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final data = {
      'id': id,
      'carId': car.id,
      'title':
          diagnosis['title'] ?? diagnosis['possible_issue'] ?? 'تشخيص سيارة',
      'obdCodes': codes,
      'status': initialStatus,
      'date': DateTime.now().toIso8601String(),
      'mileage': car.currentMileage,
      'notes': symptoms,
      'returnedAfterRepair': returned,
      'diagnosis': diagnosis,
    };
    await _issues.doc(id).set(data);
    return VehicleIssue.fromJson(data);
  }

  static Future<void> saveRepair(
      {required VehicleIssue issue,
      required String changedParts,
      required double cost,
      String? workshop,
      int? mileage,
      String? notes,
      required bool issueGone}) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _repairs.doc(id).set({
      'id': id,
      'repairId': id,
      'carId': issue.carId,
      'vehicleId': issue.carId,
      'issueId': issue.id,
      'diagnosisId': issue.id,
      'changedParts': changedParts,
      'partsReplaced': changedParts
          .split(RegExp(r'[,،\n]'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(),
      'workPerformed': [
        if (notes != null && notes.trim().isNotEmpty) notes.trim()
      ],
      'repairCost': cost,
      'cost': cost,
      'workshop': workshop,
      'workshopName': workshop,
      'mileage': mileage,
      'notes': notes,
      'verificationStatus': issueGone ? 'pending' : 'unresolved',
      'issueGone': issueGone,
      'date': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'deletedAt': null,
    });
    await NotificationService.scheduleRepairVerificationReminder(repairId: id);
    await _issues.doc(issue.id).set({
      'status': issueGone ? 'repaired' : 'monitoring',
      'lastRepairId': id,
      'lastRepairDate': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
