import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../services/part_search_service.dart';
import '../theme/app_design_system.dart';

/// Bottom sheet behind the "Find the part" button: partner stores (from the backend
/// allow-list) or, when the feature is off / unreachable, a plain web search.
class PartSearchSheet extends StatefulWidget {
  const PartSearchSheet({super.key, required this.part, required this.car});
  final String part;
  final CarModel car;

  @override
  State<PartSearchSheet> createState() => _PartSearchSheetState();
}

class _PartSearchSheetState extends State<PartSearchSheet> {
  late final Future<List<PartStore>?> _stores = PartSearchService.storesLoader();

  /// The search term derived from the AI part name (English term in parentheses
  /// when there is one), used for every link so stores get a clean term.
  String get _term => searchTermFromPartName(widget.part);

  String get _query => buildPartSearchQuery(
      part: _term,
      make: widget.car.brand,
      model: widget.car.model,
      year: widget.car.year);

  Future<void> _open(Uri uri) async {
    final opened = await PartSearchService.launcher(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).searchLinkFailed)));
    }
  }

  Widget _storeButton(PartStore store, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton(
          onPressed: () => _open(PartSearchService.storeUri(store.key,
              part: _term,
              make: widget.car.brand,
              model: widget.car.model,
              year: widget.car.year)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.open_in_new, size: 18),
            const SizedBox(width: 8),
            Flexible(child: Text(store.name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            StatusChip(label: l10n.marketingLinkTag, color: AppColors.accent),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.findPartTitle,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_query, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            FutureBuilder<List<PartStore>?>(
              future: _stores,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 10),
                      Text(l10n.partsGuideLoading),
                    ]),
                  );
                }
                final stores = snapshot.data ?? const <PartStore>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final store in stores) _storeButton(store, l10n),
                    // Always available, and the only option when the guide is
                    // switched off (404) or the server cannot be reached.
                    TextButton(
                        onPressed: () =>
                            _open(PartSearchService.generalSearchUri(_query)),
                        child: Text(l10n.generalWebSearch)),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(l10n.partsGuideDisclosure,
                textAlign: TextAlign.center,
                style: AppTypography.captionFor(context).copyWith(height: 1.5)),
            const SizedBox(height: 6),
            Text(l10n.partCompatibilityNotice, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
