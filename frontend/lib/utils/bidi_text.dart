import 'package:flutter/widgets.dart';

/// First Strong Isolate / Pop Directional Isolate (Unicode bidi isolates).
const String fsi = '\u2068';
const String pdi = '\u2069';

// A run of Latin text: starts and ends with a letter/digit and may contain spaces and
// the usual joiners in part names ("Bar Links/Bushings", "ABS-sensor", "O2 sensor").
final RegExp _latinRun =
    RegExp(r"[A-Za-z0-9](?:[A-Za-z0-9 ._/&+#%:'\-]*[A-Za-z0-9])?");
final RegExp _hasLatinLetter = RegExp(r'[A-Za-z]');

/// Wraps every Latin-script run in FSI…PDI so brackets and neighbouring Arabic words keep
/// their order next to English technical terms, e.g. «(Sway Bar Links/Bushings)».
/// Pure numbers are left alone. Idempotent: existing isolates are removed first.
String isolateLatinRuns(String text) {
  if (text.isEmpty) return text;
  final clean = text.replaceAll(fsi, '').replaceAll(pdi, '');
  return clean.replaceAllMapped(_latinRun, (match) {
    final run = match[0]!;
    return _hasLatinLetter.hasMatch(run) ? '$fsi$run$pdi' : run;
  });
}

/// Text that comes from the AI and may mix Arabic and English. Isolation is only
/// needed (and only applied) when the surrounding text direction is right-to-left.
String bidiText(BuildContext context, String text) =>
    Directionality.of(context) == TextDirection.rtl
        ? isolateLatinRuns(text)
        : text;
