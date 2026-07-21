import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/car_model.dart';
import '../services/car_service.dart';
import '../services/diagnosis_session_service.dart';
import 'history_screen.dart';
import 'maintenance_screen.dart';
import 'cars_screen.dart';
import 'settings_screen.dart';
import 'parts_screen.dart';
import 'maintenance_history_screen.dart';
import 'obd_connect_screen.dart';
import 'dashboard_screen.dart';
import 'subscription_screen.dart';
import '../services/pdf_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  bool _feedbackSubmitted = false;
  bool _isSearchingParts = false;
  Map<String, dynamic>? _result;
  String? _errorText;

  CarModel? _activeCar;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedImage;
  String _selectedImageMimeType = 'image/jpeg';

  static const String backendUrl =
      'https://car-ai-backend-7gpb.onrender.com/api/diagnose';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadActiveCar();
    if (DiagnosisSessionService.hasSavedResult) {
      _result = DiagnosisSessionService.lastResult;
      _descriptionController.text = DiagnosisSessionService.lastDescription ?? '';
    }
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

  String _severityEmoji(String? severity) {
    switch (severity) {
      case 'عالية':
        return '🔴';
      case 'متوسطة':
        return '🟠';
      case 'منخفضة':
        return '🟢';
      default:
        return '⚪';
    }
  }

  void _resetForm() {
    setState(() {
      _descriptionController.clear();
      _result = null;
      _errorText = null;
      _feedbackSubmitted = false;
    });
    DiagnosisSessionService.clear();
  }

  Future<void> _searchPartsOnline() async {
    if (_result == null) return;
    setState(() => _isSearchingParts = true);
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(
        Uri.parse('https://car-ai-backend-7gpb.onrender.com/api/parts/external-search'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'query': _result!['possible_issue'],
          'car': {
            'brand': _activeCar?.brand,
            'model': _activeCar?.model,
            'year': _activeCar?.year,
          },
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _result!['external_search'] = data;
        });
        DiagnosisSessionService.save(_result!, _descriptionController.text.trim());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر البحث الآن، حاول مرة أخرى')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالسيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearchingParts = false);
    }
  }

  Future<void> _submitFeedback(bool accurate) async {
    final id = _result?['diagnosis_id'];
    if (id == null) return;
    setState(() => _feedbackSubmitted = true);
    try {
      await http.patch(
        Uri.parse(
            'https://car-ai-backend-7gpb.onrender.com/api/history/$id/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accurate': accurate}),
      );
    } catch (e) {
      // تجاهل فشل الإرسال، ما يهم تجربة المستخدم
    }
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

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('التقاط صورة'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('اختيار من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 70,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = bytes;
          _selectedImageMimeType = picked.mimeType ?? 'image/jpeg';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الوصول للكاميرا/المعرض')),
        );
      }
    }
  }

  Future<void> _submitDiagnosis() async {
    if ((_descriptionController.text.trim().isEmpty && _selectedImage == null) ||
        _activeCar == null) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _result = null;
      _errorText = null;
    });

    try {
      String? imageBase64;
      if (_selectedImage != null) {
        imageBase64 = base64Encode(_selectedImage!);
      }

      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'description': _descriptionController.text.trim(),
          'car': {
            'brand': _activeCar!.brand,
            'model': _activeCar!.model,
            'year': _activeCar!.year,
          },
          if (imageBase64 != null)
            'image': {
              'data': imageBase64,
              'media_type': _selectedImageMimeType,
            },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _result = data;
          _feedbackSubmitted = false;
        });
        DiagnosisSessionService.save(data, _descriptionController.text.trim());
      } else if (response.statusCode == 402) {
        setState(() => _errorText =
            'استنفدت عدد التشخيصات المجانية لهذا الشهر (5 تشخيصات). اشترك للاستمرار بدون حدود.');
      } else if (response.statusCode == 401) {
        setState(() =>
            _errorText = 'يرجى تسجيل الدخول مرة أخرى للمتابعة');
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
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تشخيص السيارة الذكي'),
          centerTitle: true,
          actions: [
            AnimatedBuilder(
              animation: _descriptionController,
              builder: (context, _) {
                final showReset = _result != null ||
                    _errorText != null ||
                    _descriptionController.text.isNotEmpty;
                if (!showReset) return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'بدء تشخيص جديد',
                  onPressed: _resetForm,
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(104),
            child: Container(
              color: const Color(0xFF1E3A5F),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                children: [
                    _buildNavItem(
                      icon: Icons.dashboard_outlined,
                      label: 'لوحة التحكم',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DashboardScreen()),
                        );
                      },
                    ),
                    if (_activeCar != null)
                      _buildNavItem(
                        icon: Icons.receipt_long_outlined,
                        label: 'سجل السيارة',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    MaintenanceHistoryScreen(
                                        car: _activeCar!)),
                          );
                        },
                      ),
                    _buildNavItem(
                      icon: Icons.build_circle_outlined,
                      label: 'الصيانة',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const MaintenanceScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.storefront_outlined,
                      label: 'قطع الغيار',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PartsScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.bluetooth,
                      label: 'OBD',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ObdConnectScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.history,
                      label: 'السجل',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'الاشتراك',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SubscriptionScreen()),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.settings_outlined,
                      label: 'الإعدادات',
                      onTap: _openSettingsScreen,
                    ),
                ],
              ),
            ),
          ),
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
                        ClipOval(
                          child: Image.asset(
                            'assets/icon/icon_mark.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
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
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
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
                const SizedBox(height: 12),
                if (_selectedImage != null)
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImage!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () =>
                                setState(() => _selectedImage = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('أضف صورة للمبة التحذير (اختياري)'),
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
                if (kIsWeb) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse("https://car-ai-backend-7gpb.onrender.com/download/app-release.apk");
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.android),
                      label: const Text("تحميل تطبيق أندرويد"),
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
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ],
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

  void _showAskExpertSheet() {
    final questionController = TextEditingController();
    String? answer;
    bool isAsking = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submitQuestion() async {
              if (questionController.text.trim().isEmpty || isAsking) return;
              setSheetState(() {
                isAsking = true;
                errorText = null;
                answer = null;
              });
              try {
                final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
                final response = await http.post(
                  Uri.parse('https://car-ai-backend-7gpb.onrender.com/api/ask-expert'),
                  headers: {
                    'Content-Type': 'application/json',
                    if (idToken != null) 'Authorization': 'Bearer $idToken',
                  },
                  body: jsonEncode({
                    'question': questionController.text.trim(),
                    'diagnosis': _result,
                    'car': {
                      'brand': _activeCar?.brand,
                      'model': _activeCar?.model,
                      'year': _activeCar?.year,
                    },
                  }),
                );
                if (response.statusCode == 200) {
                  final data = jsonDecode(utf8.decode(response.bodyBytes));
                  setSheetState(() {
                    answer = data['answer'];
                    isAsking = false;
                  });
                } else {
                  setSheetState(() {
                    errorText = 'تعذر الحصول على إجابة، حاول مرة أخرى';
                    isAsking = false;
                  });
                }
              } catch (e) {
                setSheetState(() {
                  errorText = 'تعذر الاتصال بالسيرفر';
                  isAsking = false;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.support_agent, color: Color(0xFF1E3A5F)),
                      const SizedBox(width: 8),
                      const Text('اسأل خبير السيارات الذكي',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: questionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'مثال: هل أستطيع السفر بالسيارة الآن؟',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isAsking ? null : submitQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A5F),
                        foregroundColor: Colors.white,
                      ),
                      child: isAsking
                          ? const SizedBox(
                              height: 18, width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('إرسال السؤال'),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  if (answer != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(answer!, style: const TextStyle(fontSize: 14, height: 1.6)),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
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
            child: Text('${_severityEmoji(severity)} الخطورة: ${severity ?? "غير محددة"}',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          if (_result!['confidence_score'] != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.psychology_outlined, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text('نسبة الثقة بالتشخيص: ${_result!['confidence_score']}%',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800])),
              ],
            ),
            if (_result!['confidence_reason'] != null) ...[
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.only(right: 22),
                child: Text(_result!['confidence_reason'],
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
              ),
            ],
          ],
          if (_result!['can_drive'] != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_result!['can_drive'],
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ),
                ],
              ),
            ),
          ],
          if (_result!['estimated_cost'] != null &&
              _result!['estimated_cost'] != 'null') ...[
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF66BB6A), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF66BB6A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_outlined,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('التكلفة التقديرية',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF2E7D32))),
                        const SizedBox(height: 2),
                        Text('${_result!['estimated_cost']}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

          if (_result!['matched_parts'] != null &&
              (_result!['matched_parts'] as List).isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('قطع غيار متوفرة لهذي المشكلة',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List<Map<String, dynamic>>.from(_result!['matched_parts']).map(
              (p) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBDEFB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['partName'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          if (p['price'] != null)
                            Text('${p['price']} ر.س',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final uri = Uri.parse('tel:${p['sellerPhone']}');
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      },
                      icon: const Icon(Icons.call_outlined,
                          color: Color(0xFF1E3A5F)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((_result!['matched_parts'] == null ||
                  (_result!['matched_parts'] as List).isEmpty) &&
              _result!['external_search'] == null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSearchingParts ? null : _searchPartsOnline,
                icon: _isSearchingParts
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.travel_explore, size: 18),
                label: Text(_isSearchingParts
                    ? 'جاري البحث...'
                    : 'ابحث عن القطعة أونلاين'),
              ),
            ),
          ],
          if (_result!['external_search'] != null &&
              _result!['external_search']['found'] == true) ...[
            const SizedBox(height: 14),
            const Text('🔍 نتائج بحث من الإنترنت',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...List<Map<String, dynamic>>.from(
                    _result!['external_search']['suggestions'] ?? [])
                .map(
              (s) {
                final hasUrl =
                    s['url'] != null && s['url'].toString().isNotEmpty && s['url'] != 'null';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: hasUrl
                          ? () async {
                              final uri = Uri.tryParse(s['url']);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            }
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC107),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront,
                                  size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  if (s['estimated_price'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text('${s['estimated_price']}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2E7D32))),
                                  ],
                                  if (s['store_name'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(s['store_name'],
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ],
                              ),
                            ),
                            if (hasUrl) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_outward,
                                  size: 18, color: Color(0xFF9E7B1F)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (_result!['external_search']['summary'] != null) ...[
              const SizedBox(height: 4),
              Text(_result!['external_search']['summary'],
                  style: const TextStyle(
                      fontSize: 12, fontStyle: FontStyle.italic)),
            ],
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PartsScreen(
                      initialBrand: _activeCar?.brand,
                      initialModel: _activeCar?.model,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.build_outlined, size: 18),
              label: const Text('ابحث عن قطعة الغيار المطلوبة'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAskExpertSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text('اسأل خبير السيارات الذكي'),
            ),
          ),
          if (_result!['diagnosis_id'] != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _feedbackSubmitted
                ? const Center(
                    child: Text('شكراً على تقييمك! 🙏',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  )
                : Column(
                    children: [
                      const Text('هل كان هذا التشخيص صحيحاً؟',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _submitFeedback(true),
                            icon: const Icon(Icons.thumb_up_outlined,
                                size: 16, color: Colors.green),
                            label: const Text('نعم، صحيح'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _submitFeedback(false),
                            icon: const Icon(Icons.thumb_down_outlined,
                                size: 16, color: Colors.red),
                            label: const Text('لا، غير دقيق'),
                          ),
                        ],
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }
}
