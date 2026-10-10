import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../config/pricing.dart';
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  bool _isLoading = true;
  bool _isSubscribing = false;
  String? _errorText;
  bool _isActive = false;
  String? _plan;
  String? _currentPeriodEnd;
  int _freeUsageCount = 0;
  int _freeUsageLimit = AppPricing.freeDiagnosesPerMonth;
  String _selectedPlan = 'yearly';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<String?> _getToken() async {
    return FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Future<void> _loadStatus() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _isActive = data['isActive'] ?? false;
          _plan = data['plan'];
          _currentPeriodEnd = data['currentPeriodEnd'];
          _freeUsageCount = data['freeUsageCount'] ?? 0;
          _freeUsageLimit = data['freeUsageLimit'] ?? 5;
        });
      } else {
        setState(() => _errorText = l10n.subscriptionStatusLoadFailed);
      }
    } catch (e) {
      setState(() => _errorText = l10n.serverConnectionFailed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribe(String plan) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _isSubscribing = true;
      _errorText = null;
    });
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/subscribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
        body: jsonEncode({
          'plan': plan,
          'locale': locale,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final checkoutUrl = data['checkoutUrl'];
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        setState(() => _errorText = l10n.paymentCreationFailed);
      }
    } catch (e) {
      setState(() => _errorText = l10n.serverConnectionFailed);
    } finally {
      setState(() => _isSubscribing = false);
    }
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const goldColor = Color(0xFFC9A876);
    const navyColor = Color(0xFF1E3A5F);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscription)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: navyColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isActive
                              ? Icons.workspace_premium
                              : Icons.workspace_premium_outlined,
                          color: goldColor,
                          size: 40,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isActive
                              ? l10n.subscriptionActive
                              : l10n.unlockFullApp,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isActive
                              ? l10n.subscriptionEndsOn(
                                  _plan == 'yearly'
                                      ? l10n.yearlyPlan
                                      : l10n.monthlyPlan,
                                  _currentPeriodEnd != null
                                      ? _formatDate(_currentPeriodEnd!)
                                      : '')
                              : l10n.freeUsageStatus(
                                  _freeUsageCount, _freeUsageLimit),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.subscriptionBenefits,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _featureRow(Icons.all_inclusive, l10n.unlimitedAiDiagnoses,
                      l10n.unlimitedAiDiagnosesDescription, goldColor),
                  _featureRow(Icons.support_agent, l10n.expertAssistant,
                      l10n.expertAssistantDescription, goldColor),
                  _featureRow(
                      Icons.picture_as_pdf_outlined,
                      l10n.professionalPdfReports,
                      l10n.professionalPdfReportsDescription,
                      goldColor),
                  _featureRow(Icons.support, l10n.prioritySupport,
                      l10n.prioritySupportDescription, goldColor),
                  const SizedBox(height: 28),
                  if (!_isActive) ...[
                    Text(l10n.choosePlan,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _planCard(
                      plan: 'yearly',
                      title: l10n.yearly,
                      price: AppPricing.plusYearly,
                      subtitle: l10n.yearlyValue,
                      badge: l10n.bestValue,
                      goldColor: goldColor,
                    ),
                    const SizedBox(height: 10),
                    _planCard(
                      plan: 'monthly',
                      title: l10n.monthly,
                      price: AppPricing.plusMonthly,
                      subtitle: l10n.monthlyFlexibility,
                      badge: null,
                      goldColor: goldColor,
                    ),
                    const SizedBox(height: 20),
                    if (_errorText != null) ...[
                      Text(_errorText!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubscribing
                            ? null
                            : () => _subscribe(_selectedPlan),
                        child: _isSubscribing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(l10n.subscribeNow,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else if (_errorText != null) ...[
                    Text(_errorText!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _featureRow(
      IconData icon, String title, String subtitle, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required String plan,
    required String title,
    required String price,
    required String subtitle,
    required String? badge,
    required Color goldColor,
  }) {
    final isSelected = _selectedPlan == plan;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? goldColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? goldColor.withValues(alpha: 0.08) : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? goldColor : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: goldColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Text('$price ${AppLocalizations.of(context).sarShort}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
