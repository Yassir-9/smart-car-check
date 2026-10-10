import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../l10n/app_localizations.dart';
import '../models/car_model.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle_issue.dart';
import '../services/car_health_service.dart';
import '../services/car_service.dart';
import '../services/maintenance_record_service.dart';
import '../services/obd_session_service.dart';
import '../theme/app_design_system.dart';
import '../utils/image_mime_type.dart';
import 'repair_review_result_screen.dart';

class BeforeYouPayScreen extends StatefulWidget {
  const BeforeYouPayScreen({super.key});
  @override
  State<BeforeYouPayScreen> createState() => _BeforeYouPayScreenState();
}

class _BeforeYouPayScreenState extends State<BeforeYouPayScreen> {
  final _statement = TextEditingController(),
      _parts = TextEditingController(),
      _price = TextEditingController();
  int _step = 0;
  List<CarModel> _cars = [];
  CarModel? _car;
  List<VehicleIssue> _issues = [];
  List<Map<String, dynamic>> _repairs = [];
  List<MaintenanceRecord> _maintenance = [];
  Uint8List? _image;
  String _mime = 'image/jpeg';
  bool _loading = true, _submitting = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _statement.dispose();
    _parts.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final cars = await CarService.loadCars(),
        active = await CarService.getActiveCarId();
    if (!mounted) return;
    _cars = cars;
    _car = cars.isEmpty
        ? null
        : cars.firstWhere((c) => c.id == active, orElse: () => cars.first);
    await _loadContext();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadContext() async {
    final car = _car;
    if (car == null) return;
    final values = await Future.wait([
      CarHealthService.loadIssues(car.id),
      CarHealthService.loadRepairs(car.id),
      MaintenanceRecordService.loadRecords(carId: car.id)
    ]);
    if (!mounted || _car?.id != car.id) return;
    setState(() {
      _issues = values[0] as List<VehicleIssue>;
      _repairs = values[1] as List<Map<String, dynamic>>;
      _maintenance = values[2] as List<MaintenanceRecord>;
    });
  }

