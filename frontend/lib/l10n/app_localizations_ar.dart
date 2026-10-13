// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تشخيص السيارة الذكي';

  @override
  String get preparingApp => 'جاري تجهيز Smart Car Check';

  @override
  String get onboardingUnderstandTitle => 'افهم مشكلة سيارتك';

  @override
  String get onboardingUnderstandBody =>
      'تحليل إرشادي واضح يجمع الأعراض وبيانات السيارة.';

  @override
  String get onboardingConnectTitle => 'وصّل OBD أو اشرح الأعراض';

  @override
  String get onboardingConnectBody =>
      'اختر طريقة الفحص المناسبة وتجاوز ما لا تحتاجه.';

  @override
  String get onboardingChecksTitle => 'احصل على خطوات فحص واضحة';

  @override
  String get onboardingChecksBody => 'اعرف ما الذي يجب فحصه قبل تغيير أي قطعة.';

  @override
  String get onboardingHistoryTitle => 'احتفظ بسجل سيارتك';

  @override
  String get onboardingHistoryBody =>
      'تابع الأعطال والصيانة والإصلاحات في مكان واحد.';

  @override
  String get next => 'التالي';

  @override
  String get start => 'ابدأ';

  @override
  String get loginTitle => 'تسجيل الدخول برقم الجوال';

  @override
  String get otpTitle => 'أدخل رمز التحقق';

  @override
  String get otpSubtitle => 'أرسلنا رمز تحقق مكوّنًا من 6 أرقام إلى جوالك';

  @override
  String get phoneLabel => 'رقم الجوال';

  @override
  String get phoneHelper => 'يمكنك أيضًا إدخال الرقم بصيغة 05XXXXXXXX';

  @override
  String get otpLabel => 'رمز التحقق';

  @override
  String get sendOtp => 'إرسال رمز التحقق';

  @override
  String get verifyOtp => 'تأكيد الرمز';

  @override
  String get changePhone => 'تغيير رقم الجوال';

  @override
  String get invalidSaudiPhone => 'اكتب رقم جوال سعودي صحيح';

  @override
  String get incompleteOtp => 'اكتب رمز التحقق كاملًا';

  @override
  String get authUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get authAutomaticFailed => 'تعذر التحقق التلقائي، أدخل الرمز يدويًا';

  @override
  String get authSendFailed =>
      'تعذر إرسال رمز التحقق. تحقق من رقم الجوال وحاول مرة أخرى.';

  @override
  String get authSessionExpired => 'انتهت صلاحية الجلسة، أعد إرسال الرمز';

  @override
  String get authInvalidPhone => 'رقم الجوال غير صحيح، تأكد من الصيغة';

  @override
  String get authInvalidCode => 'رمز التحقق غير صحيح';

  @override
  String get authCodeExpired => 'انتهت صلاحية الرمز، أعد الإرسال';

  @override
  String get authTooManyRequests => 'محاولات كثيرة، حاول لاحقًا';

  @override
  String get authRequestFailed => 'تعذر إكمال الطلب الآن. حاول مرة أخرى.';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navDiagnosis => 'الفحص';

  @override
  String get navCars => 'سياراتي';

  @override
  String get navHistory => 'السجل';

  @override
  String get settings => 'الإعدادات';

  @override
  String get addFirstCar => 'أضف سيارتك الأولى لبدء الفحص';

  @override
  String get addCar => 'إضافة سيارة';

  @override
  String get currentCar => 'السيارة الحالية';

  @override
  String get carHealth => 'حالة السيارة';

  @override
  String get changeCar => 'تغيير السيارة';

  @override
  String get healthGood => 'جيدة';

  @override
  String get healthAttention => 'تحتاج انتباه';

  @override
  String get healthUrgent => 'عاجلة';

  @override
  String get healthUnknown => 'غير محددة';

  @override
  String mileageKm(int mileage) {
    return '$mileage كم';
  }

  @override
  String get startCarCheck => 'ابدأ فحص السيارة';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get obdCheck => 'فحص OBD';

  @override
  String get readCarCodes => 'قراءة أكواد السيارة';

  @override
  String get describeSymptoms => 'وصف الأعراض';

  @override
  String get explainProblem => 'اشرح المشكلة';

  @override
  String get beforeYouPay => 'قبل ما تدفع';

  @override
  String get reviewWorkshopQuote => 'راجع عرض الورشة';

  @override
  String get carRecord => 'سجل السيارة';

  @override
  String get checksAndRepairs => 'الفحوصات والإصلاحات';

  @override
  String get unresolvedIssues => 'الأعطال غير المحلولة';

  @override
  String get noUnresolvedIssues => 'لا توجد أعطال غير محلولة';

  @override
  String get returnedAfterRepair => 'عاد بعد إصلاح';

  @override
  String get additionalServices => 'خدمات إضافية';

  @override
  String get beforePayWorkshop => 'قبل ما تدفع للورشة';

  @override
  String get reviewRepairWithCarData => 'راجع اقتراح الإصلاح مع بيانات سيارتك';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get partsMarketplace => 'سوق قطع الغيار';

  @override
  String get additionalService => 'خدمة إضافية';

  @override
  String get repairPendingVerification => 'إصلاح ينتظر التحقق';

  @override
  String get verifyRepairSubtitle => 'تحقق هل المشكلة اختفت بعد الإصلاح.';

  @override
  String get verifyNow => 'تحقق الآن';

  @override
  String get repairedIssueReturned => 'عاد عطل سبق إصلاحه';

  @override
  String get upcomingMaintenance => 'الصيانة القادمة';

  @override
  String get noMaintenanceAdded => 'لم تضف موعد صيانة بعد';

  @override
  String get latestCheck => 'آخر فحص';

  @override
  String get noPreviousCheck => 'لا يوجد فحص سابق';

  @override
  String get repaired => 'تم الإصلاح';

  @override
  String get followUp => 'متابعة';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get darkMode => 'الوضع الليلي';

  @override
  String get darkModeEnabled => 'الوضع الداكن مفعّل';

  @override
  String get lightModeEnabled => 'الوضع الفاتح مفعّل';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get manageCars => 'إدارة سياراتي';

  @override
  String get manageCarsSubtitle => 'إضافة أو تعديل بيانات سياراتك';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get version => 'الإصدار 1.0.0';

  @override
  String get appDescription =>
      'تطبيق يستخدم الذكاء الاصطناعي لتقديم تشخيص أولي توجيهي لمشاكل السيارات بناءً على وصف المستخدم وبيانات السيارة.';

  @override
  String get disclaimerText =>
      'هذا التشخيص أولي وتوجيهي فقط، ولا يغني عن فحص فني معتمد من ورشة متخصصة قبل اتخاذ أي قرار يخص السلامة.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get back => 'السابق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get replace => 'استبدال';

  @override
  String get camera => 'التقاط صورة';

  @override
  String get gallery => 'اختيار من الصور';

  @override
  String get diagnosisTitle => 'فحص السيارة';

  @override
  String get preparingDiagnosis => 'جاري تجهيز الفحص';

  @override
  String get selectCarToContinue => 'اختر سيارة للمتابعة.';

  @override
  String get selectDiagnosisSource => 'اختر مصدرًا واحدًا على الأقل للفحص.';

  @override
  String get diagnosisInputRequired =>
      'أضف وصفًا للأعراض أو أكواد OBD أو صورة.';

  @override
  String get freeDiagnosisLimitReached =>
      'انتهى الحد المجاني لهذا الشهر. يمكنك إدارة الاشتراك من الصفحة الرئيسية.';

  @override
  String diagnosisRequestFailed(int status) {
    return 'تعذر إكمال الفحص الآن ($status)';
  }

  @override
  String get serverConnectionFailed => 'تعذر الاتصال بالسيرفر';

  @override
  String get diagnosisStepCar => 'السيارة';

  @override
  String get diagnosisStepSources => 'مصادر الفحص';

  @override
  String get diagnosisStepDetails => 'التفاصيل';

  @override
  String get diagnosisStepReview => 'المراجعة';

  @override
  String get chooseVehicle => 'اختر السيارة';

  @override
  String get chooseVehicleSubtitle => 'حدد السيارة التي تريد فحصها.';

  @override
  String get chooseSources => 'اختر مصادر الفحص';

  @override
  String get chooseSourcesSubtitle =>
      'يمكنك الجمع بين أكثر من مصدر للحصول على نتيجة أوضح.';

  @override
  String get enterDiagnosisDetails => 'أدخل تفاصيل الفحص';

  @override
  String get enterDiagnosisDetailsSubtitle =>
      'أضف البيانات المتاحة لكل مصدر اخترته.';

  @override
  String get reviewDiagnosis => 'راجع الطلب';

  @override
  String get reviewDiagnosisSubtitle => 'تأكد من البيانات قبل بدء التحليل.';

  @override
  String get obdCodes => 'أكواد OBD';

  @override
  String obdCodesAvailable(int count) {
    return 'تم العثور على $count كود';
  }

  @override
  String get noObdCodes => 'لا توجد أكواد محفوظة';

  @override
  String get connectObd => 'الاتصال بجهاز OBD';

  @override
  String get manageObd => 'إدارة اتصال OBD';

  @override
  String get symptoms => 'الأعراض';

  @override
  String get symptomsHint => 'مثال: اهتزاز عند الوقوف أو صوت عند التسارع';

  @override
  String get diagnosisImage => 'صورة المشكلة';

  @override
  String get diagnosisImageHint => 'مثل لمبة تحذير أو جزء ظاهر من السيارة';

  @override
  String get selectImage => 'اختيار صورة';

  @override
  String get imageAttached => 'تم إرفاق صورة';

  @override
  String get sourceObd => 'أكواد OBD';

  @override
  String get sourceSymptoms => 'وصف الأعراض';

  @override
  String get sourceImage => 'صورة';

  @override
  String get selectedSources => 'المصادر المختارة';

  @override
  String get vehicle => 'السيارة';

  @override
  String get startDiagnosis => 'بدء التشخيص';

  @override
  String get analyzing => 'جاري التحليل...';

  @override
  String get analyzingDiagnosisData => 'جاري تحليل بيانات الفحص';

  @override
  String get analysisMayTakeMoments => 'قد يستغرق ذلك لحظات قليلة';

  @override
  String get analysisStageSources => 'تجميع مصادر الفحص';

  @override
  String get analysisStageSafety => 'مراجعة مؤشرات السلامة';

  @override
  String get analysisStageResult => 'إعداد النتيجة والخطوات المقترحة';

  @override
  String get analysisStagesNotice =>
      'هذه مراحل عرض عامة وليست مؤشر تقدم لحظيًا من الخادم.';

  @override
  String get diagnosisResult => 'نتيجة الفحص';

  @override
  String get severity => 'مستوى الخطورة';

  @override
  String get severityCritical => 'حرج';

  @override
  String get severityHigh => 'مرتفع';

  @override
  String get severityMedium => 'متوسط';

  @override
  String get severityLow => 'منخفض';

  @override
  String get canDrive => 'هل يمكن القيادة؟';

  @override
  String get whatWeFound => 'ما الذي وجدناه؟';

  @override
  String get faultReturnedAfterRepair => 'عاد هذا العطل بعد إصلاح سابق';

  @override
  String get faultCodes => 'أكواد الأعطال';

  @override
  String get unknownDtcMeaning => 'لم يتوفر وصف لهذا الكود.';

  @override
  String get likelyCauses => 'الأسباب الأكثر احتمالًا';

  @override
  String get checksFirst => 'ما الذي يجب فحصه أولًا؟';

  @override
  String get relatedParts => 'قطع قد تكون مرتبطة';

  @override
  String get findPart => 'ابحث عن القطعة';

  @override
  String get findPartTitle => 'البحث عن القطعة';

  @override
  String get generalWebSearch => 'بحث عام على الويب';

  @override
  String get partCompatibilityNotice =>
      'تأكد من رقم القطعة وتوافقها مع سيارتك قبل الشراء.';

  @override
  String get partSearchNotice =>
      'البحث يساعدك على المقارنة فقط. لا تشترِ قطعة قبل تأكيد العطل ورقم القطعة المطابق.';

  @override
  String get openWorkshopMode => 'فتح وضع الورشة';

  @override
  String get nextStep => 'الخطوة التالية';

  @override
  String get saveToCarRecord => 'حفظ في سجل السيارة';

  @override
  String get savedToCarRecord => 'تم الحفظ في سجل السيارة';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get recordRepair => 'تم تسجيل إصلاح';

  @override
  String get verifyRepairLater => 'تحقق من الإصلاح لاحقًا';

  @override
  String get recordRepairTitle => 'تسجيل الإصلاح';

  @override
  String get repairWorkLabel => 'ماذا تم تغييره أو إصلاحه؟';

  @override
  String get repairCost => 'تكلفة الإصلاح';

  @override
  String get sarShort => 'ر.س';

  @override
  String get workshopOptional => 'اسم الورشة (اختياري)';

  @override
  String get odometer => 'العداد';

  @override
  String get kmShort => 'كم';

  @override
  String get note => 'ملاحظة';

  @override
  String get issueGoneQuestion => 'هل اختفى العطل؟';

  @override
  String get repairSaved => 'تم حفظ الإصلاح في سجل السيارة';

  @override
  String get diagnosisSafetyDisclaimer =>
      'هذه النتيجة توجيهية ولا تغني عن فحص فني مباشر قبل اتخاذ قرار يتعلق بالسلامة أو تغيير القطع.';

  @override
  String get beforeYouPayTitle => 'قبل ما تدفع';

  @override
  String get preparingVehicleData => 'جاري تجهيز بيانات السيارة';

  @override
  String get beforeYouPayIntro => 'راجع تشخيص الورشة وعرض السعر قبل الموافقة.';

  @override
  String get quoteStepCar => 'السيارة';

  @override
  String get quoteStepDetails => 'العرض';

  @override
  String get quoteStepReview => 'المراجعة';

  @override
  String get selectQuoteCar => 'اختر السيارة';

  @override
  String get selectQuoteCarSubtitle =>
      'سنربط العرض بتاريخ السيارة وبياناتها المتاحة.';

  @override
  String get enterQuoteDetails => 'أدخل تفاصيل عرض الورشة';

  @override
  String get enterQuoteDetailsSubtitle =>
      'أضف كلام الورشة والقطع والسعر أو صورة العرض.';

  @override
  String get reviewQuoteRequest => 'راجع بيانات الطلب';

  @override
  String get reviewQuoteRequestSubtitle =>
      'تأكد من البيانات قبل إرسالها للمراجعة.';

  @override
  String get noCarAdded => 'لا توجد سيارة مضافة';

  @override
  String mileageValue(int mileage) {
    return 'العداد: $mileage كم';
  }

  @override
  String get workshopStatement => 'كلام الورشة';

  @override
  String get workshopStatementHint =>
      'مثال: تغيير المساعد الأمامي بسبب صوت عند المطبات';

  @override
  String get proposedParts => 'القطع المقترح تغييرها';

  @override
  String get proposedPartsHint => 'كل قطعة في سطر أو افصل بينها بفاصلة';

  @override
  String get totalPriceOptional => 'السعر الإجمالي (اختياري)';

  @override
  String get captureQuote => 'تصوير عرض السعر';

  @override
  String get chooseQuoteImage => 'اختيار صورة';

  @override
  String get attachQuoteImage => 'إرفاق صورة العرض';

  @override
  String get replaceQuoteImage => 'استبدال صورة العرض';

  @override
  String get quoteInputRequired =>
      'أضف كلام الورشة أو القطع المقترحة أو صورة العرض.';

  @override
  String get quoteReviewFailed => 'تعذر مراجعة العرض الآن. حاول مرة أخرى.';

  @override
  String get reviewQuote => 'مراجعة العرض';

  @override
  String get reviewingQuote => 'جاري المراجعة...';

  @override
  String get quoteReviewTitle => 'مراجعة عرض الورشة';

  @override
  String get quoteStop => 'لا توافق قبل فحوصات إضافية';

  @override
  String get quoteLogical => 'العرض يبدو منطقيًا';

  @override
  String get quoteVerify => 'يحتاج تحقق قبل الموافقة';

  @override
  String get reviewIncomplete =>
      'لم تكتمل المراجعة الآلية؛ لا تعتمد على هذه النتيجة لاتخاذ قرار.';

  @override
  String get safetyAlert => 'تنبيه سلامة';

  @override
  String get alignedEvidence => 'ما الذي يتوافق مع بيانات سيارتك؟';

  @override
  String get evidenceNeeded => 'ما الذي يحتاج إثباتًا؟';

  @override
  String get askTechnician => 'قبل ما تدفع، اسأل الفني:';

  @override
  String get recommendedChecksFirst => 'الفحوصات التي يفضل تنفيذها أولًا';

  @override
  String get proposedPartsTitle => 'القطع المقترحة';

  @override
  String get price => 'السعر';

  @override
  String get priceAssessment => 'الحكم على السعر';

  @override
  String get insufficientPriceData =>
      'لا تتوفر لدينا بيانات سوق كافية للحكم على السعر حاليًا.';

  @override
  String vehicleLabel(String car) {
    return 'السيارة: $car';
  }

  @override
  String get evidenceStrong => 'توافق قوي';

  @override
  String get evidencePartial => 'توافق جزئي';

  @override
  String get evidenceInsufficient => 'أدلة غير كافية';

  @override
  String workshopReason(String reason) {
    return 'سبب الورشة: $reason';
  }

  @override
  String get reasonNotProvided => 'غير مذكور';

  @override
  String get obdUnavailable => 'غير متاح على هذا الجهاز حاليًا';

  @override
  String get moreSourcesHelp =>
      'كلما أضفت معلومات أكثر، حصل Smart Car Check على سياق أفضل للتشخيص.';

  @override
  String get obdNotConnected => 'جهاز OBD غير متصل';

  @override
  String get obdCodesRead => 'تمت قراءة الأكواد';

  @override
  String get connectObdToRead => 'اتصل بالجهاز لقراءة أكواد الأعطال الحقيقية';

  @override
  String get noDriveAdvice => 'لا تتوفر توصية كافية';

  @override
  String get diagnosisFallbackTitle => 'نتيجة التشخيص';

  @override
  String confidencePercent(Object value) {
    return 'الثقة $value%';
  }

  @override
  String get doNotReplaceBeforeInspection =>
      'لا تغيّر أي قطعة قبل تأكيد السبب بالفحص المباشر.';

  @override
  String get quoteReviewCarHeading => 'اختر السيارة';

  @override
  String get quoteReviewCarBody =>
      'سنستخدم بيانات السيارة وسجلها المتاح للمقارنة فقط.';

  @override
  String get quoteOfferHeading => 'ماذا قالت لك الورشة؟';

  @override
  String get quoteOfferBody => 'أضف ما لديك فقط؛ لا يلزم توفر كل الحقول.';

  @override
  String get quoteReviewHeading => 'راجع البيانات';

  @override
  String get quoteReviewBody =>
      'سنستخدم السياق المتاح دون اختراع معلومات مفقودة.';

  @override
  String get notProvided => 'غير مذكور';

  @override
  String get notAttached => 'غير مرفقة';

  @override
  String get attached => 'مرفقة';

  @override
  String get parts => 'القطع';

  @override
  String get quoteImage => 'صورة العرض';

  @override
  String get availableContext => 'السياق المتاح';

  @override
  String contextSummary(int issues, int maintenance, int codes) {
    return '$issues مشكلة • $maintenance صيانة • $codes كود OBD';
  }

  @override
  String get diagnosisReviewNotice =>
      'سيتم استخدام بيانات السيارة والأعراض والأكواد المقروءة فقط لإنشاء تحليل إرشادي.';

  @override
  String get bluetooth => 'بلوتوث';

  @override
  String get obdConnection => 'اتصال OBD';

  @override
  String get processingVehicleData => 'تحليل بيانات السيارة';

  @override
  String get processingObdCodes => 'مراجعة أكواد OBD';

  @override
  String get processingSymptoms => 'مقارنة الأعراض';

  @override
  String get processingResult => 'إعداد نتيجة الفحص';

  @override
  String get myCars => 'سياراتي';

  @override
  String get keepOneCar => 'يجب إبقاء سيارة واحدة على الأقل';

  @override
  String get deleteCar => 'حذف السيارة';

  @override
  String get deleteCarConfirm => 'هل تريد حذف هذه السيارة من قائمتك؟';

  @override
  String get addNewCar => 'إضافة سيارة جديدة';

  @override
  String get editCar => 'تعديل السيارة';

  @override
  String get manufacturer => 'الشركة المصنعة';

  @override
  String get manufacturerName => 'اكتب اسم الشركة المصنعة';

  @override
  String get carModel => 'الموديل';

  @override
  String get carModelName => 'اكتب اسم الموديل';

  @override
  String get manufactureYear => 'سنة الصنع';

  @override
  String get vinOptional => 'رقم الهيكل VIN (اختياري)';

  @override
  String get engineTypeOptional => 'نوع المحرك (اختياري)';

  @override
  String get transmissionTypeOptional => 'نوع ناقل الحركة (اختياري)';

  @override
  String get currentMileageOptional => 'قراءة العداد الحالية (اختياري)';

  @override
  String get registrationExpiry => 'انتهاء الاستمارة';

  @override
  String get insuranceExpiry => 'انتهاء التأمين';

  @override
  String get inspectionExpiry => 'انتهاء الفحص الدوري';

  @override
  String get notSet => 'غير محدد';

  @override
  String get chooseDate => 'تحديد';

  @override
  String get loadingCars => 'جاري تحميل سياراتك';

  @override
  String get firstCarMessage => 'ستظهر حالة السيارة وسجلها هنا.';

  @override
  String get mileageNotRecorded => 'العداد غير مسجل';

  @override
  String get activeVehicle => 'السيارة الحالية';

  @override
  String get other => 'أخرى';

  @override
  String get brandToyota => 'تويوتا';

  @override
  String get brandHonda => 'هوندا';

  @override
  String get brandNissan => 'نيسان';

  @override
  String get brandHyundai => 'هيونداي';

  @override
  String get brandKia => 'كيا';

  @override
  String get brandFord => 'فورد';

  @override
  String get brandChevrolet => 'شيفروليه';

  @override
  String get brandMercedes => 'مرسيدس';

  @override
  String get brandBmw => 'بي إم دبليو';

  @override
  String get brandAudi => 'أودي';

  @override
  String get brandLexus => 'لكزس';

  @override
  String get brandMazda => 'مازدا';

  @override
  String get brandMitsubishi => 'ميتسوبيشي';

  @override
  String get brandJeep => 'جيب';

  @override
  String get brandGmc => 'جي إم سي';

  @override
  String get brandDodge => 'دودج';

  @override
  String get brandInfiniti => 'إنفينيتي';

  @override
  String get brandSuzuki => 'سوزوكي';

  @override
  String get brandVolkswagen => 'فولكس فاجن';

  @override
  String get vehicleRecordTitle => 'سجل السيارة';

  @override
  String get preparingVehicleRecord => 'جاري تجهيز سجل السيارة';

  @override
  String get emptyVehicleRecord => 'لا يوجد سجل للسيارة حتى الآن';

  @override
  String get emptyVehicleRecordMessage =>
      'ستظهر الفحوصات والصيانة والإصلاحات هنا زمنيًا.';

  @override
  String get vehicleTimeline => 'الخط الزمني للسيارة';

  @override
  String get diagnosesCount => 'الفحوصات';

  @override
  String get repairsCount => 'الإصلاحات';

  @override
  String get maintenanceCount => 'الصيانة';

  @override
  String get obdScan => 'فحص OBD';

  @override
  String get codesRead => 'تمت القراءة';

  @override
  String get repairReview => 'مراجعة إصلاح';

  @override
  String get reviewStatus => 'مراجعة';

  @override
  String get recordedRepair => 'إصلاح مسجل';

  @override
  String get recordedStatus => 'مسجلة';

  @override
  String get issueReturned => 'عاد العطل';

  @override
  String get noObdCodesRecorded => 'بدون أكواد OBD';

  @override
  String get checkAndDiagnosis => 'فحص وتشخيص';

  @override
  String get repairType => 'إصلاح';

  @override
  String get maintenanceType => 'صيانة';

  @override
  String get issueOngoing => 'العطل مستمر';

  @override
  String get statusNew => 'جديد';

  @override
  String get statusMonitoring => 'تحت المراقبة';

  @override
  String get statusRepairNeeded => 'يحتاج إصلاح';

  @override
  String get maintenanceReminders => 'تنبيهات الصيانة الدورية';

  @override
  String get loadingMaintenanceReminders => 'جاري تحميل مواعيد الصيانة';

  @override
  String get noMaintenanceReminders => 'لا توجد مواعيد صيانة';

  @override
  String get noMaintenanceRemindersMessage => 'أضف موعدًا وسنساعدك على تذكره.';

  @override
  String get addReminder => 'إضافة موعد';

  @override
  String overdueDays(int days) {
    return 'متأخر منذ $days يوم';
  }

  @override
  String daysRemaining(int days) {
    return 'باقي $days يوم';
  }

  @override
  String get newMaintenanceReminder => 'تنبيه صيانة جديد';

  @override
  String get maintenanceTypeExample => 'نوع الصيانة (مثال: تغيير الزيت)';

  @override
  String get notesOptional => 'ملاحظات (اختياري)';

  @override
  String dateLabel(String date) {
    return 'التاريخ: $date';
  }

  @override
  String get change => 'تغيير';

  @override
  String maintenanceHistoryFor(String car) {
    return 'سجل صيانة $car';
  }

  @override
  String get noMaintenanceHistory => 'لا يوجد سجل صيانة لهذه السيارة بعد';

  @override
  String get deleteConfirmation => 'تأكيد الحذف';

  @override
  String get deleteMaintenanceConfirm => 'هل تريد حذف هذا السجل نهائيًا؟';

  @override
  String get viewInvoice => 'عرض الفاتورة';

  @override
  String get addMaintenanceRecord => 'إضافة سجل صيانة';

  @override
  String get maintenanceCategory => 'نوع الصيانة';

  @override
  String get workDescriptionOptional => 'وصف العمل (اختياري)';

  @override
  String get workDescriptionHint => 'مثال: تغيير الزيت + الفلتر';

  @override
  String get serviceMileageOptional => 'الكيلومترات عند الصيانة (اختياري)';

  @override
  String get partNumberOptional => 'رقم القطعة (اختياري)';

  @override
  String get partNumberHint => 'مثال: 90915-YZZD4';

  @override
  String get workshopNameOptional => 'الورشة (اختياري)';

  @override
  String get workshopNameHint => 'اسم الورشة';

  @override
  String get date => 'التاريخ';

  @override
  String get costOptional => 'التكلفة (اختياري)';

  @override
  String get additionalDetailsHint => 'تفاصيل إضافية';

  @override
  String get invoiceImageOptional => 'صورة الفاتورة (اختياري)';

  @override
  String get attachInvoice => 'إرفاق صورة الفاتورة';

  @override
  String get saveRecord => 'حفظ السجل';

  @override
  String get workTypeRequired => 'اكتب نوع العمل';

  @override
  String get saveFailed => 'تعذر الحفظ، حاول مرة أخرى';

  @override
  String nextMaintenanceFor(String category) {
    return 'موعد $category القادم';
  }

  @override
  String get autoReminderNote => 'تم إنشاؤه تلقائيًا بعد تسجيل صيانة';

  @override
  String get categoryEngineOil => 'تغيير زيت المحرك';

  @override
  String get categoryOilFilter => 'فلتر الزيت';

  @override
  String get categoryAirFilter => 'فلتر الهواء';

  @override
  String get categorySparkPlugs => 'البواجي';

  @override
  String get categoryBrakePads => 'فحمات الفرامل (تيل الفرامل)';

  @override
  String get categoryBattery => 'البطارية';

  @override
  String get categoryTires => 'الكفرات (الإطارات)';

  @override
  String get categoryCabinFilter => 'فلتر المكيف';

  @override
  String get categoryBrakeFluid => 'سائل الفرامل';

  @override
  String get obdConnectTitle => 'ربط جهاز OBD-II';

  @override
  String get checkingObdCapability => 'جاري التحقق من إمكانات الفحص...';

  @override
  String savedObdScan(int count) {
    return 'نتيجة آخر فحص محفوظة ($count كود)';
  }

  @override
  String get obdDirectUnavailable =>
      'الفحص المباشر عبر OBD غير متاح على هذا الجهاز حاليًا';

  @override
  String get findPairedObd => 'ابحث عن أجهزة OBD المقترنة بجوالك';

  @override
  String get findNearbyObd => 'ابحث عن أجهزة OBD الحديثة القريبة';

  @override
  String get searching => 'جاري البحث...';

  @override
  String get noNearbyObd =>
      'لم نجد جهاز OBD قريبًا. تأكد من تشغيل المحول ثم أعد البحث.';

  @override
  String get noPairedObd =>
      'لم نجد أجهزة مقترنة. قرّن جهاز OBD من إعدادات البلوتوث ثم أعد المحاولة.';

  @override
  String get chooseObdDevice => 'اختر جهاز OBD من القائمة';

  @override
  String get obdSearchFailed =>
      'تعذر البحث. تحقق من تشغيل البلوتوث ومنح الصلاحيات.';

  @override
  String connectingToDevice(String device) {
    return 'جاري الاتصال بـ $device...';
  }

  @override
  String connectedToDevice(String device) {
    return 'متصل بجهاز $device';
  }

  @override
  String get obdConnectionFailed =>
      'فشل الاتصال. تحقق من تشغيل الجهاز واقترانه بالهاتف.';

  @override
  String get readingEngineTransmissionCodes =>
      'جاري قراءة أكواد المحرك وناقل الحركة...';

  @override
  String get transmissionModuleUnavailable =>
      'وحدة ناقل الحركة غير متاحة على هذا الجهاز أو السيارة';

  @override
  String get noStoredFaultCodes => 'لا توجد أكواد أعطال محفوظة حاليًا';

  @override
  String faultCodesFound(int total, int engine, int transmission) {
    return 'تم العثور على $total كود (محرك: $engine، ناقل حركة: $transmission)';
  }

  @override
  String get clearCodesTitle => 'تأكيد المسح';

  @override
  String get clearCodesConfirm =>
      'هل أنت متأكد من مسح جميع أكواد الأعطال؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get confirmClear => 'نعم، امسح';

  @override
  String get clearingCodes => 'جاري مسح الأكواد...';

  @override
  String get codesCleared => 'تم مسح جميع أكواد الأعطال بنجاح';

  @override
  String get clearCodesFailed => 'تعذر مسح الأكواد. أعد المحاولة.';

  @override
  String get disconnected => 'تم قطع الاتصال';

  @override
  String get disconnectedSaved =>
      'تم قطع الاتصال — نتيجة الفحص محفوظة وجاهزة للتشخيص';

  @override
  String get searchLinkFailed => 'تعذر فتح رابط البحث';

  @override
  String get obdTranscriptCopied => 'تم نسخ سجل OBD';

  @override
  String get dtcGuide => 'دليل أكواد الأعطال';

  @override
  String get chooseConnectionMethod => 'اختر طريقة الاتصال';

  @override
  String get searchNearbyDevices => 'بحث عن أجهزة قريبة';

  @override
  String get showPairedDevices => 'عرض الأجهزة المقترنة';

  @override
  String get connected => 'متصل';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get readCodes => 'قراءة الأكواد';

  @override
  String get clearCodes => 'مسح الأكواد';

  @override
  String diagnoseWithCodes(int count) {
    return 'ابدأ التشخيص بهذه الأكواد ($count)';
  }

  @override
  String get copyObdTranscript => 'نسخ سجل OBD';

  @override
  String get obdUnavailableAlternative =>
      'يمكنك متابعة التشخيص بوصف الأعراض أو إرفاق صورة دون استخدام OBD.';

  @override
  String get nearbyDevice => 'جهاز قريب';

  @override
  String get pairedDevice => 'جهاز مقترن';

  @override
  String get classicBluetooth => 'بلوتوث';

  @override
  String get bleDescription => 'مناسب للأجهزة الحديثة والآيفون';

  @override
  String get classicBluetoothDescription => 'مناسب لأجهزة ELM327 التقليدية';

  @override
  String get findRequiredPart => 'ابحث عن القطعة المطلوبة';

  @override
  String get dtcLoadFailed => 'تعذر تحميل دليل الأكواد';

  @override
  String get dtcSearchHint => 'ابحث بالكود (مثال: P0301) أو بالوصف';

  @override
  String dtcCount(int shown, int total) {
    return '$shown من $total كود';
  }

  @override
  String get noMatchingResults => 'لا توجد نتائج مطابقة';

  @override
  String get commonCauses => 'الأسباب الشائعة:';

  @override
  String get workshopMode => 'وضع الورشة';

  @override
  String get showTechnician => 'افتح هذه الشاشة أمام الفني';

  @override
  String get workshopModeIntro =>
      'معلومات مختصرة وعملية تساعد على بدء الفحص الصحيح.';

  @override
  String get unrecorded => 'غير مسجل';

  @override
  String get noCodesRead => 'لا توجد أكواد مقروءة';

  @override
  String get noSymptomsAdded => 'لم تُضف أعراضًا';

  @override
  String get askTechnicianToCheck =>
      'اطلب من الفني التحقق من التالي قبل تغيير القطع';

  @override
  String get directTestRequired => 'تحديد سبب العطل باختبار مباشر';

  @override
  String get shareWithTechnician => 'مشاركة مع الفني';

  @override
  String get workshopSummaryDisclaimer =>
      'هذا ملخص إرشادي. يعتمد القرار النهائي على الاختبارات المباشرة التي يجريها فني مؤهل.';

  @override
  String workshopShareText(String vehicle, String mileage, String codes,
      String symptoms, String checks) {
    return 'السيارة: $vehicle\nالعداد: $mileage كم\nأكواد الفحص: $codes\nالأعراض: $symptoms\n\nأطلب التحقق من التالي قبل تغيير القطع:\n$checks\n\nيرجى شرح نتيجة الاختبارات وعدم تغيير أي قطعة قبل تأكيد سبب العطل.';
  }

  @override
  String get repairRecordTitle => 'تسجيل الإصلاح';

  @override
  String get repairActionRequired =>
      'أدخل القطع التي تم تغييرها أو الإجراء المنفذ.';

  @override
  String get repairSaveFailed =>
      'تعذر حفظ الإصلاح. تحقق من الاتصال وحاول مرة أخرى.';

  @override
  String get deleteRepairRecord => 'حذف سجل الإصلاح';

  @override
  String get deleteLinkedRepairConfirm =>
      'يوجد تحقق مرتبط بهذا الإصلاح. سيتم إخفاء سجل الإصلاح دون حذف سجل التحقق.';

  @override
  String get hideRepairConfirm => 'هل تريد إخفاء سجل الإصلاح؟';

  @override
  String get deleteRecord => 'حذف السجل';

  @override
  String get partsActuallyReplaced => 'القطع التي تم تغييرها فعليًا';

  @override
  String get partsConfirmationHint =>
      'أكد ما تم تغييره، ولا تعتمد على المقترح فقط';

  @override
  String get workPerformed => 'الإجراء المنفذ';

  @override
  String get repairMileageOptional => 'عداد السيارة وقت الإصلاح (اختياري)';

  @override
  String get saveRepair => 'حفظ الإصلاح';

  @override
  String get repairVerificationTitle => 'تحقق من الإصلاح';

  @override
  String get postRepairComparison =>
      'قارن حالة السيارة بعد الإصلاح بالبيانات السابقة دون افتراض نتيجة غير موجودة.';

  @override
  String get afterRepair => 'بعد الإصلاح';

  @override
  String get currentObdCodesOptional => 'أكواد OBD الحالية (اختياري)';

  @override
  String get currentObdCodesHint => 'مثال: P0133 P0300';

  @override
  String get symptomsAfterRepair => 'كيف أصبحت الأعراض؟';

  @override
  String get symptomsAfterRepairHint => 'اختفت، تحسنت، أو ما زالت موجودة';

  @override
  String get addPostRepairImage => 'إضافة صورة بعد الإصلاح (اختياري)';

  @override
  String get replaceImage => 'استبدال الصورة';

  @override
  String get deleteImage => 'حذف الصورة';

  @override
  String temporaryImageNotice(String mime) {
    return 'الصورة مؤقتة أثناء التحقق ($mime) ولا تُحفظ في Firestore.';
  }

  @override
  String get verifyNowButton => 'تحقق الآن';

  @override
  String removedCodes(String codes) {
    return 'الأكواد المختفية: $codes';
  }

  @override
  String remainingCodes(String codes) {
    return 'الأكواد المستمرة: $codes';
  }

  @override
  String newCodes(String codes) {
    return 'الأكواد الجديدة: $codes';
  }

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get none => 'لا توجد';

  @override
  String get verificationSuccess => 'الإصلاح يبدو ناجحًا';

  @override
  String get verificationImproved => 'تحسن، لكن يحتاج متابعة';

  @override
  String get verificationUnresolved => 'المشكلة قد لا تكون حُلّت بالكامل';

  @override
  String get verificationReturned => 'العطل عاد بعد الإصلاح';

  @override
  String get verificationInsufficient => 'لا توجد معلومات كافية للحكم';

  @override
  String get revisitWorkshop => 'يفضل إعادة زيارة الورشة للفحص.';

  @override
  String get marketplaceTitle => 'سوق قطع الغيار';

  @override
  String get sellerDashboard => 'لوحة تحكم البائع';

  @override
  String get cart => 'السلة';

  @override
  String get searchPartsHint => 'ابحث باسم القطعة أو الموديل';

  @override
  String get noPartsAvailable => 'لا توجد قطع متاحة حالياً';

  @override
  String serverErrorStatus(int status) {
    return 'خطأ من السيرفر: $status';
  }

  @override
  String get rateSeller => 'قيّم البائع';

  @override
  String get commentOptional => 'تعليق (اختياري)';

  @override
  String get send => 'إرسال';

  @override
  String get ratingSubmitted => 'تم إرسال تقييمك، شكرًا';

  @override
  String get deletePartConfirm => 'هل تريد حذف هذه القطعة نهائيًا؟';

  @override
  String get deletePartFailed => 'تعذر حذف القطعة';

  @override
  String get editPart => 'تعديل القطعة';

  @override
  String get deletePart => 'حذف القطعة';

  @override
  String get newPart => 'جديدة';

  @override
  String get usedPart => 'مستعملة';

  @override
  String sellerRating(String rating, int count) {
    return 'تقييم البائع: $rating ($count)';
  }

  @override
  String get sellerNotRated => 'البائع غير مقيّم';

  @override
  String get contactSeller => 'تواصل مع البائع';

  @override
  String callSeller(String phone) {
    return 'اتصال: $phone';
  }

  @override
  String get addedToCart => 'مضافة للسلة';

  @override
  String get addToCart => 'أضف للسلة';

  @override
  String get rateThisSeller => 'قيّم هذا البائع';

  @override
  String get shoppingCart => 'سلة المشتريات';

  @override
  String get emptyCart => 'السلة فارغة حالياً';

  @override
  String get total => 'الإجمالي';

  @override
  String get checkout => 'إتمام الشراء';

  @override
  String get paymentCreationFailed => 'تعذر إنشاء عملية الدفع';

  @override
  String get addPartForSale => 'إضافة قطعة للبيع';

  @override
  String get partName => 'اسم القطعة';

  @override
  String get partNameHint => 'مثال: حامل مساند خلفي';

  @override
  String get compatibleVehicleBrand => 'شركة السيارة المتوافقة';

  @override
  String get partCondition => 'حالة القطعة';

  @override
  String get partManufacturerOptional => 'الشركة المصنّعة للقطعة (اختياري)';

  @override
  String get partManufacturerHint => 'مثال: Bosch، Denso، أصلي وكالة';

  @override
  String get priceOptional => 'السعر (اختياري)';

  @override
  String get sellerPhone => 'رقم جوالك للتواصل';

  @override
  String get partNotesHint => 'حالة القطعة وتفاصيل أخرى';

  @override
  String get oemNumberOptional => 'رقم القطعة الأصلي OEM (اختياري)';

  @override
  String partNumberLabel(String number) {
    return 'رقم القطعة: $number';
  }

  @override
  String partManufacturerLabel(String manufacturer) {
    return 'الشركة المصنّعة: $manufacturer';
  }

  @override
  String get partImageOptional => 'صورة القطعة (اختياري)';

  @override
  String get attachPartImage => 'إرفاق صورة القطعة';

  @override
  String get saveChanges => 'حفظ التعديلات';

  @override
  String get publishPart => 'نشر القطعة';

  @override
  String get requiredPartFields => 'عبّئ اسم القطعة والشركة ورقم الجوال';

  @override
  String get myListings => 'منتجاتي';

  @override
  String get soldOrders => 'طلبات مبيعة';

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get listedProducts => 'منتجاتي المعروضة';

  @override
  String get noListings => 'لم تعرض أي قطعة بعد';

  @override
  String get mySalesOrders => 'طلبات بيعي';

  @override
  String get noSalesOrders => 'لا توجد طلبات بيع بعد';

  @override
  String get sellerDashboardLoadFailed => 'تعذر تحميل بيانات لوحة البائع';

  @override
  String get subscriptionStatusLoadFailed => 'تعذر جلب حالة الاشتراك';

  @override
  String get subscriptionActive => 'اشتراكك نشط';

  @override
  String get unlockFullApp => 'افتح كامل إمكانيات التطبيق';

  @override
  String get yearlyPlan => 'خطة سنوية';

  @override
  String get monthlyPlan => 'خطة شهرية';

  @override
  String subscriptionEndsOn(String plan, String date) {
    return '$plan — ينتهي في $date';
  }

  @override
  String freeUsageStatus(int used, int limit) {
    return 'استخدمت $used من $limit تشخيصات مجانية هذا الشهر';
  }

  @override
  String get subscriptionBenefits => 'مميزات الاشتراك';

  @override
  String get unlimitedAiDiagnoses => 'تشخيصات ذكاء اصطناعي غير محدودة';

  @override
  String get unlimitedAiDiagnosesDescription =>
      'شخّص أي عدد من مشاكل سيارتك بدون حد شهري';

  @override
  String get expertAssistant => 'مساعد اسأل خبير السيارات';

  @override
  String get expertAssistantDescription =>
      'اسأل أي سؤال متابعة بعد كل تشخيص بدون حدود';

  @override
  String get professionalPdfReports => 'تقارير PDF احترافية';

  @override
  String get professionalPdfReportsDescription =>
      'تقرير كامل برمز QR للتحقق، جاهز للطباعة أو المشاركة';

  @override
  String get prioritySupport => 'أولوية بالدعم الفني';

  @override
  String get prioritySupportDescription =>
      'ردود أسرع على استفساراتك ومشاكلك التقنية';

  @override
  String get choosePlan => 'اختر الباقة';

  @override
  String get yearly => 'سنوي';

  @override
  String get monthly => 'شهري';

  @override
  String get yearlyValue => 'أفضل قيمة — يعادل 9.92 ر.س شهريًا';

  @override
  String get bestValue => 'الأفضل قيمة';

  @override
  String get monthlyFlexibility => 'مرونة الإلغاء بأي وقت';

  @override
  String get subscribeNow => 'اشترك الآن';

  @override
  String get repairPdfTitle => 'تقرير إصلاح السيارة';

  @override
  String get diagnosisPdfTitle => 'تقرير تشخيص السيارة الذكي';

  @override
  String get pdfVehicle => 'السيارة';

  @override
  String get pdfDate => 'التاريخ';

  @override
  String get pdfOdometer => 'العداد';

  @override
  String get pdfDiagnosis => 'التشخيص';

  @override
  String get pdfQuoteReview => 'مراجعة العرض';

  @override
  String get pdfRepair => 'الإصلاح';

  @override
  String get pdfCost => 'التكلفة';

  @override
  String get pdfVerification => 'التحقق';

  @override
  String get pdfNotSpecified => 'غير محدد';

  @override
  String get pdfAvailable => 'متاح';

  @override
  String get pdfDocumentationDisclaimer =>
      'هذا التقرير توثيقي ولا يغني عن الفحص الفني.';

  @override
  String get pdfReportNumber => 'رقم التقرير';

  @override
  String get pdfProblemDescription => 'وصف المشكلة';

  @override
  String get pdfSeverity => 'الخطورة';

  @override
  String get pdfConfidence => 'نسبة الثقة';

  @override
  String get pdfExplanation => 'التفسير';

  @override
  String get pdfRecommendations => 'التوصيات';

  @override
  String get pdfRequiredParts => 'القطع المحتملة';

  @override
  String get pdfPart => 'القطعة';

  @override
  String get pdfPrice => 'السعر';

  @override
  String get pdfSource => 'المصدر';

  @override
  String get pdfEstimatedCost => 'التكلفة التقديرية';

  @override
  String get pdfAiDisclaimer =>
      'هذا تشخيص أولي توجيهي بالذكاء الاصطناعي، وليس بديلاً عن فحص فني معتمد.';

  @override
  String get pdfQrInstruction => 'امسح الرمز للتحقق من محتوى التقرير';

  @override
  String get contactSignInRequired => 'سجّل الدخول للتواصل مع البائع';

  @override
  String get sellerContactUnavailable => 'بيانات تواصل البائع غير متاحة';

  @override
  String get sellerContactRateLimited => 'طلبات تواصل كثيرة. حاول لاحقًا.';

  @override
  String get sellerContactFailed => 'تعذّر جلب بيانات تواصل البائع';

  @override
  String get historyPageTitle => 'سجل التشخيصات';

  @override
  String get historyLoading => 'جاري تحميل سجل السيارة';

  @override
  String get historyFilterAll => 'الكل';

  @override
  String get historyDeleteTitle => 'حذف التشخيص';

  @override
  String get historyDeleteConfirm => 'هل تريد حذف هذا التشخيص من السجل؟';

  @override
  String get historyDeleteFailed => 'تعذر حذف العنصر';

  @override
  String get historyConnectionFailed => 'تعذر الاتصال بالسيرفر';

  @override
  String get historyUnknownSeverity => 'غير محددة';

  @override
  String get historySeverityLabel => 'الخطورة';

  @override
  String get historyRecommendationsLabel => 'التوصيات';

  @override
  String get historyEstimatedCostLabel => 'التكلفة التقديرية';

  @override
  String get historyEmpty => 'لا يوجد أي تشخيصات محفوظة بعد';

  @override
  String get historyNoFiltered => 'لا توجد تشخيصات بمستوى خطورة';

  @override
  String get historyUntitled => 'تشخيص بدون عنوان';

  @override
  String get historyLoadFailed => 'تعذر تحميل السجل';

  @override
  String get historyRetry => 'إعادة المحاولة';

  @override
  String get privacyAndAccount => 'الخصوصية والحساب';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicySubtitle =>
      'اطّلع على كيفية استخدام بياناتك وحمايتها';

  @override
  String get deleteMyAccount => 'حذف حسابي';

  @override
  String get deleteAccountSubtitle => 'حذف الحساب والبيانات الشخصية نهائيًا';

  @override
  String get deleteAccountTitle => 'حذف حساب Smart Car Check';

  @override
  String get deleteAccountIntro =>
      'سيؤدي حذف الحساب إلى إزالة بياناتك الشخصية نهائيًا.';

  @override
  String get deleteAccountDeletes =>
      'سيتم حذف بيانات الحساب والسيارات والتشخيصات والصيانة والإصلاحات وإعلانات القطع والتقييمات المرتبطة بك.';

  @override
  String get deleteAccountRetains =>
      'قد نحتفظ بسجلات مالية محدودة بعد نزع بيانات الهوية لمدة تصل إلى 7 سنوات للالتزامات النظامية والمحاسبية.';

  @override
  String get deleteAccountIrreversible =>
      'لا يمكن التراجع عن هذا الإجراء بعد اكتماله.';

  @override
  String get deleteAccountConfirm => 'أفهم ذلك، احذف حسابي';

  @override
  String get deleteAccountCancel => 'إلغاء';

  @override
  String get deleteAccountPasswordPrompt => 'أدخل كلمة المرور لتأكيد هويتك';

  @override
  String get deleteAccountOtpPrompt => 'أدخل رمز التحقق المرسل إلى جوالك';

  @override
  String get deleteAccountOtpSent => 'تم إرسال رمز تحقق جديد';

  @override
  String get deleteAccountReauthFailed => 'تعذر تأكيد هويتك. أعد المحاولة.';

  @override
  String get deleteAccountProcessing => 'جارٍ حذف الحساب والبيانات…';

  @override
  String get deleteAccountCompleted => 'اكتمل حذف الحساب';

  @override
  String get deleteAccountRetryRequired =>
      'تعذر إكمال بعض خطوات الحذف. حسابك موقوف عن إنشاء بيانات جديدة وسيُستأنف الطلب بأمان عند إعادة المحاولة.';

  @override
  String get deleteAccountRecentAuthRequired =>
      'يلزم تأكيد هويتك مجددًا قبل الحذف.';

  @override
  String get deleteAccountNetworkError =>
      'تعذر الاتصال بالخادم. لم يتم اعتبار الحساب محذوفًا.';

  @override
  String get accountDeletionLearnMore => 'ما الذي يحدث لبياناتي؟';

  @override
  String get confirmAction => 'تأكيد';
}
