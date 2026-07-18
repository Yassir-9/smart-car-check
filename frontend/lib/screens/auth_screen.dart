import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorText = 'عبّي البريد وكلمة المرور');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = _isLogin
        ? await AuthService.signIn(email, password)
        : await AuthService.signUp(email, password);

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
                  _isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isLogin ? 'دخول' : 'إنشاء الحساب'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() {
                    _isLogin = !_isLogin;
                    _errorText = null;
                  }),
                  child: Text(_isLogin
                      ? 'ما عندك حساب؟ أنشئ حساب جديد'
                      : 'عندك حساب؟ سجّل دخول'),
                ),
                if (_isLogin)
                  TextButton(
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        setState(() => _errorText = 'اكتب بريدك أول عشان نرسل لك رابط الاستعادة');
                        return;
                      }
                      final error = await AuthService.resetPassword(email);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(error ?? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك'),
                          ),
                        );
                      }
                    },
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
