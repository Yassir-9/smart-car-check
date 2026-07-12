import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _errorText;

  // بيانات السيارة القابلة للتعديل
  String _carBrand = 'تويوتا';
  String _carModel = 'كامري';
  int _carYear = 2022;

  static const String backendUrl =
      'https://fuzzy-space-goldfish-vpp5vg9rjpvv2pgp6-3000.app.github.dev/api/diagnose';

  Color _severityColor(String? severity) {
    switch (severity) {
      case 'عالية':
        return const Color(0xFFD32F2F);
      case 'متوسطة':
        return const Color(0xFFF57C00);
      case 'منخفضة':
        return const Color(0xFF388E3C);
      default:
        return Colors.grey;
    }
  }

  IconData _severityIcon(String? severity) {
    switch (severity) {
      case 'عالية':
        return Icons.dangerous_outlined;
      case 'متوسطة':
        return Icons.warning_amber_rounded;
      case 'منخفضة':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _editCarDetails() async {
    final brandController = TextEditingController(text: _carBrand);
    final modelController = TextEditingController(text: _carModel);
    final yearController = TextEditingController(text: _carYear.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('بيانات سيارتك'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: brandController,
              decoration: const InputDecoration(labelText: 'الشركة المصنعة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'الموديل'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'سنة الصنع'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _carBrand = brandController.text.trim().isEmpty
                    ? _carBrand
                    : brandController.text.trim();
                _carModel = modelController.text.trim().isEmpty
                    ? _carModel
                    : modelController.text.trim();
                _carYear =
                    int.tryParse(yearController.text.trim()) ?? _carYear;
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDiagnosis() async {
    if (_descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
      _errorText = null;
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descriptionController.text.trim(),
          'car': {
            'brand': _carBrand,
            'model': _carModel,
            'year': _carYear,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() => _result = data);
      } else {
        setState(() => _errorText = 'خطأ من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تشخيص السيارة الذكي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة السيارة القابلة للضغط للتعديل
            InkWell(
              onTap: _editCarDetails,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car_filled,
                          color: Color(0xFF1E3A5F)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('سيارتك الحالية',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('$_carBrand $_carModel - $_carYear',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('اوصف المشكلة',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'مثال: صوت طقطقة عند الدوران يمين',
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitDiagnosis,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? 'جاري التحليل...' : 'شخّص المشكلة'),
              ),
            ),
            const SizedBox(height: 24),

            if (_errorText != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorText!)),
                  ],
                ),
              ),

            if (_result != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final severity = _result!['severity'] as String?;
    final color = _severityColor(severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_severityIcon(severity), color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _result!['possible_issue'] ?? '',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('الخطورة: ${severity ?? "غير محددة"}',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Text(_result!['explanation'] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.6)),
          if (_result!['recommendations'] != null) ...[
            const SizedBox(height: 12),
            const Text('التوصيات:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            ...List<String>.from(_result!['recommendations']).map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF1E3A5F)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
          if (_result!['estimated_cost'] != null &&
              _result!['estimated_cost'] != 'null') ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('التكلفة التقديرية: ${_result!['estimated_cost']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}