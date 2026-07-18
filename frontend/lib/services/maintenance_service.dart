import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/maintenance_reminder.dart';

class MaintenanceService {
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static CollectionReference<Map<String, dynamic>> get _remindersRef {
    final uid = _uid;
    if (uid == null) {
      throw Exception('لا يوجد مستخدم مسجل الدخول');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('maintenance_reminders');
  }

  static Future<List<MaintenanceReminder>> loadReminders() async {
    final snapshot = await _remindersRef.get();
    return snapshot.docs
        .map((doc) => MaintenanceReminder.fromJson(doc.data()))
        .toList();
  }

  static Future<void> saveReminders(List<MaintenanceReminder> reminders) async {
    final ref = _remindersRef;
    final existing = await ref.get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final r in reminders) {
      batch.set(ref.doc(r.id), r.toJson());
    }
    await batch.commit();
  }
}
