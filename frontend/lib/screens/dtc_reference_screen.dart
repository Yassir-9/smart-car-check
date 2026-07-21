import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DtcReferenceScreen extends StatefulWidget {
  const DtcReferenceScreen({super.key});

  @override
  State<DtcReferenceScreen> createState() => _DtcReferenceScreenState();
}

class _DtcReferenceScreenState extends State<DtcReferenceScreen> {
  Map<String, dynamic> _codes = {};
  bool _isLoading = true;
  String? _errorText;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  Future<void> _loadCodes() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/obd_codes.json');
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      setState(() {
        _codes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = 'تعذر تحميل دليل الأكواد';
        _isLoading = false;
      });
    }
  }

  List<MapEntry<String, dynamic>> get _filteredCodes {
    final query = _searchController.text.trim();
    final entries = _codes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    if (query.isEmpty) return entries;
    final lowerQuery = query.toLowerCase();
    return entries.where((e) {
      final code = e.key.toLowerCase();
      final title = (e.value['title_ar'] ?? '').toString();
      return code.contains(lowerQuery) || title.contains(query);
    }).toList();
  }

  Color _codeColor(String code) {
    if (code.startsWith('P')) return const Color(0xFF1E3A5F);
    if (code.startsWith('B')) return const Color(0xFF7B1FA2);
    if (code.startsWith('C')) return const Color(0xFFC9772E);
    if (code.startsWith('U')) return const Color(0xFF2D6A4F);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دليل أكواد الأعطال')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث بالكود (مثال: P0301) أو بالوصف',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_isLoading && _errorText == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${_filteredCodes.length} من ${_codes.length} كود',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorText != null
                    ? Center(child: Text(_errorText!))
                    : _filteredCodes.isEmpty
                        ? const Center(child: Text('ما فيه نتائج مطابقة'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _filteredCodes.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredCodes[index];
                              final color = _codeColor(entry.key);
                              final causes = List<String>.from(
                                  entry.value['common_causes'] ?? []);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(entry.key,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                            fontFamily: 'monospace')),
                                  ),
                                  title: Text(entry.value['title_ar'] ?? '',
                                      style: const TextStyle(fontSize: 13)),
                                  children: [
                                    if (causes.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 16, right: 16, bottom: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('الأسباب الشائعة:',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12)),
                                            const SizedBox(height: 6),
                                            ...causes.map((c) => Padding(
                                                  padding: const EdgeInsets
                                                      .only(bottom: 4),
                                                  child: Text('•  $c',
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                )),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
