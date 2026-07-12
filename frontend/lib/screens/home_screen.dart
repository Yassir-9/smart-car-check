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
  String? _resultText;
  String? _errorText;

  static const String backendUrl =
      'https://fuzzy-space-goldfish-vpp5vg9rjpvv2pgp6-3000.app.github.dev/api/diagnose';

  Future<void> _submitDiagnosis() async {
    if (_descriptionController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _resultText = null;
      _errorText = null;
    });

    try {
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'description': _descriptionController.text.trim(),
          'car': {'brand': 'تويوتا', 'model': 'كامري', 'year': 2022},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _resultText =
              '${data['possible_issue']}\n\nالخطورة: ${data['severity']}\n\n${data['explanation']}';
        });
      } else {
        setState(() {
          _errorText = 'خطأ من السيرفر: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'تعذر الاتصال بالسيرفر: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تشخيص السيارة الذكي')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'اوصف المشكلة',
                hintText: 'مثال: صوت طقطقة عند الدوران يمين',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitDiagnosis,
              child: Text(_isLoading ? 'جاري التحليل...' : 'شخّص المشكلة'),
            ),
            const SizedBox(height: 24),
            if (_errorText != null)
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            if (_resultText != null) Text(_resultText!),
          ],
        ),
      ),
    );
  }
}