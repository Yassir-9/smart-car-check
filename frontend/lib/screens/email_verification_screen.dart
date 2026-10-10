import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends State<EmailVerificationScreen> {
  bool _busy = false;
  String? _message;
  bool _isError = false;

  String _t(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      await user.sendEmailVerification();

      if (!mounted) return;

      setState(() {
        _isError = false;
        _message = _t(
          'تم إرسال رابط جديد. افحص بريدك والرسائل غير المرغوبة.',
          'A new link was sent. Check your inbox and spam folder.',
        );
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isError = true;
        _message = e.code == 'too-many-requests'
            ? _t(
                'طلبات كثيرة. انتظر قليلًا ثم حاول مجددًا.',
                'Too many requests. Wait before trying again.',
              )
            : _t(
                'تعذر إرسال الرابط. حاول مرة أخرى.',
                'Could not send the link. Please try again.',
              );
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isError = true;
        _message = _t(
          'حدث خطأ. حاول مرة أخرى.',
          'Something went wrong. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      await user.reload();

      final refreshed = FirebaseAuth.instance.currentUser;

      if (refreshed != null && refreshed.emailVerified) {
        await refreshed.getIdToken(true);
      }

      if (!mounted) return;

      setState(() {
        _isError = false;
        _message = refreshed?.emailVerified == true
            ? _t(
                'تم تأكيد بريدك بنجاح.',
                'Your email has been verified.',
              )
            : _t(
                'البريد لم يتأكد بعد. افتح رابط التأكيد أولًا.',
                'Email is not verified yet. Open the verification link first.',
              );
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isError = true;
        _message = _t(
          'تعذر التحقق الآن. حاول مرة أخرى.',
          'Could not check verification. Please try again.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 60,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _t('تأكيد البريد الإلكتروني', 'Verify your email'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _t(
                          'أرسلنا رابط تأكيد إلى بريدك الإلكتروني. افتح الرابط ثم ارجع هنا.',
                          'We sent a verification link to your email. Open it, then return here.',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        email,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (_message != null) ...[
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isError
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (_busy)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy ? null : _checkVerification,
                          child: Text(
                            _t('تحققت من بريدي', "I've verified my email"),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : _resend,
                        child: Text(
                          _t('إعادة إرسال الرابط', 'Resend verification link'),
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => FirebaseAuth.instance.signOut(),
                        child: Text(
                          _t('تسجيل الخروج', 'Sign out'),
                        ),
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