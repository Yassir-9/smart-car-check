import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// An icon on a light blue rounded square (#E8EFFD).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.size = 44, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              color: Ui.iconBg,
              borderRadius: BorderRadius.circular(Ui.rSmall)),
          child: Icon(icon, size: size * 0.5, color: color ?? Ui.primaryText),
        ),
      );
}
