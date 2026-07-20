import 'package:flutter/material.dart';
import 'services/locale_service.dart';

class LocaleNotifier extends ValueNotifier<String> {
  LocaleNotifier() : super('ar') {
    _load();
  }

  Future<void> _load() async {
    value = await LocaleService.getLanguage();
  }

  Future<void> setLanguage(String code) async {
    value = code;
    await LocaleService.setLanguage(code);
  }
}

final localeNotifier = LocaleNotifier();
