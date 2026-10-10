import 'dart:convert';
import 'dart:typed_data';

import 'package:car_ai_diagnosis/models/diagnosis_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const car = <String, dynamic>{
    'id': 'car-1',
    'brand': 'Nissan',
    'model': 'Maxima',
    'year': 2016,
  };

  test('selects one diagnosis source', () {
    final draft = DiagnosisDraft()..toggle(DiagnosisMethod.symptoms);
    expect(draft.sources, {DiagnosisMethod.symptoms});
  });

  test('selects two diagnosis sources', () {
    final draft = DiagnosisDraft()
      ..toggle(DiagnosisMethod.obd)
      ..toggle(DiagnosisMethod.image);
    expect(draft.sources, {DiagnosisMethod.obd, DiagnosisMethod.image});
  });

  test('selects all three diagnosis sources', () {
    final draft = DiagnosisDraft()
      ..toggle(DiagnosisMethod.obd)
      ..toggle(DiagnosisMethod.symptoms)
      ..toggle(DiagnosisMethod.image);
    expect(draft.sources, DiagnosisMethod.values.toSet());
  });

  test('removes a source after selecting it', () {
    final draft = DiagnosisDraft(
      initialSources: {DiagnosisMethod.obd, DiagnosisMethod.symptoms},
    )..toggle(DiagnosisMethod.obd);
    expect(draft.sources, {DiagnosisMethod.symptoms});
  });

  test('OBD availability does not affect symptoms and image', () {
    const availability = DiagnosisSourceAvailability(obdAvailable: false);
    expect(availability.isAvailable(DiagnosisMethod.obd), isFalse);
    expect(availability.isAvailable(DiagnosisMethod.symptoms), isTrue);
    expect(availability.isAvailable(DiagnosisMethod.image), isTrue);
  });

  test('validation rejects an empty selection and selected source without data',
      () {
    final empty = DiagnosisDraft();
    expect(
      empty.validationMessage(
        symptoms: '',
        obdCodes: const [],
        imageBytes: null,
      ),
      'اختر مصدرًا واحدًا على الأقل للفحص.',
    );
    final selected = DiagnosisDraft(
      initialSources: {DiagnosisMethod.obd, DiagnosisMethod.symptoms},
    );
    expect(
      selected.validationMessage(
        symptoms: '   ',
        obdCodes: const [],
        imageBytes: null,
      ),
      isNotNull,
    );
  });

  test('symptoms-only data is valid', () {
    final draft = DiagnosisDraft(initialSources: {DiagnosisMethod.symptoms});
    expect(
      draft.hasActualData(
        symptoms: 'اهتزاز عند التسارع',
        obdCodes: const [],
        imageBytes: null,
      ),
      isTrue,
    );
  });

  test('image-only data is valid', () {
    final draft = DiagnosisDraft(initialSources: {DiagnosisMethod.image});
    expect(
      draft.hasActualData(
        symptoms: '',
        obdCodes: const [],
        imageBytes: Uint8List.fromList([1, 2]),
      ),
      isTrue,
    );
  });

  test('OBD-only data is valid', () {
    final draft = DiagnosisDraft(initialSources: {DiagnosisMethod.obd});
    expect(
      draft.hasActualData(
        symptoms: '',
        obdCodes: const ['P0133'],
        imageBytes: null,
      ),
      isTrue,
    );
  });

  test('merged payload contains every selected source and omits empty values',
      () {
    final image = Uint8List.fromList([1, 2, 3]);
    final draft = DiagnosisDraft(
      initialSources: DiagnosisMethod.values.toSet(),
    );
    final payload = draft.buildPayload(
      car: car,
      symptoms: '  تنتفض عند التسارع  ',
      obdCodes: const ['P0133', 'P0300'],
      imageBytes: image,
      imageMime: 'image/jpeg',
    );
    expect(payload['car'], car);
    expect(payload['description'], 'تنتفض عند التسارع');
    expect(payload['obd_codes'], ['P0133', 'P0300']);
    expect(payload['image'], {
      'data': base64Encode(image),
      'media_type': 'image/jpeg',
    });

    final symptomsOnly = DiagnosisDraft(
      initialSources: {DiagnosisMethod.symptoms},
    ).buildPayload(
      car: car,
      symptoms: 'صوت عند التشغيل',
      obdCodes: const ['P9999'],
      imageBytes: image,
      imageMime: 'image/jpeg',
    );
    expect(symptomsOnly, containsPair('description', 'صوت عند التشغيل'));
    expect(symptomsOnly, isNot(contains('obd_codes')));
    expect(symptomsOnly, isNot(contains('image')));
  });
}
