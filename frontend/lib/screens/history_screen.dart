import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String baseUrl =
      'https://car-ai-backend-7gpb.onrender.com';

  bool _isLoading = true;
  String? _errorText;
  List<dynamic> _items = [];
  String _selectedFilter = 'الكل';

  static const List<String> _filters = ['الكل', 'عالية', 'متوسطة', 'منخفضة'];

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
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
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

  List<dynamic> get _filteredItems {
    if (_selectedFilter == 'الكل') return _items;
    return _items.where((item) {
      final result = (item['result'] as Map?) ?? {};
      return result['severity'] == _selectedFilter;
    }).toList();
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
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/history/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final period = date.hour >= 12 ? 'م' : 'ص';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year} - $hour:$minute $period';
    } catch (e) {
      return isoDate;
    }
  }

  void _showDetails(Map item) {
    final result = (item['result'] as Map?) ?? {};
    final severity = result['severity'] as String?;
    final color = _severityColor(severity);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
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
                        result['possible_issue'] ?? '',
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
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('الخطورة: ${severity ?? "غير محددة"}',
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Text(result['explanation'] ?? '',
                    style: const TextStyle(fontSize: 14, height: 1.6)),
                if (result['recommendations'] != null) ...[
                  const SizedBox(height: 12),
                  const Text('التوصيات:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  ...List<String>.from(result['recommendations']).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF1E3A5F)),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(r,
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                ],
                if (result['estimated_cost'] != null &&
                    result['estimated_cost'] != 'null') ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            'التكلفة التقديرية: ${result['estimated_cost']}',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          final color = filter == 'الكل' ? const Color(0xFF1E3A5F) : _severityColor(filter);
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            selectedColor: color.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              color: isSelected ? color : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? color : Colors.grey.shade300,
            ),
            backgroundColor: Colors.transparent,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final noneAtAll = _items.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                  noneAtAll ? Icons.history_rounded : Icons.filter_alt_off_outlined,
                  size: 40, color: const Color(0xFF1E3A5F).withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 16),
            Text(
              noneAtAll
                  ? 'لا يوجد أي تشخيصات محفوظة بعد'
                  : 'لا يوجد تشخيصات بخطورة "$_selectedFilter"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map item) {
    final result = (item['result'] as Map?) ?? {};
    final severity = result['severity'] as String?;
    final color = _severityColor(severity);
    final id = item['id'].toString();
    final car = (item['car'] as Map?) ?? {};
    final carLabel = car.isNotEmpty
        ? '${car['brand'] ?? ''} ${car['model'] ?? ''} - ${car['year'] ?? ''}'
        : null;

    return InkWell(
      onTap: () => _showDetails(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
        child: Row(
          children: [
            Icon(_severityIcon(severity), color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['possible_issue'] ?? 'تشخيص بدون عنوان',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (carLabel != null)
                    Text(
                      carLabel,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(item['timestamp'] as String?),
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
    final filtered = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل التشخيصات'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_isLoading && _errorText == null && _items.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildFilterBar(),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHistory,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorText != null
                        ? ListView(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 80),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(_errorText!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14)),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : filtered.isEmpty
                            ? ListView(
                                children: [_buildEmptyState()],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildItemCard(filtered[index]),
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
