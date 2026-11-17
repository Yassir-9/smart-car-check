import '../config/feature_flags.dart';
import '../utils/bidi_text.dart';
import '../utils/reminder_title.dart';
import '../utils/localized_vehicle_text.dart';
import 'package:flutter/material.dart';
import '../config/app_brand.dart';
import '../models/car_model.dart';
import '../models/maintenance_reminder.dart';
import '../models/vehicle_issue.dart';
import '../services/car_health_service.dart';
import '../services/car_service.dart';
import '../services/latest_diagnosis_service.dart';
import '../services/maintenance_service.dart';
import '../theme/app_design_system.dart' hide StatusChip;
import '../theme/app_tokens.dart';
import '../utils/home_stats.dart';
import '../widgets/ui/ui.dart';
import 'before_you_pay_screen.dart';
import 'car_health_record_screen.dart';
import 'cars_screen.dart';
import 'diagnosis_wizard_screen.dart';
import 'history_screen.dart';
import 'maintenance_screen.dart';
import 'repair_verification_screen.dart';
import 'parts_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';
import '../l10n/app_localizations.dart';

class HomeV2Screen extends StatefulWidget {
  final bool embedded;
  const HomeV2Screen({super.key, this.embedded = false});
  @override
  State<HomeV2Screen> createState() => _HomeV2ScreenState();
}

