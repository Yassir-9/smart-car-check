import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'تشخيص السيارة الذكي'**
  String get appTitle;

  /// No description provided for @preparingApp.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز Smart Car Check'**
  String get preparingApp;

  /// No description provided for @onboardingUnderstandTitle.
  ///
  /// In ar, this message translates to:
  /// **'افهم مشكلة سيارتك'**
  String get onboardingUnderstandTitle;

  /// No description provided for @onboardingUnderstandBody.
  ///
  /// In ar, this message translates to:
  /// **'تحليل إرشادي واضح يجمع الأعراض وبيانات السيارة.'**
  String get onboardingUnderstandBody;

  /// No description provided for @onboardingConnectTitle.
  ///
  /// In ar, this message translates to:
  /// **'وصّل OBD أو اشرح الأعراض'**
  String get onboardingConnectTitle;

  /// No description provided for @onboardingConnectBody.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الفحص المناسبة وتجاوز ما لا تحتاجه.'**
  String get onboardingConnectBody;

  /// No description provided for @onboardingChecksTitle.
  ///
  /// In ar, this message translates to:
  /// **'احصل على خطوات فحص واضحة'**
  String get onboardingChecksTitle;

  /// No description provided for @onboardingChecksBody.
  ///
  /// In ar, this message translates to:
  /// **'اعرف ما الذي يجب فحصه قبل تغيير أي قطعة.'**
  String get onboardingChecksBody;

  /// No description provided for @onboardingHistoryTitle.
  ///
  /// In ar, this message translates to:
  /// **'احتفظ بسجل سيارتك'**
  String get onboardingHistoryTitle;

  /// No description provided for @onboardingHistoryBody.
  ///
  /// In ar, this message translates to:
  /// **'تابع الأعطال والصيانة والإصلاحات في مكان واحد.'**
  String get onboardingHistoryBody;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @start.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ'**
  String get start;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول برقم الجوال'**
  String get loginTitle;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمز تحقق مكوّنًا من 6 أرقام إلى جوالك'**
  String get otpSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال'**
  String get phoneLabel;

  /// No description provided for @phoneHelper.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك أيضًا إدخال الرقم بصيغة 05XXXXXXXX'**
  String get phoneHelper;

  /// No description provided for @otpLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get otpLabel;

  /// No description provided for @sendOtp.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رمز التحقق'**
  String get sendOtp;

  /// No description provided for @verifyOtp.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الرمز'**
  String get verifyOtp;

  /// No description provided for @changePhone.
  ///
  /// In ar, this message translates to:
  /// **'تغيير رقم الجوال'**
  String get changePhone;

  /// No description provided for @invalidSaudiPhone.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم جوال سعودي صحيح'**
  String get invalidSaudiPhone;

  /// No description provided for @incompleteOtp.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رمز التحقق كاملًا'**
  String get incompleteOtp;

  /// No description provided for @authUnexpected.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع'**
  String get authUnexpected;

  /// No description provided for @authAutomaticFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر التحقق التلقائي، أدخل الرمز يدويًا'**
  String get authAutomaticFailed;

  /// No description provided for @authSendFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إرسال رمز التحقق. تحقق من رقم الجوال وحاول مرة أخرى.'**
  String get authSendFailed;

  /// No description provided for @authSessionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الجلسة، أعد إرسال الرمز'**
  String get authSessionExpired;

  /// No description provided for @authInvalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم الجوال غير صحيح، تأكد من الصيغة'**
  String get authInvalidPhone;

  /// No description provided for @authInvalidCode.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق غير صحيح'**
  String get authInvalidCode;

  /// No description provided for @authCodeExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الرمز، أعد الإرسال'**
  String get authCodeExpired;

  /// No description provided for @authTooManyRequests.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كثيرة، حاول لاحقًا'**
  String get authTooManyRequests;

  /// No description provided for @authRequestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال الطلب الآن. حاول مرة أخرى.'**
  String get authRequestFailed;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navHome;

  /// No description provided for @navDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'الفحص'**
  String get navDiagnosis;

  /// No description provided for @navCars.
  ///
  /// In ar, this message translates to:
  /// **'سياراتي'**
  String get navCars;

  /// No description provided for @navHistory.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get navHistory;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @addFirstCar.
  ///
  /// In ar, this message translates to:
  /// **'أضف سيارتك الأولى لبدء الفحص'**
  String get addFirstCar;

  /// No description provided for @addCar.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سيارة'**
  String get addCar;

  /// No description provided for @currentCar.
  ///
  /// In ar, this message translates to:
  /// **'السيارة الحالية'**
  String get currentCar;

  /// No description provided for @carHealth.
  ///
  /// In ar, this message translates to:
  /// **'حالة السيارة'**
  String get carHealth;

  /// No description provided for @changeCar.
  ///
  /// In ar, this message translates to:
  /// **'تغيير السيارة'**
  String get changeCar;

  /// No description provided for @healthGood.
  ///
  /// In ar, this message translates to:
  /// **'جيدة'**
  String get healthGood;

  /// No description provided for @healthAttention.
  ///
  /// In ar, this message translates to:
  /// **'تحتاج انتباه'**
  String get healthAttention;

  /// No description provided for @healthUrgent.
  ///
  /// In ar, this message translates to:
  /// **'عاجلة'**
  String get healthUrgent;

  /// No description provided for @healthUnknown.
  ///
  /// In ar, this message translates to:
  /// **'غير محددة'**
  String get healthUnknown;

  /// No description provided for @mileageKm.
  ///
  /// In ar, this message translates to:
  /// **'{mileage} كم'**
  String mileageKm(int mileage);

  /// No description provided for @startCarCheck.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ فحص السيارة'**
  String get startCarCheck;

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'إجراءات سريعة'**
  String get quickActions;

  /// No description provided for @obdCheck.
  ///
  /// In ar, this message translates to:
  /// **'فحص OBD'**
  String get obdCheck;

  /// No description provided for @readCarCodes.
  ///
  /// In ar, this message translates to:
  /// **'قراءة أكواد السيارة'**
  String get readCarCodes;

  /// No description provided for @describeSymptoms.
  ///
  /// In ar, this message translates to:
  /// **'وصف الأعراض'**
  String get describeSymptoms;

  /// No description provided for @explainProblem.
  ///
  /// In ar, this message translates to:
  /// **'اشرح المشكلة'**
  String get explainProblem;

  /// No description provided for @beforeYouPay.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تدفع'**
  String get beforeYouPay;

  /// No description provided for @reviewWorkshopQuote.
  ///
  /// In ar, this message translates to:
  /// **'راجع عرض الورشة'**
  String get reviewWorkshopQuote;

  /// No description provided for @carRecord.
  ///
  /// In ar, this message translates to:
  /// **'سجل السيارة'**
  String get carRecord;

  /// No description provided for @checksAndRepairs.
  ///
  /// In ar, this message translates to:
  /// **'الفحوصات والإصلاحات'**
  String get checksAndRepairs;

  /// No description provided for @unresolvedIssues.
  ///
  /// In ar, this message translates to:
  /// **'الأعطال غير المحلولة'**
  String get unresolvedIssues;

  /// No description provided for @noUnresolvedIssues.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أعطال غير محلولة'**
  String get noUnresolvedIssues;

  /// No description provided for @returnedAfterRepair.
  ///
  /// In ar, this message translates to:
  /// **'عاد بعد إصلاح'**
  String get returnedAfterRepair;

  /// No description provided for @additionalServices.
  ///
  /// In ar, this message translates to:
  /// **'خدمات إضافية'**
  String get additionalServices;

  /// No description provided for @beforePayWorkshop.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تدفع للورشة'**
  String get beforePayWorkshop;

  /// No description provided for @reviewRepairWithCarData.
  ///
  /// In ar, this message translates to:
  /// **'راجع اقتراح الإصلاح مع بيانات سيارتك'**
  String get reviewRepairWithCarData;

  /// No description provided for @subscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscription;

  /// No description provided for @partsMarketplace.
  ///
  /// In ar, this message translates to:
  /// **'سوق قطع الغيار'**
  String get partsMarketplace;

  /// No description provided for @additionalService.
  ///
  /// In ar, this message translates to:
  /// **'خدمة إضافية'**
  String get additionalService;

  /// No description provided for @repairPendingVerification.
  ///
  /// In ar, this message translates to:
  /// **'إصلاح ينتظر التحقق'**
  String get repairPendingVerification;

  /// No description provided for @verifyRepairSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تحقق هل المشكلة اختفت بعد الإصلاح.'**
  String get verifyRepairSubtitle;

  /// No description provided for @verifyNow.
  ///
  /// In ar, this message translates to:
  /// **'تحقق الآن'**
  String get verifyNow;

  /// No description provided for @repairedIssueReturned.
  ///
  /// In ar, this message translates to:
  /// **'عاد عطل سبق إصلاحه'**
  String get repairedIssueReturned;

  /// No description provided for @upcomingMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة القادمة'**
  String get upcomingMaintenance;

  /// No description provided for @noMaintenanceAdded.
  ///
  /// In ar, this message translates to:
  /// **'لم تضف موعد صيانة بعد'**
  String get noMaintenanceAdded;

  /// No description provided for @latestCheck.
  ///
  /// In ar, this message translates to:
  /// **'آخر فحص'**
  String get latestCheck;

  /// No description provided for @noPreviousCheck.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد فحص سابق'**
  String get noPreviousCheck;

  /// No description provided for @repaired.
  ///
  /// In ar, this message translates to:
  /// **'تم الإصلاح'**
  String get repaired;

  /// No description provided for @followUp.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get followUp;

  /// No description provided for @viewAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get viewAll;

  /// No description provided for @preferences.
  ///
  /// In ar, this message translates to:
  /// **'التفضيلات'**
  String get preferences;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get darkMode;

  /// No description provided for @darkModeEnabled.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن مفعّل'**
  String get darkModeEnabled;

  /// No description provided for @lightModeEnabled.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الفاتح مفعّل'**
  String get lightModeEnabled;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @manageCars.
  ///
  /// In ar, this message translates to:
  /// **'إدارة سياراتي'**
  String get manageCars;

  /// No description provided for @manageCarsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أو تعديل بيانات سياراتك'**
  String get manageCarsSubtitle;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار 1.0.0'**
  String get version;

  /// No description provided for @appDescription.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق يستخدم الذكاء الاصطناعي لتقديم تشخيص أولي توجيهي لمشاكل السيارات بناءً على وصف المستخدم وبيانات السيارة.'**
  String get appDescription;

  /// No description provided for @disclaimerText.
  ///
  /// In ar, this message translates to:
  /// **'هذا التشخيص أولي وتوجيهي فقط، ولا يغني عن فحص فني معتمد من ورشة متخصصة قبل اتخاذ أي قرار يخص السلامة.'**
  String get disclaimerText;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @back.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get back;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @replace.
  ///
  /// In ar, this message translates to:
  /// **'استبدال'**
  String get replace;

  /// No description provided for @camera.
  ///
  /// In ar, this message translates to:
  /// **'التقاط صورة'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In ar, this message translates to:
  /// **'اختيار من الصور'**
  String get gallery;

  /// No description provided for @diagnosisTitle.
  ///
  /// In ar, this message translates to:
  /// **'فحص السيارة'**
  String get diagnosisTitle;

  /// No description provided for @preparingDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز الفحص'**
  String get preparingDiagnosis;

  /// No description provided for @selectCarToContinue.
  ///
  /// In ar, this message translates to:
  /// **'اختر سيارة للمتابعة.'**
  String get selectCarToContinue;

  /// No description provided for @selectDiagnosisSource.
  ///
  /// In ar, this message translates to:
  /// **'اختر مصدرًا واحدًا على الأقل للفحص.'**
  String get selectDiagnosisSource;

  /// No description provided for @diagnosisInputRequired.
  ///
  /// In ar, this message translates to:
  /// **'أضف وصفًا للأعراض أو أكواد OBD أو صورة.'**
  String get diagnosisInputRequired;

  /// No description provided for @freeDiagnosisLimitReached.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الحد المجاني لهذا الشهر. يمكنك إدارة الاشتراك من الصفحة الرئيسية.'**
  String get freeDiagnosisLimitReached;

  /// No description provided for @diagnosisRequestFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إكمال الفحص الآن ({status})'**
  String diagnosisRequestFailed(int status);

  /// No description provided for @serverConnectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالسيرفر'**
  String get serverConnectionFailed;

  /// No description provided for @diagnosisStepCar.
  ///
  /// In ar, this message translates to:
  /// **'السيارة'**
  String get diagnosisStepCar;

  /// No description provided for @diagnosisStepSources.
  ///
  /// In ar, this message translates to:
  /// **'مصادر الفحص'**
  String get diagnosisStepSources;

  /// No description provided for @diagnosisStepDetails.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get diagnosisStepDetails;

  /// No description provided for @diagnosisStepReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة'**
  String get diagnosisStepReview;

  /// No description provided for @chooseVehicle.
  ///
  /// In ar, this message translates to:
  /// **'اختر السيارة'**
  String get chooseVehicle;

  /// No description provided for @chooseVehicleSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حدد السيارة التي تريد فحصها.'**
  String get chooseVehicleSubtitle;

  /// No description provided for @chooseSources.
  ///
  /// In ar, this message translates to:
  /// **'اختر مصادر الفحص'**
  String get chooseSources;

  /// No description provided for @chooseSourcesSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك الجمع بين أكثر من مصدر للحصول على نتيجة أوضح.'**
  String get chooseSourcesSubtitle;

  /// No description provided for @enterDiagnosisDetails.
  ///
  /// In ar, this message translates to:
  /// **'أدخل تفاصيل الفحص'**
  String get enterDiagnosisDetails;

  /// No description provided for @enterDiagnosisDetailsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف البيانات المتاحة لكل مصدر اخترته.'**
  String get enterDiagnosisDetailsSubtitle;

  /// No description provided for @reviewDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'راجع الطلب'**
  String get reviewDiagnosis;

  /// No description provided for @reviewDiagnosisSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من البيانات قبل بدء التحليل.'**
  String get reviewDiagnosisSubtitle;

  /// No description provided for @obdCodes.
  ///
  /// In ar, this message translates to:
  /// **'أكواد OBD'**
  String get obdCodes;

  /// No description provided for @obdCodesAvailable.
  ///
  /// In ar, this message translates to:
  /// **'تم العثور على {count} كود'**
  String obdCodesAvailable(int count);

  /// No description provided for @noObdCodes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد محفوظة'**
  String get noObdCodes;

  /// No description provided for @connectObd.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال بجهاز OBD'**
  String get connectObd;

  /// No description provided for @manageObd.
  ///
  /// In ar, this message translates to:
  /// **'إدارة اتصال OBD'**
  String get manageObd;

  /// No description provided for @symptoms.
  ///
  /// In ar, this message translates to:
  /// **'الأعراض'**
  String get symptoms;

  /// No description provided for @symptomsHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: اهتزاز عند الوقوف أو صوت عند التسارع'**
  String get symptomsHint;

  /// No description provided for @diagnosisImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة المشكلة'**
  String get diagnosisImage;

  /// No description provided for @diagnosisImageHint.
  ///
  /// In ar, this message translates to:
  /// **'مثل لمبة تحذير أو جزء ظاهر من السيارة'**
  String get diagnosisImageHint;

  /// No description provided for @selectImage.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة'**
  String get selectImage;

  /// No description provided for @imageAttached.
  ///
  /// In ar, this message translates to:
  /// **'تم إرفاق صورة'**
  String get imageAttached;

  /// No description provided for @sourceObd.
  ///
  /// In ar, this message translates to:
  /// **'أكواد OBD'**
  String get sourceObd;

  /// No description provided for @sourceSymptoms.
  ///
  /// In ar, this message translates to:
  /// **'وصف الأعراض'**
  String get sourceSymptoms;

  /// No description provided for @sourceImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get sourceImage;

  /// No description provided for @selectedSources.
  ///
  /// In ar, this message translates to:
  /// **'المصادر المختارة'**
  String get selectedSources;

  /// No description provided for @vehicle.
  ///
  /// In ar, this message translates to:
  /// **'السيارة'**
  String get vehicle;

  /// No description provided for @startDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'بدء التشخيص'**
  String get startDiagnosis;

  /// No description provided for @analyzing.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحليل...'**
  String get analyzing;

  /// No description provided for @analyzingDiagnosisData.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحليل بيانات الفحص'**
  String get analyzingDiagnosisData;

  /// No description provided for @analysisMayTakeMoments.
  ///
  /// In ar, this message translates to:
  /// **'قد يستغرق ذلك لحظات قليلة'**
  String get analysisMayTakeMoments;

  /// No description provided for @analysisStageSources.
  ///
  /// In ar, this message translates to:
  /// **'تجميع مصادر الفحص'**
  String get analysisStageSources;

  /// No description provided for @analysisStageSafety.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة مؤشرات السلامة'**
  String get analysisStageSafety;

  /// No description provided for @analysisStageResult.
  ///
  /// In ar, this message translates to:
  /// **'إعداد النتيجة والخطوات المقترحة'**
  String get analysisStageResult;

  /// No description provided for @analysisStagesNotice.
  ///
  /// In ar, this message translates to:
  /// **'هذه مراحل عرض عامة وليست مؤشر تقدم لحظيًا من الخادم.'**
  String get analysisStagesNotice;

  /// No description provided for @diagnosisResult.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة الفحص'**
  String get diagnosisResult;

  /// No description provided for @severity.
  ///
  /// In ar, this message translates to:
  /// **'مستوى الخطورة'**
  String get severity;

  /// No description provided for @severityCritical.
  ///
  /// In ar, this message translates to:
  /// **'حرج'**
  String get severityCritical;

  /// No description provided for @severityHigh.
  ///
  /// In ar, this message translates to:
  /// **'مرتفع'**
  String get severityHigh;

  /// No description provided for @severityMedium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get severityMedium;

  /// No description provided for @severityLow.
  ///
  /// In ar, this message translates to:
  /// **'منخفض'**
  String get severityLow;

  /// No description provided for @canDrive.
  ///
  /// In ar, this message translates to:
  /// **'هل يمكن القيادة؟'**
  String get canDrive;

  /// No description provided for @whatWeFound.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي وجدناه؟'**
  String get whatWeFound;

  /// No description provided for @faultReturnedAfterRepair.
  ///
  /// In ar, this message translates to:
  /// **'عاد هذا العطل بعد إصلاح سابق'**
  String get faultReturnedAfterRepair;

  /// No description provided for @faultCodes.
  ///
  /// In ar, this message translates to:
  /// **'أكواد الأعطال'**
  String get faultCodes;

  /// No description provided for @unknownDtcMeaning.
  ///
  /// In ar, this message translates to:
  /// **'لم يتوفر وصف لهذا الكود.'**
  String get unknownDtcMeaning;

  /// No description provided for @likelyCauses.
  ///
  /// In ar, this message translates to:
  /// **'الأسباب الأكثر احتمالًا'**
  String get likelyCauses;

  /// No description provided for @checksFirst.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يجب فحصه أولًا؟'**
  String get checksFirst;

  /// No description provided for @relatedParts.
  ///
  /// In ar, this message translates to:
  /// **'قطع قد تكون مرتبطة'**
  String get relatedParts;

  /// No description provided for @findPart.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن القطعة'**
  String get findPart;

  /// No description provided for @findPartTitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث عن القطعة'**
  String get findPartTitle;

  /// No description provided for @generalWebSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث عام على الويب'**
  String get generalWebSearch;

  /// No description provided for @partCompatibilityNotice.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من رقم القطعة وتوافقها مع سيارتك قبل الشراء.'**
  String get partCompatibilityNotice;

  /// No description provided for @partSearchNotice.
  ///
  /// In ar, this message translates to:
  /// **'البحث يساعدك على المقارنة فقط. لا تشترِ قطعة قبل تأكيد العطل ورقم القطعة المطابق.'**
  String get partSearchNotice;

  /// No description provided for @openWorkshopMode.
  ///
  /// In ar, this message translates to:
  /// **'فتح وضع الورشة'**
  String get openWorkshopMode;

  /// No description provided for @nextStep.
  ///
  /// In ar, this message translates to:
  /// **'الخطوة التالية'**
  String get nextStep;

  /// No description provided for @saveToCarRecord.
  ///
  /// In ar, this message translates to:
  /// **'حفظ في سجل السيارة'**
  String get saveToCarRecord;

  /// No description provided for @savedToCarRecord.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ في سجل السيارة'**
  String get savedToCarRecord;

  /// No description provided for @saving.
  ///
  /// In ar, this message translates to:
  /// **'جاري الحفظ...'**
  String get saving;

  /// No description provided for @recordRepair.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل إصلاح'**
  String get recordRepair;

  /// No description provided for @verifyRepairLater.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الإصلاح لاحقًا'**
  String get verifyRepairLater;

  /// No description provided for @recordRepairTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الإصلاح'**
  String get recordRepairTitle;

  /// No description provided for @repairWorkLabel.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تم تغييره أو إصلاحه؟'**
  String get repairWorkLabel;

  /// No description provided for @repairCost.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة الإصلاح'**
  String get repairCost;

  /// No description provided for @sarShort.
  ///
  /// In ar, this message translates to:
  /// **'ر.س'**
  String get sarShort;

  /// No description provided for @workshopOptional.
  ///
  /// In ar, this message translates to:
  /// **'اسم الورشة (اختياري)'**
  String get workshopOptional;

  /// No description provided for @odometer.
  ///
  /// In ar, this message translates to:
  /// **'العداد'**
  String get odometer;

  /// No description provided for @kmShort.
  ///
  /// In ar, this message translates to:
  /// **'كم'**
  String get kmShort;

  /// No description provided for @note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get note;

  /// No description provided for @issueGoneQuestion.
  ///
  /// In ar, this message translates to:
  /// **'هل اختفى العطل؟'**
  String get issueGoneQuestion;

  /// No description provided for @repairSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإصلاح في سجل السيارة'**
  String get repairSaved;

  /// No description provided for @diagnosisSafetyDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'هذه النتيجة توجيهية ولا تغني عن فحص فني مباشر قبل اتخاذ قرار يتعلق بالسلامة أو تغيير القطع.'**
  String get diagnosisSafetyDisclaimer;

  /// No description provided for @beforeYouPayTitle.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تدفع'**
  String get beforeYouPayTitle;

  /// No description provided for @preparingVehicleData.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز بيانات السيارة'**
  String get preparingVehicleData;

  /// No description provided for @beforeYouPayIntro.
  ///
  /// In ar, this message translates to:
  /// **'راجع تشخيص الورشة وعرض السعر قبل الموافقة.'**
  String get beforeYouPayIntro;

  /// No description provided for @quoteStepCar.
  ///
  /// In ar, this message translates to:
  /// **'السيارة'**
  String get quoteStepCar;

  /// No description provided for @quoteStepDetails.
  ///
  /// In ar, this message translates to:
  /// **'العرض'**
  String get quoteStepDetails;

  /// No description provided for @quoteStepReview.
  ///
  /// In ar, this message translates to:
  /// **'المراجعة'**
  String get quoteStepReview;

  /// No description provided for @selectQuoteCar.
  ///
  /// In ar, this message translates to:
  /// **'اختر السيارة'**
  String get selectQuoteCar;

  /// No description provided for @selectQuoteCarSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سنربط العرض بتاريخ السيارة وبياناتها المتاحة.'**
  String get selectQuoteCarSubtitle;

  /// No description provided for @enterQuoteDetails.
  ///
  /// In ar, this message translates to:
  /// **'أدخل تفاصيل عرض الورشة'**
  String get enterQuoteDetails;

  /// No description provided for @enterQuoteDetailsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف كلام الورشة والقطع والسعر أو صورة العرض.'**
  String get enterQuoteDetailsSubtitle;

  /// No description provided for @reviewQuoteRequest.
  ///
  /// In ar, this message translates to:
  /// **'راجع بيانات الطلب'**
  String get reviewQuoteRequest;

  /// No description provided for @reviewQuoteRequestSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكد من البيانات قبل إرسالها للمراجعة.'**
  String get reviewQuoteRequestSubtitle;

  /// No description provided for @noCarAdded.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سيارة مضافة'**
  String get noCarAdded;

  /// No description provided for @mileageValue.
  ///
  /// In ar, this message translates to:
  /// **'العداد: {mileage} كم'**
  String mileageValue(int mileage);

  /// No description provided for @workshopStatement.
  ///
  /// In ar, this message translates to:
  /// **'كلام الورشة'**
  String get workshopStatement;

  /// No description provided for @workshopStatementHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تغيير المساعد الأمامي بسبب صوت عند المطبات'**
  String get workshopStatementHint;

  /// No description provided for @proposedParts.
  ///
  /// In ar, this message translates to:
  /// **'القطع المقترح تغييرها'**
  String get proposedParts;

  /// No description provided for @proposedPartsHint.
  ///
  /// In ar, this message translates to:
  /// **'كل قطعة في سطر أو افصل بينها بفاصلة'**
  String get proposedPartsHint;

  /// No description provided for @totalPriceOptional.
  ///
  /// In ar, this message translates to:
  /// **'السعر الإجمالي (اختياري)'**
  String get totalPriceOptional;

  /// No description provided for @captureQuote.
  ///
  /// In ar, this message translates to:
  /// **'تصوير عرض السعر'**
  String get captureQuote;

  /// No description provided for @chooseQuoteImage.
  ///
  /// In ar, this message translates to:
  /// **'اختيار صورة'**
  String get chooseQuoteImage;

  /// No description provided for @attachQuoteImage.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة العرض'**
  String get attachQuoteImage;

  /// No description provided for @replaceQuoteImage.
  ///
  /// In ar, this message translates to:
  /// **'استبدال صورة العرض'**
  String get replaceQuoteImage;

  /// No description provided for @quoteInputRequired.
  ///
  /// In ar, this message translates to:
  /// **'أضف كلام الورشة أو القطع المقترحة أو صورة العرض.'**
  String get quoteInputRequired;

  /// No description provided for @quoteReviewFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر مراجعة العرض الآن. حاول مرة أخرى.'**
  String get quoteReviewFailed;

  /// No description provided for @reviewQuote.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة العرض'**
  String get reviewQuote;

  /// No description provided for @reviewingQuote.
  ///
  /// In ar, this message translates to:
  /// **'جاري المراجعة...'**
  String get reviewingQuote;

  /// No description provided for @quoteReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة عرض الورشة'**
  String get quoteReviewTitle;

  /// No description provided for @quoteStop.
  ///
  /// In ar, this message translates to:
  /// **'لا توافق قبل فحوصات إضافية'**
  String get quoteStop;

  /// No description provided for @quoteLogical.
  ///
  /// In ar, this message translates to:
  /// **'العرض يبدو منطقيًا'**
  String get quoteLogical;

  /// No description provided for @quoteVerify.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج تحقق قبل الموافقة'**
  String get quoteVerify;

  /// No description provided for @reviewIncomplete.
  ///
  /// In ar, this message translates to:
  /// **'لم تكتمل المراجعة الآلية؛ لا تعتمد على هذه النتيجة لاتخاذ قرار.'**
  String get reviewIncomplete;

  /// No description provided for @safetyAlert.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه سلامة'**
  String get safetyAlert;

  /// No description provided for @alignedEvidence.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يتوافق مع بيانات سيارتك؟'**
  String get alignedEvidence;

  /// No description provided for @evidenceNeeded.
  ///
  /// In ar, this message translates to:
  /// **'ما الذي يحتاج إثباتًا؟'**
  String get evidenceNeeded;

  /// No description provided for @askTechnician.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تدفع، اسأل الفني:'**
  String get askTechnician;

  /// No description provided for @recommendedChecksFirst.
  ///
  /// In ar, this message translates to:
  /// **'الفحوصات التي يفضل تنفيذها أولًا'**
  String get recommendedChecksFirst;

  /// No description provided for @proposedPartsTitle.
  ///
  /// In ar, this message translates to:
  /// **'القطع المقترحة'**
  String get proposedPartsTitle;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get price;

  /// No description provided for @priceAssessment.
  ///
  /// In ar, this message translates to:
  /// **'الحكم على السعر'**
  String get priceAssessment;

  /// No description provided for @insufficientPriceData.
  ///
  /// In ar, this message translates to:
  /// **'لا تتوفر لدينا بيانات سوق كافية للحكم على السعر حاليًا.'**
  String get insufficientPriceData;

  /// No description provided for @vehicleLabel.
  ///
  /// In ar, this message translates to:
  /// **'السيارة: {car}'**
  String vehicleLabel(String car);

  /// No description provided for @evidenceStrong.
  ///
  /// In ar, this message translates to:
  /// **'توافق قوي'**
  String get evidenceStrong;

  /// No description provided for @evidencePartial.
  ///
  /// In ar, this message translates to:
  /// **'توافق جزئي'**
  String get evidencePartial;

  /// No description provided for @evidenceInsufficient.
  ///
  /// In ar, this message translates to:
  /// **'أدلة غير كافية'**
  String get evidenceInsufficient;

  /// No description provided for @workshopReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الورشة: {reason}'**
  String workshopReason(String reason);

  /// No description provided for @reasonNotProvided.
  ///
  /// In ar, this message translates to:
  /// **'غير مذكور'**
  String get reasonNotProvided;

  /// No description provided for @obdUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'غير متاح على هذا الجهاز حاليًا'**
  String get obdUnavailable;

  /// No description provided for @moreSourcesHelp.
  ///
  /// In ar, this message translates to:
  /// **'كلما أضفت معلومات أكثر، حصل Smart Car Check على سياق أفضل للتشخيص.'**
  String get moreSourcesHelp;

  /// No description provided for @obdNotConnected.
  ///
  /// In ar, this message translates to:
  /// **'جهاز OBD غير متصل'**
  String get obdNotConnected;

  /// No description provided for @obdCodesRead.
  ///
  /// In ar, this message translates to:
  /// **'تمت قراءة الأكواد'**
  String get obdCodesRead;

  /// No description provided for @connectObdToRead.
  ///
  /// In ar, this message translates to:
  /// **'اتصل بالجهاز لقراءة أكواد الأعطال الحقيقية'**
  String get connectObdToRead;

  /// No description provided for @noDriveAdvice.
  ///
  /// In ar, this message translates to:
  /// **'لا تتوفر توصية كافية'**
  String get noDriveAdvice;

  /// No description provided for @diagnosisFallbackTitle.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة التشخيص'**
  String get diagnosisFallbackTitle;

  /// No description provided for @confidencePercent.
  ///
  /// In ar, this message translates to:
  /// **'الثقة {value}%'**
  String confidencePercent(Object value);

  /// No description provided for @doNotReplaceBeforeInspection.
  ///
  /// In ar, this message translates to:
  /// **'لا تغيّر أي قطعة قبل تأكيد السبب بالفحص المباشر.'**
  String get doNotReplaceBeforeInspection;

  /// No description provided for @quoteReviewCarHeading.
  ///
  /// In ar, this message translates to:
  /// **'اختر السيارة'**
  String get quoteReviewCarHeading;

  /// No description provided for @quoteReviewCarBody.
  ///
  /// In ar, this message translates to:
  /// **'سنستخدم بيانات السيارة وسجلها المتاح للمقارنة فقط.'**
  String get quoteReviewCarBody;

  /// No description provided for @quoteOfferHeading.
  ///
  /// In ar, this message translates to:
  /// **'ماذا قالت لك الورشة؟'**
  String get quoteOfferHeading;

  /// No description provided for @quoteOfferBody.
  ///
  /// In ar, this message translates to:
  /// **'أضف ما لديك فقط؛ لا يلزم توفر كل الحقول.'**
  String get quoteOfferBody;

  /// No description provided for @quoteReviewHeading.
  ///
  /// In ar, this message translates to:
  /// **'راجع البيانات'**
  String get quoteReviewHeading;

  /// No description provided for @quoteReviewBody.
  ///
  /// In ar, this message translates to:
  /// **'سنستخدم السياق المتاح دون اختراع معلومات مفقودة.'**
  String get quoteReviewBody;

  /// No description provided for @notProvided.
  ///
  /// In ar, this message translates to:
  /// **'غير مذكور'**
  String get notProvided;

  /// No description provided for @notAttached.
  ///
  /// In ar, this message translates to:
  /// **'غير مرفقة'**
  String get notAttached;

  /// No description provided for @attached.
  ///
  /// In ar, this message translates to:
  /// **'مرفقة'**
  String get attached;

  /// No description provided for @parts.
  ///
  /// In ar, this message translates to:
  /// **'القطع'**
  String get parts;

  /// No description provided for @quoteImage.
  ///
  /// In ar, this message translates to:
  /// **'صورة العرض'**
  String get quoteImage;

  /// No description provided for @availableContext.
  ///
  /// In ar, this message translates to:
  /// **'السياق المتاح'**
  String get availableContext;

  /// No description provided for @contextSummary.
  ///
  /// In ar, this message translates to:
  /// **'{issues} مشكلة • {maintenance} صيانة • {codes} كود OBD'**
  String contextSummary(int issues, int maintenance, int codes);

  /// No description provided for @diagnosisReviewNotice.
  ///
  /// In ar, this message translates to:
  /// **'سيتم استخدام بيانات السيارة والأعراض والأكواد المقروءة فقط لإنشاء تحليل إرشادي.'**
  String get diagnosisReviewNotice;

  /// No description provided for @bluetooth.
  ///
  /// In ar, this message translates to:
  /// **'بلوتوث'**
  String get bluetooth;

  /// No description provided for @obdConnection.
  ///
  /// In ar, this message translates to:
  /// **'اتصال OBD'**
  String get obdConnection;

  /// No description provided for @processingVehicleData.
  ///
  /// In ar, this message translates to:
  /// **'تحليل بيانات السيارة'**
  String get processingVehicleData;

  /// No description provided for @processingObdCodes.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة أكواد OBD'**
  String get processingObdCodes;

  /// No description provided for @processingSymptoms.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة الأعراض'**
  String get processingSymptoms;

  /// No description provided for @processingResult.
  ///
  /// In ar, this message translates to:
  /// **'إعداد نتيجة الفحص'**
  String get processingResult;

  /// No description provided for @myCars.
  ///
  /// In ar, this message translates to:
  /// **'سياراتي'**
  String get myCars;

  /// No description provided for @keepOneCar.
  ///
  /// In ar, this message translates to:
  /// **'يجب إبقاء سيارة واحدة على الأقل'**
  String get keepOneCar;

  /// No description provided for @deleteCar.
  ///
  /// In ar, this message translates to:
  /// **'حذف السيارة'**
  String get deleteCar;

  /// No description provided for @deleteCarConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذه السيارة من قائمتك؟'**
  String get deleteCarConfirm;

  /// No description provided for @addNewCar.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سيارة جديدة'**
  String get addNewCar;

  /// No description provided for @editCar.
  ///
  /// In ar, this message translates to:
  /// **'تعديل السيارة'**
  String get editCar;

  /// No description provided for @manufacturer.
  ///
  /// In ar, this message translates to:
  /// **'الشركة المصنعة'**
  String get manufacturer;

  /// No description provided for @manufacturerName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الشركة المصنعة'**
  String get manufacturerName;

  /// No description provided for @carModel.
  ///
  /// In ar, this message translates to:
  /// **'الموديل'**
  String get carModel;

  /// No description provided for @carModelName.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الموديل'**
  String get carModelName;

  /// No description provided for @manufactureYear.
  ///
  /// In ar, this message translates to:
  /// **'سنة الصنع'**
  String get manufactureYear;

  /// No description provided for @vinOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهيكل VIN (اختياري)'**
  String get vinOptional;

  /// No description provided for @engineTypeOptional.
  ///
  /// In ar, this message translates to:
  /// **'نوع المحرك (اختياري)'**
  String get engineTypeOptional;

  /// No description provided for @transmissionTypeOptional.
  ///
  /// In ar, this message translates to:
  /// **'نوع ناقل الحركة (اختياري)'**
  String get transmissionTypeOptional;

  /// No description provided for @currentMileageOptional.
  ///
  /// In ar, this message translates to:
  /// **'قراءة العداد الحالية (اختياري)'**
  String get currentMileageOptional;

  /// No description provided for @registrationExpiry.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء الاستمارة'**
  String get registrationExpiry;

  /// No description provided for @insuranceExpiry.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء التأمين'**
  String get insuranceExpiry;

  /// No description provided for @inspectionExpiry.
  ///
  /// In ar, this message translates to:
  /// **'انتهاء الفحص الدوري'**
  String get inspectionExpiry;

  /// No description provided for @notSet.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get notSet;

  /// No description provided for @chooseDate.
  ///
  /// In ar, this message translates to:
  /// **'تحديد'**
  String get chooseDate;

  /// No description provided for @loadingCars.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل سياراتك'**
  String get loadingCars;

  /// No description provided for @firstCarMessage.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر حالة السيارة وسجلها هنا.'**
  String get firstCarMessage;

  /// No description provided for @mileageNotRecorded.
  ///
  /// In ar, this message translates to:
  /// **'العداد غير مسجل'**
  String get mileageNotRecorded;

  /// No description provided for @activeVehicle.
  ///
  /// In ar, this message translates to:
  /// **'السيارة الحالية'**
  String get activeVehicle;

  /// No description provided for @other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get other;

  /// No description provided for @brandToyota.
  ///
  /// In ar, this message translates to:
  /// **'تويوتا'**
  String get brandToyota;

  /// No description provided for @brandHonda.
  ///
  /// In ar, this message translates to:
  /// **'هوندا'**
  String get brandHonda;

  /// No description provided for @brandNissan.
  ///
  /// In ar, this message translates to:
  /// **'نيسان'**
  String get brandNissan;

  /// No description provided for @brandHyundai.
  ///
  /// In ar, this message translates to:
  /// **'هيونداي'**
  String get brandHyundai;

  /// No description provided for @brandKia.
  ///
  /// In ar, this message translates to:
  /// **'كيا'**
  String get brandKia;

  /// No description provided for @brandFord.
  ///
  /// In ar, this message translates to:
  /// **'فورد'**
  String get brandFord;

  /// No description provided for @brandChevrolet.
  ///
  /// In ar, this message translates to:
  /// **'شيفروليه'**
  String get brandChevrolet;

  /// No description provided for @brandMercedes.
  ///
  /// In ar, this message translates to:
  /// **'مرسيدس'**
  String get brandMercedes;

  /// No description provided for @brandBmw.
  ///
  /// In ar, this message translates to:
  /// **'بي إم دبليو'**
  String get brandBmw;

  /// No description provided for @brandAudi.
  ///
  /// In ar, this message translates to:
  /// **'أودي'**
  String get brandAudi;

  /// No description provided for @brandLexus.
  ///
  /// In ar, this message translates to:
  /// **'لكزس'**
  String get brandLexus;

  /// No description provided for @brandMazda.
  ///
  /// In ar, this message translates to:
  /// **'مازدا'**
  String get brandMazda;

  /// No description provided for @brandMitsubishi.
  ///
  /// In ar, this message translates to:
  /// **'ميتسوبيشي'**
  String get brandMitsubishi;

  /// No description provided for @brandJeep.
  ///
  /// In ar, this message translates to:
  /// **'جيب'**
  String get brandJeep;

  /// No description provided for @brandGmc.
  ///
  /// In ar, this message translates to:
  /// **'جي إم سي'**
  String get brandGmc;

  /// No description provided for @brandDodge.
  ///
  /// In ar, this message translates to:
  /// **'دودج'**
  String get brandDodge;

  /// No description provided for @brandInfiniti.
  ///
  /// In ar, this message translates to:
  /// **'إنفينيتي'**
  String get brandInfiniti;

  /// No description provided for @brandSuzuki.
  ///
  /// In ar, this message translates to:
  /// **'سوزوكي'**
  String get brandSuzuki;

  /// No description provided for @brandVolkswagen.
  ///
  /// In ar, this message translates to:
  /// **'فولكس فاجن'**
  String get brandVolkswagen;

  /// No description provided for @vehicleRecordTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل السيارة'**
  String get vehicleRecordTitle;

  /// No description provided for @preparingVehicleRecord.
  ///
  /// In ar, this message translates to:
  /// **'جاري تجهيز سجل السيارة'**
  String get preparingVehicleRecord;

  /// No description provided for @emptyVehicleRecord.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سجل للسيارة حتى الآن'**
  String get emptyVehicleRecord;

  /// No description provided for @emptyVehicleRecordMessage.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر الفحوصات والصيانة والإصلاحات هنا زمنيًا.'**
  String get emptyVehicleRecordMessage;

  /// No description provided for @vehicleTimeline.
  ///
  /// In ar, this message translates to:
  /// **'الخط الزمني للسيارة'**
  String get vehicleTimeline;

  /// No description provided for @diagnosesCount.
  ///
  /// In ar, this message translates to:
  /// **'الفحوصات'**
  String get diagnosesCount;

  /// No description provided for @repairsCount.
  ///
  /// In ar, this message translates to:
  /// **'الإصلاحات'**
  String get repairsCount;

  /// No description provided for @maintenanceCount.
  ///
  /// In ar, this message translates to:
  /// **'الصيانة'**
  String get maintenanceCount;

  /// No description provided for @obdScan.
  ///
  /// In ar, this message translates to:
  /// **'فحص OBD'**
  String get obdScan;

  /// No description provided for @codesRead.
  ///
  /// In ar, this message translates to:
  /// **'تمت القراءة'**
  String get codesRead;

  /// No description provided for @repairReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة إصلاح'**
  String get repairReview;

  /// No description provided for @reviewStatus.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة'**
  String get reviewStatus;

  /// No description provided for @recordedRepair.
  ///
  /// In ar, this message translates to:
  /// **'إصلاح مسجل'**
  String get recordedRepair;

  /// No description provided for @recordedStatus.
  ///
  /// In ar, this message translates to:
  /// **'مسجلة'**
  String get recordedStatus;

  /// No description provided for @issueReturned.
  ///
  /// In ar, this message translates to:
  /// **'عاد العطل'**
  String get issueReturned;

  /// No description provided for @noObdCodesRecorded.
  ///
  /// In ar, this message translates to:
  /// **'بدون أكواد OBD'**
  String get noObdCodesRecorded;

  /// No description provided for @checkAndDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'فحص وتشخيص'**
  String get checkAndDiagnosis;

  /// No description provided for @repairType.
  ///
  /// In ar, this message translates to:
  /// **'إصلاح'**
  String get repairType;

  /// No description provided for @maintenanceType.
  ///
  /// In ar, this message translates to:
  /// **'صيانة'**
  String get maintenanceType;

  /// No description provided for @issueOngoing.
  ///
  /// In ar, this message translates to:
  /// **'العطل مستمر'**
  String get issueOngoing;

  /// No description provided for @statusNew.
  ///
  /// In ar, this message translates to:
  /// **'جديد'**
  String get statusNew;

  /// No description provided for @statusMonitoring.
  ///
  /// In ar, this message translates to:
  /// **'تحت المراقبة'**
  String get statusMonitoring;

  /// No description provided for @statusRepairNeeded.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج إصلاح'**
  String get statusRepairNeeded;

  /// No description provided for @maintenanceReminders.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات الصيانة الدورية'**
  String get maintenanceReminders;

  /// No description provided for @loadingMaintenanceReminders.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل مواعيد الصيانة'**
  String get loadingMaintenanceReminders;

  /// No description provided for @noMaintenanceReminders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواعيد صيانة'**
  String get noMaintenanceReminders;

  /// No description provided for @noMaintenanceRemindersMessage.
  ///
  /// In ar, this message translates to:
  /// **'أضف موعدًا وسنساعدك على تذكره.'**
  String get noMaintenanceRemindersMessage;

  /// No description provided for @addReminder.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موعد'**
  String get addReminder;

  /// No description provided for @overdueDays.
  ///
  /// In ar, this message translates to:
  /// **'متأخر منذ {days} يوم'**
  String overdueDays(int days);

  /// No description provided for @daysRemaining.
  ///
  /// In ar, this message translates to:
  /// **'باقي {days} يوم'**
  String daysRemaining(int days);

  /// No description provided for @newMaintenanceReminder.
  ///
  /// In ar, this message translates to:
  /// **'تنبيه صيانة جديد'**
  String get newMaintenanceReminder;

  /// No description provided for @maintenanceTypeExample.
  ///
  /// In ar, this message translates to:
  /// **'نوع الصيانة (مثال: تغيير الزيت)'**
  String get maintenanceTypeExample;

  /// No description provided for @notesOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get notesOptional;

  /// No description provided for @dateLabel.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ: {date}'**
  String dateLabel(String date);

  /// No description provided for @change.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get change;

  /// No description provided for @maintenanceHistoryFor.
  ///
  /// In ar, this message translates to:
  /// **'سجل صيانة {car}'**
  String maintenanceHistoryFor(String car);

  /// No description provided for @noMaintenanceHistory.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد سجل صيانة لهذه السيارة بعد'**
  String get noMaintenanceHistory;

  /// No description provided for @deleteConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الحذف'**
  String get deleteConfirmation;

  /// No description provided for @deleteMaintenanceConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا السجل نهائيًا؟'**
  String get deleteMaintenanceConfirm;

  /// No description provided for @viewInvoice.
  ///
  /// In ar, this message translates to:
  /// **'عرض الفاتورة'**
  String get viewInvoice;

  /// No description provided for @addMaintenanceRecord.
  ///
  /// In ar, this message translates to:
  /// **'إضافة سجل صيانة'**
  String get addMaintenanceRecord;

  /// No description provided for @maintenanceCategory.
  ///
  /// In ar, this message translates to:
  /// **'نوع الصيانة'**
  String get maintenanceCategory;

  /// No description provided for @workDescriptionOptional.
  ///
  /// In ar, this message translates to:
  /// **'وصف العمل (اختياري)'**
  String get workDescriptionOptional;

  /// No description provided for @workDescriptionHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: تغيير الزيت + الفلتر'**
  String get workDescriptionHint;

  /// No description provided for @serviceMileageOptional.
  ///
  /// In ar, this message translates to:
  /// **'الكيلومترات عند الصيانة (اختياري)'**
  String get serviceMileageOptional;

  /// No description provided for @partNumberOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة (اختياري)'**
  String get partNumberOptional;

  /// No description provided for @partNumberHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: 90915-YZZD4'**
  String get partNumberHint;

  /// No description provided for @workshopNameOptional.
  ///
  /// In ar, this message translates to:
  /// **'الورشة (اختياري)'**
  String get workshopNameOptional;

  /// No description provided for @workshopNameHint.
  ///
  /// In ar, this message translates to:
  /// **'اسم الورشة'**
  String get workshopNameHint;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @costOptional.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة (اختياري)'**
  String get costOptional;

  /// No description provided for @additionalDetailsHint.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل إضافية'**
  String get additionalDetailsHint;

  /// No description provided for @invoiceImageOptional.
  ///
  /// In ar, this message translates to:
  /// **'صورة الفاتورة (اختياري)'**
  String get invoiceImageOptional;

  /// No description provided for @attachInvoice.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة الفاتورة'**
  String get attachInvoice;

  /// No description provided for @saveRecord.
  ///
  /// In ar, this message translates to:
  /// **'حفظ السجل'**
  String get saveRecord;

  /// No description provided for @workTypeRequired.
  ///
  /// In ar, this message translates to:
  /// **'اكتب نوع العمل'**
  String get workTypeRequired;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ، حاول مرة أخرى'**
  String get saveFailed;

  /// No description provided for @nextMaintenanceFor.
  ///
  /// In ar, this message translates to:
  /// **'موعد {category} القادم'**
  String nextMaintenanceFor(String category);

  /// No description provided for @autoReminderNote.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاؤه تلقائيًا بعد تسجيل صيانة'**
  String get autoReminderNote;

  /// No description provided for @categoryEngineOil.
  ///
  /// In ar, this message translates to:
  /// **'تغيير زيت المحرك'**
  String get categoryEngineOil;

  /// No description provided for @categoryOilFilter.
  ///
  /// In ar, this message translates to:
  /// **'فلتر الزيت'**
  String get categoryOilFilter;

  /// No description provided for @categoryAirFilter.
  ///
  /// In ar, this message translates to:
  /// **'فلتر الهواء'**
  String get categoryAirFilter;

  /// No description provided for @categorySparkPlugs.
  ///
  /// In ar, this message translates to:
  /// **'البواجي'**
  String get categorySparkPlugs;

  /// No description provided for @categoryBrakePads.
  ///
  /// In ar, this message translates to:
  /// **'فحمات الفرامل (تيل الفرامل)'**
  String get categoryBrakePads;

  /// No description provided for @categoryBattery.
  ///
  /// In ar, this message translates to:
  /// **'البطارية'**
  String get categoryBattery;

  /// No description provided for @categoryTires.
  ///
  /// In ar, this message translates to:
  /// **'الكفرات (الإطارات)'**
  String get categoryTires;

  /// No description provided for @categoryCabinFilter.
  ///
  /// In ar, this message translates to:
  /// **'فلتر المكيف'**
  String get categoryCabinFilter;

  /// No description provided for @categoryBrakeFluid.
  ///
  /// In ar, this message translates to:
  /// **'سائل الفرامل'**
  String get categoryBrakeFluid;

  /// No description provided for @obdConnectTitle.
  ///
  /// In ar, this message translates to:
  /// **'ربط جهاز OBD-II'**
  String get obdConnectTitle;

  /// No description provided for @checkingObdCapability.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحقق من إمكانات الفحص...'**
  String get checkingObdCapability;

  /// No description provided for @savedObdScan.
  ///
  /// In ar, this message translates to:
  /// **'نتيجة آخر فحص محفوظة ({count} كود)'**
  String savedObdScan(int count);

  /// No description provided for @obdDirectUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'الفحص المباشر عبر OBD غير متاح على هذا الجهاز حاليًا'**
  String get obdDirectUnavailable;

  /// No description provided for @findPairedObd.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن أجهزة OBD المقترنة بجوالك'**
  String get findPairedObd;

  /// No description provided for @findNearbyObd.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن أجهزة OBD الحديثة القريبة'**
  String get findNearbyObd;

  /// No description provided for @searching.
  ///
  /// In ar, this message translates to:
  /// **'جاري البحث...'**
  String get searching;

  /// No description provided for @noNearbyObd.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد جهاز OBD قريبًا. تأكد من تشغيل المحول ثم أعد البحث.'**
  String get noNearbyObd;

  /// No description provided for @noPairedObd.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد أجهزة مقترنة. قرّن جهاز OBD من إعدادات البلوتوث ثم أعد المحاولة.'**
  String get noPairedObd;

  /// No description provided for @chooseObdDevice.
  ///
  /// In ar, this message translates to:
  /// **'اختر جهاز OBD من القائمة'**
  String get chooseObdDevice;

  /// No description provided for @obdSearchFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر البحث. تحقق من تشغيل البلوتوث ومنح الصلاحيات.'**
  String get obdSearchFailed;

  /// No description provided for @connectingToDevice.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاتصال بـ {device}...'**
  String connectingToDevice(String device);

  /// No description provided for @connectedToDevice.
  ///
  /// In ar, this message translates to:
  /// **'متصل بجهاز {device}'**
  String connectedToDevice(String device);

  /// No description provided for @obdConnectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الاتصال. تحقق من تشغيل الجهاز واقترانه بالهاتف.'**
  String get obdConnectionFailed;

  /// No description provided for @readingEngineTransmissionCodes.
  ///
  /// In ar, this message translates to:
  /// **'جاري قراءة أكواد المحرك وناقل الحركة...'**
  String get readingEngineTransmissionCodes;

  /// No description provided for @transmissionModuleUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'وحدة ناقل الحركة غير متاحة على هذا الجهاز أو السيارة'**
  String get transmissionModuleUnavailable;

  /// No description provided for @noStoredFaultCodes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد أعطال محفوظة حاليًا'**
  String get noStoredFaultCodes;

  /// No description provided for @faultCodesFound.
  ///
  /// In ar, this message translates to:
  /// **'تم العثور على {total} كود (محرك: {engine}، ناقل حركة: {transmission})'**
  String faultCodesFound(int total, int engine, int transmission);

  /// No description provided for @clearCodesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد المسح'**
  String get clearCodesTitle;

  /// No description provided for @clearCodesConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من مسح جميع أكواد الأعطال؟ لا يمكن التراجع عن هذا الإجراء.'**
  String get clearCodesConfirm;

  /// No description provided for @confirmClear.
  ///
  /// In ar, this message translates to:
  /// **'نعم، امسح'**
  String get confirmClear;

  /// No description provided for @clearingCodes.
  ///
  /// In ar, this message translates to:
  /// **'جاري مسح الأكواد...'**
  String get clearingCodes;

  /// No description provided for @codesCleared.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح جميع أكواد الأعطال بنجاح'**
  String get codesCleared;

  /// No description provided for @clearCodesFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر مسح الأكواد. أعد المحاولة.'**
  String get clearCodesFailed;

  /// No description provided for @disconnected.
  ///
  /// In ar, this message translates to:
  /// **'تم قطع الاتصال'**
  String get disconnected;

  /// No description provided for @disconnectedSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم قطع الاتصال — نتيجة الفحص محفوظة وجاهزة للتشخيص'**
  String get disconnectedSaved;

  /// No description provided for @searchLinkFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر فتح رابط البحث'**
  String get searchLinkFailed;

  /// No description provided for @obdTranscriptCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ سجل OBD'**
  String get obdTranscriptCopied;

  /// No description provided for @dtcGuide.
  ///
  /// In ar, this message translates to:
  /// **'دليل أكواد الأعطال'**
  String get dtcGuide;

  /// No description provided for @chooseConnectionMethod.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة الاتصال'**
  String get chooseConnectionMethod;

  /// No description provided for @searchNearbyDevices.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن أجهزة قريبة'**
  String get searchNearbyDevices;

  /// No description provided for @showPairedDevices.
  ///
  /// In ar, this message translates to:
  /// **'عرض الأجهزة المقترنة'**
  String get showPairedDevices;

  /// No description provided for @connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get connected;

  /// No description provided for @disconnect.
  ///
  /// In ar, this message translates to:
  /// **'قطع الاتصال'**
  String get disconnect;

  /// No description provided for @readCodes.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الأكواد'**
  String get readCodes;

  /// No description provided for @clearCodes.
  ///
  /// In ar, this message translates to:
  /// **'مسح الأكواد'**
  String get clearCodes;

  /// No description provided for @diagnoseWithCodes.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ التشخيص بهذه الأكواد ({count})'**
  String diagnoseWithCodes(int count);

  /// No description provided for @copyObdTranscript.
  ///
  /// In ar, this message translates to:
  /// **'نسخ سجل OBD'**
  String get copyObdTranscript;

  /// No description provided for @obdUnavailableAlternative.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك متابعة التشخيص بوصف الأعراض أو إرفاق صورة دون استخدام OBD.'**
  String get obdUnavailableAlternative;

  /// No description provided for @nearbyDevice.
  ///
  /// In ar, this message translates to:
  /// **'جهاز قريب'**
  String get nearbyDevice;

  /// No description provided for @pairedDevice.
  ///
  /// In ar, this message translates to:
  /// **'جهاز مقترن'**
  String get pairedDevice;

  /// No description provided for @classicBluetooth.
  ///
  /// In ar, this message translates to:
  /// **'بلوتوث'**
  String get classicBluetooth;

  /// No description provided for @bleDescription.
  ///
  /// In ar, this message translates to:
  /// **'مناسب للأجهزة الحديثة والآيفون'**
  String get bleDescription;

  /// No description provided for @classicBluetoothDescription.
  ///
  /// In ar, this message translates to:
  /// **'مناسب لأجهزة ELM327 التقليدية'**
  String get classicBluetoothDescription;

  /// No description provided for @findRequiredPart.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن القطعة المطلوبة'**
  String get findRequiredPart;

  /// No description provided for @dtcLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل دليل الأكواد'**
  String get dtcLoadFailed;

  /// No description provided for @dtcSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالكود (مثال: P0301) أو بالوصف'**
  String get dtcSearchHint;

  /// No description provided for @dtcCount.
  ///
  /// In ar, this message translates to:
  /// **'{shown} من {total} كود'**
  String dtcCount(int shown, int total);

  /// No description provided for @noMatchingResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get noMatchingResults;

  /// No description provided for @commonCauses.
  ///
  /// In ar, this message translates to:
  /// **'الأسباب الشائعة:'**
  String get commonCauses;

  /// No description provided for @workshopMode.
  ///
  /// In ar, this message translates to:
  /// **'وضع الورشة'**
  String get workshopMode;

  /// No description provided for @showTechnician.
  ///
  /// In ar, this message translates to:
  /// **'افتح هذه الشاشة أمام الفني'**
  String get showTechnician;

  /// No description provided for @workshopModeIntro.
  ///
  /// In ar, this message translates to:
  /// **'معلومات مختصرة وعملية تساعد على بدء الفحص الصحيح.'**
  String get workshopModeIntro;

  /// No description provided for @unrecorded.
  ///
  /// In ar, this message translates to:
  /// **'غير مسجل'**
  String get unrecorded;

  /// No description provided for @noCodesRead.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أكواد مقروءة'**
  String get noCodesRead;

  /// No description provided for @noSymptomsAdded.
  ///
  /// In ar, this message translates to:
  /// **'لم تُضف أعراضًا'**
  String get noSymptomsAdded;

  /// No description provided for @askTechnicianToCheck.
  ///
  /// In ar, this message translates to:
  /// **'اطلب من الفني التحقق من التالي قبل تغيير القطع'**
  String get askTechnicianToCheck;

  /// No description provided for @directTestRequired.
  ///
  /// In ar, this message translates to:
  /// **'تحديد سبب العطل باختبار مباشر'**
  String get directTestRequired;

  /// No description provided for @shareWithTechnician.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة مع الفني'**
  String get shareWithTechnician;

  /// No description provided for @workshopSummaryDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'هذا ملخص إرشادي. يعتمد القرار النهائي على الاختبارات المباشرة التي يجريها فني مؤهل.'**
  String get workshopSummaryDisclaimer;

  /// No description provided for @workshopShareText.
  ///
  /// In ar, this message translates to:
  /// **'السيارة: {vehicle}\nالعداد: {mileage} كم\nأكواد الفحص: {codes}\nالأعراض: {symptoms}\n\nأطلب التحقق من التالي قبل تغيير القطع:\n{checks}\n\nيرجى شرح نتيجة الاختبارات وعدم تغيير أي قطعة قبل تأكيد سبب العطل.'**
  String workshopShareText(String vehicle, String mileage, String codes,
      String symptoms, String checks);

  /// No description provided for @repairRecordTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الإصلاح'**
  String get repairRecordTitle;

  /// No description provided for @repairActionRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل القطع التي تم تغييرها أو الإجراء المنفذ.'**
  String get repairActionRequired;

  /// No description provided for @repairSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ الإصلاح. تحقق من الاتصال وحاول مرة أخرى.'**
  String get repairSaveFailed;

  /// No description provided for @deleteRepairRecord.
  ///
  /// In ar, this message translates to:
  /// **'حذف سجل الإصلاح'**
  String get deleteRepairRecord;

  /// No description provided for @deleteLinkedRepairConfirm.
  ///
  /// In ar, this message translates to:
  /// **'يوجد تحقق مرتبط بهذا الإصلاح. سيتم إخفاء سجل الإصلاح دون حذف سجل التحقق.'**
  String get deleteLinkedRepairConfirm;

  /// No description provided for @hideRepairConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد إخفاء سجل الإصلاح؟'**
  String get hideRepairConfirm;

  /// No description provided for @deleteRecord.
  ///
  /// In ar, this message translates to:
  /// **'حذف السجل'**
  String get deleteRecord;

  /// No description provided for @partsActuallyReplaced.
  ///
  /// In ar, this message translates to:
  /// **'القطع التي تم تغييرها فعليًا'**
  String get partsActuallyReplaced;

  /// No description provided for @partsConfirmationHint.
  ///
  /// In ar, this message translates to:
  /// **'أكد ما تم تغييره، ولا تعتمد على المقترح فقط'**
  String get partsConfirmationHint;

  /// No description provided for @workPerformed.
  ///
  /// In ar, this message translates to:
  /// **'الإجراء المنفذ'**
  String get workPerformed;

  /// No description provided for @repairMileageOptional.
  ///
  /// In ar, this message translates to:
  /// **'عداد السيارة وقت الإصلاح (اختياري)'**
  String get repairMileageOptional;

  /// No description provided for @saveRepair.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الإصلاح'**
  String get saveRepair;

  /// No description provided for @repairVerificationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الإصلاح'**
  String get repairVerificationTitle;

  /// No description provided for @postRepairComparison.
  ///
  /// In ar, this message translates to:
  /// **'قارن حالة السيارة بعد الإصلاح بالبيانات السابقة دون افتراض نتيجة غير موجودة.'**
  String get postRepairComparison;

  /// No description provided for @afterRepair.
  ///
  /// In ar, this message translates to:
  /// **'بعد الإصلاح'**
  String get afterRepair;

  /// No description provided for @currentObdCodesOptional.
  ///
  /// In ar, this message translates to:
  /// **'أكواد OBD الحالية (اختياري)'**
  String get currentObdCodesOptional;

  /// No description provided for @currentObdCodesHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: P0133 P0300'**
  String get currentObdCodesHint;

  /// No description provided for @symptomsAfterRepair.
  ///
  /// In ar, this message translates to:
  /// **'كيف أصبحت الأعراض؟'**
  String get symptomsAfterRepair;

  /// No description provided for @symptomsAfterRepairHint.
  ///
  /// In ar, this message translates to:
  /// **'اختفت، تحسنت، أو ما زالت موجودة'**
  String get symptomsAfterRepairHint;

  /// No description provided for @addPostRepairImage.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة بعد الإصلاح (اختياري)'**
  String get addPostRepairImage;

  /// No description provided for @replaceImage.
  ///
  /// In ar, this message translates to:
  /// **'استبدال الصورة'**
  String get replaceImage;

  /// No description provided for @deleteImage.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصورة'**
  String get deleteImage;

  /// No description provided for @temporaryImageNotice.
  ///
  /// In ar, this message translates to:
  /// **'الصورة مؤقتة أثناء التحقق ({mime}) ولا تُحفظ في Firestore.'**
  String temporaryImageNotice(String mime);

  /// No description provided for @verifyNowButton.
  ///
  /// In ar, this message translates to:
  /// **'تحقق الآن'**
  String get verifyNowButton;

  /// No description provided for @removedCodes.
  ///
  /// In ar, this message translates to:
  /// **'الأكواد المختفية: {codes}'**
  String removedCodes(String codes);

  /// No description provided for @remainingCodes.
  ///
  /// In ar, this message translates to:
  /// **'الأكواد المستمرة: {codes}'**
  String remainingCodes(String codes);

  /// No description provided for @newCodes.
  ///
  /// In ar, this message translates to:
  /// **'الأكواد الجديدة: {codes}'**
  String newCodes(String codes);

  /// No description provided for @noData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات'**
  String get noData;

  /// No description provided for @none.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد'**
  String get none;

  /// No description provided for @verificationSuccess.
  ///
  /// In ar, this message translates to:
  /// **'الإصلاح يبدو ناجحًا'**
  String get verificationSuccess;

  /// No description provided for @verificationImproved.
  ///
  /// In ar, this message translates to:
  /// **'تحسن، لكن يحتاج متابعة'**
  String get verificationImproved;

  /// No description provided for @verificationUnresolved.
  ///
  /// In ar, this message translates to:
  /// **'المشكلة قد لا تكون حُلّت بالكامل'**
  String get verificationUnresolved;

  /// No description provided for @verificationReturned.
  ///
  /// In ar, this message translates to:
  /// **'العطل عاد بعد الإصلاح'**
  String get verificationReturned;

  /// No description provided for @verificationInsufficient.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد معلومات كافية للحكم'**
  String get verificationInsufficient;

  /// No description provided for @revisitWorkshop.
  ///
  /// In ar, this message translates to:
  /// **'يفضل إعادة زيارة الورشة للفحص.'**
  String get revisitWorkshop;

  /// No description provided for @marketplaceTitle.
  ///
  /// In ar, this message translates to:
  /// **'سوق قطع الغيار'**
  String get marketplaceTitle;

  /// No description provided for @sellerDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة تحكم البائع'**
  String get sellerDashboard;

  /// No description provided for @cart.
  ///
  /// In ar, this message translates to:
  /// **'السلة'**
  String get cart;

  /// No description provided for @searchPartsHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث باسم القطعة أو الموديل'**
  String get searchPartsHint;

  /// No description provided for @noPartsAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد قطع متاحة حالياً'**
  String get noPartsAvailable;

  /// No description provided for @serverErrorStatus.
  ///
  /// In ar, this message translates to:
  /// **'خطأ من السيرفر: {status}'**
  String serverErrorStatus(int status);

  /// No description provided for @rateSeller.
  ///
  /// In ar, this message translates to:
  /// **'قيّم البائع'**
  String get rateSeller;

  /// No description provided for @commentOptional.
  ///
  /// In ar, this message translates to:
  /// **'تعليق (اختياري)'**
  String get commentOptional;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @ratingSubmitted.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال تقييمك، شكرًا'**
  String get ratingSubmitted;

  /// No description provided for @deletePartConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذه القطعة نهائيًا؟'**
  String get deletePartConfirm;

  /// No description provided for @deletePartFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف القطعة'**
  String get deletePartFailed;

  /// No description provided for @editPart.
  ///
  /// In ar, this message translates to:
  /// **'تعديل القطعة'**
  String get editPart;

  /// No description provided for @deletePart.
  ///
  /// In ar, this message translates to:
  /// **'حذف القطعة'**
  String get deletePart;

  /// No description provided for @newPart.
  ///
  /// In ar, this message translates to:
  /// **'جديدة'**
  String get newPart;

  /// No description provided for @usedPart.
  ///
  /// In ar, this message translates to:
  /// **'مستعملة'**
  String get usedPart;

  /// No description provided for @sellerRating.
  ///
  /// In ar, this message translates to:
  /// **'تقييم البائع: {rating} ({count})'**
  String sellerRating(String rating, int count);

  /// No description provided for @sellerNotRated.
  ///
  /// In ar, this message translates to:
  /// **'البائع غير مقيّم'**
  String get sellerNotRated;

  /// No description provided for @contactSeller.
  ///
  /// In ar, this message translates to:
  /// **'تواصل مع البائع'**
  String get contactSeller;

  /// No description provided for @callSeller.
  ///
  /// In ar, this message translates to:
  /// **'اتصال: {phone}'**
  String callSeller(String phone);

  /// No description provided for @addedToCart.
  ///
  /// In ar, this message translates to:
  /// **'مضافة للسلة'**
  String get addedToCart;

  /// No description provided for @addToCart.
  ///
  /// In ar, this message translates to:
  /// **'أضف للسلة'**
  String get addToCart;

  /// No description provided for @rateThisSeller.
  ///
  /// In ar, this message translates to:
  /// **'قيّم هذا البائع'**
  String get rateThisSeller;

  /// No description provided for @shoppingCart.
  ///
  /// In ar, this message translates to:
  /// **'سلة المشتريات'**
  String get shoppingCart;

  /// No description provided for @emptyCart.
  ///
  /// In ar, this message translates to:
  /// **'السلة فارغة حالياً'**
  String get emptyCart;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get total;

  /// No description provided for @checkout.
  ///
  /// In ar, this message translates to:
  /// **'إتمام الشراء'**
  String get checkout;

  /// No description provided for @paymentCreationFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر إنشاء عملية الدفع'**
  String get paymentCreationFailed;

  /// No description provided for @addPartForSale.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قطعة للبيع'**
  String get addPartForSale;

  /// No description provided for @partName.
  ///
  /// In ar, this message translates to:
  /// **'اسم القطعة'**
  String get partName;

  /// No description provided for @partNameHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: حامل مساند خلفي'**
  String get partNameHint;

  /// No description provided for @compatibleVehicleBrand.
  ///
  /// In ar, this message translates to:
  /// **'شركة السيارة المتوافقة'**
  String get compatibleVehicleBrand;

  /// No description provided for @partCondition.
  ///
  /// In ar, this message translates to:
  /// **'حالة القطعة'**
  String get partCondition;

  /// No description provided for @partManufacturerOptional.
  ///
  /// In ar, this message translates to:
  /// **'الشركة المصنّعة للقطعة (اختياري)'**
  String get partManufacturerOptional;

  /// No description provided for @partManufacturerHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: Bosch، Denso، أصلي وكالة'**
  String get partManufacturerHint;

  /// No description provided for @priceOptional.
  ///
  /// In ar, this message translates to:
  /// **'السعر (اختياري)'**
  String get priceOptional;

  /// No description provided for @sellerPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم جوالك للتواصل'**
  String get sellerPhone;

  /// No description provided for @partNotesHint.
  ///
  /// In ar, this message translates to:
  /// **'حالة القطعة وتفاصيل أخرى'**
  String get partNotesHint;

  /// No description provided for @oemNumberOptional.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة الأصلي OEM (اختياري)'**
  String get oemNumberOptional;

  /// No description provided for @partNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم القطعة: {number}'**
  String partNumberLabel(String number);

  /// No description provided for @partManufacturerLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشركة المصنّعة: {manufacturer}'**
  String partManufacturerLabel(String manufacturer);

  /// No description provided for @partImageOptional.
  ///
  /// In ar, this message translates to:
  /// **'صورة القطعة (اختياري)'**
  String get partImageOptional;

  /// No description provided for @attachPartImage.
  ///
  /// In ar, this message translates to:
  /// **'إرفاق صورة القطعة'**
  String get attachPartImage;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get saveChanges;

  /// No description provided for @publishPart.
  ///
  /// In ar, this message translates to:
  /// **'نشر القطعة'**
  String get publishPart;

  /// No description provided for @requiredPartFields.
  ///
  /// In ar, this message translates to:
  /// **'عبّئ اسم القطعة والشركة ورقم الجوال'**
  String get requiredPartFields;

  /// No description provided for @myListings.
  ///
  /// In ar, this message translates to:
  /// **'منتجاتي'**
  String get myListings;

  /// No description provided for @soldOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مبيعة'**
  String get soldOrders;

  /// No description provided for @totalRevenue.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الإيرادات'**
  String get totalRevenue;

  /// No description provided for @listedProducts.
  ///
  /// In ar, this message translates to:
  /// **'منتجاتي المعروضة'**
  String get listedProducts;

  /// No description provided for @noListings.
  ///
  /// In ar, this message translates to:
  /// **'لم تعرض أي قطعة بعد'**
  String get noListings;

  /// No description provided for @mySalesOrders.
  ///
  /// In ar, this message translates to:
  /// **'طلبات بيعي'**
  String get mySalesOrders;

  /// No description provided for @noSalesOrders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات بيع بعد'**
  String get noSalesOrders;

  /// No description provided for @sellerDashboardLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل بيانات لوحة البائع'**
  String get sellerDashboardLoadFailed;

  /// No description provided for @subscriptionStatusLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب حالة الاشتراك'**
  String get subscriptionStatusLoadFailed;

  /// No description provided for @subscriptionActive.
  ///
  /// In ar, this message translates to:
  /// **'اشتراكك نشط'**
  String get subscriptionActive;

  /// No description provided for @unlockFullApp.
  ///
  /// In ar, this message translates to:
  /// **'افتح كامل إمكانيات التطبيق'**
  String get unlockFullApp;

  /// No description provided for @yearlyPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة سنوية'**
  String get yearlyPlan;

  /// No description provided for @monthlyPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة شهرية'**
  String get monthlyPlan;

  /// No description provided for @subscriptionEndsOn.
  ///
  /// In ar, this message translates to:
  /// **'{plan} — ينتهي في {date}'**
  String subscriptionEndsOn(String plan, String date);

  /// No description provided for @freeUsageStatus.
  ///
  /// In ar, this message translates to:
  /// **'استخدمت {used} من {limit} تشخيصات مجانية هذا الشهر'**
  String freeUsageStatus(int used, int limit);

  /// No description provided for @subscriptionBenefits.
  ///
  /// In ar, this message translates to:
  /// **'مميزات الاشتراك'**
  String get subscriptionBenefits;

  /// No description provided for @unlimitedAiDiagnoses.
  ///
  /// In ar, this message translates to:
  /// **'تشخيصات ذكاء اصطناعي غير محدودة'**
  String get unlimitedAiDiagnoses;

  /// No description provided for @unlimitedAiDiagnosesDescription.
  ///
  /// In ar, this message translates to:
  /// **'شخّص أي عدد من مشاكل سيارتك بدون حد شهري'**
  String get unlimitedAiDiagnosesDescription;

  /// No description provided for @expertAssistant.
  ///
  /// In ar, this message translates to:
  /// **'مساعد اسأل خبير السيارات'**
  String get expertAssistant;

  /// No description provided for @expertAssistantDescription.
  ///
  /// In ar, this message translates to:
  /// **'اسأل أي سؤال متابعة بعد كل تشخيص بدون حدود'**
  String get expertAssistantDescription;

  /// No description provided for @professionalPdfReports.
  ///
  /// In ar, this message translates to:
  /// **'تقارير PDF احترافية'**
  String get professionalPdfReports;

  /// No description provided for @professionalPdfReportsDescription.
  ///
  /// In ar, this message translates to:
  /// **'تقرير كامل برمز QR للتحقق، جاهز للطباعة أو المشاركة'**
  String get professionalPdfReportsDescription;

  /// No description provided for @prioritySupport.
  ///
  /// In ar, this message translates to:
  /// **'أولوية بالدعم الفني'**
  String get prioritySupport;

  /// No description provided for @prioritySupportDescription.
  ///
  /// In ar, this message translates to:
  /// **'ردود أسرع على استفساراتك ومشاكلك التقنية'**
  String get prioritySupportDescription;

  /// No description provided for @choosePlan.
  ///
  /// In ar, this message translates to:
  /// **'اختر الباقة'**
  String get choosePlan;

  /// No description provided for @yearly.
  ///
  /// In ar, this message translates to:
  /// **'سنوي'**
  String get yearly;

  /// No description provided for @monthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get monthly;

  /// No description provided for @yearlyValue.
  ///
  /// In ar, this message translates to:
  /// **'أفضل قيمة — يعادل 9.92 ر.س شهريًا'**
  String get yearlyValue;

  /// No description provided for @bestValue.
  ///
  /// In ar, this message translates to:
  /// **'الأفضل قيمة'**
  String get bestValue;

  /// No description provided for @monthlyFlexibility.
  ///
  /// In ar, this message translates to:
  /// **'مرونة الإلغاء بأي وقت'**
  String get monthlyFlexibility;

  /// No description provided for @subscribeNow.
  ///
  /// In ar, this message translates to:
  /// **'اشترك الآن'**
  String get subscribeNow;

  /// No description provided for @repairPdfTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير إصلاح السيارة'**
  String get repairPdfTitle;

  /// No description provided for @diagnosisPdfTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير تشخيص السيارة الذكي'**
  String get diagnosisPdfTitle;

  /// No description provided for @pdfVehicle.
  ///
  /// In ar, this message translates to:
  /// **'السيارة'**
  String get pdfVehicle;

  /// No description provided for @pdfDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get pdfDate;

  /// No description provided for @pdfOdometer.
  ///
  /// In ar, this message translates to:
  /// **'العداد'**
  String get pdfOdometer;

  /// No description provided for @pdfDiagnosis.
  ///
  /// In ar, this message translates to:
  /// **'التشخيص'**
  String get pdfDiagnosis;

  /// No description provided for @pdfQuoteReview.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة العرض'**
  String get pdfQuoteReview;

  /// No description provided for @pdfRepair.
  ///
  /// In ar, this message translates to:
  /// **'الإصلاح'**
  String get pdfRepair;

  /// No description provided for @pdfCost.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة'**
  String get pdfCost;

  /// No description provided for @pdfVerification.
  ///
  /// In ar, this message translates to:
  /// **'التحقق'**
  String get pdfVerification;

  /// No description provided for @pdfNotSpecified.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get pdfNotSpecified;

  /// No description provided for @pdfAvailable.
  ///
  /// In ar, this message translates to:
  /// **'متاح'**
  String get pdfAvailable;

  /// No description provided for @pdfDocumentationDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'هذا التقرير توثيقي ولا يغني عن الفحص الفني.'**
  String get pdfDocumentationDisclaimer;

  /// No description provided for @pdfReportNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم التقرير'**
  String get pdfReportNumber;

  /// No description provided for @pdfProblemDescription.
  ///
  /// In ar, this message translates to:
  /// **'وصف المشكلة'**
  String get pdfProblemDescription;

  /// No description provided for @pdfSeverity.
  ///
  /// In ar, this message translates to:
  /// **'الخطورة'**
  String get pdfSeverity;

  /// No description provided for @pdfConfidence.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الثقة'**
  String get pdfConfidence;

  /// No description provided for @pdfExplanation.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get pdfExplanation;

  /// No description provided for @pdfRecommendations.
  ///
  /// In ar, this message translates to:
  /// **'التوصيات'**
  String get pdfRecommendations;

  /// No description provided for @pdfRequiredParts.
  ///
  /// In ar, this message translates to:
  /// **'القطع المحتملة'**
  String get pdfRequiredParts;

  /// No description provided for @pdfPart.
  ///
  /// In ar, this message translates to:
  /// **'القطعة'**
  String get pdfPart;

  /// No description provided for @pdfPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get pdfPrice;

  /// No description provided for @pdfSource.
  ///
  /// In ar, this message translates to:
  /// **'المصدر'**
  String get pdfSource;

  /// No description provided for @pdfEstimatedCost.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة التقديرية'**
  String get pdfEstimatedCost;

  /// No description provided for @pdfAiDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'هذا تشخيص أولي توجيهي بالذكاء الاصطناعي، وليس بديلاً عن فحص فني معتمد.'**
  String get pdfAiDisclaimer;

  /// No description provided for @pdfQrInstruction.
  ///
  /// In ar, this message translates to:
  /// **'امسح الرمز للتحقق من محتوى التقرير'**
  String get pdfQrInstruction;

  /// No description provided for @contactSignInRequired.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للتواصل مع البائع'**
  String get contactSignInRequired;

  /// No description provided for @sellerContactUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'بيانات تواصل البائع غير متاحة'**
  String get sellerContactUnavailable;

  /// No description provided for @sellerContactRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبات تواصل كثيرة. حاول لاحقًا.'**
  String get sellerContactRateLimited;

  /// No description provided for @sellerContactFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر جلب بيانات تواصل البائع'**
  String get sellerContactFailed;

  /// No description provided for @historyPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل التشخيصات'**
  String get historyPageTitle;

  /// No description provided for @historyLoading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل سجل السيارة'**
  String get historyLoading;

  /// No description provided for @historyFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get historyFilterAll;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف التشخيص'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف هذا التشخيص من السجل؟'**
  String get historyDeleteConfirm;

  /// No description provided for @historyDeleteFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف العنصر'**
  String get historyDeleteFailed;

  /// No description provided for @historyConnectionFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بالسيرفر'**
  String get historyConnectionFailed;

  /// No description provided for @historyUnknownSeverity.
  ///
  /// In ar, this message translates to:
  /// **'غير محددة'**
  String get historyUnknownSeverity;

  /// No description provided for @historySeverityLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخطورة'**
  String get historySeverityLabel;

  /// No description provided for @historyRecommendationsLabel.
  ///
  /// In ar, this message translates to:
  /// **'التوصيات'**
  String get historyRecommendationsLabel;

  /// No description provided for @historyEstimatedCostLabel.
  ///
  /// In ar, this message translates to:
  /// **'التكلفة التقديرية'**
  String get historyEstimatedCostLabel;

  /// No description provided for @historyEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد أي تشخيصات محفوظة بعد'**
  String get historyEmpty;

  /// No description provided for @historyNoFiltered.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تشخيصات بمستوى خطورة'**
  String get historyNoFiltered;

  /// No description provided for @historyUntitled.
  ///
  /// In ar, this message translates to:
  /// **'تشخيص بدون عنوان'**
  String get historyUntitled;

  /// No description provided for @historyLoadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل السجل'**
  String get historyLoadFailed;

  /// No description provided for @historyRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get historyRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
