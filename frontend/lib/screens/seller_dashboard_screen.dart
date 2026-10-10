import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../models/part_listing.dart';
import 'add_part_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  bool _isLoading = true;
  String? _errorText;
  List<PartListing> _myParts = [];
  List<Map<String, dynamic>> _myOrders = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();

      final partsResponse = await http.get(
        Uri.parse('$baseUrl/parts/mine'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
      );
      final ordersResponse = await http.get(
        Uri.parse('$baseUrl/orders/selling'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
      );

      List<PartListing> myParts = [];
      if (partsResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(partsResponse.bodyBytes)) as List;
        myParts = data
            .map((e) => PartListing.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      List<Map<String, dynamic>> myOrders = [];
      if (ordersResponse.statusCode == 200) {
        final data = jsonDecode(utf8.decode(ordersResponse.bodyBytes)) as List;
        myOrders = data.cast<Map<String, dynamic>>();
      }

      if (!mounted) return;
      setState(() {
        _myParts = myParts;
        _myOrders = myOrders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = l10n.sellerDashboardLoadFailed;
        _isLoading = false;
      });
    }
  }

  double get _myRevenue {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    double sum = 0;
    for (final order in _myOrders) {
      final items = (order['items'] as List?) ?? [];
      for (final item in items) {
        if (item['sellerId'] == uid) {
          sum += (item['price'] as num?)?.toDouble() ?? 0;
        }
      }
    }
    return sum;
  }

  Future<void> _deletePart(String id) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteConfirmation),
        content: Text(l10n.deletePartConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  Text(l10n.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/parts/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
      );
      if (response.statusCode == 200) _loadAll();
    } catch (e) {
      // تجاهل
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sellerDashboard),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText != null
              ? Center(child: Text(_errorText!))
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: _statCard(
                                  l10n.myListings,
                                  '${_myParts.length}',
                                  Icons.inventory_2_outlined,
                                  const Color(0xFF1E3A5F))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _statCard(
                                  l10n.soldOrders,
                                  '${_myOrders.length}',
                                  Icons.receipt_long_outlined,
                                  const Color(0xFFF57C00))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: _statCard(
                                  l10n.totalRevenue,
                                  '${_myRevenue.toStringAsFixed(0)} ${l10n.sarShort}',
                                  Icons.payments_outlined,
                                  const Color(0xFF388E3C))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.listedProducts,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      if (_myParts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.noListings,
                              style: const TextStyle(color: Colors.grey)),
                        )
                      else
                        ..._myParts.map((part) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(part.partName),
                                subtitle: Text(
                                    '${part.carBrand} ${part.carModel}'
                                    '${part.price != null ? ' - ${part.price} ${l10n.sarShort}' : ''}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 20),
                                      onPressed: () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AddPartScreen(
                                                      existingPart: part)),
                                        );
                                        if (updated == true) _loadAll();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 20),
                                      onPressed: () => _deletePart(part.id),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      const SizedBox(height: 20),
                      Text(l10n.mySalesOrders,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      if (_myOrders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.noSalesOrders,
                              style: const TextStyle(color: Colors.grey)),
                        )
                      else
                        ..._myOrders.map((order) {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          final items = (order['items'] as List?) ?? [];
                          final myItems =
                              items.where((i) => i['sellerId'] == uid).toList();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: myItems
                                    .map((i) => Text(
                                        '${i['partName']} - ${i['price']} ${l10n.sarShort}',
                                        style: const TextStyle(fontSize: 13)))
                                    .toList(),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