class _HomeV2ScreenState extends State<HomeV2Screen> {
  bool _loading = true;
  CarModel? _car;
  List<CarModel> _allCars = [];
  List<VehicleIssue> _issues = [];
  LatestDiagnosis? _latestDiagnosis;
  List<MaintenanceReminder> _reminders = [];
  List<Map<String, dynamic>> _repairs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool forceHistory = false}) async {
    try {
      final cars = await CarService.loadCars(),
          active = await CarService.getActiveCarId();
      CarModel? car;
      if (cars.isNotEmpty) {
        car = cars.firstWhere((c) => c.id == active, orElse: () => cars.first);
      }
      final issues = car == null
          ? <VehicleIssue>[]
          : await CarHealthService.loadIssues(car.id);
      final repairs = car == null
          ? <Map<String, dynamic>>[]
          : await CarHealthService.loadRepairs(car.id);
      final reminders = await MaintenanceService.loadReminders();
      if (mounted) {
        setState(() {
          _car = car;
          _allCars = cars;
          _issues = issues;
          _repairs = repairs;
          _reminders = reminders;
          _loading = false;
        });
        // Not awaited: the history comes from the server (it can be slow on a
        // cold start) and must not hold back the first paint of the home screen.
        final activeCar = car;
        if (activeCar != null) {
          LatestDiagnosisService.forCarCached(activeCar, force: forceHistory).then((latest) {
            if (mounted && _car?.id == activeCar.id) {
              setState(() => _latestDiagnosis = latest);
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    await _load();
  }

  List<VehicleIssue> get _unresolved =>
      _issues.where((i) => i.status != 'repaired').toList();
  List<MaintenanceReminder> get _upcoming {
    final items = _reminders.where((r) => !r.isDone).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  Color get _maintenanceColor {
    if (_upcoming.isEmpty) return AppColors.accent;
    final days = _upcoming.first.dueDate.difference(DateTime.now()).inDays;
    if (days < 0) return AppColors.danger;
    if (days <= 7) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
          title: const Text(AppBrand.name),
          actions: [
            IconButton(
                onPressed: () => _open(const SettingsScreen()),
                icon: const Icon(Icons.settings_outlined))
          ]),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        return RefreshIndicator(
          onRefresh: () => _load(forceHistory: true),
          child: ListView(children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? AppSpacing.lg : AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_car == null)
                        AppEmptyState(
                            icon: Icons.directions_car_outlined,
                            title: l10n.addFirstCar,
                            actionLabel: l10n.addCar,
                            onAction: () => _open(const CarsScreen()))
                      else ...[
                        _carCard(l10n),
                        const SizedBox(height: 12),
                        PrimaryButton(
                            label: l10n.startCarCheck,
                            icon: Icons.car_repair_outlined,
                            onPressed: () =>
                                _open(const DiagnosisWizardScreen())),
                        const SizedBox(height: 18),
                        SectionTitle(l10n.quickActions),
                        const SizedBox(height: 10),
                        LayoutBuilder(builder: (context, quickConstraints) {
                          const gap = 10.0;
                          final columns = isWide ? 4 : 2;
                          final itemWidth = (quickConstraints.maxWidth -
                                  (gap * (columns - 1))) /
                              columns;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              _quick(
                                  itemWidth,
                                  Icons.bluetooth_searching,
                                  l10n.obdCheck,
                                  l10n.readCarCodes,
                                  () => _open(const DiagnosisWizardScreen(
                                      initialMethod: DiagnosisMethod.obd))),
                              _quick(
                                  itemWidth,
                                  Icons.notes_outlined,
                                  l10n.describeSymptoms,
                                  l10n.explainProblem,
                                  () => _open(const DiagnosisWizardScreen(
                                      initialMethod:
                                          DiagnosisMethod.symptoms))),
                              _quick(
                                  itemWidth,
                                  Icons.price_check_outlined,
                                  l10n.beforeYouPay,
                                  l10n.reviewWorkshopQuote,
                                  () => _open(const BeforeYouPayScreen())),
                              _quick(
                                  itemWidth,
                                  Icons.history_rounded,
                                  l10n.carRecord,
                                  l10n.checksAndRepairs,
                                  () =>
                                      _open(CarHealthRecordScreen(car: _car!))),
                            ],
                          );
                        }),
                        const SizedBox(height: 18),
                        ..._pendingRepairWidgets(),
                        _activityOverview(isWide),
                        const SizedBox(height: 18),
                        SectionTitle(l10n.unresolvedIssues),
                        const SizedBox(height: 8),
                        if (_unresolved.isEmpty)
                          Card(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  child: _CompactEmpty(
                                      icon: Icons.check_circle_outline,
                                      text: l10n.noUnresolvedIssues,
                                      color: AppColors.success)))
                        else
                          ..._unresolved.take(3).map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Card(
                                  child: ListTile(
                                      title: Text(i.title),
                                      subtitle: Text(i.obdCodes.join(
                                          l10n.localeName == 'ar'
                                              ? '، '
                                              : ', ')),
                                      trailing: i.returnedAfterRepair
                                          ? StatusChip(
                                              label: l10n.returnedAfterRepair,
                                              level: StatusLevel.danger)
                                          : null)))),
                        const SizedBox(height: 22),
                        SectionTitle(l10n.additionalServices),
                        const SizedBox(height: 8),
                        Card(
                            child: Column(children: [
                          ListTile(
                              hoverColor:
                                  AppColors.cyan.withValues(alpha: .035),
                              leading: _serviceIcon(
                                  Icons.price_check_outlined, AppColors.cyan),
                              title: Text(l10n.beforePayWorkshop),
                              subtitle: Text(l10n.reviewRepairWithCarData),
                              onTap: () => _open(const BeforeYouPayScreen())),
                          if (FeatureFlags.subscriptionEnabled) ...[
                            const Divider(height: 1),
                            ListTile(
                                hoverColor:
                                    AppColors.premium.withValues(alpha: .035),
                                leading: _serviceIcon(
                                    Icons.workspace_premium_outlined,
                                    AppColors.premium),
                                title: Text(l10n.subscription),
                                onTap: () =>
                                    _open(const SubscriptionScreen())),
                          ],
                          if (FeatureFlags.marketplaceEnabled) ...[
                            const Divider(height: 1),
                            ListTile(
                                hoverColor:
                                    AppColors.accent.withValues(alpha: .035),
                                leading: _serviceIcon(Icons.storefront_outlined,
                                    AppColors.accent),
                                title: Text(l10n.partsMarketplace),
                                subtitle: Text(l10n.additionalService),
                                onTap: () => _open(PartsScreen(
                                    initialBrand: _car?.brand,
                                    initialModel: _car?.model))),
                          ],
                        ])),
                      ],
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  List<Widget> _pendingRepairWidgets() {
    final l10n = AppLocalizations.of(context);
    final pending = _repairs.where((r) {
      final status = (r['verificationStatus'] ?? 'pending').toString();
      return status == 'pending' && r['deletedAt'] == null;
    }).toList();
    final returned =
        _issues.any((i) => i.returnedAfterRepair || i.status == 'returned');
    return [
      if (pending.isNotEmpty)
        Card(
          child: ListTile(
            leading:
                const Icon(Icons.fact_check_outlined, color: AppColors.accent),
            title: Text(l10n.repairPendingVerification),
            subtitle: Text(l10n.verifyRepairSubtitle),
            trailing: TextButton(
                onPressed: () => _open(RepairVerificationScreen(car: _car!)),
                child: Text(l10n.verifyNow)),
          ),
        ),
      if (returned)
        Card(
            child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger),
                title: Text(l10n.repairedIssueReturned))),
      if (pending.isNotEmpty || returned) const SizedBox(height: 12),
    ];
  }

  Widget _quick(double width, IconData icon, String label, String description,
          VoidCallback onTap) =>
      SizedBox(
          width: width,
          child: AppCard(
              onTap: onTap,
              semanticLabel: '$label. $description',
              padding: const EdgeInsets.symmetric(
                  horizontal: Ui.s12, vertical: Ui.s12),
              child: Row(children: [
                IconTile(icon, size: 40),
                const SizedBox(width: Ui.s8),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: Ui.secondary,
                              color: Ui.textSecondary)),
                    ]))
              ])));

  DateTime? get _latestCheckDate {
    final d = _latestDiagnosis?.date;
    final i = _issues.isEmpty ? null : _issues.first.date;
    if (d == null) return i;
    if (i == null) return d;
    return i.isAfter(d) ? i : d;
  }

  Widget _statTile(String value, String label) => Expanded(
        child: Semantics(
          container: true,
          label: '$label: $value',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: Ui.minTouch + 16),
            padding: const EdgeInsets.symmetric(
                horizontal: Ui.s8, vertical: Ui.s12),
            decoration: BoxDecoration(
                color: Ui.darkTile,
                borderRadius: BorderRadius.circular(Ui.rSmall)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Ui.onDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: Ui.s4),
                  Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Ui.onDarkMuted, fontSize: Ui.secondary)),
                ]),
          ),
        ),
      );

  Widget _carCard(AppLocalizations l10n) {
    final car = _car!;
    final lang = Localizations.localeOf(context).languageCode;
    final latest = _latestCheckDate;
    final name =
        '${l10n.carBrand(car.brand)} ${l10n.localizedCarModel(car.model, lang)}';
    return AppCard(
      dark: true,
      padding: const EdgeInsets.all(Ui.s16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: Ui.darkTile,
                  borderRadius: BorderRadius.circular(Ui.rSmall)),
              child:
                  const Icon(Icons.directions_car_rounded, color: Ui.onDark)),
          const SizedBox(width: Ui.s12),
          Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.currentCar,
                style: const TextStyle(
                    color: Ui.onDarkMuted, fontSize: Ui.secondary)),
            Text(name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Ui.onDark)),
            Text(
                '${car.year}${car.currentMileage == null ? '' : '  •  ${l10n.mileageKm(car.currentMileage!)}'}',
                style: const TextStyle(
                    color: Ui.onDarkMuted, fontSize: Ui.secondary)),
          ])),
          IconButton(
              tooltip: l10n.changeCar,
              color: Ui.onDark,
              constraints: const BoxConstraints(
                  minWidth: Ui.minTouch, minHeight: Ui.minTouch),
              onPressed: () => _open(const CarsScreen()),
              icon: const Icon(Icons.swap_horiz)),
        ]),
        const SizedBox(height: Ui.s16),
        Row(children: [
          _statTile('${upcomingReminderCount(_reminders)}',
              l10n.homeStatReminders),
          const SizedBox(width: Ui.s8),
          _statTile('${openIssueCount(_issues)}', l10n.homeStatOpenIssues),
          const SizedBox(width: Ui.s8),
          _statTile(
              latest == null
                  ? l10n.homeStatNone
                  : relativeDayText(l10n, latest, DateTime.now()),
              l10n.homeStatLastCheck),
        ]),
      ]),
    );
  }

  String _reminderDisplayTitle(MaintenanceReminder reminder) =>
      reminderDisplayTitle(
          l10n: AppLocalizations.of(context),
          languageCode: Localizations.localeOf(context).languageCode,
          reminder: reminder,
          cars: _allCars);

  /// The newest of: the latest saved diagnosis (History source) and the latest
  /// recorded vehicle issue (Firestore); empty state only when both are absent.
  Widget _latestCheckChild(AppLocalizations l10n) {
    final diagnosis = _latestDiagnosis;
    final issue = _issues.isEmpty ? null : _issues.first;
    final useDiagnosis =
        diagnosis != null && (issue == null || !issue.date.isAfter(diagnosis.date));
    if (useDiagnosis) {
      final d = diagnosis.date.toLocal();
      return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.fact_check_outlined, color: AppColors.accent),
          title: Text(bidiText(context, diagnosis.title),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${d.year}/${d.month}/${d.day}'));
    }
    if (issue == null) {
      return _CompactEmpty(
          icon: Icons.fact_check_outlined,
          text: l10n.noPreviousCheck,
          color: AppColors.unknown);
    }
    return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(issue.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(issue.obdCodes.join(l10n.localeName == 'ar' ? '، ' : ', '),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: StatusChip(
            label: issue.status == 'repaired' ? l10n.repaired : l10n.followUp,
            level: issue.status == 'repaired'
                ? StatusLevel.ok
                : StatusLevel.warn));
  }

  Widget _activityOverview(bool isWide) {
    final l10n = AppLocalizations.of(context);
    final maintenance = _overviewSection(
      title: l10n.upcomingMaintenance,
      onOpen: () => _open(const MaintenanceScreen()),
      child: _upcoming.isEmpty
          ? _CompactEmpty(
              icon: Icons.event_available_outlined,
              text: l10n.noMaintenanceAdded,
              color: _maintenanceColor)
          : ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.build_circle_outlined, color: _maintenanceColor),
              title: Text(_reminderDisplayTitle(_upcoming.first)),
              subtitle: Text(
                  '${_upcoming.first.dueDate.year}/${_upcoming.first.dueDate.month}/${_upcoming.first.dueDate.day}')),
    );
    final latest = _overviewSection(
      title: l10n.latestCheck,
      onOpen: () => _open(const HistoryScreen()),
      child: _latestCheckChild(l10n),
    );
    if (!isWide) {
      return Column(
          children: [maintenance, const SizedBox(height: 12), latest]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: maintenance),
      const SizedBox(width: 12),
      Expanded(child: latest)
    ]);
  }

  Widget _overviewSection({
    required String title,
    required VoidCallback onOpen,
    required Widget child,
  }) =>
      AppCard(
          padding: const EdgeInsets.fromLTRB(Ui.s16, Ui.s8, Ui.s16, Ui.s12),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionTitle(title,
                    actionLabel: AppLocalizations.of(context).viewAll,
                    onAction: onOpen),
                const Divider(height: 8),
                child,
              ]));
  Widget _serviceIcon(IconData icon, Color color) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(AppRadius.sm)),
        child: Icon(icon, size: 20, color: color),
      );
}

class _CompactEmpty extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _CompactEmpty(
      {required this.icon, required this.text, this.color = AppColors.unknown});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(icon, size: 20, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.secondary(context))),
        ]),
      );
}
