import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RepairReviewHistoryService {
  static Future<List<Map<String, dynamic>>> readByVehicleId(
      String vehicleId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('repair_reviews')
        .where('vehicleId', isEqualTo: vehicleId)
        .get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }
}
