import 'package:flutter/material.dart';

import 'app_design_system.dart';
import 'app_tokens.dart';

/// The unified theme. Light mode follows the approved palette; dark mode keeps
/// the existing dark theme (same font) so the theme switch keeps working.
class AppUiTheme {
  AppUiTheme._();

  static ThemeData dark() => AppTheme.dark();

  static RoundedRectangleBorder _shape(double r,
          {BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r), side: side);

  static OutlineInputBorder _field(Color c, [double w = 1]) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(Ui.rButton),
          borderSide: BorderSide(color: c, width: w));

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Ui.primary,
      brightness: Brightness.light,
      primary: Ui.primary,
      onPrimary: Colors.white,
      surface: Ui.card,
      onSurface: Ui.textPrimary,
      onSurfaceVariant: Ui.textSecondary,
      outline: Ui.border,
      error: Ui.dangerText,
    );
    const base = TextStyle(fontFamily: Ui.fontFamily);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: Ui.fontFamily,
      scaffoldBackgroundColor: Ui.screenBg,
      cardColor: Ui.card,
      dividerColor: Ui.border,
      visualDensity: VisualDensity.standard,
      textTheme: ThemeData.light().textTheme.apply(
            fontFamily: Ui.fontFamily,
            bodyColor: Ui.textPrimary,
            displayColor: Ui.textPrimary,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Ui.screenBg,
        foregroundColor: Ui.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontFamily: Ui.fontFamily,
            fontSize: Ui.screenTitle,
            fontWeight: FontWeight.w700,
            color: Ui.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: Ui.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: _shape(Ui.rCard, side: const BorderSide(color: Ui.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Ui.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: _shape(Ui.rButton),
          textStyle: base.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Ui.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: _shape(Ui.rButton),
          textStyle: base.copyWith(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Ui.primaryText,
          minimumSize: const Size(64, 44),
          side: const BorderSide(color: Ui.primary),
          shape: _shape(Ui.rButton),
          textStyle: base.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Ui.primaryText,
          minimumSize: const Size(48, 48),
          textStyle: base.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Ui.card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Ui.s16, vertical: Ui.s12),
        border: _field(Ui.border),
        enabledBorder: _field(Ui.border),
        focusedBorder: _field(Ui.primary, 1.5),
        errorBorder: _field(Ui.dangerText),
        focusedErrorBorder: _field(Ui.dangerText, 1.5),
        hintStyle: const TextStyle(color: Ui.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: Ui.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Ui.iconBg,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? Ui.primaryText
                : Ui.textSecondary)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: Ui.fontFamily,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected)
                ? Ui.primaryText
                : Ui.textSecondary)),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Ui.card,
        indicatorColor: Ui.iconBg,
        selectedIconTheme: IconThemeData(color: Ui.primaryText),
        unselectedIconTheme: IconThemeData(color: Ui.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Ui.darkCard,
        contentTextStyle: const TextStyle(
            fontFamily: Ui.fontFamily, color: Colors.white, fontSize: 14),
        shape: _shape(Ui.rButton),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Ui.primary, foregroundColor: Colors.white),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: Ui.primary),
      chipTheme: ChipThemeData(
        shape: _shape(Ui.rSmall),
        side: const BorderSide(color: Ui.border),
        labelStyle: const TextStyle(
            fontFamily: Ui.fontFamily, fontSize: 13, color: Ui.textPrimary),
      ),
    );
  }
}
