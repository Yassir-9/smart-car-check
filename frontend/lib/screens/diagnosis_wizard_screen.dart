import '../utils/localized_vehicle_text.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../models/diagnosis_input.dart';
import '../models/obd_scan_result.dart';
import '../services/car_service.dart';
import '../services/obd/obd_transport_factory.dart';
import '../services/obd_session_service.dart';
import '../theme/app_design_system.dart';
import '../utils/image_mime_type.dart';
import 'cars_screen.dart';
import 'diagnosis_result_screen.dart';
import 'obd_connect_screen.dart';

export '../models/diagnosis_input.dart' show DiagnosisMethod;

class DiagnosisWizardScreen extends StatefulWidget {
  final DiagnosisMethod? initialMethod;
  final bool embedded;
  const DiagnosisWizardScreen(
      {super.key, this.initialMethod, this.embedded = false});
  @override
  State<DiagnosisWizardScreen> createState() => _DiagnosisWizardScreenState();
}

class _DiagnosisWizardScreenState extends State<DiagnosisWizardScreen> {
  int _step = 0;
  List<CarModel> _cars = [];
  CarModel? _car;
  late final DiagnosisDraft _draft;
  final _symptoms = TextEditingController();
  Uint8List? _image;
  String _imageMime = 'image/jpeg';
  bool _loading = true, _submitting = false;
  String? _error;
  String? _stepError;
  bool _obdAvailable = false;

