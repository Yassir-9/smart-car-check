import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import 'history_screen.dart';
import 'cars_screen.dart';
import 'settings_screen.dart';
import '../services/pdf_service.dart';

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

  CarModel? _activeCar;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  static const String backendUrl =
      'https://car-ai-backend-7gpb.onrender.com/api/diagnose';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadActiveCar();
  }

  Future<void> _loadActiveCar() async {
    final cars = await CarService.loadCars();
    final activeId = await CarService.getActiveCarId();
    final car = cars.firstWhere(
      (c) => c.id == activeId,
      orElse: () => cars.first,
    );
    setState(() => _activeCar = car);
  }

  Future<void> _openCarsScreen() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CarsScreen()),
    );
    if (changed == true) {
      _loadActiveCar();
    }
  }

  Future<void> _openSettingsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    _loadActiveCar();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      setState(() {
        _errorText = 'الميكروفون غير متاح. تأكد من إعطاء صلاحية الوصول للمتصفح.';
      });
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _errorText = null;
      });
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _descriptionController.text = result.recognizedWords;
          });
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: 'ar-SA',
          partialResults: true,
        ),
      );
    }
  }

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

  void _resetForm() {
    setState(() {
      _descriptionController.clear();
      _result = null;
      _errorText = null;
    });
  }

  Future<void> _exportPdf() async {
    if (_result == null) return;
    await PdfService.shareDiagnosisPdf(
      result: _result!,
      car: _activeCar,
      description: _descriptionController.text.trim(),
    );
  }

  void _shareResult() {
    if (_result == null) return;
    final severity = _result!['severity'] ?? 'غير محددة';
    final issue = _result!['possible_issue'] ?? '';
    final explanation = _result!['explanation'] ?? '';
    final recommendations = _result!['recommendations'] != null
        ? List<String>.from(_result!['recommendations'])
        : <String>[];
    final cost = _result!['estimated_cost'];

    final buffer = StringBuffer();
    buffer.writeln('🚗 تشخيص السيارة الذكي');
    buffer.writeln('السيارة: ${_activeCar?.label ?? ""}');
    buffer.writeln();
    buffer.writeln('⚠️ المشكلة المحتملة: $issue');
    buffer.writeln('درجة الخطورة: $severity');
    buffer.writeln();
    buffer.writeln('التفسير:');
    buffer.writeln(explanation);
    if (recommendations.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('التوصيات:');
      for (final r in recommendations) {
        buffer.writeln('• $r');
      }
    }
    if (cost != null && cost != 'null') {
      buffer.writeln();
      buffer.writeln('التكلفة التقديرية: $cost');
    }
    buffer.writeln();
    buffer.writeln('تشخيص أولي توجيهي بالذكاء الاصطناعي، وليس بديلاً عن فحص فني معتمد.');

    SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  Future<void> _submitDiagnosis() async {
    if (_descriptionController.text.trim().isEmpty || _activeCar == null) return;
    FocusScope.of(context).unfocus();

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
            'brand': _activeCar!.brand,
            'model': _activeCar!.model,
            'year': _activeCar!.year,
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
    final hasContent = _result != null || _errorText != null ||
        _descriptionController.text.isNotEmpty;
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تشخيص السيارة الذكي'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'الإعدادات',
              onPressed: _openSettingsScreen,
            ),
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'سجل التشخيصات',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            if (hasContent)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'بدء تشخيص جديد',
                onPressed: _resetForm,
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A5F), Color(0xFF3B6EA5)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A5F).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.directions_car_filled_rounded,
                            size: 48, color: Colors.white),
                        Positioned(
                          bottom: 8,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded,
                                size: 16, color: Color(0xFFF57C00)),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.build_rounded,
                                size: 14, color: Color(0xFF1E3A5F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: _openCarsScreen,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
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
                            color: const Color(0xFF1E3A5F).withValues(alpha: 0.1),
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                              Text(
                                _activeCar?.label ?? 'اضغط لاختيار سيارة',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.swap_horiz_rounded,
                            size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text('اوصف المشكلة',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'مثال: صوت طقطقة عند الدوران يمين',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF1E3A5F),
                      ),
                      onPressed: _toggleListening,
                      tooltip: _isListening ? 'إيقاف التسجيل' : 'تسجيل صوتي',
                    ),
                  ),
                ),
                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFD32F2F)),
                        ),
                        const SizedBox(width: 8),
                        Text('جاري الاستماع...',
                            style: TextStyle(
                                fontSize: 12, color: Colors.red.shade400)),
                      ],
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
                    label:
                        Text(_isLoading ? 'جاري التحليل...' : 'شخّص المشكلة'),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'تشخيص أولي توجيهي بالذكاء الاصطناعي، وليس بديلاً عن فحص فني معتمد',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
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

                if (_result != null)
                  _buildResultCard()
                else if (!_isLoading && _errorText == null)
                  _buildEmptyState(),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse("app-release.apk");
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.android),
                    label: const Text("تحميل تطبيق أندرويد (نسخة تجريبية)"),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "نسخة iOS قريباً بإذن الله",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_rounded,
                size: 40, color: const Color(0xFF1E3A5F).withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            'اكتب وصف المشكلة أعلاه وسنساعدك بتشخيص أولي',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final severity = _result!['severity'] as String?;
    final color = _severityColor(severity);
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Color(0xFF1E3A5F)),
                tooltip: 'مشاركة التشخيص',
                onPressed: _shareResult,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF1E3A5F)),
                tooltip: 'تصدير PDF',
                onPressed: _exportPdf,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                    Expanded(
                        child: Text(r, style: const TextStyle(fontSize: 13))),
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
                const Icon(Icons.payments_outlined,
                    size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text('التكلفة التقديرية: ${_result!['estimated_cost']}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse("app-release.apk");
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.android),
                    label: const Text("تحميل تطبيق أندرويد (نسخة تجريبية)"),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "نسخة iOS قريباً بإذن الله",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
