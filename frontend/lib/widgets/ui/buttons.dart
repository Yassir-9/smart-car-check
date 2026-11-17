import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Primary action: solid blue, height 52, radius 16.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Ui.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Ui.border,
      minimumSize: Size(expand ? double.infinity : 64, 52),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ui.rButton)),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    final button = icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label))
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 20),
            label: Text(label));
    return Semantics(button: true, enabled: onPressed != null, child: button);
  }
}

/// Secondary action: blue border, #1D4ED8 text, height 44 (hit area padded to 48).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: Ui.primaryText,
      minimumSize: Size(expand ? double.infinity : 64, 44),
      tapTargetSize: MaterialTapTargetSize.padded,
      side: const BorderSide(color: Ui.primary),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Ui.rButton)),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
    final button = icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label));
    return Semantics(button: true, enabled: onPressed != null, child: button);
  }
}
