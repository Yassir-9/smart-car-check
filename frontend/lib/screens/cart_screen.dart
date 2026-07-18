import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const String baseUrl = 'https://car-ai-backend-7gpb.onrender.com/api';

  bool _isCheckingOut = false;
  String? _errorText;

  Future<void> _checkout() async {
    setState(() {
      _isCheckingOut = true;
      _errorText = null;
    });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final partIds = CartService.items.map((p) => p.id).toList();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/checkout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'partIds': partIds}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final checkoutUrl = data['checkoutUrl'];
        final uri = Uri.tryParse(checkoutUrl);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          CartService.clear();
          if (mounted) setState(() {});
        }
      } else {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() => _errorText = data['error'] ?? 'تعذر إنشاء عملية الدفع');
      }
    } catch (e) {
      setState(() => _errorText = 'تعذر الاتصال بالسيرفر');
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;
    return Scaffold(
      appBar: AppBar(title: const Text('سلة المشتريات')),
      body: items.isEmpty
          ? const Center(child: Text('السلة فاضية حالياً'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final part = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(part.partName),
                          subtitle: Text('${part.carBrand} ${part.carModel}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${part.price} ر.س',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32))),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () {
                                  CartService.remove(part.id);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('الإجمالي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${CartService.total.toStringAsFixed(0)} ر.س',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isCheckingOut ? null : _checkout,
                          child: _isCheckingOut
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('إتمام الشراء'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
