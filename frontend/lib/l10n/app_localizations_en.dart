// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Car Diagnosis';

  @override
  String get preparingApp => 'Preparing Smart Car Check';

  @override
  String get onboardingUnderstandTitle => 'Understand your car\'s problem';

  @override
  String get onboardingUnderstandBody =>
      'Get clear guidance based on symptoms and vehicle data.';

  @override
  String get onboardingConnectTitle => 'Connect OBD or describe the symptoms';

  @override
  String get onboardingConnectBody =>
      'Choose the right diagnostic method and skip what you do not need.';

  @override
  String get onboardingChecksTitle => 'Get clear inspection steps';

  @override
  String get onboardingChecksBody =>
      'Know what to inspect before replacing any part.';

  @override
  String get onboardingHistoryTitle => 'Keep your vehicle history';

  @override
  String get onboardingHistoryBody =>
      'Track faults, maintenance, and repairs in one place.';

  @override
  String get next => 'Next';

  @override
  String get start => 'Get started';

  @override
  String get loginTitle => 'Sign in with your phone number';

  @override
  String get otpTitle => 'Enter the verification code';

  @override
  String get otpSubtitle => 'We sent a 6-digit verification code to your phone';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHelper => 'You can also enter the number as 05XXXXXXXX';

  @override
  String get otpLabel => 'Verification code';

  @override
  String get sendOtp => 'Send verification code';

  @override
  String get verifyOtp => 'Verify code';

  @override
  String get changePhone => 'Change phone number';

  @override
  String get invalidSaudiPhone => 'Enter a valid Saudi mobile number';

  @override
  String get incompleteOtp => 'Enter the complete verification code';

  @override
  String get authUnexpected => 'An unexpected error occurred';

  @override
  String get authAutomaticFailed =>
      'Automatic verification failed. Enter the code manually.';

  @override
  String get authSendFailed =>
      'We could not send the verification code. Check the phone number and try again.';

  @override
  String get authSessionExpired =>
      'The verification session expired. Send a new code.';

  @override
  String get authInvalidPhone =>
      'The phone number is invalid. Check the format.';

  @override
  String get authInvalidCode => 'The verification code is incorrect';

  @override
  String get authCodeExpired =>
      'The verification code expired. Send a new one.';

  @override
  String get authTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authRequestFailed =>
      'We could not complete the request. Try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navDiagnosis => 'Diagnosis';

  @override
  String get navCars => 'My cars';

  @override
  String get navHistory => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get addFirstCar => 'Add your first car to start a check';

  @override
  String get addCar => 'Add car';

  @override
  String get currentCar => 'Current car';

  @override
  String get carHealth => 'Vehicle health';

  @override
  String get changeCar => 'Change car';

  @override
  String get healthGood => 'Good';

  @override
  String get healthAttention => 'Needs attention';

  @override
  String get healthUrgent => 'Urgent';

  @override
  String get healthUnknown => 'Not determined';

  @override
  String mileageKm(int mileage) {
    return '$mileage km';
  }

  @override
  String get startCarCheck => 'Start vehicle check';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get obdCheck => 'OBD check';

  @override
  String get readCarCodes => 'Read vehicle codes';

  @override
  String get describeSymptoms => 'Describe symptoms';

  @override
  String get explainProblem => 'Explain the problem';

  @override
  String get beforeYouPay => 'Before You Pay';

  @override
  String get reviewWorkshopQuote => 'Review the workshop quote';

  @override
  String get carRecord => 'Vehicle record';

  @override
  String get checksAndRepairs => 'Checks and repairs';

  @override
  String get unresolvedIssues => 'Unresolved issues';

  @override
  String get noUnresolvedIssues => 'No unresolved issues';

  @override
  String get returnedAfterRepair => 'Returned after repair';

  @override
  String get additionalServices => 'Additional services';

  @override
  String get beforePayWorkshop => 'Before paying the workshop';

  @override
  String get reviewRepairWithCarData =>
      'Review the proposed repair using your vehicle data';

  @override
  String get subscription => 'Subscription';

  @override
  String get partsMarketplace => 'Parts marketplace';

  @override
  String get additionalService => 'Additional service';

  @override
  String get repairPendingVerification => 'Repair awaiting verification';

  @override
  String get verifyRepairSubtitle =>
      'Check whether the problem disappeared after the repair.';

  @override
  String get verifyNow => 'Verify now';

  @override
  String get repairedIssueReturned =>
      'A previously repaired issue has returned';

  @override
  String get upcomingMaintenance => 'Upcoming maintenance';

  @override
  String get noMaintenanceAdded => 'No maintenance appointment added yet';

  @override
  String get latestCheck => 'Latest check';

  @override
  String get noPreviousCheck => 'No previous checks';

  @override
  String get repaired => 'Repaired';

  @override
  String get followUp => 'Follow up';

  @override
  String get viewAll => 'View all';

  @override
  String get preferences => 'Preferences';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeEnabled => 'Dark mode is enabled';

  @override
  String get lightModeEnabled => 'Light mode is enabled';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get manageCars => 'Manage my cars';

  @override
  String get manageCarsSubtitle => 'Add or edit your vehicle details';

  @override
  String get aboutApp => 'About the app';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get appDescription =>
      'An AI-powered app that provides preliminary guidance for vehicle problems based on your description and vehicle data.';

  @override
  String get disclaimerText =>
      'This diagnosis provides preliminary guidance only. It does not replace an inspection by a qualified technician before making any safety-related decision.';

  @override
  String get logout => 'Log out';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get replace => 'Replace';

  @override
  String get camera => 'Take photo';

  @override
  String get gallery => 'Choose from gallery';

  @override
  String get diagnosisTitle => 'Vehicle diagnosis';

  @override
  String get preparingDiagnosis => 'Preparing diagnosis';

  @override
  String get selectCarToContinue => 'Select a vehicle to continue.';

  @override
  String get selectDiagnosisSource => 'Select at least one diagnostic source.';

  @override
  String get diagnosisInputRequired => 'Add symptoms, OBD codes, or an image.';

  @override
  String get freeDiagnosisLimitReached =>
      'You have reached this month\'s free limit. Manage your subscription from the home screen.';

  @override
  String diagnosisRequestFailed(int status) {
    return 'The diagnosis could not be completed ($status)';
  }

  @override
  String get serverConnectionFailed => 'Could not connect to the server';

  @override
  String get diagnosisStepCar => 'Vehicle';

  @override
  String get diagnosisStepSources => 'Sources';

  @override
  String get diagnosisStepDetails => 'Details';

  @override
  String get diagnosisStepReview => 'Review';

  @override
  String get chooseVehicle => 'Choose vehicle';

  @override
  String get chooseVehicleSubtitle =>
      'Select the vehicle you want to diagnose.';

  @override
  String get chooseSources => 'Choose diagnostic sources';

  @override
  String get chooseSourcesSubtitle =>
      'Combine available sources for a clearer result.';

  @override
  String get enterDiagnosisDetails => 'Enter diagnosis details';

  @override
  String get enterDiagnosisDetailsSubtitle =>
      'Add the available data for each selected source.';

  @override
  String get reviewDiagnosis => 'Review request';

  @override
  String get reviewDiagnosisSubtitle =>
      'Confirm the data before starting the analysis.';

  @override
  String get obdCodes => 'OBD codes';

  @override
  String obdCodesAvailable(int count) {
    return '$count code(s) found';
  }

  @override
  String get noObdCodes => 'No saved codes';

  @override
  String get connectObd => 'Connect an OBD device';

  @override
  String get manageObd => 'Manage OBD connection';

  @override
  String get symptoms => 'Symptoms';

  @override
  String get symptomsHint =>
      'Example: vibration while idling or noise during acceleration';

  @override
  String get diagnosisImage => 'Problem image';

  @override
  String get diagnosisImageHint =>
      'For example, a warning light or a visible vehicle part';

  @override
  String get selectImage => 'Choose image';

  @override
  String get imageAttached => 'Image attached';

  @override
  String get sourceObd => 'OBD codes';

  @override
  String get sourceSymptoms => 'Symptom description';

  @override
  String get sourceImage => 'Image';

  @override
  String get selectedSources => 'Selected sources';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get startDiagnosis => 'Start diagnosis';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get analyzingDiagnosisData => 'Analyzing diagnosis data';

  @override
  String get analysisMayTakeMoments => 'This may take a few moments';

  @override
  String get analysisStageSources => 'Combining diagnostic sources';

  @override
  String get analysisStageSafety => 'Reviewing safety indicators';

  @override
  String get analysisStageResult => 'Preparing the result and suggested steps';

  @override
  String get analysisStagesNotice =>
      'These are general display stages, not a live server progress indicator.';

  @override
  String get diagnosisResult => 'Diagnosis result';

  @override
  String get severity => 'Severity';

  @override
  String get severityCritical => 'Critical';

  @override
  String get severityHigh => 'High';

  @override
  String get severityMedium => 'Medium';

  @override
  String get severityLow => 'Low';

  @override
  String get canDrive => 'Can I drive?';

  @override
  String get whatWeFound => 'What we found';

  @override
  String get faultReturnedAfterRepair =>
      'This issue returned after a previous repair';

  @override
  String get faultCodes => 'Fault codes';

  @override
  String get unknownDtcMeaning => 'No description is available for this code.';

  @override
  String get likelyCauses => 'Most likely causes';

  @override
  String get checksFirst => 'What should be checked first?';

  @override
  String get relatedParts => 'Potentially related parts';

  @override
  String get findPart => 'Find part';

  @override
  String get findPartTitle => 'Find a part';

  @override
  String get generalWebSearch => 'Search the web';

  @override
  String get partCompatibilityNotice =>
      'Confirm the part number and vehicle compatibility before buying.';

  @override
  String get partSearchNotice =>
      'Search is for comparison only. Do not buy a part before confirming the fault and matching part number.';

  @override
  String get openWorkshopMode => 'Open workshop mode';

  @override
  String get nextStep => 'Next step';

  @override
  String get saveToCarRecord => 'Save to vehicle record';

  @override
  String get savedToCarRecord => 'Saved to vehicle record';

  @override
  String get saving => 'Saving...';

  @override
  String get recordRepair => 'Record repair';

  @override
  String get verifyRepairLater => 'Verify repair later';

  @override
  String get recordRepairTitle => 'Record repair';

  @override
  String get repairWorkLabel => 'What was replaced or repaired?';

  @override
  String get repairCost => 'Repair cost';

  @override
  String get sarShort => 'SAR';

  @override
  String get workshopOptional => 'Workshop name (optional)';

  @override
  String get odometer => 'Odometer';

  @override
  String get kmShort => 'km';

  @override
  String get note => 'Note';

  @override
  String get issueGoneQuestion => 'Has the issue disappeared?';

  @override
  String get repairSaved => 'Repair saved to the vehicle record';

  @override
  String get diagnosisSafetyDisclaimer =>
      'This result is guidance only and does not replace a direct technical inspection before making a safety-related decision or replacing parts.';

  @override
  String get beforeYouPayTitle => 'Before You Pay';

  @override
  String get preparingVehicleData => 'Preparing vehicle data';

  @override
  String get beforeYouPayIntro =>
      'Review the workshop diagnosis and quote before approving it.';

  @override
  String get quoteStepCar => 'Vehicle';

  @override
  String get quoteStepDetails => 'Quote';

  @override
  String get quoteStepReview => 'Review';

  @override
  String get selectQuoteCar => 'Choose vehicle';

  @override
  String get selectQuoteCarSubtitle =>
      'We will compare the quote with the available vehicle history and data.';

  @override
  String get enterQuoteDetails => 'Enter workshop quote details';

  @override
  String get enterQuoteDetailsSubtitle =>
      'Add the workshop statement, parts, price, or a quote image.';

  @override
  String get reviewQuoteRequest => 'Review request details';

  @override
  String get reviewQuoteRequestSubtitle =>
      'Confirm the data before sending it for review.';

  @override
  String get noCarAdded => 'No vehicle added';

  @override
  String mileageValue(int mileage) {
    return 'Odometer: $mileage km';
  }

  @override
  String get workshopStatement => 'Workshop statement';

  @override
  String get workshopStatementHint =>
      'Example: replace the front strut due to a noise over bumps';

  @override
  String get proposedParts => 'Proposed replacement parts';

  @override
  String get proposedPartsHint =>
      'Enter one part per line or separate parts with commas';

  @override
  String get totalPriceOptional => 'Total price (optional)';

  @override
  String get captureQuote => 'Photograph quote';

  @override
  String get chooseQuoteImage => 'Choose image';

  @override
  String get attachQuoteImage => 'Attach quote image';

  @override
  String get replaceQuoteImage => 'Replace quote image';

  @override
  String get quoteInputRequired =>
      'Add the workshop statement, proposed parts, or a quote image.';

  @override
  String get quoteReviewFailed => 'The quote could not be reviewed. Try again.';

  @override
  String get reviewQuote => 'Review quote';

  @override
  String get reviewingQuote => 'Reviewing...';

  @override
  String get quoteReviewTitle => 'Workshop quote review';

  @override
  String get quoteStop => 'Do not approve before additional checks';

  @override
  String get quoteLogical => 'The quote appears reasonable';

  @override
  String get quoteVerify => 'Verification needed before approval';

  @override
  String get reviewIncomplete =>
      'The automated review was not completed. Do not rely on this result to make a decision.';

  @override
  String get safetyAlert => 'Safety alert';

  @override
  String get alignedEvidence => 'What aligns with your vehicle data?';

  @override
  String get evidenceNeeded => 'What still needs evidence?';

  @override
  String get askTechnician => 'Before you pay, ask the technician:';

  @override
  String get recommendedChecksFirst => 'Checks recommended before approval';

  @override
  String get proposedPartsTitle => 'Proposed parts';

  @override
  String get price => 'Price';

  @override
  String get priceAssessment => 'Price assessment';

  @override
  String get insufficientPriceData =>
      'There is not enough market data to assess the price at this time.';

  @override
  String vehicleLabel(String car) {
    return 'Vehicle: $car';
  }

  @override
  String get evidenceStrong => 'Strong match';

  @override
  String get evidencePartial => 'Partial match';

  @override
  String get evidenceInsufficient => 'Insufficient evidence';

  @override
  String workshopReason(String reason) {
    return 'Workshop reason: $reason';
  }

  @override
  String get reasonNotProvided => 'Not provided';

  @override
  String get obdUnavailable => 'Currently unavailable on this device';

  @override
  String get moreSourcesHelp =>
      'More information gives Smart Car Check better diagnostic context.';

  @override
  String get obdNotConnected => 'OBD device not connected';

  @override
  String get obdCodesRead => 'Codes read successfully';

  @override
  String get connectObdToRead =>
      'Connect the device to read actual fault codes';

  @override
  String get noDriveAdvice => 'No driving recommendation is available';

  @override
  String get diagnosisFallbackTitle => 'Diagnosis result';

  @override
  String confidencePercent(Object value) {
    return 'Confidence $value%';
  }

  @override
  String get doNotReplaceBeforeInspection =>
      'Do not replace any part before confirming the cause through a direct inspection.';

  @override
  String get quoteReviewCarHeading => 'Choose vehicle';

  @override
  String get quoteReviewCarBody =>
      'We will use the available vehicle data and history for comparison only.';

  @override
  String get quoteOfferHeading => 'What did the workshop tell you?';

  @override
  String get quoteOfferBody =>
      'Add only what you have; not every field is required.';

  @override
  String get quoteReviewHeading => 'Review details';

  @override
  String get quoteReviewBody =>
      'We will use the available context without inventing missing information.';

  @override
  String get notProvided => 'Not provided';

  @override
  String get notAttached => 'Not attached';

  @override
  String get attached => 'Attached';

  @override
  String get parts => 'Parts';

  @override
  String get quoteImage => 'Quote image';

  @override
  String get availableContext => 'Available context';

  @override
  String contextSummary(int issues, int maintenance, int codes) {
    return '$issues issue(s) • $maintenance maintenance record(s) • $codes OBD code(s)';
  }

  @override
  String get diagnosisReviewNotice =>
      'Only the vehicle data, symptoms, and read codes will be used to create a guidance result.';

  @override
  String get bluetooth => 'Bluetooth';

  @override
  String get obdConnection => 'OBD connection';

  @override
  String get processingVehicleData => 'Analyzing vehicle data';

  @override
  String get processingObdCodes => 'Reviewing OBD codes';

  @override
  String get processingSymptoms => 'Comparing symptoms';

  @override
  String get processingResult => 'Preparing the diagnosis result';

  @override
  String get myCars => 'My vehicles';

  @override
  String get keepOneCar => 'At least one vehicle must remain';

  @override
  String get deleteCar => 'Delete vehicle';

  @override
  String get deleteCarConfirm => 'Remove this vehicle from your list?';

  @override
  String get addNewCar => 'Add new vehicle';

  @override
  String get editCar => 'Edit vehicle';

  @override
  String get manufacturer => 'Manufacturer';

  @override
  String get manufacturerName => 'Enter manufacturer name';

  @override
  String get carModel => 'Model';

  @override
  String get carModelName => 'Enter model name';

  @override
  String get manufactureYear => 'Model year';

  @override
  String get vinOptional => 'VIN (optional)';

  @override
  String get engineTypeOptional => 'Engine type (optional)';

  @override
  String get transmissionTypeOptional => 'Transmission type (optional)';

  @override
  String get currentMileageOptional => 'Current odometer (optional)';

  @override
  String get registrationExpiry => 'Registration expiry';

  @override
  String get insuranceExpiry => 'Insurance expiry';

  @override
  String get inspectionExpiry => 'Inspection expiry';

  @override
  String get notSet => 'Not set';

  @override
  String get chooseDate => 'Set date';

  @override
  String get loadingCars => 'Loading your vehicles';

  @override
  String get firstCarMessage => 'Vehicle health and records will appear here.';

  @override
  String get mileageNotRecorded => 'Odometer not recorded';

  @override
  String get activeVehicle => 'Current vehicle';

  @override
  String get other => 'Other';

  @override
  String get brandToyota => 'Toyota';

  @override
  String get brandHonda => 'Honda';

  @override
  String get brandNissan => 'Nissan';

  @override
  String get brandHyundai => 'Hyundai';

  @override
  String get brandKia => 'Kia';

  @override
  String get brandFord => 'Ford';

  @override
  String get brandChevrolet => 'Chevrolet';

  @override
  String get brandMercedes => 'Mercedes-Benz';

  @override
  String get brandBmw => 'BMW';

  @override
  String get brandAudi => 'Audi';

  @override
  String get brandLexus => 'Lexus';

  @override
  String get brandMazda => 'Mazda';

  @override
  String get brandMitsubishi => 'Mitsubishi';

  @override
  String get brandJeep => 'Jeep';

  @override
  String get brandGmc => 'GMC';

  @override
  String get brandDodge => 'Dodge';

  @override
  String get brandInfiniti => 'Infiniti';

  @override
  String get brandSuzuki => 'Suzuki';

  @override
  String get brandVolkswagen => 'Volkswagen';

  @override
  String get vehicleRecordTitle => 'Vehicle health record';

  @override
  String get preparingVehicleRecord => 'Preparing vehicle record';

  @override
  String get emptyVehicleRecord => 'No vehicle records yet';

  @override
  String get emptyVehicleRecordMessage =>
      'Diagnoses, maintenance, and repairs will appear here chronologically.';

  @override
  String get vehicleTimeline => 'Vehicle timeline';

  @override
  String get diagnosesCount => 'Diagnoses';

  @override
  String get repairsCount => 'Repairs';

  @override
  String get maintenanceCount => 'Maintenance';

  @override
  String get obdScan => 'OBD scan';

  @override
  String get codesRead => 'Read';

  @override
  String get repairReview => 'Repair review';

  @override
  String get reviewStatus => 'Review';

  @override
  String get recordedRepair => 'Recorded repair';

  @override
  String get recordedStatus => 'Recorded';

  @override
  String get issueReturned => 'Issue returned';

  @override
  String get noObdCodesRecorded => 'No OBD codes';

  @override
  String get checkAndDiagnosis => 'Check and diagnosis';

  @override
  String get repairType => 'Repair';

  @override
  String get maintenanceType => 'Maintenance';

  @override
  String get issueOngoing => 'Issue ongoing';

  @override
  String get statusNew => 'New';

  @override
  String get statusMonitoring => 'Monitoring';

  @override
  String get statusRepairNeeded => 'Repair needed';

  @override
  String get maintenanceReminders => 'Scheduled maintenance reminders';

  @override
  String get loadingMaintenanceReminders => 'Loading maintenance reminders';

  @override
  String get noMaintenanceReminders => 'No maintenance reminders';

  @override
  String get noMaintenanceRemindersMessage =>
      'Add a reminder and we will help you remember it.';

  @override
  String get addReminder => 'Add reminder';

  @override
  String overdueDays(int days) {
    return 'Overdue by $days day(s)';
  }

  @override
  String daysRemaining(int days) {
    return '$days day(s) remaining';
  }

  @override
  String get newMaintenanceReminder => 'New maintenance reminder';

  @override
  String get maintenanceTypeExample =>
      'Maintenance type (for example, oil change)';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String dateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get change => 'Change';

  @override
  String maintenanceHistoryFor(String car) {
    return 'Maintenance history — $car';
  }

  @override
  String get noMaintenanceHistory =>
      'No maintenance records for this vehicle yet';

  @override
  String get deleteConfirmation => 'Confirm deletion';

  @override
  String get deleteMaintenanceConfirm => 'Permanently delete this record?';

  @override
  String get viewInvoice => 'View invoice';

  @override
  String get addMaintenanceRecord => 'Add maintenance record';

  @override
  String get maintenanceCategory => 'Maintenance category';

  @override
  String get workDescriptionOptional => 'Work description (optional)';

  @override
  String get workDescriptionHint => 'Example: engine oil and filter change';

  @override
  String get serviceMileageOptional => 'Odometer at service (optional)';

  @override
  String get partNumberOptional => 'Part number (optional)';

  @override
  String get partNumberHint => 'Example: 90915-YZZD4';

  @override
  String get workshopNameOptional => 'Workshop (optional)';

  @override
  String get workshopNameHint => 'Workshop name';

  @override
  String get date => 'Date';

  @override
  String get costOptional => 'Cost (optional)';

  @override
  String get additionalDetailsHint => 'Additional details';

  @override
  String get invoiceImageOptional => 'Invoice image (optional)';

  @override
  String get attachInvoice => 'Attach invoice image';

  @override
  String get saveRecord => 'Save record';

  @override
  String get workTypeRequired => 'Enter the work performed';

  @override
  String get saveFailed => 'Could not save. Try again.';

  @override
  String nextMaintenanceFor(String category) {
    return 'Next $category service';
  }

  @override
  String get autoReminderNote =>
      'Created automatically after recording maintenance';

  @override
  String get categoryEngineOil => 'Engine oil change';

  @override
  String get categoryOilFilter => 'Oil filter';

  @override
  String get categoryAirFilter => 'Air filter';

  @override
  String get categorySparkPlugs => 'Spark plugs';

  @override
  String get categoryBrakePads => 'Brake pads';

  @override
  String get categoryBattery => 'Battery';

  @override
  String get categoryTires => 'Tires';

  @override
  String get categoryCabinFilter => 'Cabin air filter';

  @override
  String get categoryBrakeFluid => 'Brake fluid';

  @override
  String get obdConnectTitle => 'Connect OBD-II device';

  @override
  String get checkingObdCapability => 'Checking diagnostic capabilities...';

  @override
  String savedObdScan(int count) {
    return 'Last scan saved ($count code(s))';
  }

  @override
  String get obdDirectUnavailable =>
      'Direct OBD scanning is currently unavailable on this device';

  @override
  String get findPairedObd => 'Find OBD devices paired with your phone';

  @override
  String get findNearbyObd => 'Find nearby modern OBD devices';

  @override
  String get searching => 'Searching...';

  @override
  String get noNearbyObd =>
      'No nearby OBD device found. Turn on the adapter and try again.';

  @override
  String get noPairedObd =>
      'No paired devices found. Pair the OBD adapter in Bluetooth settings and try again.';

  @override
  String get chooseObdDevice => 'Choose an OBD device';

  @override
  String get obdSearchFailed =>
      'Search failed. Check Bluetooth and its permissions.';

  @override
  String connectingToDevice(String device) {
    return 'Connecting to $device...';
  }

  @override
  String connectedToDevice(String device) {
    return 'Connected to $device';
  }

  @override
  String get obdConnectionFailed =>
      'Connection failed. Check that the device is on and paired.';

  @override
  String get readingEngineTransmissionCodes =>
      'Reading engine and transmission codes...';

  @override
  String get transmissionModuleUnavailable =>
      'The transmission module is unavailable on this adapter or vehicle';

  @override
  String get noStoredFaultCodes => 'No stored fault codes found';

  @override
  String faultCodesFound(int total, int engine, int transmission) {
    return 'Found $total code(s) (engine: $engine, transmission: $transmission)';
  }

  @override
  String get clearCodesTitle => 'Confirm clearing codes';

  @override
  String get clearCodesConfirm =>
      'Clear all fault codes? This action cannot be undone.';

  @override
  String get confirmClear => 'Yes, clear';

  @override
  String get clearingCodes => 'Clearing codes...';

  @override
  String get codesCleared => 'All fault codes were cleared successfully';

  @override
  String get clearCodesFailed => 'Could not clear the codes. Try again.';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get disconnectedSaved =>
      'Disconnected — the scan result is saved and ready for diagnosis';

  @override
  String get searchLinkFailed => 'Could not open the search link';

  @override
  String get obdTranscriptCopied => 'OBD transcript copied';

  @override
  String get dtcGuide => 'DTC reference';

  @override
  String get chooseConnectionMethod => 'Choose connection method';

  @override
  String get searchNearbyDevices => 'Search nearby devices';

  @override
  String get showPairedDevices => 'Show paired devices';

  @override
  String get connected => 'Connected';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get readCodes => 'Read codes';

  @override
  String get clearCodes => 'Clear codes';

  @override
  String diagnoseWithCodes(int count) {
    return 'Diagnose with these codes ($count)';
  }

  @override
  String get copyObdTranscript => 'Copy OBD transcript';

  @override
  String get obdUnavailableAlternative =>
      'Continue with symptoms or an image without using OBD.';

  @override
  String get nearbyDevice => 'Nearby device';

  @override
  String get pairedDevice => 'Paired device';

  @override
  String get classicBluetooth => 'Bluetooth Classic';

  @override
  String get bleDescription => 'For modern adapters and iPhone';

  @override
  String get classicBluetoothDescription => 'For traditional ELM327 adapters';

  @override
  String get findRequiredPart => 'Find the related part';

  @override
  String get dtcLoadFailed => 'Could not load the DTC reference';

  @override
  String get dtcSearchHint =>
      'Search by code (for example, P0301) or description';

  @override
  String dtcCount(int shown, int total) {
    return '$shown of $total codes';
  }

  @override
  String get noMatchingResults => 'No matching results';

  @override
  String get commonCauses => 'Common causes:';

  @override
  String get workshopMode => 'Workshop mode';

  @override
  String get showTechnician => 'Show this screen to the technician';

  @override
  String get workshopModeIntro =>
      'A concise, practical summary to help start the correct inspection.';

  @override
  String get unrecorded => 'Not recorded';

  @override
  String get noCodesRead => 'No codes were read';

  @override
  String get noSymptomsAdded => 'No symptoms added';

  @override
  String get askTechnicianToCheck =>
      'Ask the technician to verify these items before replacing parts';

  @override
  String get directTestRequired =>
      'Identify the fault cause with a direct test';

  @override
  String get shareWithTechnician => 'Share with technician';

  @override
  String get workshopSummaryDisclaimer =>
      'This is a guidance summary. The final decision depends on direct tests performed by a qualified technician.';

  @override
  String workshopShareText(String vehicle, String mileage, String codes,
      String symptoms, String checks) {
    return 'Vehicle: $vehicle\nOdometer: $mileage km\nDiagnostic codes: $codes\nSymptoms: $symptoms\n\nPlease verify the following before replacing parts:\n$checks\n\nPlease explain the test results and do not replace any part before confirming the fault cause.';
  }

  @override
  String get repairRecordTitle => 'Record repair';

  @override
  String get repairActionRequired =>
      'Enter the parts actually replaced or the work performed.';

  @override
  String get repairSaveFailed =>
      'Could not save the repair. Check your connection and try again.';

  @override
  String get deleteRepairRecord => 'Delete repair record';

  @override
  String get deleteLinkedRepairConfirm =>
      'A verification is linked to this repair. The repair record will be hidden without deleting the verification.';

  @override
  String get hideRepairConfirm => 'Hide this repair record?';

  @override
  String get deleteRecord => 'Delete record';

  @override
  String get partsActuallyReplaced => 'Parts actually replaced';

  @override
  String get partsConfirmationHint =>
      'Confirm what was replaced; do not rely only on the proposal';

  @override
  String get workPerformed => 'Work performed';

  @override
  String get repairMileageOptional => 'Vehicle odometer at repair (optional)';

  @override
  String get saveRepair => 'Save repair';

  @override
  String get repairVerificationTitle => 'Repair verification';

  @override
  String get postRepairComparison =>
      'Compare the post-repair condition with earlier data without assuming a result.';

  @override
  String get afterRepair => 'After repair';

  @override
  String get currentObdCodesOptional => 'Current OBD codes (optional)';

  @override
  String get currentObdCodesHint => 'Example: P0133 P0300';

  @override
  String get symptomsAfterRepair => 'How are the symptoms now?';

  @override
  String get symptomsAfterRepairHint => 'Gone, improved, or still present';

  @override
  String get addPostRepairImage => 'Add a post-repair image (optional)';

  @override
  String get replaceImage => 'Replace image';

  @override
  String get deleteImage => 'Delete image';

  @override
  String temporaryImageNotice(String mime) {
    return 'The image is temporary during verification ($mime) and is not saved to Firestore.';
  }

  @override
  String get verifyNowButton => 'Verify now';

  @override
  String removedCodes(String codes) {
    return 'Cleared codes: $codes';
  }

  @override
  String remainingCodes(String codes) {
    return 'Remaining codes: $codes';
  }

  @override
  String newCodes(String codes) {
    return 'New codes: $codes';
  }

  @override
  String get noData => 'No data';

  @override
  String get none => 'None';

  @override
  String get verificationSuccess => 'The repair appears successful';

  @override
  String get verificationImproved => 'Improved, but follow-up is needed';

  @override
  String get verificationUnresolved => 'The issue may not be fully resolved';

  @override
  String get verificationReturned => 'The issue returned after repair';

  @override
  String get verificationInsufficient =>
      'There is not enough information to assess the repair';

  @override
  String get revisitWorkshop =>
      'A return visit to the workshop is recommended.';

  @override
  String get marketplaceTitle => 'Parts marketplace';

  @override
  String get sellerDashboard => 'Seller dashboard';

  @override
  String get cart => 'Cart';

  @override
  String get searchPartsHint => 'Search by part name or vehicle model';

  @override
  String get noPartsAvailable => 'No parts are currently available';

  @override
  String serverErrorStatus(int status) {
    return 'Server error: $status';
  }

  @override
  String get rateSeller => 'Rate seller';

  @override
  String get commentOptional => 'Comment (optional)';

  @override
  String get send => 'Send';

  @override
  String get ratingSubmitted => 'Your rating was submitted. Thank you.';

  @override
  String get deletePartConfirm => 'Permanently delete this listing?';

  @override
  String get deletePartFailed => 'Could not delete the listing';

  @override
  String get editPart => 'Edit listing';

  @override
  String get deletePart => 'Delete listing';

  @override
  String get newPart => 'New';

  @override
  String get usedPart => 'Used';

  @override
  String sellerRating(String rating, int count) {
    return 'Seller rating: $rating ($count)';
  }

  @override
  String get sellerNotRated => 'Seller has not been rated';

  @override
  String get contactSeller => 'Contact seller';

  @override
  String callSeller(String phone) {
    return 'Call seller: $phone';
  }

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get addToCart => 'Add to cart';

  @override
  String get rateThisSeller => 'Rate this seller';

  @override
  String get shoppingCart => 'Shopping cart';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get total => 'Total';

  @override
  String get checkout => 'Checkout';

  @override
  String get paymentCreationFailed => 'Could not create the payment';

  @override
  String get addPartForSale => 'List a part for sale';

  @override
  String get partName => 'Part name';

  @override
  String get partNameHint => 'Example: rear headrest bracket';

  @override
  String get compatibleVehicleBrand => 'Compatible vehicle brand';

  @override
  String get partCondition => 'Part condition';

  @override
  String get partManufacturerOptional => 'Part manufacturer (optional)';

  @override
  String get partManufacturerHint => 'Example: Bosch, Denso, or OEM';

  @override
  String get priceOptional => 'Price (optional)';

  @override
  String get sellerPhone => 'Contact phone number';

  @override
  String get partNotesHint => 'Part condition and other details';

  @override
  String get oemNumberOptional => 'OEM part number (optional)';

  @override
  String partNumberLabel(String number) {
    return 'Part number: $number';
  }

  @override
  String partManufacturerLabel(String manufacturer) {
    return 'Manufacturer: $manufacturer';
  }

  @override
  String get partImageOptional => 'Part image (optional)';

  @override
  String get attachPartImage => 'Attach part image';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get publishPart => 'Publish listing';

  @override
  String get requiredPartFields =>
      'Enter the part name, vehicle brand, and phone number';

  @override
  String get myListings => 'My listings';

  @override
  String get soldOrders => 'Sold orders';

  @override
  String get totalRevenue => 'Total revenue';

  @override
  String get listedProducts => 'Listed products';

  @override
  String get noListings => 'You have not listed any parts yet';

  @override
  String get mySalesOrders => 'My sales orders';

  @override
  String get noSalesOrders => 'No sales orders yet';

  @override
  String get sellerDashboardLoadFailed =>
      'Could not load seller dashboard data';

  @override
  String get subscriptionStatusLoadFailed =>
      'Could not load subscription status';

  @override
  String get subscriptionActive => 'Your subscription is active';

  @override
  String get unlockFullApp => 'Unlock the full app experience';

  @override
  String get yearlyPlan => 'Yearly plan';

  @override
  String get monthlyPlan => 'Monthly plan';

  @override
  String subscriptionEndsOn(String plan, String date) {
    return '$plan — ends on $date';
  }

  @override
  String freeUsageStatus(int used, int limit) {
    return 'You used $used of $limit free diagnoses this month';
  }

  @override
  String get subscriptionBenefits => 'Plus benefits';

  @override
  String get unlimitedAiDiagnoses => 'Unlimited AI diagnoses';

  @override
  String get unlimitedAiDiagnosesDescription =>
      'Diagnose any number of vehicle issues without a monthly limit';

  @override
  String get expertAssistant => 'Ask a vehicle expert';

  @override
  String get expertAssistantDescription =>
      'Ask unlimited follow-up questions after each diagnosis';

  @override
  String get professionalPdfReports => 'Professional PDF reports';

  @override
  String get professionalPdfReportsDescription =>
      'A complete report with a verification QR code, ready to print or share';

  @override
  String get prioritySupport => 'Priority support';

  @override
  String get prioritySupportDescription =>
      'Faster responses to your questions and technical issues';

  @override
  String get choosePlan => 'Choose a plan';

  @override
  String get yearly => 'Yearly';

  @override
  String get monthly => 'Monthly';

  @override
  String get yearlyValue => 'Best value — equivalent to 9.92 SAR/month';

  @override
  String get bestValue => 'Best value';

  @override
  String get monthlyFlexibility => 'Cancel whenever you want';

  @override
  String get subscribeNow => 'Subscribe now';

  @override
  String get repairPdfTitle => 'Vehicle repair report';

  @override
  String get diagnosisPdfTitle => 'Smart vehicle diagnosis report';

  @override
  String get pdfVehicle => 'Vehicle';

  @override
  String get pdfDate => 'Date';

  @override
  String get pdfOdometer => 'Odometer';

  @override
  String get pdfDiagnosis => 'Diagnosis';

  @override
  String get pdfQuoteReview => 'Quote review';

  @override
  String get pdfRepair => 'Repair';

  @override
  String get pdfCost => 'Cost';

  @override
  String get pdfVerification => 'Verification';

  @override
  String get pdfNotSpecified => 'Not specified';

  @override
  String get pdfAvailable => 'Available';

  @override
  String get pdfDocumentationDisclaimer =>
      'This report is for documentation and does not replace a professional inspection.';

  @override
  String get pdfReportNumber => 'Report number';

  @override
  String get pdfProblemDescription => 'Problem description';

  @override
  String get pdfSeverity => 'Severity';

  @override
  String get pdfConfidence => 'Confidence';

  @override
  String get pdfExplanation => 'Explanation';

  @override
  String get pdfRecommendations => 'Recommendations';

  @override
  String get pdfRequiredParts => 'Potential parts';

  @override
  String get pdfPart => 'Part';

  @override
  String get pdfPrice => 'Price';

  @override
  String get pdfSource => 'Source';

  @override
  String get pdfEstimatedCost => 'Estimated cost';

  @override
  String get pdfAiDisclaimer =>
      'This is preliminary AI guidance and does not replace an inspection by a qualified technician.';

  @override
  String get pdfQrInstruction => 'Scan the code to verify the report content';

  @override
  String get contactSignInRequired => 'Sign in to contact the seller';

  @override
  String get sellerContactUnavailable =>
      'Seller contact information is unavailable';

  @override
  String get sellerContactRateLimited =>
      'Too many contact requests. Try again later.';

  @override
  String get sellerContactFailed =>
      'Could not retrieve seller contact information';
}
