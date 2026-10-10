import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
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
  static String get baseUrl => '${ApiConfig.apiBaseUrl}/parts';

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
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      final query = <String, String>{};
      if (widget.initialBrand != null) query['brand'] = widget.initialBrand!;
      final uri = Uri.parse(baseUrl)
          .replace(queryParameters: query.isEmpty ? null : query);
      final response = await http.get(uri, headers: {'X-App-Locale': locale});
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          _parts = data
              .map((e) => PartListing.fromJson(e as Map<String, dynamic>))
              .toList();
        });
        _loadSellerRatings();
      } else {
        setState(
            () => _errorText = l10n.serverErrorStatus(response.statusCode));
      }
    } catch (e) {
      setState(() => _errorText = l10n.serverConnectionFailed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSellerRatings() async {
    final ownerIds = _parts.map((p) => p.ownerId).whereType<String>().toSet();
    for (final ownerId in ownerIds) {
      if (_sellerRatings.containsKey(ownerId)) continue;
      try {
        final response = await http.get(
          ApiConfig.apiUri('/sellers/$ownerId/rating'),
        );
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(utf8.decode(response.bodyBytes))
              as Map<String, dynamic>;
          setState(() => _sellerRatings[ownerId] = data);
        }
      } catch (e) {
        // تجاهل فشل تحميل تقييم بائع معيّن
      }
    }
  }

  Future<void> _showRateSellerDialog(String sellerId) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    int selectedStars = 0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.rateSeller),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        onPressed: () =>
                            setDialogState(() => selectedStars = i + 1),
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
                    decoration: InputDecoration(
                      hintText: l10n.commentOptional,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: selectedStars == 0
                      ? null
                      : () async {
                          try {
                            final token = await FirebaseAuth
                                .instance.currentUser
                                ?.getIdToken();
                            final response = await http.post(
                              ApiConfig.apiUri('/sellers/$sellerId/rating'),
                              headers: {
                                'Content-Type': 'application/json',
                                'Authorization': 'Bearer $token',
                                'X-App-Locale': locale,
                              },
                              body: jsonEncode({
                                'rating': selectedStars,
                                'comment': commentController.text.trim(),
                              }),
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            if (response.statusCode == 200) {
                              _sellerRatings.remove(sellerId);
                              _loadSellerRatings();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.ratingSubmitted)),
                                );
                              }
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          }
                        },
                  child: Text(l10n.send),
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

  Future<void> _contactSeller(PartListing part) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactSignInRequired)),
      );
      return;
    }
    try {
      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$baseUrl/${part.id}/contact'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final phone = data['sellerPhone'] as String?;
        if (phone != null && phone.isNotEmpty) {
          await launchUrl(
            Uri.parse('tel:$phone'),
            mode: LaunchMode.externalApplication,
          );
          return;
        }
      }
      final message = response.statusCode == 401
          ? l10n.contactSignInRequired
          : response.statusCode == 429
              ? l10n.sellerContactRateLimited
              : response.statusCode == 404
                  ? l10n.sellerContactUnavailable
                  : l10n.sellerContactFailed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.sellerContactFailed)),
      );
    }
  }

  Future<void> _editPart(PartListing part) async {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contactSignInRequired)),
      );
      return;
    }
    final token = await user.getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/${part.id}/private'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-App-Locale': locale,
      },
    );
    if (!mounted) return;
    if (response.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.serverErrorStatus(response.statusCode))),
      );
      return;
    }
    final privatePart = PartListing.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
    );
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (context) => AddPartScreen(existingPart: privatePart)),
    );
    if (updated == true) _loadParts();
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
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'X-App-Locale': locale,
        },
      );
      if (response.statusCode == 200) {
        _loadParts();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deletePartFailed)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.serverConnectionFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.marketplaceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: l10n.sellerDashboard,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SellerDashboardScreen()),
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
                    tooltip: l10n.cart,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartScreen()),
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
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text('$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
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
                hintText: l10n.searchPartsHint,
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
                        ? Center(child: Text(l10n.noPartsAvailable))
                        : RefreshIndicator(
                            onRefresh: _loadParts,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (part.condition != null)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    left: 6),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: part.condition ==
                                                          'جديدة'
                                                      ? const Color(0xFFC9A876)
                                                          .withValues(
                                                              alpha: 0.15)
                                                      : const Color(0xFF1E3A5F)
                                                          .withValues(
                                                              alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  part.condition == 'جديدة'
                                                      ? l10n.newPart
                                                      : l10n.usedPart,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: part.condition ==
                                                              'جديدة'
                                                          ? const Color(
                                                              0xFF8A6D3B)
                                                          : const Color(
                                                              0xFF1E3A5F)),
                                                ),
                                              ),
                                            Expanded(
                                              child: Text(
                                                part.partName,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                            if (part.price != null)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '${part.price} ${l10n.sarShort}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF1B5E20)),
                                                ),
                                              ),
                                            if (part.ownerId != null &&
                                                part.ownerId ==
                                                    FirebaseAuth.instance
                                                        .currentUser?.uid)
                                              IconButton(
                                                onPressed: () =>
                                                    _editPart(part),
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    color: Colors.blueGrey,
                                                    size: 20),
                                                tooltip: l10n.editPart,
                                              ),
                                            if (part.ownerId != null &&
                                                part.ownerId ==
                                                    FirebaseAuth.instance
                                                        .currentUser?.uid)
                                              IconButton(
                                                onPressed: () =>
                                                    _deletePart(part.id),
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.red,
                                                    size: 20),
                                                tooltip: l10n.deletePart,
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
                                          Text(
                                              l10n.partNumberLabel(
                                                  part.oemNumber!),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey)),
                                        ],
                                        if (part.partBrand != null &&
                                            part.partBrand!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                              l10n.partManufacturerLabel(
                                                  part.partBrand!),
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
                                        if (part.notes != null &&
                                            part.notes!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(part.notes!,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ],
                                        if (part.ownerId != null &&
                                            _sellerRatings[part.ownerId!]
                                                    ?['average'] !=
                                                null) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.star,
                                                  color: Color(0xFFC9A876),
                                                  size: 15),
                                              const SizedBox(width: 3),
                                              Text(
                                                l10n.sellerRating(
                                                    '${_sellerRatings[part.ownerId!]!['average']}',
                                                    _sellerRatings[part
                                                            .ownerId!]!['count']
                                                        as int),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () =>
                                                _contactSeller(part),
                                            icon: const Icon(
                                                Icons.call_outlined,
                                                size: 18),
                                            label: Text(l10n.contactSeller),
                                          ),
                                        ),
                                        if (part.price != null &&
                                            part.ownerId !=
                                                FirebaseAuth.instance
                                                    .currentUser?.uid) ...[
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  CartService.contains(part.id)
                                                      ? null
                                                      : () {
                                                          CartService.add(part);
                                                          setState(() {});
                                                        },
                                              icon: Icon(
                                                CartService.contains(part.id)
                                                    ? Icons.check
                                                    : Icons
                                                        .add_shopping_cart_outlined,
                                                size: 18,
                                              ),
                                              label: Text(
                                                  CartService.contains(part.id)
                                                      ? l10n.addedToCart
                                                      : l10n.addToCart),
                                            ),
                                          ),
                                        ],
                                        if (part.ownerId != null &&
                                            part.ownerId !=
                                                FirebaseAuth.instance
                                                    .currentUser?.uid) ...[
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _showRateSellerDialog(
                                                      part.ownerId!),
                                              icon: const Icon(
                                                  Icons.star_border,
                                                  size: 16),
                                              label: Text(l10n.rateThisSeller),
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
