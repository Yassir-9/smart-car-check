import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../locale_notifier.dart';
import '../services/auth_service.dart';
import 'cars_screen.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _gold = Color(0xFFC9A876);
  static const Color _navy = Color(0xFF1E3A5F);

  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
    localeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    localeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value;
    final cardColor = Theme.of(context).cardColor;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle(l10n.preferences),
            Container(
              decoration: _sectionDecoration(cardColor),
              child: Column(
                children: [
                  _switchRow(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    title: l10n.darkMode,
                    subtitle:
                        isDark ? l10n.darkModeEnabled : l10n.lightModeEnabled,
                    value: isDark,
                    onChanged: (_) => themeNotifier.toggle(),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _dropdownRow(
                    icon: Icons.language,
                    title: l10n.language,
                    subtitle: localeNotifier.value == 'ar'
                        ? l10n.arabic
                        : l10n.english,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _listRow(
                    icon: Icons.directions_car_filled,
                    title: l10n.manageCars,
                    subtitle: l10n.manageCarsSubtitle,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CarsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(l10n.aboutApp),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _sectionDecoration(cardColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_navy, Color(0xFF3B6EA5)],
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/icon/icon_mark.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.appTitle,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(l10n.version,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.appDescription,
                    style: TextStyle(
                        fontSize: 13, height: 1.6, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: 0.35)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: _gold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.disclaimerText,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B5B3D), height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _sectionDecoration(Color cardColor) {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _gold, size: 18),
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, activeThumbColor: _navy, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _dropdownRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _iconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: localeNotifier.value,
            underline: const SizedBox.shrink(),
            items: [
              DropdownMenuItem(value: 'ar', child: Text(l10n.arabic)),
              DropdownMenuItem(value: 'en', child: Text(l10n.english)),
            ],
            onChanged: (val) {
              if (val != null) localeNotifier.setLanguage(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _listRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _iconBox(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600),
      ),
    );
  }
}
