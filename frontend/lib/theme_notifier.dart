import 'package:flutter/material.dart';
import 'services/theme_service.dart';

class ThemeNotifier extends ValueNotifier<bool> {
  ThemeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    value = await ThemeService.isDarkMode();
  }

  Future<void> toggle() async {
    value = !value;
    await ThemeService.setDarkMode(value);
  }
}

final themeNotifier = ThemeNotifier();
