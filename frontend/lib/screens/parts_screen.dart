import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/part_listing.dart';
import 'add_part_screen.dart';
import '../services/cart_service.dart';
import 'cart_screen.dart';
import 'seller_dashboard_screen.dart';

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
  final Map<String, Map<String, dynamic>> _sellerRatings = {};

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
        _loadSellerRatings();
      } else {
        setState(() => _errorText = 'خطأ من السيرفر: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSellerRatings() async {
    final ownerIds = _parts
        .map((p) => p.ownerId)
        .whereType<String>()
        .toSet();
    for (final ownerId in ownerIds) {
      if (_sellerRatings.containsKey(ownerId)) continue;
      try {
        final response = await http.get(
          Uri.parse('https://car-ai-backend-7gpb.onrender.com/api/sellers/$ownerId/rating'),
        );
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
          setState(() => _sellerRatings[ownerId] = data);
        }
      } catch (e) {
        // تجاهل فشل تحميل تقييم بائع معيّن
      }
    }
  }

  Future<void> _showRateSellerDialog(String sellerId) async {
    int selectedStars = 0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('قيّم البائع'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedStars = i + 1),
                        icon: Icon(
                          i < selectedStars ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFA000),
                          size: 28,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: commentController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'تعليق (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: selectedStars == 0
                      ? null
                      : () async {
                          try {
                            final token = await FirebaseAuth.instance.currentUser?.getIdToken();
                            final response = await http.post(
                              Uri.parse(
                                  'https://car-ai-backend-7gpb.onrender.com/api/sellers/$sellerId/rating'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $token',
                              },
                              body: jsonEncode({
                                'rating': selectedStars,
                                'comment': commentController.text.trim(),
                              }),
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (response.statusCode == 200) {
                              _sellerRatings.remove(sellerId);
                              _loadSellerRatings();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إرسال تقييمك، شكراً 🙏')),
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('إرسال'),
                ),
              ],
            );
          },
        );
      },
    );
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
      appBar: AppBar(
        title: const Text('سوق قطع الغيار'),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'لوحة تحكم البائع',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
              );
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: CartService.itemCount,
            builder: (context, count, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    tooltip: 'السلة',
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                      setState(() {});
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
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
                                            if (part.condition != null)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: part.condition == 'جديدة'
                                                      ? const Color(0xFFC9A876).withValues(alpha: 0.15)
                                                      : const Color(0xFF1E3A5F).withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  part.condition!,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: part.condition == 'جديدة'
                                                          ? const Color(0xFF8A6D3B)
                                                          : const Color(0xFF1E3A5F)),
                                                ),
                                              ),
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
                                        if (part.partBrand != null &&
                                            part.partBrand!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text('الشركة المصنّعة: ${part.partBrand}',
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
                                        if (part.ownerId != null &&
                                            _sellerRatings[part.ownerId!]?['average'] != null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.star, color: Color(0xFFC9A876), size: 15),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${_sellerRatings[part.ownerId!]!['average']} '
                                                '(${_sellerRatings[part.ownerId!]!['count']} تقييم)',
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ],
                                          ),
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
                                        if (part.price != null &&
                                            part.ownerId != FirebaseAuth.instance.currentUser?.uid) ...[
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: CartService.contains(part.id)
                                                  ? null
                                                  : () {
                                                      CartService.add(part);
                                                      setState(() {});
                                                    },
                                              icon: Icon(
                                                CartService.contains(part.id)
                                                    ? Icons.check
                                                    : Icons.add_shopping_cart_outlined,
                                                size: 18,
                                              ),
                                              label: Text(
                                                  CartService.contains(part.id) ? 'مضافة للسلة' : 'أضف للسلة'),
                                            ),
                                          ),
                                        ],
                                        if (part.ownerId != null &&
                                            part.ownerId != FirebaseAuth.instance.currentUser?.uid) ...[
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            child: TextButton.icon(
                                              onPressed: () => _showRateSellerDialog(part.ownerId!),
                                              icon: const Icon(Icons.star_border, size: 16),
                                              label: const Text('قيّم هذا البائع'),
                                            ),
                                          ),
                                        ],
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
