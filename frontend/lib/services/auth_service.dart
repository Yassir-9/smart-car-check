import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  static Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e.code);
    } catch (e) {
      return 'حدث خطأ غير متوقع';
    }
  }

  static String? _verificationId;

  static String? normalizeSaudiPhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('966')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (!RegExp(r'^5\d{8}$').hasMatch(digits)) {
      return null;
    }
    return '+966$digits';
  }

  static Future<void> sendOtp({
    required String phone,
    required void Function() onCodeSent,
    required void Function(String) onError,
    required void Function() onAutoVerified,
    String Function(String code)? errorMessageForCode,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);
            onAutoVerified();
          } catch (error) {
            _logUnexpectedError('automatic verification', error);
            onError(
                errorMessageForCode?.call('automatic-verification-failed') ??
                    'تعذر التحقق التلقائي، أدخل الرمز يدوياً');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _logFirebaseError('sendOtp verification', e);
          onError(errorMessageForCode?.call(e.code) ?? _mapError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      _logFirebaseError('sendOtp', e);
      onError(errorMessageForCode?.call(e.code) ?? _mapError(e.code));
    } catch (error) {
      _logUnexpectedError('sendOtp', error);
      onError(errorMessageForCode?.call('send-failed') ??
          'تعذر إرسال رمز التحقق. تحقق من رقم الجوال وحاول مرة أخرى.');
    }
  }

  static Future<String?> verifyOtp(
    String smsCode, {
    String Function(String code)? errorMessageForCode,
  }) async {
    try {
      if (_verificationId == null) {
        return errorMessageForCode?.call('missing-verification-session') ??
            'انتهت صلاحية الجلسة، أعد إرسال الرمز';
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );
      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      _logFirebaseError('verifyOtp', e);
      return errorMessageForCode?.call(e.code) ?? _mapError(e.code);
    } catch (error) {
      _logUnexpectedError('verifyOtp', error);
      return errorMessageForCode?.call('unexpected') ?? 'حدث خطأ غير متوقع';
    }
  }

  static String _mapError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
      case 'invalid-credential':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم مسبقاً';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)';
      case 'invalid-phone-number':
        return 'رقم الجوال غير صحيح، تأكد من الصيغة';
      case 'invalid-app-credential':
      case 'app-not-authorized':
      case 'operation-not-allowed':
      case 'captcha-check-failed':
        return 'تعذر إرسال رمز التحقق. تحقق من رقم الجوال وحاول مرة أخرى.';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'session-expired':
        return 'انتهت صلاحية الرمز، أعد الإرسال';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      default:
        return 'تعذر إكمال الطلب الآن. حاول مرة أخرى.';
    }
  }

  static void _logFirebaseError(String operation, FirebaseAuthException error) {
    debugPrint('Firebase Auth $operation failed (${error.code}).');
  }

  static void _logUnexpectedError(String operation, Object error) {
    debugPrint('Firebase Auth $operation failed (${error.runtimeType}).');
  }
}
