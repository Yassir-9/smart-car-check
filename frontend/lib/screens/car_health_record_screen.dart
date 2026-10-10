import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../models/vehicle_issue.dart';
import '../services/car_health_service.dart';
import '../services/maintenance_record_service.dart';
import '../models/maintenance_record.dart';
import '../theme/app_design_system.dart';
import '../models/car_timeline_event.dart';
import '../models/repair_verification.dart';
import '../services/car_timeline_service.dart';
import '../services/repair_review_history_service.dart';
import '../services/repair_verification_service.dart';

class CarHealthRecordScreen extends StatefulWidget {
  final CarModel car;
  const CarHealthRecordScreen({super.key, required this.car});
  @override
  State<CarHealthRecordScreen> createState() => _CarHealthRecordScreenState();
}

class _CarHealthRecordScreenState extends State<CarHealthRecordScreen> {
  List<VehicleIssue>? _issues;
  List<Map<String, dynamic>> _repairs = [];
  List<MaintenanceRecord> _maintenance = [];
  List<CarTimelineEvent> _timeline = [];
  List<Map<String, dynamic>> _reviews = [];
  List<RepairVerificationRecord> _verifications = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final issues = await CarHealthService.loadIssues(widget.car.id);
    final repairs = await CarHealthService.loadRepairs(widget.car.id);
    final maintenance =
        await MaintenanceRecordService.loadRecords(carId: widget.car.id);
    final reviews =
        await RepairReviewHistoryService.readByVehicleId(widget.car.id);
    final verifications =
        await RepairVerificationService.readByVehicleId(widget.car.id);
    if (mounted) {
      setState(() {
        _issues = issues;
        _repairs = repairs;
        _maintenance = maintenance;
        _reviews = reviews;
        _verifications = verifications;
        _timeline = CarTimelineService.merge(
            diagnoses: _issues!
                .map((i) => CarTimelineService.event(
                    id: i.id,
                    vehicleId: widget.car.id,
                    type: CarTimelineEventType.diagnosis,
                    date: i.date,
                    title: i.title,
                    summary: i.obdCodes.join('، '),
                    status: i.status,
                    mileage: i.mileage,
                    relatedRecordId: i.id,
                    relatedRecordType: 'vehicle_issue'))
                .toList(),
            obdScans: _issues!
                .where((i) => i.obdCodes.isNotEmpty)
                .map((i) => CarTimelineService.event(
                    id: '${i.id}-obd',
                    vehicleId: widget.car.id,
                    type: CarTimelineEventType.obdScan,
                    date: i.date,
                    title: 'obd_scan',
                    summary: i.obdCodes.join('، '),
                    status: 'codes_read',
                    relatedRecordId: i.id,
                    relatedRecordType: 'diagnosis'))
                .toList(),
            repairReviews: _reviews
                .map((r) => CarTimelineService.event(
                    id: '${r['id']}',
                    vehicleId: widget.car.id,
                    type: CarTimelineEventType.repairReview,
                    date: DateTime.tryParse('${r['createdAt'] ?? r['date']}') ??
                        DateTime.now(),
                    title: 'repair_review',
                    summary: '${r['summary'] ?? ''}',
                    status: 'review',
                    relatedRecordId: '${r['id']}',
                    relatedRecordType: 'repair_review'))
                .toList(),
            repairs: _repairs
                .map((r) => CarTimelineService.event(
                    id: '${r['id'] ?? r['repairId']}',
                    vehicleId: widget.car.id,
                    type: CarTimelineEventType.repair,
                    date: DateTime.tryParse('${r['date']}') ?? DateTime.now(),
                    title: '${r['changedParts'] ?? 'recorded_repair'}',
                    summary: '${r['workPerformed'] ?? ''}',
                    status: '${r['verificationStatus'] ?? 'repaired'}',
                    relatedRecordId: '${r['id'] ?? r['repairId']}',
                    relatedRecordType: 'repair'))
                .toList(),
            verifications: const [],
            maintenance: _maintenance
                .map((m) => CarTimelineService.event(
                    id: m.id,
                    vehicleId: widget.car.id,
                    type: CarTimelineEventType.maintenance,
                    date: m.date,
                    title: m.workType,
                    summary: m.notes ?? '',
                    status: 'recorded',
                    relatedRecordId: m.id,
                    relatedRecordType: 'maintenance'))
                .toList(),
            returnedIssues: _issues!.where((i) => i.returnedAfterRepair || i.status == 'returned').map((i) => CarTimelineService.event(id: '${i.id}-returned', vehicleId: widget.car.id, type: CarTimelineEventType.issueReturned, date: i.date, title: 'issue_returned', summary: i.title, status: 'returned', relatedRecordId: i.id, relatedRecordType: 'vehicle_issue')).toList());
        _timeline = CarTimelineService.merge(
            diagnoses: _timeline,
            obdScans: const [],
            repairReviews: const [],
            repairs: const [],
            verifications: _verifications
                .map((v) => CarTimelineService.event(
                    id: v.verificationId,
                    vehicleId: widget.car.id,
                    type: CarTimelineEventType.repairVerification,
                    date: v.date,
                    title: 'repair_verification',
                    summary: v.summary,
                    status: v.resultState,
                    relatedRecordId: v.verificationId,
                    relatedRecordType: 'repair_verification'))
                .toList(),
            maintenance: const [],
            returnedIssues: const []);
      });
    }
  }

  String _status(String value, AppLocalizations l10n) => switch (value) {
        'new' => l10n.statusNew,
        'monitoring' => l10n.statusMonitoring,
        'repair_needed' => l10n.statusRepairNeeded,
        'repaired' => l10n.repaired,
        'returned' => l10n.repairedIssueReturned,
        'codes_read' => l10n.codesRead,
        'review' => l10n.reviewStatus,
        'recorded' => l10n.recordedStatus,
        'success' => l10n.verificationSuccess,
        'improved' => l10n.verificationImproved,
        'unresolved' => l10n.verificationUnresolved,
        'insufficientData' => l10n.verificationInsufficient,
        _ => value
      };
  Color _color(String value) => switch (value) {
        'repaired' => AppColors.success,
        'returned' || 'repair_needed' => AppColors.danger,
        _ => AppColors.warning
      };

  List<_HealthEvent> _events(AppLocalizations l10n) {
    if (_timeline.isNotEmpty) {
      return _timeline
          .map((e) => _HealthEvent(
              id: '${e.type.name}:${e.relatedRecordId ?? e.id}',
              date: e.date,
              icon: _iconFor(e.type),
              color: _color(e.status),
              type: _timelineType(e.type, l10n),
              title: _timelineTitle(e, l10n),
              details: e.summary,
              status: _status(e.status, l10n),
              mileage: e.mileage?.toString()))
          .toList();
    }
    final events = <_HealthEvent>[
      ..._issues!.map((issue) => _HealthEvent(
            id: issue.id,
            date: issue.date,
            icon: Icons.monitor_heart_outlined,
            color: _color(issue.status),
            type: l10n.checkAndDiagnosis,
            title: issue.title,
            details: issue.obdCodes.isEmpty
                ? l10n.noObdCodesRecorded
                : issue.obdCodes.join('، '),
            status: _status(issue.status, l10n),
            mileage: issue.mileage?.toString(),
          )),
      ..._repairs.map((repair) => _HealthEvent(
            id: (repair['repairId'] ?? repair['id'] ?? repair['date'])
                .toString(),
            date: DateTime.tryParse(repair['date']?.toString() ?? '') ??
                DateTime.now(),
            icon: Icons.handyman_outlined,
            color: AppColors.success,
            type: l10n.repairType,
            title: repair['changedParts']?.toString() ?? l10n.recordedRepair,
            details: [
              '${repair['repairCost'] ?? 0} ${l10n.sarShort}',
              repair['workshop']?.toString()
            ].whereType<String>().join('  •  '),
            status: repair['issueGone'] == false
                ? l10n.issueOngoing
                : l10n.repaired,
            mileage: repair['mileage']?.toString(),
          )),
      ..._maintenance.map((record) => _HealthEvent(
            id: record.id,
            date: record.date,
            icon: Icons.build_circle_outlined,
            color: AppColors.accent,
            type: l10n.maintenanceType,
            title: record.workType,
            details: [
              record.workshop,
              record.cost == null ? null : '${record.cost} ${l10n.sarShort}'
            ].whereType<String>().join('  •  '),
            status: l10n.recordedStatus,
            mileage: record.mileageAtService,
          )),
    ];
    final seen = <String>{};
    events.sort((a, b) => b.date.compareTo(a.date));
    return events.where((event) => seen.add(event.id)).toList();
  }

  String _timelineType(CarTimelineEventType type, AppLocalizations l10n) =>
      switch (type) {
        CarTimelineEventType.diagnosis => l10n.checkAndDiagnosis,
        CarTimelineEventType.obdScan => l10n.obdScan,
        CarTimelineEventType.repairReview => l10n.repairReview,
        CarTimelineEventType.repair => l10n.repairType,
        CarTimelineEventType.repairVerification => l10n.repairVerificationTitle,
        CarTimelineEventType.maintenance => l10n.maintenanceType,
        CarTimelineEventType.issueReturned => l10n.issueReturned,
      };

  String _timelineTitle(CarTimelineEvent event, AppLocalizations l10n) =>
      switch (event.title) {
        'obd_scan' => l10n.obdScan,
        'repair_review' => l10n.repairReview,
        'recorded_repair' => l10n.recordedRepair,
        'repair_verification' => l10n.repairVerificationTitle,
        'issue_returned' => l10n.issueReturned,
        _ => event.title,
      };

  IconData _iconFor(CarTimelineEventType type) => switch (type) {
        CarTimelineEventType.diagnosis => Icons.monitor_heart_outlined,
        CarTimelineEventType.obdScan => Icons.bluetooth_searching,
        CarTimelineEventType.repairReview => Icons.receipt_long_outlined,
        CarTimelineEventType.repair => Icons.handyman_outlined,
        CarTimelineEventType.repairVerification => Icons.fact_check_outlined,
        CarTimelineEventType.maintenance => Icons.build_circle_outlined,
        CarTimelineEventType.issueReturned => Icons.warning_amber_rounded
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final events = _issues == null ? const <_HealthEvent>[] : _events(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleRecordTitle)),
      body: _issues == null
          ? AppStateView(
              icon: Icons.history_rounded,
              title: l10n.preparingVehicleRecord,
              loading: true)
          : (_issues!.isEmpty && _repairs.isEmpty && _maintenance.isEmpty)
              ? AppStateView(
                  icon: Icons.history_rounded,
                  title: l10n.emptyVehicleRecord,
                  message: l10n.emptyVehicleRecordMessage)
              : ListView(children: [
                  AppPage(
                    maxWidth: 820,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.car.label, style: AppTypography.display),
                        if (widget.car.currentMileage != null)
                          Text('${widget.car.currentMileage} ${l10n.kmShort}',
                              style: AppTypography.secondary(context)),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: _summary(l10n.diagnosesCount,
                                  _issues!.length.toString())),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _summary(l10n.repairsCount,
                                  _repairs.length.toString())),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _summary(l10n.maintenanceCount,
                                  _maintenance.length.toString())),
                        ]),
                        const SizedBox(height: 18),
                        Text(l10n.vehicleTimeline,
                            style: AppTypography.section),
                        const SizedBox(height: 8),
                        ...events.asMap().entries.map((entry) => _timelineItem(
                            entry.value,
                            last: entry.key == events.length - 1,
                            l10n: l10n)),
                      ],
                    ),
                  ),
                ]),
    );
  }

  Widget _timelineItem(_HealthEvent event,
          {required bool last, required AppLocalizations l10n}) =>
      IntrinsicHeight(
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: event.color.withValues(alpha: .11),
                      shape: BoxShape.circle),
                  child: Icon(event.icon, size: 18, color: event.color)),
              if (!last)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(event.type,
                                style: AppTypography.label.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant))),
                        StatusChip(label: event.status, color: event.color),
                      ]),
                      const SizedBox(height: 5),
                      Text(event.title,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      if (event.details.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(event.details, style: AppTypography.caption),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${event.date.day}/${event.date.month}/${event.date.year}${event.mileage == null ? '' : '  •  ${event.mileage} ${l10n.kmShort}'}',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ));

  Widget _summary(String label, String value) => Card(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: AppTypography.secondary(context, fontSize: 11))
        ]),
      ));
}

class _HealthEvent {
  final String id;
  final DateTime date;
  final IconData icon;
  final Color color;
  final String type;
  final String title;
  final String details;
  final String status;
  final String? mileage;
  const _HealthEvent({
    required this.id,
    required this.date,
    required this.icon,
    required this.color,
    required this.type,
    required this.title,
    required this.details,
    required this.status,
    this.mileage,
  });
}
