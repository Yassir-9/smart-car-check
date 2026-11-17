import '../config/feature_flags.dart';
import '../utils/bidi_text.dart';
import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../l10n/app_localizations.dart';
import '../models/vehicle_issue.dart';
import '../services/car_health_service.dart';
import 'part_search_sheet.dart';
import '../theme/app_design_system.dart' hide StatusChip;
import '../theme/app_tokens.dart';
import '../widgets/ui/ui.dart';
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

  /// AI text may mix Arabic and English (e.g. part names): isolate the Latin runs.
  String _bidi(String text) => bidiText(context, text);

  List<String> _list(String key) =>
      List<String>.from(widget.result[key] ?? const []);

  /// Questions generated with the diagnosis; blank entries are dropped.
  List<String> get _workshopQuestions => _list('workshop_questions')
      .map((q) => q.trim())
      .where((q) => q.isNotEmpty)
      .toList();
  String get _severity =>
      widget.result['severity_code'] ?? widget.result['severity'] ?? 'medium';
  StatusLevel get _severityLevel => switch (_severity) {
        'critical' || 'high' || 'عالية' => StatusLevel.danger,
        'medium' || 'متوسطة' => StatusLevel.warn,
        _ => StatusLevel.ok,
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
                            child: Text(_bidi(question),
                                style: const TextStyle(height: 1.5)))
                      ])),
          ]));

  Widget _partsSection(AppLocalizations l10n) => Card(
      child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                        child: Text(_bidi(part),
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
    return AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                IconTile(icon, size: 36),
                const SizedBox(width: Ui.s8),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: Ui.sectionTitle,
                            fontWeight: FontWeight.w700)))
              ]),
              const SizedBox(height: 10),
              ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(
                            child: Text(_bidi(e),
                                style: const TextStyle(height: 1.5)))
                      ]))),
            ]));
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
            AppCard(
              dark: true,
              padding: const EdgeInsets.all(Ui.s24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                        spacing: Ui.s8,
                        runSpacing: Ui.s8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                      Text(l10n.severity,
                          style: const TextStyle(
                              color: Ui.onDarkMuted, fontSize: Ui.secondary)),
                      StatusChip(label: _severityLabel, level: _severityLevel),
                      if (confidence != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Ui.darkTile,
                              borderRadius: BorderRadius.circular(999)),
                          child: Text(l10n.confidencePercent(confidence),
                              style: const TextStyle(
                                  color: Ui.onDark,
                                  fontSize: Ui.secondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ]),
                    const SizedBox(height: Ui.s16),
                    Text(
                        _bidi((widget.result['title'] ??
                                widget.result['possible_issue'] ??
                                l10n.diagnosisFallbackTitle)
                            .toString()),
                        style: const TextStyle(
                            color: Ui.onDark,
                            fontSize: Ui.screenTitle,
                            fontWeight: FontWeight.w700,
                            height: 1.4)),
                    const SizedBox(height: Ui.s12),
                    Text(l10n.canDrive,
                        style: const TextStyle(
                            color: Ui.onDarkMuted,
                            fontSize: Ui.secondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: Ui.s4),
                    Text(
                        driveAdvice.isEmpty
                            ? l10n.noDriveAdvice
                            : _bidi(driveAdvice.toString()),
                        style: const TextStyle(
                            color: Ui.onDark,
                            fontSize: Ui.body,
                            height: 1.6)),
                  ]),
            ),
            const SizedBox(height: 20),
            SectionTitle(l10n.whatWeFound),
            const SizedBox(height: 6),
            Text(
                _bidi((widget.result['summary'] ??
                        widget.result['explanation'] ??
                        '')
                    .toString()),
                style: const TextStyle(fontSize: 15, height: 1.7)),
            if (_savedIssue?.returnedAfterRepair == true) ...[
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(l10n.faultReturnedAfterRepair,
                          style: const TextStyle(
                              color: Ui.dangerText,
                              fontWeight: FontWeight.w700))))
            ],
            if (obd.isNotEmpty) ...[
              const SizedBox(height: 18),
              SectionTitle(l10n.faultCodes),
              const SizedBox(height: 8),
              ...obd.map((item) => Card(
                  child: ListTile(
                      title: Text(
                          _bidi(
                              '${item['code']} — ${item['official_title'] ?? item['fault_name'] ?? ''}'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          _bidi((item['meaning'] ?? l10n.unknownDtcMeaning)
                              .toString()),
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
                          color: Ui.warnText,
                          fontWeight: FontWeight.w700))),
              const SizedBox(height: 12),
            ],
            SecondaryButton(
                onPressed: _showWorkshopMode,
                icon: Icons.handyman_outlined,
                expand: true,
                label: l10n.openWorkshopMode),
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
                          Text(
                              _bidi((widget.result['next_step'] ?? '')
                                  .toString()),
                              style: const TextStyle(height: 1.6))
                        ]))),
            const SizedBox(height: 16),
            PrimaryButton(
                onPressed: _savedIssue != null || _saving ? null : _save,
                icon: Icons.bookmark_add_outlined,
                label: _savedIssue != null
                    ? l10n.savedToCarRecord
                    : _saving
                        ? l10n.saving
                        : l10n.saveToCarRecord),
            if (_savedIssue != null) ...[
              const SizedBox(height: 10),
              SecondaryButton(
                  onPressed: _showRepairDialog,
                  icon: Icons.task_alt,
                  expand: true,
                  label: l10n.recordRepair),
              const SizedBox(height: 8),
              SecondaryButton(
                  expand: true,
                  icon: Icons.fact_check_outlined,
                  label: l10n.verifyRepairLater,
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RepairVerificationScreen(
                              car: widget.car,
                              beforeCodes: _obdCodeLabels,
                              beforeSymptoms: widget.symptoms))))
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
