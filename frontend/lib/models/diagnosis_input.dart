import 'dart:convert';
import 'dart:typed_data';

enum DiagnosisMethod { obd, symptoms, image }

class DiagnosisSourceAvailability {
  const DiagnosisSourceAvailability({required this.obdAvailable});
  final bool obdAvailable;

  bool isAvailable(DiagnosisMethod source) =>
      source != DiagnosisMethod.obd || obdAvailable;
}

class DiagnosisDraft {
  DiagnosisDraft({Set<DiagnosisMethod>? initialSources})
      : _sources = {...?initialSources};

  final Set<DiagnosisMethod> _sources;

  Set<DiagnosisMethod> get sources => Set.unmodifiable(_sources);
  bool isSelected(DiagnosisMethod source) => _sources.contains(source);

  void toggle(DiagnosisMethod source) {
    if (!_sources.remove(source)) _sources.add(source);
  }

  void remove(DiagnosisMethod source) => _sources.remove(source);

  bool hasActualData({
    required String symptoms,
    required List<String> obdCodes,
    required Uint8List? imageBytes,
  }) =>
      (isSelected(DiagnosisMethod.symptoms) && symptoms.trim().isNotEmpty) ||
      (isSelected(DiagnosisMethod.obd) && obdCodes.isNotEmpty) ||
      (isSelected(DiagnosisMethod.image) && imageBytes != null);

  String? validationMessage({
    required String symptoms,
    required List<String> obdCodes,
    required Uint8List? imageBytes,
  }) {
    if (_sources.isEmpty) return 'اختر مصدرًا واحدًا على الأقل للفحص.';
    if (!hasActualData(
      symptoms: symptoms,
      obdCodes: obdCodes,
      imageBytes: imageBytes,
    )) {
      return 'أضف بيانات فعلية من مصدر واحد على الأقل قبل المتابعة.';
    }
    return null;
  }

  Map<String, dynamic> buildPayload({
    required Map<String, dynamic> car,
    required String symptoms,
    required List<String> obdCodes,
    required Uint8List? imageBytes,
    required String imageMime,
    String? locale,
  }) {
    final description = symptoms.trim();
    return <String, dynamic>{
      'car': car,
      if (locale == 'ar' || locale == 'en') 'locale': locale,
      if (isSelected(DiagnosisMethod.symptoms) && description.isNotEmpty)
        'description': description,
      if (isSelected(DiagnosisMethod.obd) && obdCodes.isNotEmpty)
        'obd_codes': List<String>.from(obdCodes),
      if (isSelected(DiagnosisMethod.image) && imageBytes != null)
        'image': <String, dynamic>{
          'data': base64Encode(imageBytes),
          'media_type': imageMime,
        },
    };
  }
}
