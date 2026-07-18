import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/part_listing.dart';
import 'add_part_screen.dart';

class PartsScreen extends StatefulWidget {
  final String? initialBrand;
  final String? initialModel;

  const PartsScreen({super.key, this.initialBrand, this.initialModel});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> {
  static const String baseUrl =
      'https://car-ai-backend-7gpb.onrender.com/api/parts';

  List<PartListing> _parts = [];
  bool _isLoading = true;
  String? _errorText;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialModel != null) {
      _searchController.text = widget.initialModel!;
    }
    _loadParts();
  }

  Future<void> _loadParts() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final query = <String, String>{};
      if (widget.initialBrand != null) query['brand'] = widget.initialBrand!;
      final uri = Uri.parse(baseUrl).replace(queryParameters: query.isEmpty ? null : query);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          _parts = data
              .map((e) => PartListing.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } else {
        setState(() => _errorText = 'خطأ من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<PartListing> get _filteredParts {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _parts;
    return _parts.where((p) {
      return p.partName.contains(query) || p.carModel.contains(query);
    }).toList();
  }

  Future<void> _callSeller(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _editPart(part) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddPartScreen(existingPart: part)),
    );
    if (updated == true) _loadParts();
  }

  Future<void> _deletePart(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تبي تحذف هذي القطعة نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        _loadParts();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر حذف القطعة')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالسيرفر')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سوق قطع الغيار')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث باسم القطعة أو الموديل',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorText != null
                    ? Center(child: Text(_errorText!))
                    : _filteredParts.isEmpty
                        ? const Center(child: Text('لا توجد قطع متاحة حالياً'))
                        : RefreshIndicator(
                            onRefresh: _loadParts,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _filteredParts.length,
                              itemBuilder: (context, index) {
                                final part = _filteredParts[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                part.partName,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (part.price != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${part.price} ر.س',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1B5E20)),
                                                ),
                                              ),
                                            if (part.ownerId == null ||
                                                part.ownerId ==
                                                    FirebaseAuth.instance.currentUser?.uid)
                                              IconButton(
                                                onPressed: () => _editPart(part),
                                                icon: const Icon(Icons.edit_outlined,
                                                    color: Colors.blueGrey, size: 20),
                                                tooltip: 'تعديل القطعة',
                                              ),
                                            if (part.ownerId == null ||
                                                part.ownerId ==
FirebaseAuth.instance.currentUser?.uid)
                                              IconButton(
                                                onPressed: () => _deletePart(part.id),
                                                icon: const Icon(Icons.delete_outline,
                                                    color: Colors.red, size: 20),
                                                tooltip: 'حذف القطعة',
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${part.carBrand} ${part.carModel}',
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.grey),
                                        ),
                                        if (part.oemNumber != null &&
                                            part.oemNumber!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text('رقم القطعة: ${part.oemNumber}',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey)),
                                        ],
                                        if (part.imageBase64 != null) ...[
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.memory(
                                              base64Decode(part.imageBase64!),
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ],
                                        if (part.notes != null && part.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(part.notes!,
                                              style: const TextStyle(fontSize: 13)),
                                        ],
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () => _callSeller(part.sellerPhone),
                                            icon: const Icon(Icons.call_outlined, size: 18),
                                            label: Text('اتصال: ${part.sellerPhone}'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const AddPartScreen()),
          );
          if (added == true) _loadParts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
