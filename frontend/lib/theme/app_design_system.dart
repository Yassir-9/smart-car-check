import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF102A43);
  static const midnight = Color(0xFF0B1F33);
  static const accent = Color(0xFF1677FF);
  static const cta = Color(0xFF1268E3);
  static const ctaHover = Color(0xFF0F5DCC);
  static const ctaPressed = Color(0xFF0C4FAE);
  static const accentSoft = Color(0xFFE8F2FF);
  static const heroBlue = Color(0xFF123B5D);
  static const heroHighlight = Color(0xFF17486D);
  static const canvas = Color(0xFFF7F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF14213D);
  static const steel = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);

  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFECFDF3);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF7E6);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);
  static const high = Color(0xFFEA580C);
  static const unknown = Color(0xFF64748B);
  static const unknownSoft = Color(0xFFF1F5F9);
  static const premium = Color(0xFFD49A23);
  static const cyan = Color(0xFF0891B2);

  static const darkCanvas = Color(0xFF07111F);
  static const darkSurface = Color(0xFF0D1B2A);
  static const darkSurfaceElevated = Color(0xFF132337);
  static const darkAccent = Color(0xFF3B82F6);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFFA8B4C4);
  static const darkBorder = Color(0xFF23364D);
}

class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
}

class AppTypography {
  static const display = TextStyle(fontSize: 26, fontWeight: FontWeight.w900);
  static const title = TextStyle(fontSize: 20, fontWeight: FontWeight.w900);
  static const section = TextStyle(fontSize: 17, fontWeight: FontWeight.w800);
  static const body = TextStyle(fontSize: 14, height: 1.6);
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);
  static const caption = TextStyle(fontSize: 11.5, color: AppColors.steel);

  static TextStyle secondary(BuildContext context, {double fontSize = 13}) =>
      TextStyle(
          fontSize: fontSize,
          color: Theme.of(context).colorScheme.onSurfaceVariant);

  static TextStyle captionFor(BuildContext context) => TextStyle(
      fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant);
}

class AppSemanticColors {
  static Color softBackground(BuildContext context, Color color) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return color.withValues(alpha: .16);
    }
    if (color == AppColors.success) return AppColors.successSoft;
    if (color == AppColors.warning) return AppColors.warningSoft;
    if (color == AppColors.danger || color == AppColors.high) {
      return AppColors.dangerSoft;
    }
    if (color == AppColors.accent) return AppColors.accentSoft;
    return AppColors.unknownSoft;
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: dark ? AppColors.darkAccent : AppColors.accent,
      brightness: brightness,
      primary: dark ? AppColors.darkAccent : AppColors.accent,
      surface: dark ? AppColors.darkSurface : AppColors.surface,
      onSurface: dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      onSurfaceVariant: dark ? AppColors.darkTextSecondary : AppColors.steel,
      outline: dark ? AppColors.darkBorder : AppColors.border,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
      cardColor: dark ? AppColors.darkSurface : AppColors.surface,
      fontFamily: 'NotoSansArabic',
      visualDensity: VisualDensity.standard,
      dividerColor: dark ? AppColors.darkBorder : AppColors.border,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.darkCanvas : AppColors.canvas,
        foregroundColor:
            dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        elevation: dark ? 0 : .4,
        shadowColor: Colors.black.withValues(alpha: .08),
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: dark ? 0 : .6,
        shadowColor: Colors.black.withValues(alpha: .07),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
              color: dark ? AppColors.darkBorder : AppColors.border, width: .8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: dark ? AppColors.darkAccent : AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          overlayColor: Colors.white.withValues(alpha: .14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkSurfaceElevated : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: dark ? AppColors.darkBorder : AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: dark ? AppColors.darkBorder : AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: dark ? AppColors.darkAccent : AppColors.accent,
              width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: dark ? AppColors.darkSurface : AppColors.surface,
        indicatorColor: dark
            ? AppColors.darkAccent.withValues(alpha: .18)
            : AppColors.accentSoft,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? (dark ? AppColors.darkAccent : AppColors.accent)
                : (dark ? AppColors.darkTextSecondary : AppColors.steel))),
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: dark ? AppColors.darkSurface : AppColors.surface,
        indicatorColor: dark
            ? AppColors.darkAccent.withValues(alpha: .18)
            : AppColors.accentSoft,
        selectedIconTheme: IconThemeData(
            color: dark ? AppColors.darkAccent : AppColors.accent),
        unselectedIconTheme: IconThemeData(
            color: dark ? AppColors.darkTextSecondary : AppColors.steel),
        selectedLabelTextStyle: TextStyle(
            color: dark ? AppColors.darkAccent : AppColors.accent,
            fontWeight: FontWeight.w800),
        unselectedLabelTextStyle: TextStyle(
            color: dark ? AppColors.darkTextSecondary : AppColors.steel),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: dark ? AppColors.darkAccent : AppColors.accent,
        foregroundColor: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: dark ? AppColors.darkAccent : AppColors.accent)),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: dark ? AppColors.darkAccent : AppColors.accent),
    );
  }
}

class AppPage extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const AppPage({super.key, required this.child, this.maxWidth = 1120});

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md), child: child),
        ),
      );
}

class AppInteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  const AppInteractiveCard({
    super.key,
    required this.child,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<AppInteractiveCard> createState() => _AppInteractiveCardState();
}

class _AppInteractiveCardState extends State<AppInteractiveCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highlighted = widget.selected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: widget.selected
              ? AppSemanticColors.softBackground(context, AppColors.accent)
              : (dark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: highlighted
                  ? AppColors.accent
                      .withValues(alpha: widget.selected ? .7 : .3)
                  : (dark ? AppColors.darkBorder : AppColors.border),
              width: widget.selected ? 1.5 : 1),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color:
                        AppColors.midnight.withValues(alpha: dark ? .16 : .06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AppSectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(title, style: AppTypography.section)),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ]);
}

class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (loading)
              const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
            else
              Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .09),
                      borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(icon, color: AppColors.accent)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            if (message != null) ...[
              const SizedBox(height: 5),
              Text(message!,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.captionFor(context).copyWith(height: 1.5)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppSemanticColors.softBackground(context, color),
            borderRadius: BorderRadius.circular(30)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AppEmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 42, color: AppColors.steel),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ]),
        ),
      );
}
