import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String? _normalizePhone(String raw) {
    var digits = raw.trim().replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.startsWith('0')) return '+966${digits.substring(1)}';
    if (digits.startsWith('966')) return '+$digits';
    if (digits.startsWith('5') && digits.length == 9) return '+966$digits';
    return '+$digits';
  }

  Future<void> _sendCode() async {
    final phone = _normalizePhone(_phoneController.text);
    if (phone == null || phone.length < 8) {
      setState(() => _errorText = 'اكتب رقم جوال صحيح');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await AuthService.sendOtp(
      phone: phone,
      onCodeSent: () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _codeSent = true;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorText = err;
        });
      },
      onAutoVerified: () {
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_otpController.text.trim().length < 4) {
      setState(() => _errorText = 'اكتب رمز التحقق كامل');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await AuthService.verifyOtp(_otpController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorText = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_car, size: 64, color: Color(0xFF1E3A5F)),
                const SizedBox(height: 16),
                Text(
                  _codeSent ? 'أدخل رمز التحقق' : 'تسجيل الدخول برقم الجوال',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_codeSent)
                  Text(
                    'أرسلنا رمز تحقق مكوّن من 6 أرقام إلى جوالك',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                if (!_codeSent) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.left,
                    decoration: const InputDecoration(
                      labelText: 'رقم الجوال',
                      hintText: '05XXXXXXXX',
                      prefixIcon: Icon(Icons.phone_iphone_outlined),
                    ),
                  ),
                ] else ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, letterSpacing: 6),
                    decoration: const InputDecoration(
                      labelText: 'رمز التحقق',
                      hintText: '------',
                    ),
                  ),
                ],
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_codeSent ? _verifyCode : _sendCode),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_codeSent ? 'تأكيد الرمز' : 'إرسال رمز التحقق'),
                  ),
                ),
                const SizedBox(height: 12),
                if (_codeSent)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _codeSent = false;
                              _otpController.clear();
                              _errorText = null;
                            }),
                    child: const Text('تغيير رقم الجوال'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
