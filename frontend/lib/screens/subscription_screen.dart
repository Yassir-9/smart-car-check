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
    return Scaffold(
      appBar: AppBar(
        title: const Text('الاشتراك'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث الحالة',
            onPressed: _isLoading ? null : _loadStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_errorText!,
                          style: const TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_isActive) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: const Color(0xFF66BB6A)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.verified,
                              color: Color(0xFF2E7D32), size: 40),
                          const SizedBox(height: 10),
                          Text(
                            _plan == 'yearly'
                                ? 'أنت مشترك بالباقة السنوية'
                                : 'أنت مشترك بالباقة الشهرية',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (_currentPeriodEnd != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'ينتهي في ${_formatDate(_currentPeriodEnd!)}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey),
                            ),
                          ],
                          const SizedBox(height: 6),
                          const Text('تشخيصات غير محدودة ✅',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'استخدمت $_freeUsageCount من $_freeUsageLimit تشخيصات مجانية هذا الشهر',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _freeUsageLimit == 0
                                  ? 0
                                  : (_freeUsageCount / _freeUsageLimit)
                                      .clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE0E0E0),
                              color: _freeUsageCount >= _freeUsageLimit
                                  ? Colors.red
                                  : const Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('اشترك لتشخيصات غير محدودة',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    _buildPlanCard(
                      title: 'شهري',
                      price: '29 ريال / شهر',
                      badge: null,
                      onTap: () => _subscribe('monthly'),
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      title: 'سنوي',
                      price: '249 ريال / سنة',
                      badge: 'وفّر 28%',
                      onTap: () => _subscribe('yearly'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBBDEFB)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isSubscribing ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(badge,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(price,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                _isSubscribing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
