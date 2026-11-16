import '../config/feature_flags.dart';
import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../l10n/app_localizations.dart';
import '../models/vehicle_issue.dart';
import '../services/car_health_service.dart';
import 'part_search_sheet.dart';
import '../theme/app_design_system.dart';
import 'workshop_mode_screen.dart';
import 'repair_verification_screen.dart';

class DiagnosisResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final CarModel car;
  final String symptoms;
  const DiagnosisResultScreen(
      {super.key,
      required this.result,
      required this.car,
      required this.symptoms});
  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  VehicleIssue? _savedIssue;
  bool _saving = false;

  List<String> _list(String key) =>
      List<String>.from(widget.result[key] ?? const []);
  /// Questions generated with the diagnosis; blank entries are dropped.
  List<String> get _workshopQuestions => _list('workshop_questions')
      .map((q) => q.trim())
      .where((q) => q.isNotEmpty)
      .toList();
  String get _severity =>
      widget.result['severity_code'] ?? widget.result['severity'] ?? 'medium';
  Color get _severityColor => switch (_severity) {
        'critical' => AppColors.danger,
        'high' || 'عالية' => AppColors.high,
        'medium' || 'متوسطة' => AppColors.warning,
        _ => AppColors.success,
      };
  String get _severityLabel => switch (_severity) {
        'critical' => AppLocalizations.of(context).severityCritical,
        'high' || 'عالية' => AppLocalizations.of(context).severityHigh,
        'medium' || 'متوسطة' => AppLocalizations.of(context).severityMedium,
        _ => AppLocalizations.of(context).severityLow,
      };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final issue = await CarHealthService.recordDiagnosis(
          car: widget.car, diagnosis: widget.result, symptoms: widget.symptoms);
      if (mounted) {
        setState(() => _savedIssue = issue);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<String> get _obdCodeLabels {
    final codes = List<Map<String, dynamic>>.from(widget.result['obd_codes'] ??
        widget.result['obd_analysis'] ??
        const []);
    return codes.map((e) => e['code']).whereType<String>().toList();
  }

  Future<void> _showPartSearch(String part) async {
    await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (_) => PartSearchSheet(part: part, car: widget.car));
  }

  void _showWorkshopMode() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WorkshopModeScreen(
                  car: widget.car,
                  symptoms: widget.symptoms,
                  codes: _obdCodeLabels,
                  checks: _list('recommended_checks'),
                )));
  }

  Future<void> _showRepairDialog() async {
    final l10n = AppLocalizations.of(context);
    if (_savedIssue == null) {
      await _save();
    }
    if (_savedIssue == null || !mounted) {
      return;
    }
    final parts = TextEditingController(),
        cost = TextEditingController(),
        workshop = TextEditingController();
    final mileage = TextEditingController(
            text: widget.car.currentMileage?.toString() ?? ''),
        notes = TextEditingController();
    bool gone = true;
    final saved = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (_, setDialogState) => AlertDialog(
                  title: Text(l10n.recordRepairTitle),
                  content: SingleChildScrollView(
                      child: Column(children: [
                    TextField(
                        controller: parts,
                        onChanged: (_) => setDialogState(() {}),
                        decoration:
                            InputDecoration(labelText: l10n.repairWorkLabel)),
                    const SizedBox(height: 10),
                    TextField(
                        controller: cost,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: l10n.repairCost,
                            suffixText: l10n.sarShort)),
                    const SizedBox(height: 10),
                    TextField(
                        controller: workshop,
                        decoration:
                            InputDecoration(labelText: l10n.workshopOptional)),
                    const SizedBox(height: 10),
                    TextField(
                        controller: mileage,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: l10n.odometer,
                            suffixText: l10n.kmShort)),
                    const SizedBox(height: 10),
                    TextField(
                        controller: notes,
                        decoration: InputDecoration(labelText: l10n.note)),
                    SwitchListTile(
                        value: gone,
                        onChanged: (v) => setDialogState(() => gone = v),
                        title: Text(l10n.issueGoneQuestion)),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel)),
                    FilledButton(
                        onPressed: parts.text.trim().isEmpty
                            ? null
                            : () => Navigator.pop(context, true),
                        child: Text(l10n.save))
                  ],
                )));
    if (saved == true) {
      await CarHealthService.saveRepair(
          issue: _savedIssue!,
          changedParts: parts.text.trim(),
          cost: double.tryParse(cost.text) ?? 0,
          workshop: workshop.text.trim().isEmpty ? null : workshop.text.trim(),
          mileage: int.tryParse(mileage.text),
          notes: notes.text.trim(),
          issueGone: gone);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.repairSaved)));
      }
    }
  }

  /// Questions generated with the diagnosis, collapsed by default; hidden when empty.
  Widget _askYourWorkshop(AppLocalizations l10n) => Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
          key: const Key('ask-your-workshop'),
          leading: const Icon(Icons.question_answer_outlined,
              size: 22, color: AppColors.accent),
          title: Text(l10n.askYourWorkshop,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final question in _workshopQuestions)
              Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                            child: Text(question,
                                style: const TextStyle(height: 1.5)))
                      ])),
          ]));

  Widget _partsSection(AppLocalizations l10n) => Card(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.build_outlined,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(l10n.relatedParts,
                      style: const TextStyle(fontWeight: FontWeight.w800)))
            ]),
            const SizedBox(height: 6),
            for (final part in _list('possible_parts'))
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Expanded(
                        child: Text(part,
                            style: const TextStyle(height: 1.5))),
                    Semantics(
                        label: l10n.findPartNamed(part),
                        button: true,
                        excludeSemantics: true,
                        child: TextButton.icon(
                          onPressed: () => _showPartSearch(part),
                          icon: const Icon(Icons.search, size: 18),
                          label: Text(l10n.findPart),
                        )),
                  ])),
          ])));

  Widget _section(String title, List<String> items, IconData icon) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w800)))
              ]),
              const SizedBox(height: 10),
              ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                            child: Text(e, style: const TextStyle(height: 1.5)))
                      ]))),
            ])));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final obd = List<Map<String, dynamic>>.from(widget.result['obd_codes'] ??
        widget.result['obd_analysis'] ??
        const []);
    final driveAdvice =
        widget.result['drive_advice'] ?? widget.result['can_drive_text'] ?? '';
    final confidence = widget.result['confidence_score'];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.diagnosisResult)),
      body: ListView(children: [
        AppPage(
          maxWidth: 860,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: _severityColor.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border:
                    Border.all(color: _severityColor.withValues(alpha: .25)),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                  color: _severityColor.withValues(alpha: .14),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                              child: Icon(Icons.health_and_safety_outlined,
                                  color: _severityColor)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(l10n.severity,
                                    style: AppTypography.caption),
                                Text(_severityLabel,
                                    style: AppTypography.title
                                        .copyWith(color: _severityColor)),
                              ])),
                          if (confidence != null)
                            StatusChip(
                                label: l10n.confidencePercent(confidence),
                                color: AppColors.accent),
                        ]),
                    const SizedBox(height: 16),
                    Text(
                        widget.result['title'] ??
                            widget.result['possible_issue'] ??
                            l10n.diagnosisFallbackTitle,
                        style: AppTypography.display),
                    const SizedBox(height: 10),
                    Text(l10n.canDrive, style: AppTypography.label),
                    const SizedBox(height: 3),
                    Text(driveAdvice.isEmpty ? l10n.noDriveAdvice : driveAdvice,
                        style:
                            AppTypography.body.copyWith(color: _severityColor)),
                  ]),
            ),
            const SizedBox(height: 20),
            AppSectionHeader(title: l10n.whatWeFound),
            const SizedBox(height: 6),
            Text(widget.result['summary'] ?? widget.result['explanation'] ?? '',
                style: const TextStyle(fontSize: 15, height: 1.7)),
            if (_savedIssue?.returnedAfterRepair == true) ...[
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(l10n.faultReturnedAfterRepair,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w800))))
            ],
            if (obd.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(l10n.faultCodes,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...obd.map((item) => Card(
                  child: ListTile(
                      title: Text(
                          '${item['code']} — ${item['official_title'] ?? item['fault_name'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(item['meaning'] ?? l10n.unknownDtcMeaning,
                          style: const TextStyle(height: 1.5)),
                      trailing: item['locally_verified'] == false
                          ? const Icon(Icons.info_outline,
                              color: AppColors.warning)
                          : const Icon(Icons.verified_outlined,
                              color: AppColors.success))))
            ],
            const SizedBox(height: 12),
            _section(l10n.likelyCauses, _list('likely_causes'),
                Icons.account_tree_outlined),
            const SizedBox(height: 12),
            _section(l10n.checksFirst, _list('recommended_checks'),
                Icons.fact_check_outlined),
            const SizedBox(height: 12),
            if (_workshopQuestions.isNotEmpty) ...[
              _askYourWorkshop(l10n),
              const SizedBox(height: 12),
            ],
            if (FeatureFlags.partsGuideEnabled &&
                _list('possible_parts').isNotEmpty) ...[
              _partsSection(l10n),
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.doNotReplaceBeforeInspection,
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
                onPressed: _showWorkshopMode,
                icon: const Icon(Icons.handyman_outlined),
                label: Text(l10n.openWorkshopMode)),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.nextStep,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(widget.result['next_step'] ?? '',
                              style: const TextStyle(height: 1.6))
                        ]))),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                    onPressed: _savedIssue != null || _saving ? null : _save,
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(_savedIssue != null
                        ? l10n.savedToCarRecord
                        : _saving
                            ? l10n.saving
                            : l10n.saveToCarRecord))),
            if (_savedIssue != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                  onPressed: _showRepairDialog,
                  icon: const Icon(Icons.task_alt),
                  label: Text(l10n.recordRepair)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RepairVerificationScreen(
                              car: widget.car,
                              beforeCodes: _obdCodeLabels,
                              beforeSymptoms: widget.symptoms))),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(l10n.verifyRepairLater))
            ],
            const SizedBox(height: 18),
            Text(l10n.diagnosisSafetyDisclaimer,
                style: AppTypography.captionFor(context).copyWith(height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
          ]),
        ),
      ]),
    );
  }
}
