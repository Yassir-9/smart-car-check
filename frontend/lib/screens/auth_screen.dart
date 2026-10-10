import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_design_system.dart';
import '../l10n/app_localizations.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _emailMode = true;
  bool _register = false;
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _t(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  String _emailError(String message) {
    if (Localizations.localeOf(context).languageCode == 'ar') {
      return message;
    }

    return switch (message) {
      'البريد الإلكتروني غير صحيح' => 'Invalid email address.',
      'لا يوجد حساب بهذا البريد' => 'No account found with this email.',
      'كلمة المرور غير صحيحة' => 'Incorrect email or password.',
      'هذا البريد مستخدم مسبقاً' => 'This email is already registered.',
      'كلمة المرور ضعيفة جداً (6 أحرف على الأقل)' =>
        'Password is too weak. Use at least 6 characters.',
      'محاولات كثيرة، حاول لاحقاً' =>
        'Too many attempts. Please try again later.',
      _ => 'Unable to complete the request. Please try again.',
    };
  }

  bool _validEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_validEmail(email)) {
      setState(() => _errorText =
          _t('أدخل بريدًا إلكترونيًا صحيحًا', 'Enter a valid email address.'));
      return;
    }

    if (password.length < 6) {
      setState(() => _errorText = _t(
          'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
          'Password must contain at least 6 characters.'));
      return;
    }

    if (_register && password != _confirmController.text) {
      setState(() => _errorText =
          _t('كلمتا المرور غير متطابقتين', 'Passwords do not match.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = _register
        ? await AuthService.signUp(email, password)
        : await AuthService.signIn(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorText = error == null ? null : _emailError(error);
    });
  }

  Future<void> _resetEmail() async {
    final email = _emailController.text.trim();

    if (!_validEmail(email)) {
      setState(() => _errorText = _t(
          'أدخل بريدك الإلكتروني أولًا',
          'Enter your email address first.'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await AuthService.resetPassword(email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _errorText = error == null ? null : _emailError(error);
    });

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(
          'إذا كان البريد مسجلًا، ستصلك رسالة استعادة كلمة المرور',
          'If the email is registered, you will receive a password reset email.',
        ))),
      );
    }
  }

  Future<void> _sendCode() async {
    final l10n = AppLocalizations.of(context);
    final phone = AuthService.normalizeSaudiPhone(_phoneController.text);
    if (phone == null) {
      setState(() => _errorText = l10n.invalidSaudiPhone);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    await AuthService.sendOtp(
      phone: phone,
      onCodeSent: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _codeSent = true;
        });
      },
      onError: (err) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _errorText = err;
        });
      },
      onAutoVerified: () {
        if (!mounted) {
          return;
        }
        setState(() => _isLoading = false);
      },
      errorMessageForCode: (code) => _authError(l10n, code),
    );
  }

  Future<void> _verifyCode() async {
    final l10n = AppLocalizations.of(context);
    if (_otpController.text.trim().length < 4) {
      setState(() => _errorText = l10n.incompleteOtp);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await AuthService.verifyOtp(
      _otpController.text.trim(),
      errorMessageForCode: (code) => _authError(l10n, code),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorText = error;
      });
    }
  }

  String _authError(AppLocalizations l10n, String code) => switch (code) {
        'invalid-phone-number' => l10n.authInvalidPhone,
        'invalid-verification-code' => l10n.authInvalidCode,
        'session-expired' => l10n.authCodeExpired,
        'too-many-requests' => l10n.authTooManyRequests,
        'invalid-app-credential' ||
        'app-not-authorized' ||
        'operation-not-allowed' ||
        'captcha-check-failed' ||
        'send-failed' =>
          l10n.authSendFailed,
        'automatic-verification-failed' => l10n.authAutomaticFailed,
        'missing-verification-session' => l10n.authSessionExpired,
        'unexpected' => l10n.authUnexpected,
        _ => l10n.authRequestFailed,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: .10),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg)),
                          child: const Icon(Icons.speed_rounded,
                              size: 34, color: AppColors.accent)),
                      const SizedBox(height: 16),
                      Text(
                        _emailMode
                            ? _t('تسجيل الدخول بالبريد الإلكتروني',
                                'Sign in with email')
                            : (_codeSent ? l10n.otpTitle : l10n.loginTitle),
                        style: AppTypography.title,
                      ),
                      const SizedBox(height: 8),
                      if (_codeSent)
                        Text(
                          l10n.otpSubtitle,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.steel),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 24),
                      if (!_codeSent) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: Text(_t('البريد الإلكتروني', 'Email')),
                              selected: _emailMode,
                              onSelected: _isLoading ? null : (_) {
                                setState(() {
                                  _emailMode = true;
                                  _errorText = null;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: Text(_t('رقم الجوال', 'Phone')),
                              selected: !_emailMode,
                              onSelected: _isLoading ? null : (_) {
                                setState(() {
                                  _emailMode = false;
                                  _errorText = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_emailMode) ...[
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: _t('البريد الإلكتروني', 'Email address'),
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: _t('كلمة المرور', 'Password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                            ),
                          ),
                        ),
                        if (_register) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmController,
                            obscureText: !_showPassword,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: _t(
                                  'تأكيد كلمة المرور', 'Confirm password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                        ],
                      ] else if (!_codeSent) ...[
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: l10n.phoneLabel,
                            hintText: '55XXXXXXX',
                            prefixText: '+966  ',
                            prefixIcon: const Icon(Icons.phone_iphone_outlined),
                            helperText: l10n.phoneHelper,
                          ),
                        ),
                      ] else ...[
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 22, letterSpacing: 6),
                          decoration: InputDecoration(
                            labelText: l10n.otpLabel,
                            hintText: '------',
                          ),
                        ),
                      ],
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: .08),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm)),
                          child: Text(_errorText!,
                              style: const TextStyle(color: AppColors.danger)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_emailMode
                                    ? _submitEmail
                                    : (_codeSent ? _verifyCode : _sendCode)),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_emailMode
                                    ? (_register
                                        ? _t('إنشاء حساب', 'Create account')
                                        : _t('تسجيل الدخول', 'Sign in'))
                                    : (_codeSent
                                        ? l10n.verifyOtp
                                        : l10n.sendOtp)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_emailMode) ...[
                        TextButton(
                          onPressed: _isLoading ? null : () {
                            setState(() {
                              _register = !_register;
                              _errorText = null;
                              _confirmController.clear();
                            });
                          },
                          child: Text(_register
                              ? _t('لديك حساب؟ تسجيل الدخول',
                                  'Already have an account? Sign in')
                              : _t('ليس لديك حساب؟ إنشاء حساب',
                                  'New here? Create an account')),
                        ),
                        if (!_register)
                          TextButton(
                            onPressed: _isLoading ? null : _resetEmail,
                            child: Text(_t(
                                'نسيت كلمة المرور؟', 'Forgot password?')),
                          ),
                      ],
                      if (_codeSent)
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => setState(() {
                                    _codeSent = false;
                                    _otpController.clear();
                                    _errorText = null;
                                  }),
                          child: Text(l10n.changePhone),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
