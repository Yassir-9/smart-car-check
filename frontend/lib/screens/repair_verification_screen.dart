import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../models/repair_verification.dart';
import '../theme/app_design_system.dart';
import '../utils/image_mime_type.dart';

class RepairVerificationScreen extends StatefulWidget {
  const RepairVerificationScreen(
      {super.key,
      required this.car,
      this.beforeCodes = const [],
      this.beforeSymptoms = ''});
  final CarModel car;
  final List<String> beforeCodes;
  final String beforeSymptoms;
  @override
  State<RepairVerificationScreen> createState() =>
      _RepairVerificationScreenState();
}

class _RepairVerificationScreenState extends State<RepairVerificationScreen> {
  final _afterCodes = TextEditingController(),
      _afterSymptoms = TextEditingController();
  RepairVerificationResult? _result;
  Uint8List? _imageBytes;
  String? _imageMime;
  final _picker = ImagePicker();
  @override
  void dispose() {
    _afterCodes.dispose();
    _afterSymptoms.dispose();
    super.dispose();
  }

  void _verify() {
    final codes = _afterCodes.text
        .split(RegExp(r'[,،\s]+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    setState(() => _result = RepairVerificationLogic.compare(
        beforeCodes: widget.beforeCodes,
        afterCodes: codes,
        beforeSymptoms: widget.beforeSymptoms,
        afterSymptoms: _afterSymptoms.text));
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: Text(l10n.camera),
            onTap: () => Navigator.pop(context, ImageSource.camera)),
        ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l10n.gallery),
            onTap: () => Navigator.pop(context, ImageSource.gallery)),
      ])),
    );
    if (source == null) return;
    final file = await _picker.pickImage(
        source: source, imageQuality: 85, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageMime = resolveImageMimeType(
          path: file.path, reportedMimeType: file.mimeType);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(title: Text(l10n.repairVerificationTitle)),
        body: SafeArea(
            top: false,
            child: ListView(children: [
              AppPage(
                  maxWidth: 720,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.car.label, style: AppTypography.display),
                        const SizedBox(height: 5),
                        Text(l10n.postRepairComparison,
                            style: AppTypography.body),
                        const SizedBox(height: 16),
                        Card(
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.afterRepair,
                                          style: AppTypography.title),
                                      const SizedBox(height: 12),
                                      TextField(
                                          controller: _afterCodes,
                                          decoration: InputDecoration(
                                              labelText:
                                                  l10n.currentObdCodesOptional,
                                              hintText:
                                                  l10n.currentObdCodesHint)),
                                      const SizedBox(height: 12),
                                      TextField(
                                          controller: _afterSymptoms,
                                          minLines: 3,
                                          maxLines: 6,
                                          decoration: InputDecoration(
                                              labelText:
                                                  l10n.symptomsAfterRepair,
                                              hintText: l10n
                                                  .symptomsAfterRepairHint)),
                                      const SizedBox(height: 14),
                                      OutlinedButton.icon(
                                          onPressed: _pickImage,
                                          icon: const Icon(
                                              Icons.add_a_photo_outlined),
                                          label: Text(_imageBytes == null
                                              ? l10n.addPostRepairImage
                                              : l10n.replaceImage)),
                                      if (_imageBytes != null) ...[
                                        const SizedBox(height: 10),
                                        ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Image.memory(_imageBytes!,
                                                height: 180,
                                                width: double.infinity,
                                                fit: BoxFit.cover)),
                                        Align(
                                            alignment:
                                                AlignmentDirectional.centerEnd,
                                            child: TextButton.icon(
                                                onPressed: () => setState(() {
                                                      _imageBytes = null;
                                                      _imageMime = null;
                                                    }),
                                                icon: const Icon(
                                                    Icons.delete_outline),
                                                label: Text(l10n.deleteImage))),
                                        Text(
                                            l10n.temporaryImageNotice(
                                                _imageMime ?? ''),
                                            style: AppTypography.caption),
                                      ],
                                    ]))),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                            onPressed: _verify,
                            icon: const Icon(Icons.fact_check_outlined),
                            label: Text(l10n.verifyNowButton)),
                        if (_result != null) ...[
                          _resultCard(context, _result!),
                          const SizedBox(height: 16),
                          Text(
                              l10n.removedCodes(_result!.removedCodes.isEmpty
                                  ? l10n.noData
                                  : _result!.removedCodes.join(', ')),
                              style: AppTypography.body),
                          Text(
                              l10n.remainingCodes(
                                  _result!.remainingCodes.isEmpty
                                      ? l10n.none
                                      : _result!.remainingCodes.join(', ')),
                              style: AppTypography.body),
                          Text(
                              l10n.newCodes(_result!.newCodes.isEmpty
                                  ? l10n.none
                                  : _result!.newCodes.join(', ')),
                              style: AppTypography.body)
                        ],
                      ]))
            ])));
  }

  Widget _resultCard(BuildContext context, RepairVerificationResult result) {
    final l10n = AppLocalizations.of(context);
    final color = result.state == RepairVerificationState.success
        ? AppColors.success
        : result.state == RepairVerificationState.improved
            ? AppColors.warning
            : result.state == RepairVerificationState.returned ||
                    result.state == RepairVerificationState.unresolved
                ? AppColors.danger
                : AppColors.unknown;
    final label = switch (result.state) {
      RepairVerificationState.success => l10n.verificationSuccess,
      RepairVerificationState.improved => l10n.verificationImproved,
      RepairVerificationState.unresolved => l10n.verificationUnresolved,
      RepairVerificationState.returned => l10n.verificationReturned,
      RepairVerificationState.insufficientData => l10n.verificationInsufficient
    };
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.health_and_safety_outlined, color: color),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(label,
                        style: AppTypography.section.copyWith(color: color)),
                    const SizedBox(height: 5),
                    Text(result.summary, style: AppTypography.body),
                    if (result.needsWorkshopVisit)
                      Text(l10n.revisitWorkshop,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w800))
                  ]))
            ])));
  }
}
