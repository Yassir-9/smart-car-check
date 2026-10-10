import 'package:flutter/material.dart';
import 'services/locale_service.dart';

class LocaleNotifier extends ValueNotifier<String> {
  final Future<String> Function() _loadLanguage;
  final Future<void> Function(String) _saveLanguage;
  late final Future<void> initialized;

  LocaleNotifier({
    Future<String> Function()? loadLanguage,
    Future<void> Function(String)? saveLanguage,
  })  : _loadLanguage = loadLanguage ?? LocaleService.getLanguage,
        _saveLanguage = saveLanguage ?? LocaleService.setLanguage,
        super('ar') {
    initialized = _load();
  }

  Future<void> _load() async {
    final stored = await _loadLanguage();
    value = stored == 'en' ? 'en' : 'ar';
  }

  Future<void> setLanguage(String code) async {
    final supported = code == 'en' ? 'en' : 'ar';
    value = supported;
    await _saveLanguage(supported);
  }
}

final localeNotifier = LocaleNotifier();
