import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// White card with a 1px border and 18 radius. With [dark] it becomes the
/// dark car/diagnosis card (24 radius). Tappable when [onTap] is set (the
/// target is never smaller than the content, min height 48).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(Ui.s16),
    this.dark = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool dark;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(dark ? Ui.rCarCard : Ui.rCard);
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Ui.minTouch),
        child: InkWell(borderRadius: radius, onTap: onTap, child: content),
      );
    }
    final card = Material(
      color: dark ? Ui.darkCard : Ui.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: dark ? BorderSide.none : const BorderSide(color: Ui.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
    if (onTap == null || semanticLabel == null) return card;
    return Semantics(
        button: true, label: semanticLabel, container: true, child: card);
  }
}
