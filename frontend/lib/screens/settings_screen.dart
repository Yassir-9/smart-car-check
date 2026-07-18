import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../services/auth_service.dart';
import 'cars_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeNotifier.value;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('التفضيلات'),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: const Color(0xFF1E3A5F),
                    ),
                    title: const Text('الوضع الداكن'),
                    value: isDark,
                    activeThumbColor: const Color(0xFF1E3A5F),
                    onChanged: (_) => themeNotifier.toggle(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.directions_car_filled,
                        color: Color(0xFF1E3A5F)),
                    title: const Text('إدارة سياراتي'),
                    trailing: const Icon(Icons.chevron_left, size: 20),
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
            _buildSectionTitle('عن التطبيق'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                            colors: [Color(0xFF1E3A5F), Color(0xFF3B6EA5)],
                          ),
                        ),
                        child: const Icon(Icons.directions_car_filled_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تشخيص السيارة الذكي',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                          Text('الإصدار 1.0.0',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تطبيق يستخدم الذكاء الاصطناعي لتقديم تشخيص أولي توجيهي لمشاكل السيارات بناءً على وصف المستخدم وبيانات السيارة.',
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هذا التشخيص أولي وتوجيهي فقط، ولا يغني عن فحص فني معتمد من ورشة متخصصة قبل اتخاذ أي قرار يخص السلامة.',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.5),
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
                ),
                onPressed: () async {
                  await AuthService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('تسجيل الخروج'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
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