  @override
  void initState() {
    super.initState();
    _draft = DiagnosisDraft(
      initialSources: widget.initialMethod == null
          ? null
          : <DiagnosisMethod>{widget.initialMethod!},
    );
    _loadCars();
  }

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    final cars = await CarService.loadCars();
    final active = await CarService.getActiveCarId();
    final capabilities = await ObdTransportFactory().detectCapabilities();
    if (!mounted) {
      return;
    }
    setState(() {
      _cars = cars;
      _obdAvailable = capabilities.hasAnyTransport;
      if (_draft.isSelected(DiagnosisMethod.obd) && !_obdAvailable) {
        _draft.remove(DiagnosisMethod.obd);
      }
      if (cars.isNotEmpty) {
        _car = cars.firstWhere((c) => c.id == active, orElse: () => cars.first);
      }
      _loading = false;
    });
  }

  Future<void> _addCar() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const CarsScreen()));
    await _loadCars();
  }

  Future<void> _openObd() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ObdConnectScreen()));
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _chooseImage() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              minVerticalPadding: 12,
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.camera),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              minVerticalPadding: 12,
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.gallery),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 1280, imageQuality: 72);
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (mounted) {
      setState(() {
        _image = bytes;
        _imageMime = resolveImageMimeType(
          path: picked.path,
          reportedMimeType: picked.mimeType,
        );
      });
    }
  }

  void _removeImage() => setState(() {
        _image = null;
        _imageMime = 'image/jpeg';
      });

  void _continue() {
    final l10n = AppLocalizations.of(context);
    String? message;
    if (_step == 0 && _car == null) {
      message = l10n.selectCarToContinue;
    } else if (_step == 1 && _draft.sources.isEmpty) {
      message = l10n.selectDiagnosisSource;
    } else if (_step == 2) {
      message = _draft.hasActualData(
              symptoms: _symptoms.text,
              obdCodes: ObdSessionService.lastCodes,
              imageBytes: _image)
          ? null
          : l10n.diagnosisInputRequired;
    }
    if (message != null) {
      setState(() => _stepError = message);
      return;
    }
    setState(() {
      _stepError = null;
      _step += 1;
    });
  }

  Future<void> _submit() async {
    if (_car == null || _submitting) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final l10n = AppLocalizations.of(context);
      final locale =
          Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ar';
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      final response = await http.post(ApiConfig.apiUri('/diagnose'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode(_draft.buildPayload(
            car: {
              'id': _car!.id,
              'brand': _car!.brand,
              'model': _car!.model,
              'year': _car!.year,
              'currentMileage': _car!.currentMileage
            },
            symptoms: _symptoms.text,
            obdCodes: ObdSessionService.lastCodes,
            imageBytes: _image,
            imageMime: _imageMime,
            locale: locale,
          )));
      if (response.statusCode == 200) {
        final result = Map<String, dynamic>.from(
            jsonDecode(utf8.decode(response.bodyBytes)));
        if (!mounted) {
          return;
        }
        await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => DiagnosisResultScreen(
                    result: result,
                    car: _car!,
                    symptoms: _draft.isSelected(DiagnosisMethod.symptoms)
                        ? _symptoms.text.trim()
                        : '')));
      } else if (response.statusCode == 402) {
        setState(() => _error = l10n.freeDiagnosisLimitReached);
      } else {
        setState(
            () => _error = l10n.diagnosisRequestFailed(response.statusCode));
      }
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = AppLocalizations.of(context).serverConnectionFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
          body: AppStateView(
              icon: Icons.car_repair_outlined,
              title: l10n.preparingDiagnosis,
              loading: true));
    }
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: !widget.embedded,
          title: Text(l10n.diagnosisTitle,
              style: const TextStyle(fontWeight: FontWeight.w900))),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _progressIndicator(),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                  width: .8),
                              boxShadow: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? [
                                      BoxShadow(
                                        color: AppColors.midnight
                                            .withValues(alpha: .035),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(constraints.maxWidth < 520
                                  ? 16
                                  : AppSpacing.lg),
                              child: _stepContent(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _bottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _progressIndicator() {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.diagnosisStepCar,
      l10n.diagnosisStepSources,
      l10n.diagnosisStepDetails,
      l10n.diagnosisStepReview
    ];
    return Semantics(
      label: '${_step + 1}/4: ${labels[_step]}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).dividerColor, width: .8),
        ),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  AppSemanticColors.softBackground(context, AppColors.accent),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text('${_step + 1}',
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_step + 1}/4 • ${labels[_step]}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 76,
            child: Row(children: [
              for (var index = 0; index < labels.length; index++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _step
                          ? AppColors.accent
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (index < labels.length - 1) const SizedBox(width: 4),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stepContent() => switch (_step) {
        0 => _carStep(),
        1 => _methodStep(),
        2 => _dataStep(),
        _ => _reviewStep(),
      };

  Widget _stepHeading(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5)),
          ],
        ),
      );

  Widget _carStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeading(l10n.chooseVehicle, l10n.chooseVehicleSubtitle),
        if (_cars.isEmpty)
          AppEmptyState(
              icon: Icons.directions_car_outlined,
              title: l10n.addFirstCar,
              actionLabel: l10n.addCar,
              onAction: _addCar)
        else
          ..._cars.map(_carChoice),
      ],
    );
  }

  Widget _carChoice(CarModel car) {
    final selected = _car?.id == car.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [AppColors.navy, AppColors.midnight],
                )
              : null,
          color: selected ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.accent : Theme.of(context).dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _car = car),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: .12)
                            : AppSemanticColors.softBackground(
                                context, AppColors.accent),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.directions_car_rounded,
                        color: selected ? Colors.white : AppColors.accent)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${AppLocalizations.of(context).carBrand(car.brand)} ${AppLocalizations.of(context).localizedCarModel(car.model, Localizations.localeOf(context).languageCode)}',
                          style: TextStyle(
                              color: selected ? Colors.white : null,
                              fontWeight: FontWeight.w800)),
                      Text('${car.year}',
                          style: TextStyle(
                              color: selected
                                  ? Colors.white.withValues(alpha: .72)
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                    ])),
                Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _methodStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeading(l10n.chooseSources, l10n.chooseSourcesSubtitle),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 640 ? 3 : 1;
          const gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            SizedBox(
                width: width,
                child: _methodTile(
                    DiagnosisMethod.obd,
                    Icons.bluetooth_searching,
                    l10n.obdCheck,
                    _obdAvailable ? l10n.readCarCodes : l10n.obdUnavailable,
                    enabled: _obdAvailable)),
            SizedBox(
                width: width,
                child: _methodTile(
                    DiagnosisMethod.symptoms,
                    Icons.subject_rounded,
                    l10n.sourceSymptoms,
                    l10n.explainProblem)),
            SizedBox(
                width: width,
                child: _methodTile(
                    DiagnosisMethod.image,
                    Icons.camera_alt_outlined,
                    l10n.sourceImage,
                    l10n.diagnosisImageHint)),
          ]);
        }),
        const SizedBox(height: 12),
        Text(l10n.moreSourcesHelp, style: AppTypography.captionFor(context)),
      ],
    );
  }

  Widget _dataStep() {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeading(
            l10n.enterDiagnosisDetails, l10n.enterDiagnosisDetailsSubtitle),
        if (_draft.isSelected(DiagnosisMethod.obd)) ...[
          _detailTitle(Icons.bluetooth_searching, l10n.obdCodes),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppSemanticColors.softBackground(
                  context,
                  ObdSessionService.lastCodes.isEmpty
                      ? AppColors.unknown
                      : AppColors.success),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(children: [
              Icon(
                  ObdSessionService.lastCodes.isEmpty
                      ? Icons.bluetooth_disabled_outlined
                      : Icons.bluetooth_connected_rounded,
                  color: ObdSessionService.lastCodes.isEmpty
                      ? AppColors.unknown
                      : AppColors.success),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        ObdSessionService.lastCodes.isEmpty
                            ? l10n.obdNotConnected
                            : l10n.obdCodesRead,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (ObdSessionService.lastResult != null)
                      Text(
                        [
                          if (ObdSessionService.lastDeviceName != null)
                            ObdSessionService.lastDeviceName!,
                          _transportLabel,
                        ].join(' • '),
                        style: AppTypography.secondary(context, fontSize: 11.5),
                      ),
                    Text(
                        ObdSessionService.lastCodes.isEmpty
                            ? l10n.connectObdToRead
                            : l10n.obdCodesAvailable(
                                ObdSessionService.lastCodes.length),
                        style:
                            AppTypography.secondary(context, fontSize: 11.5)),
                  ])),
            ]),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: _openObd,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(ObdSessionService.lastCodes.isEmpty
                  ? l10n.connectObd
                  : l10n.manageObd)),
          if (ObdSessionService.lastCodes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ObdSessionService.lastCodes
                    .map((c) => StatusChip(label: c, color: AppColors.warning))
                    .toList()),
          ],
          const SizedBox(height: 14),
        ],
        if (_draft.isSelected(DiagnosisMethod.image)) ...[
          _detailTitle(Icons.camera_alt_outlined, l10n.diagnosisImage),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  AppSemanticColors.softBackground(context, AppColors.accent),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: .24)),
            ),
            child: _image == null
                ? Column(children: [
                    const Icon(Icons.add_photo_alternate_outlined,
                        size: 38, color: AppColors.accent),
                    const SizedBox(height: 8),
                    Text(l10n.diagnosisImage,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(l10n.diagnosisImageHint,
                        style:
                            AppTypography.secondary(context, fontSize: 11.5)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                        onPressed: _chooseImage,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(l10n.selectImage)),
                  ])
                : Column(children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Image.memory(_image!,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                          onPressed: _chooseImage,
                          icon: const Icon(Icons.sync_rounded),
                          label: Text(l10n.replace)),
                      TextButton.icon(
                          onPressed: _removeImage,
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.danger),
                          label: Text(l10n.delete,
                              style: const TextStyle(color: AppColors.danger))),
                    ]),
                  ]),
          ),
          const SizedBox(height: 14),
        ],
        if (_draft.isSelected(DiagnosisMethod.symptoms)) ...[
          _detailTitle(Icons.subject_rounded, l10n.symptoms),
          const SizedBox(height: 8),
          TextField(
              controller: _symptoms,
              onChanged: (_) => setState(() {}),
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: l10n.symptoms,
                  hintText: l10n.symptomsHint)),
        ],
      ],
    );
  }

  Widget _detailTitle(IconData icon, String title) => Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppSemanticColors.softBackground(context, AppColors.accent),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(title, style: AppTypography.section)),
      ]);

  Widget _reviewStep() {
    final l10n = AppLocalizations.of(context);
    return _submitting
        ? const _DiagnosisProcessing()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepHeading(l10n.reviewDiagnosis, l10n.reviewDiagnosisSubtitle),
              _reviewRow(l10n.vehicle, _car?.label ?? ''),
              _reviewRow(l10n.selectedSources, _usedSourceLabels.join(' + ')),
              if (_draft.isSelected(DiagnosisMethod.obd) &&
                  ObdSessionService.lastCodes.isNotEmpty)
                _reviewRow(
                    l10n.obdCodes, ObdSessionService.lastCodes.join(', ')),
              if (_draft.isSelected(DiagnosisMethod.symptoms) &&
                  _symptoms.text.trim().isNotEmpty)
                _reviewRow(l10n.symptoms, _symptoms.text.trim()),
              if (_draft.isSelected(DiagnosisMethod.image) &&
                  _image != null) ...[
                const SizedBox(height: 4),
                Text(l10n.sourceImage, style: AppTypography.secondary(context)),
                const SizedBox(height: 7),
                ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.memory(_image!,
                        width: 120, height: 82, fit: BoxFit.cover)),
              ],
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.danger))),
              const SizedBox(height: 12),
              Text(l10n.diagnosisReviewNotice,
                  style: AppTypography.secondary(context, fontSize: 12)
                      .copyWith(height: 1.5)),
            ],
          );
  }

  List<String> get _usedSourceLabels => [
        if (_draft.isSelected(DiagnosisMethod.obd) &&
            ObdSessionService.lastCodes.isNotEmpty)
          'OBD',
        if (_draft.isSelected(DiagnosisMethod.symptoms) &&
            _symptoms.text.trim().isNotEmpty)
          AppLocalizations.of(context).sourceSymptoms,
        if (_draft.isSelected(DiagnosisMethod.image) && _image != null)
          AppLocalizations.of(context).sourceImage,
      ];

  String get _transportLabel =>
      switch (ObdSessionService.lastResult?.transportType) {
        ObdTransportType.androidClassic =>
          AppLocalizations.of(context).bluetooth,
        ObdTransportType.ble => 'Bluetooth LE',
        ObdTransportType.wifi => 'Wi-Fi',
        _ => AppLocalizations.of(context).obdConnection,
      };

  Widget _bottomActions() {
    final l10n = AppLocalizations.of(context);
    final primary = ElevatedButton.icon(
      onPressed: _submitting ? null : () => _step < 3 ? _continue() : _submit(),
      icon: Icon(
          _step == 3 ? Icons.auto_awesome_rounded : Icons.arrow_back_rounded),
      label: Text(_step == 3
          ? (_submitting ? l10n.analyzing : l10n.startDiagnosis)
          : l10n.next),
    );
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shadowColor: AppColors.midnight.withValues(alpha: .08),
      child: SafeArea(
        top: false,
        bottom: !widget.embedded,
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_stepError != null) _stepErrorText(),
                  if (compact)
                    Row(children: [
                      if (_step > 0) ...[
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: IconButton.outlined(
                            tooltip: l10n.back,
                            onPressed: _goBack,
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: primary),
                    ])
                  else
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      if (_step > 0)
                        TextButton.icon(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(l10n.back),
                        ),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 210),
                        child: primary,
                      ),
                    ]),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  void _goBack() => setState(() {
        _step -= 1;
        _stepError = null;
      });

  Widget _stepErrorText() => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          _stepError!,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _methodTile(
      DiagnosisMethod value, IconData icon, String title, String subtitle,
      {bool enabled = true}) {
    final selected = _draft.isSelected(value);
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.62,
          child: AppInteractiveCard(
            selected: selected,
            onTap: () => setState(() {
              _draft.toggle(value);
              _stepError = null;
            }),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                          color: selected
                              ? AppColors.accent.withValues(alpha: .13)
                              : AppSemanticColors.softBackground(
                                  context,
                                  enabled
                                      ? AppColors.accent
                                      : AppColors.unknown),
                          borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Icon(icon,
                          color:
                              enabled ? AppColors.accent : AppColors.unknown)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(subtitle,
                            style:
                                AppTypography.secondary(context, fontSize: 11.5)
                                    .copyWith(height: 1.35)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : enabled
                              ? Icons.add_circle_outline_rounded
                              : Icons.block_rounded,
                      key: ValueKey((selected, enabled)),
                      color: selected
                          ? AppColors.accent
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _reviewRow(String label, String value) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceElevated
              : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Theme.of(context).dividerColor, width: .7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.secondary(context, fontSize: 11.5)),
            const SizedBox(height: 3),
            SelectableText(value,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _DiagnosisProcessing extends StatelessWidget {
  const _DiagnosisProcessing();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stages = [
      l10n.processingVehicleData,
      l10n.processingObdCodes,
      l10n.processingSymptoms,
      l10n.processingResult
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: const CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(height: 18),
        Text(l10n.analyzingDiagnosisData, style: AppTypography.title),
        const SizedBox(height: 6),
        Text(l10n.analysisMayTakeMoments,
            style: AppTypography.captionFor(context)),
        const SizedBox(height: 14),
        const LinearProgressIndicator(minHeight: 3),
        const SizedBox(height: 20),
        for (final entry in stages.asMap().entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: AppSemanticColors.softBackground(
                          context, AppColors.accent),
                      shape: BoxShape.circle),
                  child: Text('${entry.key + 1}',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800))),
              const SizedBox(width: 8),
              Expanded(child: Text(entry.value, style: AppTypography.body)),
            ]),
          ),
          if (entry.key < 3)
            const Padding(
                padding: EdgeInsetsDirectional.only(start: 5, bottom: 8),
                child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Icon(Icons.arrow_downward_rounded,
                        size: 14, color: AppColors.muted))),
        ],
        Text(l10n.analysisStagesNotice,
            textAlign: TextAlign.center,
            style: AppTypography.captionFor(context)),
      ],
    );
  }
}
