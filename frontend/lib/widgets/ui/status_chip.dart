import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

enum StatusLevel { ok, warn, danger, neutral }

/// Text colour / background pairs of each level (all pairs are >= 4.5:1).
({Color text, Color bg}) statusColors(StatusLevel level) => switch (level) {
      StatusLevel.neutral => (text: Ui.neutralText, bg: Ui.neutralBg),
      StatusLevel.ok => (text: Ui.okText, bg: Ui.okBg),
      StatusLevel.warn => (text: Ui.warnText, bg: Ui.warnBg),
      StatusLevel.danger => (text: Ui.dangerText, bg: Ui.dangerBg),
    };

/// A pill that always carries a text label (never colour alone). The icon is
/// decorative and only reinforces the label.
class StatusChip extends StatelessWidget {
  const StatusChip(
      {super.key, required this.label, required this.level, this.icon});

  final String label;
  final StatusLevel level;

  /// Overrides the default icon of [level].
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = statusColors(level);
    final icon = this.icon ??
        switch (level) {
          StatusLevel.ok => Icons.check_circle_outline,
          StatusLevel.warn => Icons.error_outline,
          StatusLevel.danger => Icons.warning_amber_rounded,
          StatusLevel.neutral => Icons.schedule,
        };
    return Semantics(
      label: label,
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: c.text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: TextStyle(
                    color: c.text,
                    fontSize: Ui.secondary,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
