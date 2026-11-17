/// Replaces Arabic-Indic (٠-٩) and Persian (۰-۹) digits with Western digits
/// (0-9) so numbers look the same everywhere in the app.
String westernDigits(String text) {
  final out = StringBuffer();
  for (final unit in text.runes) {
    if (unit >= 0x0660 && unit <= 0x0669) {
      out.writeCharCode(0x30 + unit - 0x0660);
    } else if (unit >= 0x06F0 && unit <= 0x06F9) {
      out.writeCharCode(0x30 + unit - 0x06F0);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

/// Western digits plus, for Arabic, the Arabic comma "،" instead of ",".
String localizedDateText(String text, String languageCode) {
  final digits = westernDigits(text);
  return languageCode == 'ar' ? digits.replaceAll(',', '،') : digits;
}
