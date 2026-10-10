import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../theme/app_design_system.dart';
import 'repair_record_screen.dart';
import 'repair_verification_screen.dart';

class RepairReviewResultScreen extends StatelessWidget {
  const RepairReviewResultScreen(
      {super.key, required this.result, required this.car});
  final Map<String, dynamic> result;
  final CarModel car;
  List<String> _list(String key) => List<String>.from(result[key] ?? const []);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = result['status']?.toString() ?? 'verify';
    final safety = Map<String, dynamic>.from(result['safety'] ?? const {});
    final critical = safety['critical'] == true;
    final color = critical || status == 'stop'
        ? AppColors.danger
        : status == 'logical'
            ? AppColors.success
            : AppColors.warning;
    final label = critical || status == 'stop'
        ? l10n.quoteStop
        : status == 'logical'
            ? l10n.quoteLogical
            : l10n.quoteVerify;
    final parts = List<Map<String, dynamic>>.from(result['parts'] ?? const []);
    final price = Map<String, dynamic>.from(result['price'] ?? const {});
    return Scaffold(
        appBar: AppBar(title: Text(l10n.quoteReviewTitle)),
        body: SafeArea(
            top: false,
            child: ListView(children: [
              AppPage(
                  maxWidth: 760,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                                color: AppSemanticColors.softBackground(
                                    context, color),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                    color: color.withValues(alpha: .35))),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                      critical
                                          ? Icons.health_and_safety
                                          : Icons.fact_check_outlined,
                                      color: color,
                                      size: 32),
                                  const SizedBox(height: 10),
                                  Text(label,
                                      style: AppTypography.title
                                          .copyWith(color: color)),
                                  const SizedBox(height: 6),
                                  Text(result['summary'] ?? '',
                                      style: AppTypography.body),
                                  if (result['analysis_complete'] == false)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(l10n.reviewIncomplete,
                                            style: const TextStyle(
                                                color: AppColors.danger,
                                                fontWeight: FontWeight.w800)))
                                ])),
                        if (critical) ...[
                          const SizedBox(height: 12),
                          _notice(
                              l10n.safetyAlert,
                              safety['advice']?.toString() ?? '',
                              AppColors.danger)
                        ],
                        const SizedBox(height: 16),
                        _section(
                            l10n.alignedEvidence,
                            _list('aligned_evidence'),
                            Icons.check_circle_outline,
                            AppColors.success),
                        _section(l10n.evidenceNeeded, _list('evidence_needed'),
                            Icons.help_outline, AppColors.warning),
                        _section(
                            l10n.askTechnician,
                            _list('technician_questions'),
                            Icons.question_answer_outlined,
                            AppColors.accent),
                        _section(
                            l10n.recommendedChecksFirst,
                            _list('recommended_checks'),
                            Icons.rule_outlined,
                            AppColors.accent),
                        if (parts.isNotEmpty) ...[
                          AppSectionHeader(title: l10n.proposedPartsTitle),
                          const SizedBox(height: 8),
                          ...parts.map((p) => _part(context, p)),
                          const SizedBox(height: 14)
                        ],
                        AppSectionHeader(title: l10n.price),
                        const SizedBox(height: 8),
                        _notice(
                            l10n.priceAssessment,
                            price['note']?.toString() ??
                                l10n.insufficientPriceData,
                            AppColors.unknown),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => RepairRecordScreen(
                                        car: car,
                                        repairReviewId:
                                            result['review_id']?.toString(),
                                        suggestedParts: parts
                                            .map((p) =>
                                                p['name']?.toString() ?? '')
                                            .where((p) => p.isNotEmpty)
                                            .toList(),
                                        suggestedCost:
                                            (price['quoted_total'] as num?)
                                                ?.toDouble()))),
                            icon: const Icon(Icons.task_alt),
                            label: Text(l10n.repaired)),
                        OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        RepairVerificationScreen(car: car))),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: Text(l10n.verifyRepairLater)),
                        const SizedBox(height: 12),
                        Text(l10n.vehicleLabel(car.label),
                            style: AppTypography.captionFor(context)),
                      ]))
            ])));
  }

  static Widget _notice(String title, String text, Color color) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, color: color),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(text, style: AppTypography.body)
                ]))
          ])));
  Widget _section(
          String title, List<String> items, IconData icon, Color color) =>
      items.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                  child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(icon, color: color),
                              const SizedBox(width: 8),
                              Expanded(
                                  child:
                                      Text(title, style: AppTypography.section))
                            ]),
                            const SizedBox(height: 8),
                            ...items.map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('• $e', style: AppTypography.body)))
                          ]))));
  Widget _part(BuildContext context, Map<String, dynamic> part) {
    final l10n = AppLocalizations.of(context);
    final evidence = part['evidence']?.toString() ?? 'insufficient';
    final label = evidence == 'strong'
        ? l10n.evidenceStrong
        : evidence == 'partial'
            ? l10n.evidencePartial
            : l10n.evidenceInsufficient;
    final color = evidence == 'strong'
        ? AppColors.success
        : evidence == 'partial'
            ? AppColors.warning
            : AppColors.unknown;
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Card(
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(part['name']?.toString() ?? '',
                                style: AppTypography.section)),
                        StatusChip(label: label, color: color)
                      ]),
                      const SizedBox(height: 7),
                      Text(
                          l10n.workshopReason(
                              part['workshop_reason']?.toString() ??
                                  l10n.reasonNotProvided),
                          style: AppTypography.body),
                      Text(part['explanation']?.toString() ?? '',
                          style: AppTypography.secondary(context))
                    ]))));
  }
}
