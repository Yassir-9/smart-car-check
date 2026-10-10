import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../models/repair_record.dart';
import '../services/notification_service.dart';
import '../services/repair_record_service.dart';
import '../theme/app_design_system.dart';

class RepairRecordScreen extends StatefulWidget {
  const RepairRecordScreen(
      {super.key,
      required this.car,
      this.repairReviewId,
      this.diagnosisId,
      this.suggestedParts = const [],
      this.suggestedCost,
      this.existing});
  final RepairRecord? existing;
  final CarModel car;
  final String? repairReviewId, diagnosisId;
  final List<String> suggestedParts;
  final double? suggestedCost;
  @override
  State<RepairRecordScreen> createState() => _RepairRecordScreenState();
}

class _RepairRecordScreenState extends State<RepairRecordScreen> {
  late final TextEditingController _parts,
      _work,
      _cost,
      _workshop,
      _notes,
      _mileage;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _parts = TextEditingController(
        text: r?.partsReplaced.join('، ') ?? widget.suggestedParts.join('، '));
    _work = TextEditingController(text: r?.workPerformed.join('، ') ?? '');
    _cost = TextEditingController(text: r == null ? '' : r.cost.toString());
    _workshop = TextEditingController(text: r?.workshopName ?? '');
    _notes = TextEditingController(text: r?.notes ?? '');
    _mileage = TextEditingController(text: r?.mileage?.toString() ?? '');
  }

  @override
  void dispose() {
    _parts.dispose();
    _work.dispose();
    _cost.dispose();
    _workshop.dispose();
    _notes.dispose();
    _mileage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final parts = _parts.text
        .split(RegExp(r'[,،\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty && _work.text.trim().isEmpty) {
      setState(() => _error = l10n.repairActionRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      final record = RepairRecord(
          repairId: existing?.repairId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          vehicleId: widget.car.id,
          diagnosisId: widget.diagnosisId,
          repairReviewId: widget.repairReviewId,
          date: DateTime.now(),
          mileage: int.tryParse(_mileage.text),
          partsReplaced: parts,
          workPerformed:
              _work.text.trim().isEmpty ? const [] : [_work.text.trim()],
          cost: double.tryParse(_cost.text) ?? widget.suggestedCost ?? 0,
          workshopName:
              _workshop.text.trim().isEmpty ? null : _workshop.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          verificationStatus: existing?.verificationStatus ?? 'pending',
          createdAt: existing?.createdAt,
          updatedAt: DateTime.now());
      if (existing == null) {
        await RepairRecordService.create(record);
      } else {
        await RepairRecordService.update(record);
      }
      await NotificationService.scheduleRepairVerificationReminder(
          repairId: record.repairId);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = l10n.repairSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final id = widget.existing?.repairId;
    if (id == null) return;
    final linked = await RepairRecordService.hasVerification(id);
    if (!mounted) return;
    final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
                    title: Text(l10n.deleteRepairRecord),
                    content: Text(linked
                        ? l10n.deleteLinkedRepairConfirm
                        : l10n.hideRepairConfirm),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel)),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.deleteRecord))
                    ])) ??
        false;
    if (!ok) return;
    await RepairRecordService.softDelete(id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.repairRecordTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          children: [
            AppPage(
              maxWidth: 720,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.car.label, style: AppTypography.display),
                  const SizedBox(height: 14),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        TextField(
                            controller: _parts,
                            minLines: 2,
                            maxLines: 4,
                            decoration: InputDecoration(
                                labelText: l10n.partsActuallyReplaced,
                                hintText: l10n.partsConfirmationHint)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _work,
                            minLines: 2,
                            maxLines: 4,
                            decoration:
                                InputDecoration(labelText: l10n.workPerformed)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _cost,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                                labelText: l10n.repairCost,
                                suffixText: l10n.sarShort)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _workshop,
                            decoration: InputDecoration(
                                labelText: l10n.workshopNameOptional)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _mileage,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: l10n.repairMileageOptional)),
                        const SizedBox(height: 12),
                        TextField(
                            controller: _notes,
                            minLines: 2,
                            maxLines: 4,
                            decoration:
                                InputDecoration(labelText: l10n.notesOptional)),
                      ]),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.danger))),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? l10n.saving : l10n.saveRepair)),
                  if (widget.existing != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: Text(l10n.deleteRepairRecord)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
