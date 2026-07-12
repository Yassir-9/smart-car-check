import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String baseUrl =
      'https://fuzzy-space-goldfish-vpp5vg9rjpvv2pgp6-3000.app.github.dev';

  bool _isLoading = true;
  String? _errorText;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/history'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() => _items = data is List ? data : (data['items'] ?? []));
      } else {
        setState(() => _errorText = 'خطأ من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف التشخيص'),
        content: const Text('هل تريد حذف هذا التشخيص من السجل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(Uri.parse('$baseUrl/api/history/$id'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => _items.removeWhere((e) => e['id'].toString() == id));
      } else {
        _showSnack('تعذر حذف العنصر');
      }
    } catch (e) {
      _showSnack('تعذر الاتصال بالسيرفر');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  void _showDetails(Map item) {
    final severity = item['severity'] as String?;
    final color = _severityColor(severity);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(_severityIcon(severity), color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['possible_issue'] ?? '',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('الخطورة: ${severity ?? "غير محددة"}',
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text(item['explanation'] ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.6)),
              if (item['recommendations'] != null) ...[
                const SizedBox(height: 12),
                const Text('التوصيات:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                ...List<String>.from(item['recommendations']).map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle,
                            size: 16, color: Color(0xFF1E3A5F)),
                        const SizedBox(width: 6),
                        Expanded(
                            child:
                                Text(r, style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_rounded,
                  size: 40, color: const Color(0xFF1E3A5F).withOpacity(0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد أي تشخيصات محفوظة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map item) {
    final severity = item['severity'] as String?;
    final color = _severityColor(severity);
    final id = item['id'].toString();

    return InkWell(
      onTap: () => _showDetails(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Row(
          children: [
            Icon(_severityIcon(severity), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['possible_issue'] ?? '',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['created_at'] ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => _deleteItem(id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التشخيصات'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorText != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    )
                  : _items.isEmpty
                      ? ListView(
                          children: [_buildEmptyState()],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) =>
                              _buildItemCard(_items[index]),
                        ),
        ),
      ),
    );
  }
}
