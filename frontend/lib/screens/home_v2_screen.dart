import '../utils/localized_vehicle_text.dart';
import 'package:flutter/material.dart';
import '../config/app_brand.dart';
import '../models/car_model.dart';
import '../models/maintenance_reminder.dart';
import '../models/vehicle_issue.dart';
import '../services/car_health_service.dart';
import '../services/car_service.dart';
import '../services/maintenance_service.dart';
import '../theme/app_design_system.dart';
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

enum _HealthState { good, attention, urgent, unknown }

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
  List<MaintenanceReminder> _reminders = [];
  List<Map<String, dynamic>> _repairs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

  (_HealthState, Color) get _health {
    if (_unresolved
        .any((i) => i.status == 'returned' || i.status == 'repair_needed')) {
      return (_HealthState.urgent, AppColors.danger);
    }
    if (_unresolved.isNotEmpty ||
        _reminders
            .any((r) => !r.isDone && r.dueDate.isBefore(DateTime.now()))) {
      return (_HealthState.attention, AppColors.warning);
    }
    if (_issues.isEmpty) {
      return (_HealthState.unknown, AppColors.steel);
    }
    return (_HealthState.good, AppColors.success);
  }

  IconData get _healthIcon => switch (_health.$1) {
        _HealthState.good => Icons.check_circle_outline_rounded,
        _HealthState.attention => Icons.error_outline_rounded,
        _HealthState.urgent => Icons.warning_amber_rounded,
        _ => Icons.help_outline_rounded,
      };

  String _healthLabel(AppLocalizations l10n, _HealthState state) =>
      switch (state) {
        _HealthState.good => l10n.healthGood,
        _HealthState.attention => l10n.healthAttention,
        _HealthState.urgent => l10n.healthUrgent,
        _HealthState.unknown => l10n.healthUnknown,
      };

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
    final health = _health;
    final healthLabel = _healthLabel(l10n, health.$1);
    final heroHealthColor = health.$1 == _HealthState.unknown
        ? AppColors.darkTextSecondary
        : health.$2;
    return Scaffold(
      appBar: AppBar(
          title: const Text(AppBrand.name,
              style: TextStyle(fontWeight: FontWeight.w900)),
          actions: [
            IconButton(
                onPressed: () => _open(const SettingsScreen()),
                icon: const Icon(Icons.settings_outlined))
          ]),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 820;
        return RefreshIndicator(
          onRefresh: _load,
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
                        Container(
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: AlignmentDirectional.topStart,
                                  end: AlignmentDirectional.bottomEnd,
                                  colors: [
                                    AppColors.midnight,
                                    AppColors.navy,
                                    AppColors.heroBlue,
                                    AppColors.heroHighlight,
                                  ],
                                  stops: [0, .38, .76, 1],
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppColors.midnight
                                          .withValues(alpha: .16),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7)),
                                ]),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(children: [
                                  Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                          color: AppColors.surface
                                              .withValues(alpha: .11),
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      child: const Icon(
                                          Icons.directions_car_rounded,
                                          color: AppColors.surface)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(l10n.currentCar,
                                            style: const TextStyle(
                                                color: AppColors.surface,
                                                fontSize: 12)),
                                        const SizedBox(height: 2),
                                        Text('${l10n.carBrand(_car!.brand)} ${l10n.localizedCarModel(_car!.model, Localizations.localeOf(context).languageCode)}',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: AppColors.surface)),
                                        Text(
                                            '${_car!.year}${_car!.currentMileage == null ? '' : '  •  ${l10n.mileageKm(_car!.currentMileage!)}'}',
                                            style: TextStyle(
                                                color: AppColors.surface
                                                    .withValues(alpha: .72)))
                                      ])),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: heroHealthColor.withValues(
                                          alpha: .14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_healthIcon,
                                            size: 17, color: heroHealthColor),
                                        const SizedBox(width: 5),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(l10n.carHealth,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.surface)),
                                            Text(healthLabel,
                                                style: TextStyle(
                                                    color: heroHealthColor,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                      tooltip: l10n.changeCar,
                                      color: AppColors.surface,
                                      onPressed: () =>
                                          _open(const CarsScreen()),
                                      icon: const Icon(Icons.swap_horiz))
                                ]))),
                        const SizedBox(height: 12),
                        SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return AppColors.ctaPressed;
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return AppColors.ctaHover;
                                    }
                                    return AppColors.cta;
                                  }),
                                  elevation:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return 0;
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return 2;
                                    }
                                    return 1;
                                  }),
                                  shadowColor: WidgetStateProperty.all(
                                      AppColors.cta.withValues(alpha: .22)),
                                ),
                                onPressed: () =>
                                    _open(const DiagnosisWizardScreen()),
                                icon: const Icon(Icons.car_repair_outlined),
                                label: Text(l10n.startCarCheck,
                                    style: const TextStyle(fontSize: 17)))),
                        const SizedBox(height: 18),
                        Text(l10n.quickActions,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
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
                        Text(l10n.unresolvedIssues,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
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
                                              color: AppColors.danger)
                                          : null)))),
                        const SizedBox(height: 22),
                        Text(l10n.additionalServices,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w900)),
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
                          const Divider(height: 1),
                          ListTile(
                              hoverColor:
                                  AppColors.premium.withValues(alpha: .035),
                              leading: _serviceIcon(
                                  Icons.workspace_premium_outlined,
                                  AppColors.premium),
                              title: Text(l10n.subscription),
                              onTap: () => _open(const SubscriptionScreen())),
                          const Divider(height: 1),
                          ListTile(
                              hoverColor:
                                  AppColors.accent.withValues(alpha: .035),
                              leading: _serviceIcon(
                                  Icons.storefront_outlined, AppColors.accent),
                              title: Text(l10n.partsMarketplace),
                              subtitle: Text(l10n.additionalService),
                              onTap: () => _open(PartsScreen(
                                  initialBrand: _car?.brand,
                                  initialModel: _car?.model))),
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
          child: _PremiumHoverCard(
              onTap: onTap,
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                                color: AppSemanticColors.softBackground(
                                    context, AppColors.accent),
                                borderRadius: BorderRadius.circular(10)),
                            child:
                                Icon(icon, size: 19, color: AppColors.accent)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                              Text(description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.secondary(context,
                                      fontSize: 10.5)),
                            ]))
                      ]))));

  String _reminderDisplayTitle(MaintenanceReminder reminder) {
    final l10n = AppLocalizations.of(context);
    final id = reminder.id;
    String? type;
    if (id.endsWith('_registration')) {
      type = l10n.registrationExpiry;
    } else if (id.endsWith('_insurance')) {
      type = l10n.insuranceExpiry;
    } else if (id.endsWith('_inspection')) {
      type = l10n.inspectionExpiry;
    }
    if (type == null) return reminder.title;

    final carId = id.substring(0, id.lastIndexOf('_'));
    final cars = _allCars;
    for (final car in cars) {
      if (car.id == carId) {
        final lang = Localizations.localeOf(context).languageCode;
        return '$type - ${l10n.carBrand(car.brand)} ${l10n.localizedCarModel(car.model, lang)} - ${car.year}';
      }
    }
    return reminder.title;
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
      child: _issues.isEmpty
          ? _CompactEmpty(
              icon: Icons.fact_check_outlined,
              text: l10n.noPreviousCheck,
              color: AppColors.unknown)
          : ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_issues.first.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  _issues.first.obdCodes
                      .join(l10n.localeName == 'ar' ? '، ' : ', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              trailing: StatusChip(
                  label: _issues.first.status == 'repaired'
                      ? l10n.repaired
                      : l10n.followUp,
                  color: _issues.first.status == 'repaired'
                      ? AppColors.success
                      : AppColors.warning)),
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
      Card(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader(title, onOpen),
                    const Divider(height: 10),
                    child,
                  ])));
  Widget _sectionHeader(String title, VoidCallback action) => Row(children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w900))),
        TextButton(
            onPressed: action,
            child: Text(AppLocalizations.of(context).viewAll))
      ]);

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

class _PremiumHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PremiumHoverCard({required this.child, required this.onTap});

  @override
  State<_PremiumHoverCard> createState() => _PremiumHoverCardState();
}

class _PremiumHoverCardState extends State<_PremiumHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: _hovered
                ? AppColors.accent.withValues(alpha: .32)
                : (dark ? AppColors.darkBorder : AppColors.border),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color:
                        AppColors.midnight.withValues(alpha: dark ? .18 : .07),
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
            hoverColor: AppColors.accent.withValues(alpha: .025),
            splashColor: AppColors.accent.withValues(alpha: .07),
            onTap: widget.onTap,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