  Future<void> _selectCar(CarModel car) async {
    setState(() {
      _car = car;
      _issues = [];
      _repairs = [];
      _maintenance = [];
    });
    await _loadContext();
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        useSafeArea: true,
        builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text(l10n.captureQuote),
                  onTap: () => Navigator.pop(context, ImageSource.camera)),
              ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.chooseQuoteImage),
                  onTap: () => Navigator.pop(context, ImageSource.gallery)),
            ]));
    if (source == null) return;
    final file = await ImagePicker()
        .pickImage(source: source, maxWidth: 1280, imageQuality: 72);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _image = bytes;
      _mime = resolveImageMimeType(
          path: file.path, reportedMimeType: file.mimeType);
    });
  }

  List<String> get _proposedParts => _parts.text
      .split(RegExp(r'[,،\n]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  bool get _hasData =>
      _statement.text.trim().isNotEmpty ||
      _proposedParts.isNotEmpty ||
      _image != null;
  void _continue() {
    final l10n = AppLocalizations.of(context);
    final message = _step == 0 && _car == null
        ? l10n.selectCarToContinue
        : _step == 1 && !_hasData
            ? l10n.quoteInputRequired
            : null;
    if (message != null) {
      setState(() => _error = message);
      return;
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  Future<void> _submit() async {
    if (_car == null || !_hasData || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final locale =
          Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'ar';
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(),
          issue = _issues.isEmpty ? null : _issues.first;
      final response = await http.post(ApiConfig.apiUri('/repair-review'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'
          },
          body: jsonEncode({
            'locale': locale,
            'workshopStatement': _statement.text.trim(),
            'proposedParts': _proposedParts,
            'quotedPrice': double.tryParse(_price.text.trim()),
            'car': _car!.toJson(),
            if (issue != null)
              'diagnosis': {
                'id': issue.id,
                'title': issue.title,
                'notes': issue.notes
              },
            'obd_codes': ObdSessionService.lastCodes.isNotEmpty
                ? ObdSessionService.lastCodes
                : (issue?.obdCodes ?? const <String>[]),
            if (ObdSessionService.lastResult != null)
              'obdScan': {
                'transportType':
                    ObdSessionService.lastResult!.transportType.name,
                'timestamp':
                    ObdSessionService.lastResult!.timestamp.toIso8601String()
              },
            'openIssues': _issues
                .where((i) => i.status != 'repaired')
                .take(10)
                .map((i) => {
                      'id': i.id,
                      'title': i.title,
                      'status': i.status,
                      'obd_codes': i.obdCodes
                    })
                .toList(),
            'maintenanceHistory': _maintenance
                .take(10)
                .map((m) => {
                      'workType': m.workType,
                      'date': m.date.toIso8601String(),
                      'mileage': m.mileageAtService,
                      'partNumber': m.partNumber
                    })
                .toList(),
            'repairHistory': _repairs
                .take(10)
                .map((r) => {
                      'changedParts': r['changedParts'],
                      'date': r['date'],
                      'issueGone': r['issueGone']
                    })
                .toList(),
            if (_image != null)
              'image': {'data': base64Encode(_image!), 'media_type': _mime},
          }));
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 || decoded is! Map) throw Exception();
      if (!mounted) return;
      await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => RepairReviewResultScreen(
                  result: Map<String, dynamic>.from(decoded), car: _car!)));
    } catch (_) {
      if (mounted) {
        setState(
            () => _error = AppLocalizations.of(context).quoteReviewFailed);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Scaffold(
          body: AppStateView(
              icon: Icons.price_check_outlined,
              title: l10n.preparingVehicleData,
              loading: true));
    }
    return Scaffold(
        appBar: AppBar(title: Text(l10n.beforeYouPayTitle)),
        body: SafeArea(
            top: false,
            bottom: false,
            child: Column(children: [
              Expanded(
                  child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                    AppPage(
                        maxWidth: 720,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _progress(),
                              const SizedBox(height: 14),
                              Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: _content()))
                            ]))
                  ])),
              _actions(),
            ])));
  }

  Widget _progress() {
    final l10n = AppLocalizations.of(context);
    final steps = [
      l10n.quoteStepCar,
      l10n.quoteStepDetails,
      l10n.quoteStepReview
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.beforeYouPayIntro, style: AppTypography.body),
      const SizedBox(height: 12),
      Row(children: [
        for (var i = 0; i < 3; i++) ...[
          Expanded(
              child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                      color: i <= _step
                          ? AppColors.accent
                          : Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(8)))),
          if (i < 2) const SizedBox(width: 6)
        ]
      ]),
      const SizedBox(height: 7),
      Text('${_step + 1}/3 — ${steps[_step]}',
          style: AppTypography.captionFor(context)),
    ]);
  }

  Widget _content() =>
      switch (_step) { 0 => _carStep(), 1 => _offerStep(), _ => _reviewStep() };
  Widget _heading(String title, String subtitle) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTypography.title),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTypography.secondary(context))
      ]));
  Widget _carStep() {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(l10n.quoteReviewCarHeading, l10n.quoteReviewCarBody),
      if (_cars.isEmpty)
        AppStateView(
            icon: Icons.directions_car_outlined, title: l10n.noCarAdded)
      else
        ..._cars.map((car) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppInteractiveCard(
                selected: _car?.id == car.id,
                onTap: () => _selectCar(car),
                child: ListTile(
                    leading: const Icon(Icons.directions_car,
                        color: AppColors.accent),
                    title: Text('${car.brand} ${car.model}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(car.currentMileage == null
                        ? '${car.year}'
                        : '${car.year} • ${l10n.mileageKm(car.currentMileage!)}'),
                    trailing: Icon(
                        _car?.id == car.id
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: _car?.id == car.id
                            ? AppColors.accent
                            : AppColors.muted)))))
    ]);
  }

  Widget _offerStep() {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(l10n.quoteOfferHeading, l10n.quoteOfferBody),
      TextField(
          controller: _statement,
          minLines: 3,
          maxLines: 7,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              labelText: l10n.workshopStatement,
              hintText: l10n.workshopStatementHint)),
      const SizedBox(height: 12),
      TextField(
          controller: _parts,
          minLines: 2,
          maxLines: 5,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
              labelText: l10n.proposedParts, hintText: l10n.proposedPartsHint)),
      const SizedBox(height: 12),
      TextField(
          controller: _price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: l10n.totalPriceOptional, suffixText: l10n.sarShort)),
      const SizedBox(height: 12),
      OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.receipt_long_outlined),
          label: Text(
              _image == null ? l10n.attachQuoteImage : l10n.replaceQuoteImage)),
      if (_image != null) ...[
        const SizedBox(height: 10),
        ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(_image!, height: 160, fit: BoxFit.cover)),
        TextButton.icon(
            onPressed: () => setState(() => _image = null),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete))
      ]
    ]);
  }

  Widget _reviewStep() {
    final l10n = AppLocalizations.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(l10n.quoteReviewHeading, l10n.quoteReviewBody),
      _row(l10n.vehicle, _car?.label ?? ''),
      _row(
          l10n.workshopStatement,
          _statement.text.trim().isEmpty
              ? l10n.notProvided
              : _statement.text.trim()),
      _row(
          l10n.parts,
          _proposedParts.isEmpty
              ? l10n.notProvided
              : _proposedParts.join(', ')),
      _row(
          l10n.price,
          _price.text.trim().isEmpty
              ? l10n.notProvided
              : '${_price.text.trim()} ${l10n.sarShort}'),
      _row(l10n.quoteImage, _image == null ? l10n.notAttached : l10n.attached),
      _row(
          l10n.availableContext,
          l10n.contextSummary(_issues.length, _maintenance.length,
              ObdSessionService.lastCodes.length))
    ]);
  }

  Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTypography.caption),
        Text(value, style: AppTypography.body)
      ]));
  Widget _actions() => Material(
      color: Theme.of(context).cardColor,
      elevation: 4,
      child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_error != null)
              Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger))),
            Row(children: [
              if (_step > 0) ...[
                SizedBox(
                    width: 52,
                    height: 52,
                    child: IconButton.outlined(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                  _step--;
                                  _error = null;
                                }),
                        icon: const Icon(Icons.arrow_forward))),
                const SizedBox(width: 10)
              ],
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: _submitting
                          ? null
                          : (_step < 2 ? _continue : _submit),
                      icon: Icon(_step < 2
                          ? Icons.arrow_back
                          : Icons.fact_check_outlined),
                      label: Text(_step < 2
                          ? AppLocalizations.of(context).next
                          : (_submitting
                              ? AppLocalizations.of(context).reviewingQuote
                              : AppLocalizations.of(context).reviewQuote))))
            ])
          ])));
}
