import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/car_model.dart';
import '../models/maintenance_reminder.dart';
import '../models/maintenance_record.dart';
import '../services/car_service.dart';
import '../services/maintenance_service.dart';
import '../services/maintenance_record_service.dart';
import 'maintenance_history_screen.dart';
import 'subscription_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _baseUrl = 'https://car-ai-backend-7gpb.onrender.com';

  bool _isLoading = true;
  String? _errorText;

  List<CarModel> _cars = [];
  List<MaintenanceReminder> _reminders = [];
  List<MaintenanceRecord> _records = [];
  Map<String, dynamic>? _lastDiagnosis;
  Map<String, dynamic>? _subscriptionStatus;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final results = await Future.wait([
        CarService.loadCars(),
        MaintenanceService.loadReminders(),
        MaintenanceRecordService.loadRecords(),
        http.get(Uri.parse('$_baseUrl/api/history'), headers: headers),
        http.get(Uri.parse('$_baseUrl/api/subscription/status'), headers: headers),
      ]);

      final cars = results[0] as List<CarModel>;
      final reminders = results[1] as List<MaintenanceReminder>;
      final records = results[2] as List<MaintenanceRecord>;
      final historyResponse = results[3] as http.Response;
      final subResponse = results[4] as http.Response;

      Map<String, dynamic>? lastDiagnosis;
      if (historyResponse.statusCode == 200) {
        final list = jsonDecode(utf8.decode(historyResponse.bodyBytes)) as List;
        if (list.isNotEmpty) {
          lastDiagnosis = list.first as Map<String, dynamic>;
        }
      }

      Map<String, dynamic>? subStatus;
      if (subResponse.statusCode == 200) {
        subStatus = jsonDecode(utf8.decode(subResponse.bodyBytes)) as Map<String, dynamic>;
      }

      if (!mounted) return;
      setState(() {
        _cars = cars;
        _reminders = reminders..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        _records = records..sort((a, b) => b.date.compareTo(a.date));
        _lastDiagnosis = lastDiagnosis;
        _subscriptionStatus = subStatus;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'تعذر تحميل بيانات لوحة التحكم';
        _isLoading = false;
      });
    }
  }

  int get _upcomingRemindersCount =>
      _reminders.where((r) => !r.isDone && r.dueDate.isAfter(DateTime.now())).length;

  int get _overdueRemindersCount =>
      _reminders.where((r) => !r.isDone && r.dueDate.isBefore(DateTime.now())).length;

  Color _carStatusColor(CarModel car) {
    final now = DateTime.now();
    final dates = [car.insuranceExpiry, car.registrationExpiry, car.inspectionExpiry]
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return Colors.grey;
    final hasExpired = dates.any((d) => d.isBefore(now));
    if (hasExpired) return const Color(0xFFD32F2F);
    final hasSoon = dates.any((d) => d.difference(now).inDays <= 30);
    if (hasSoon) return const Color(0xFFF57C00);
    return const Color(0xFF388E3C);
  }

  String _carStatusLabel(CarModel car) {
    final color = _carStatusColor(car);
    if (color == const Color(0xFFD32F2F)) return 'يوجد وثيقة منتهية';
    if (color == const Color(0xFFF57C00)) return 'تجديد قريب';
    if (color == Colors.grey) return 'لا توجد بيانات وثائق';
    return 'كل الوثائق سارية';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: _loadAll,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorText != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorText!),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadAll,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsRow(),
                        const SizedBox(height: 16),
                        _buildSubscriptionCard(),
                        const SizedBox(height: 16),
                        _buildLastDiagnosisCard(),
                        const SizedBox(height: 16),
                        _buildCarsStatusSection(),
                        const SizedBox(height: 16),
                        _buildRemindersSection(),
                        const SizedBox(height: 16),
                        _buildRecentRecordsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.directions_car_filled_outlined,
            label: 'سياراتي',
            value: '${_cars.length}',
            color: const Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.notifications_active_outlined,
            label: 'تنبيهات نشطة',
            value: '${_upcomingRemindersCount + _overdueRemindersCount}',
            color: _overdueRemindersCount > 0
                ? const Color(0xFFD32F2F)
                : const Color(0xFFF57C00),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            icon: Icons.build_circle_outlined,
            label: 'سجلات صيانة',
            value: '${_records.length}',
            color: const Color(0xFF388E3C),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    final isActive = _subscriptionStatus?['isActive'] == true;
    final plan = _subscriptionStatus?['plan'];
    final usageCount = _subscriptionStatus?['freeUsageCount'] ?? 0;
    final usageLimit = _subscriptionStatus?['freeUsageLimit'] ?? 5;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isActive
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFFFFB74D)),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.workspace_premium : Icons.workspace_premium_outlined,
              color: isActive ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive
                        ? 'اشتراكك نشط (${plan == 'yearly' ? 'سنوي' : 'شهري'})'
                        : 'الباقة المجانية',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'تشخيصات غير محدودة'
                        : 'استخدمت $usageCount من $usageLimit تشخيصات هذا الشهر',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildLastDiagnosisCard() {
    if (_lastDiagnosis == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('لا يوجد تشخيص سابق بعد',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
      );
    }

    final result = _lastDiagnosis!['result'] as Map<String, dynamic>?;
    final severity = result?['severity'] as String?;
    final color = severity == 'عالية'
        ? const Color(0xFFD32F2F)
        : severity == 'متوسطة'
            ? const Color(0xFFF57C00)
            : const Color(0xFF388E3C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('آخر تشخيص',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.search, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  result?['possible_issue'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (result?['can_drive'] != null) ...[
            const SizedBox(height: 6),
            Text(result!['can_drive'],
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }

  Widget _buildCarsStatusSection() {
    if (_cars.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text('لم تضف أي سيارة بعد',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('حالة سياراتي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        ..._cars.map((car) {
          final color = _carStatusColor(car);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${car.brand} ${car.model} ${car.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(_carStatusLabel(car),
                          style: TextStyle(fontSize: 11.5, color: color)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined, size: 20),
                  tooltip: 'سجل الصيانة',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MaintenanceHistoryScreen(car: car)),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRemindersSection() {
    final upcoming = _reminders.where((r) => !r.isDone).take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('التنبيهات القادمة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('لا توجد تنبيهات حالياً',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          )
        else
          ...upcoming.map((r) {
            final isOverdue = r.dueDate.isBefore(DateTime.now());
            final color = isOverdue ? const Color(0xFFD32F2F) : const Color(0xFFF57C00);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue ? Icons.error_outline : Icons.notifications_outlined,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          '${r.dueDate.year}/${r.dueDate.month}/${r.dueDate.day}'
                          '${isOverdue ? ' (متأخر)' : ''}',
                          style: TextStyle(fontSize: 11.5, color: color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentRecordsSection() {
    final recent = _records.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('آخر سجلات الصيانة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        if (recent.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text('لا توجد سجلات صيانة بعد',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          )
        else
          ...recent.map((rec) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_outlined, size: 18, color: Color(0xFF1E3A5F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec.workType,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${rec.date.year}/${rec.date.month}/${rec.date.day}'
                            '${rec.workshop != null ? ' - ${rec.workshop}' : ''}',
                            style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (rec.cost != null)
                    Text('${rec.cost} ﷼',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2E7D32))),
                ],
              ),
            );
          }),
      ],
    );
  }
}