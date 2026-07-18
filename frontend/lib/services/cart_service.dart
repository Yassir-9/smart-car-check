import 'package:flutter/foundation.dart';
import '../models/part_listing.dart';

class CartService {
  static final List<PartListing> _items = [];
  static final ValueNotifier<int> itemCount = ValueNotifier<int>(0);

  static List<PartListing> get items => List.unmodifiable(_items);

  static void add(PartListing part) {
    if (_items.any((p) => p.id == part.id)) return;
    _items.add(part);
    itemCount.value = _items.length;
  }

  static void remove(String partId) {
    _items.removeWhere((p) => p.id == partId);
    itemCount.value = _items.length;
  }

  static bool contains(String partId) {
    return _items.any((p) => p.id == partId);
  }

  static void clear() {
    _items.clear();
    itemCount.value = 0;
  }

  static double get total {
    double sum = 0;
    for (final item in _items) {
      sum += double.tryParse(item.price ?? '0') ?? 0;
    }
    return sum;
  }
}
