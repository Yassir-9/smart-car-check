import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AccountDeletionResult {
  final bool completed;
  final String? code;
  const AccountDeletionResult({required this.completed, this.code});
}

class AccountDeletionService {
  static Future<AccountDeletionResult> deleteCurrentAccount({
    http.Client? client,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AccountDeletionResult(
          completed: false, code: 'AUTH_REQUIRED');
    }
    final token = await user.getIdToken(true);
    final response = await (client ?? http.Client()).post(
      ApiConfig.apiUri('/account/delete'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    final body = response.body.isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['status'] == 'completed') {
      final preferences = await SharedPreferences.getInstance();
      await preferences.clear();
      await FirebaseAuth.instance.signOut();
      return const AccountDeletionResult(completed: true);
    }
    return AccountDeletionResult(
      completed: false,
      code: body['code'] as String? ?? 'ACCOUNT_DELETION_FAILED',
    );
  }
}
