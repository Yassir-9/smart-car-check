import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// Section heading (16, bold) with an optional text action (min 48 high).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title,
                style: const TextStyle(
                    fontSize: Ui.sectionTitle,
                    fontWeight: FontWeight.w700,
                    color: Ui.textPrimary)),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
}
