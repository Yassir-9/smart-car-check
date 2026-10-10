import '../l10n/app_localizations.dart';

extension LocalizedVehicleText on AppLocalizations {
  String carBrand(String value) => switch (value) {
        'تويوتا' => brandToyota,
        'هوندا' => brandHonda,
        'نيسان' => brandNissan,
        'هيونداي' => brandHyundai,
        'كيا' => brandKia,
        'فورد' => brandFord,
        'شيفروليه' => brandChevrolet,
        'مرسيدس' => brandMercedes,
        'بي إم دبليو' => brandBmw,
        'أودي' => brandAudi,
        'لكزس' => brandLexus,
        'مازدا' => brandMazda,
        'ميتسوبيشي' => brandMitsubishi,
        'جيب' => brandJeep,
        'جي إم سي' => brandGmc,
        'دودج' => brandDodge,
        'إنفينيتي' => brandInfiniti,
        'سوزوكي' => brandSuzuki,
        'فولكس فاجن' => brandVolkswagen,
        'أخرى' => other,
        _ => value,
      };

  String maintenanceCategoryName(String value) => switch (value) {
        'تغيير زيت المحرك' => categoryEngineOil,
        'فلتر الزيت' => categoryOilFilter,
        'فلتر الهواء' => categoryAirFilter,
        'البواجي' => categorySparkPlugs,
        'فحمات الفرامل (تيل الفرامل)' => categoryBrakePads,
        'البطارية' => categoryBattery,
        'الكفرات (الإطارات)' => categoryTires,
        'فلتر المكيف' => categoryCabinFilter,
        'سائل الفرامل' => categoryBrakeFluid,
        'أخرى' => other,
        _ => value,
      };
}
