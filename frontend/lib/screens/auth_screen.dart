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

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
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
                        _codeSent ? l10n.otpTitle : l10n.loginTitle,
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
                              : (_codeSent ? _verifyCode : _sendCode),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_codeSent ? l10n.verifyOtp : l10n.sendOtp),
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
