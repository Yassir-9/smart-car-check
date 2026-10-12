import '../utils/localized_vehicle_text.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../theme/app_design_system.dart';

class WorkshopModeScreen extends StatelessWidget {
  final CarModel car;
  final String symptoms;
  final List<String> codes;
  final List<String> checks;

  const WorkshopModeScreen({
    super.key,
    required this.car,
    required this.symptoms,
    required this.codes,
    required this.checks,
  });

  String _shareText(AppLocalizations l10n, BuildContext context) => l10n.workshopShareText(
      '${l10n.carBrand(car.brand)} ${l10n.localizedCarModel(car.model, Localizations.localeOf(context).languageCode)} ${car.year}',
      car.currentMileage?.toString() ?? l10n.unrecorded,
      codes.isEmpty ? l10n.noCodesRead : codes.join(', '),
      symptoms.isEmpty ? l10n.noSymptomsAdded : symptoms,
      checks.isEmpty
          ? '- ${l10n.directTestRequired}'
          : checks.map((item) => '- $item').join('\n'));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.workshopMode)),
      body: ListView(children: [
        AppPage(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.showTechnician, style: AppTypography.display),
              const SizedBox(height: 6),
              Text(l10n.workshopModeIntro, style: AppTypography.body),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${l10n.carBrand(car.brand)} ${l10n.localizedCarModel(car.model, Localizations.localeOf(context).languageCode)}',
                          style: AppTypography.title),
                      Text(
                          '${car.year}  •  ${car.currentMileage ?? l10n.unrecorded} ${l10n.kmShort}',
                          style: AppTypography.caption),
                      const Divider(height: 24),
                      _detail(context, l10n.symptoms,
                          symptoms.isEmpty ? l10n.noSymptomsAdded : symptoms),
                      _detail(context, l10n.obdCodes,
                          codes.isEmpty ? l10n.noCodesRead : codes.join(', '),
                          latin: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: .22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.askTechnicianToCheck,
                        style: AppTypography.section),
                    const SizedBox(height: 12),
                    if (checks.isEmpty)
                      _CheckItem(l10n.directTestRequired)
                    else
                      ...checks.map(_CheckItem.new),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => SharePlus.instance
                    .share(ShareParams(text: _shareText(l10n, context))),
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.shareWithTechnician),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.workshopSummaryDisclaimer,
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _detail(BuildContext context, String label, String value,
          {bool latin = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTypography.label.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 3),
          Directionality(
              textDirection:
                  latin ? TextDirection.ltr : Directionality.of(context),
              child: Text(value, style: AppTypography.body)),
        ]),
      );
}

class _CheckItem extends StatelessWidget {
  final String text;
  const _CheckItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_box_outline_blank_rounded,
              size: 21, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTypography.body)),
        ]),
      );
}
