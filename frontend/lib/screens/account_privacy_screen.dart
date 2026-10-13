import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../services/account_deletion_service.dart';
import '../services/auth_service.dart';

class AccountPrivacyScreen extends StatefulWidget {
  const AccountPrivacyScreen({super.key});

  @override
  State<AccountPrivacyScreen> createState() => _AccountPrivacyScreenState();
}

class _AccountPrivacyScreenState extends State<AccountPrivacyScreen> {
  bool _busy = false;
  String? _message;

  Future<String?> _prompt(String title, {bool obscure = false}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType:
              obscure ? TextInputType.visiblePassword : TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(AppLocalizations.of(context).deleteAccountCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(AppLocalizations.of(context).confirmAction)),
        ],
      ),
    );
  }

  Future<bool> _reauthenticate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final hasPassword =
        user.providerData.any((provider) => provider.providerId == 'password');
    if (hasPassword) {
      final password = await _prompt(
          AppLocalizations.of(context).deleteAccountPasswordPrompt,
          obscure: true);
      if (password == null) return false;
      return AuthService.reauthenticateWithPassword(password);
    }
    final completer = Completer<String>();
    void completeOnce(String value) {
      if (!completer.isCompleted) completer.complete(value);
    }
    await AuthService.sendReauthenticationOtp(
      onCodeSent: () => completeOnce('sent'),
      onAutoVerified: () => completeOnce('verified'),
      onError: (_) => completeOnce('failed'),
    );
    final outcome = await completer.future.timeout(
      const Duration(seconds: 65),
      onTimeout: () => 'failed',
    );
    if (outcome == 'verified') return true;
    if (outcome != 'sent') return false;
    if (!mounted) return false;
    final code =
        await _prompt(AppLocalizations.of(context).deleteAccountOtpPrompt);
    if (code == null) return false;
    return AuthService.verifyReauthenticationOtp(code);
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(
            '${l10n.deleteAccountIntro}\n\n${l10n.deleteAccountIrreversible}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.deleteAccountCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.deleteAccountConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (!await _reauthenticate()) {
        if (mounted) setState(() => _message = l10n.deleteAccountReauthFailed);
        return;
      }
      final result = await AccountDeletionService.deleteCurrentAccount();
      if (!mounted) return;
      if (result.completed) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      setState(() => _message = result.code == 'RECENT_AUTHENTICATION_REQUIRED'
          ? l10n.deleteAccountRecentAuthRequired
          : l10n.deleteAccountRetryRequired);
    } catch (_) {
      if (mounted) setState(() => _message = l10n.deleteAccountNetworkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyAndAccount)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            subtitle: Text(l10n.privacyPolicySubtitle),
            onTap: () => launchUrl(
                Uri.parse('https://mysmartcar.app/privacy-policy.html'),
                mode: LaunchMode.externalApplication),
          ),
          const Divider(),
          Text(l10n.deleteAccountTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(l10n.deleteAccountDeletes),
          const SizedBox(height: 12),
          Text(l10n.deleteAccountRetains),
          const SizedBox(height: 12),
          Text(l10n.deleteAccountIrreversible,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: _busy ? null : _deleteAccount,
            icon: _busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_forever),
            label: Text(_busy
                ? l10n.deleteAccountProcessing
                : l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
  }
}
