import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const String baseUrl =
      'https://car-ai-backend-7gpb.onrender.com/api';

  bool _isLoading = true;
  bool _isSubscribing = false;
  String? _errorText;
  bool _isActive = false;
  String? _plan;
  String? _currentPeriodEnd;
  int _freeUsageCount = 0;
  int _freeUsageLimit = 5;
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
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/subscription/status'),
        headers: {'Authorization': 'Bearer $token'},
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
        setState(() => _errorText = 'تعذر جلب حالة الاشتراك');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribe(String plan) async {
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
        },
        body: jsonEncode({'plan': plan}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final checkoutUrl = data['checkoutUrl'];
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        setState(() => _errorText = 'تعذر إنشاء عملية الدفع، حاول مرة أخرى');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
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
    const goldColor = Color(0xFFC9A876);
    const navyColor = Color(0xFF1E3A5F);

    return Scaffold(
      appBar: AppBar(title: const Text('الاشتراك')),
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
                          _isActive ? 'اشتراكك نشط' : 'افتح كامل إمكانيات التطبيق',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isActive
                              ? '${_plan == 'yearly' ? 'خطة سنوية' : 'خطة شهرية'} — ينتهي في ${_currentPeriodEnd != null ? _formatDate(_currentPeriodEnd!) : ''}'
                              : 'استخدمت $_freeUsageCount من $_freeUsageLimit تشخيصات مجانية هذا الشهر',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('مميزات الاشتراك',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _featureRow(Icons.all_inclusive, 'تشخيصات ذكاء اصطناعي غير محدودة',
                      'شخّص أي عدد من مشاكل سيارتك بدون حد شهري', goldColor),
                  _featureRow(Icons.support_agent, 'مساعد اسأل خبير السيارات',
                      'اسأل أي سؤال متابعة بعد كل تشخيص بدون حدود', goldColor),
                  _featureRow(Icons.picture_as_pdf_outlined, 'تقارير PDF احترافية',
                      'تقرير كامل برمز QR للتحقق، جاهز للطباعة أو المشاركة', goldColor),
                  _featureRow(Icons.support, 'أولوية بالدعم الفني',
                      'ردود أسرع على استفساراتك ومشاكلك التقنية', goldColor),
                  const SizedBox(height: 28),
                  if (!_isActive) ...[
                    const Text('اختر الباقة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 12),
                    _planCard(
                      plan: 'yearly',
                      title: 'سنوي',
                      price: '249',
                      subtitle: 'أفضل قيمة — يعادل 20.75 ر.س شهريًا',
                      badge: 'الأفضل قيمة',
                      goldColor: goldColor,
                    ),
                    const SizedBox(height: 10),
                    _planCard(
                      plan: 'monthly',
                      title: 'شهري',
                      price: '29',
                      subtitle: 'مرونة الإلغاء بأي وقت',
                      badge: null,
                      goldColor: goldColor,
                    ),
                    const SizedBox(height: 20),
                    if (_errorText != null) ...[
                      Text(_errorText!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
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
                            : const Text('اشترك الآن',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _featureRow(IconData icon, String title, String subtitle, Color accentColor) {
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: goldColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Text('$price ر.س',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}