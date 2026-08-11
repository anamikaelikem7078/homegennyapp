// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'होमजेनी';

  @override
  String get splashTagline => 'आपका घर, सरल';

  @override
  String get loginTitle => 'वापस स्वागत है';

  @override
  String get loginSubtitle => 'होमजेनी में जारी रखने के लिए साइन इन करें';

  @override
  String get emailLabel => 'ईमेल पता';

  @override
  String get passwordLabel => 'पासवर्ड';

  @override
  String get loginButton => 'साइन इन';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get orContinueWith => 'या इसके साथ जारी रखें';

  @override
  String get biometricLogin => 'बायोमेट्रिक लॉगिन';

  @override
  String get otpTitle => 'OTP सत्यापित करें';

  @override
  String otpSubtitle(String phone) {
    return '$phone पर भेजा गया 6-अंकीय कोड दर्ज करें';
  }

  @override
  String get verifyOtp => 'सत्यापित करें';

  @override
  String get resendOtp => 'कोड पुनः भेजें';

  @override
  String resendOtpIn(int seconds) {
    return '$seconds सेकंड में पुनः भेजें';
  }

  @override
  String get forgotPasswordTitle => 'पासवर्ड रीसेट';

  @override
  String get forgotPasswordSubtitle =>
      'अपना ईमेल दर्ज करें, हम रीसेट निर्देश भेजेंगे';

  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';

  @override
  String get backToLogin => 'लॉगिन पर वापस';

  @override
  String get biometricTitle => 'त्वरित साइन इन';

  @override
  String get biometricSubtitle =>
      'सुरक्षित साइन इन के लिए फिंगरप्रिंट या चेहरा उपयोग करें';

  @override
  String get useBiometric => 'प्रमाणित करें';

  @override
  String get usePasswordInstead => 'पासवर्ड का उपयोग करें';

  @override
  String get sessionExpiredTitle => 'सत्र समाप्त';

  @override
  String get sessionExpiredMessage =>
      'आपका सत्र समाप्त हो गया। जारी रखने के लिए फिर साइन इन करें।';

  @override
  String get signInAgain => 'फिर साइन इन करें';

  @override
  String get noInternetTitle => 'इंटरनेट कनेक्शन नहीं';

  @override
  String get noInternetMessage =>
      'कृपया अपना कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get updateAppTitle => 'अपडेट आवश्यक';

  @override
  String get updateAppMessage =>
      'होमजेनी का नया संस्करण उपलब्ध है। जारी रखने के लिए अपडेट करें।';

  @override
  String get updateNow => 'अभी अपडेट करें';

  @override
  String get staffDashboard => 'स्टाफ डैशबोर्ड';

  @override
  String get rmDashboard => 'RM डैशबोर्ड';

  @override
  String get clientDashboard => 'क्लाइंट डैशबोर्ड';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get errorGeneric => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';

  @override
  String get emailRequired => 'ईमेल आवश्यक है';

  @override
  String get emailInvalid => 'मान्य ईमेल दर्ज करें';

  @override
  String get passwordRequired => 'पासवर्ड आवश्यक है';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए';

  @override
  String get otpRequired => 'OTP आवश्यक है';

  @override
  String get otpInvalid => 'मान्य 6-अंकीय OTP दर्ज करें';

  @override
  String get offlineBanner =>
      'आप ऑफलाइन हैं। जहाँ उपलब्ध हो कैश्ड डेटा दिखाया जा रहा है।';

  @override
  String get languageSettings => 'भाषा';

  @override
  String get themeSettings => 'थीम';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get lightMode => 'लाइट मोड';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get errorLoadingProfile => 'प्रोफ़ाइल लोड करने में त्रुटि';

  @override
  String get profileCompletion => 'प्रोफ़ाइल पूर्णता';

  @override
  String get unlockPremiumFeatures => 'प्रीमियम समन्वयक सुविधाओं को अनलॉक करें';

  @override
  String get managementModules => 'प्रबंधन मॉड्यूल';

  @override
  String get documents => 'दस्तावेज़';

  @override
  String get verifiedIdTaxForms => 'सत्यापित आईडी और कर प्रपत्र';

  @override
  String get training => 'प्रशिक्षण';

  @override
  String get modulesInProgress => '4 मॉड्यूल प्रगति पर';

  @override
  String get videoCertification => 'वीडियो प्रमाणन';

  @override
  String get awaitingSubmission => 'प्रस्तुति की प्रतीक्षा में';

  @override
  String get agreement => 'समझौता';

  @override
  String get signatureRequired => 'हस्ताक्षर आवश्यक';

  @override
  String get deployment => 'तैनाती';

  @override
  String get viewCurrentAssignment => 'वर्तमान कार्य देखें';

  @override
  String get salary => 'वेतन';

  @override
  String get financialOverview => 'वित्तीय अवलोकन';

  @override
  String get helpSupport => 'सहायता और समर्थन';

  @override
  String get conciergeAssistance => 'दरबान सहायता';

  @override
  String get systemSettings => 'सिस्टम सेटिंग्स';

  @override
  String get logoutFromDevice => 'डिवाइस से लॉगआउट करें';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get selectPreferredLanguage =>
      'एप्लिकेशन इंटरफ़ेस के लिए अपनी पसंदीदा भाषा चुनें।';

  @override
  String get languageUpdated => 'भाषा अपडेट की गई';

  @override
  String get saveChanges => 'परिवर्तन सहेजें';

  @override
  String get financialCenter => 'वित्तीय केंद्र';

  @override
  String get manageInvoicesDesc =>
      'अपने चालान, विवरण और भुगतान विधियों का प्रबंधन करें।';

  @override
  String get pendingInvoice => 'लंबित चालान';

  @override
  String get totalOutstanding => 'कुल बकाया';

  @override
  String dueBy(String date) {
    return '$date तक देय';
  }

  @override
  String get payNow => 'अभी भुगतान करें';

  @override
  String get paymentHistoryTitle => 'भुगतान\nइतिहास';

  @override
  String get downloadStatements => 'विवरण\nडाउनलोड करें';

  @override
  String get statementDownloaded => 'विवरण सफलतापूर्वक डाउनलोड किया गया';

  @override
  String get autoPaySettings => 'ऑटो-पे सेटिंग्स';

  @override
  String get recentTransactions => 'हाल के लेन-देन';

  @override
  String get invoiceDetails => 'चालान विवरण';

  @override
  String get invoiceCap => 'चालान';

  @override
  String get pending => 'लंबित';

  @override
  String get proceedToPayment => 'भुगतान के लिए आगे बढ़ें';

  @override
  String get share => 'साझा करें';

  @override
  String get download => 'डाउनलोड करें';

  @override
  String get help => 'सहायता';

  @override
  String get securePaymentDesc =>
      'भुगतान एन्क्रिप्टेड चैनलों के माध्यम से सुरक्षित रूप से संसाधित किए जाते हैं। आगे बढ़कर, आप हमारी बिलिंग शर्तों से सहमत होते हैं।';

  @override
  String get paymentHistory => 'भुगतान इतिहास';

  @override
  String get noPaymentHistory => 'कोई भुगतान इतिहास नहीं मिला।';

  @override
  String get statementOverview => 'विवरण अवलोकन';

  @override
  String get financialArchive => 'वित्तीय पुरालेख';

  @override
  String get paid => 'भुगतान किया गया';

  @override
  String get loadMoreRecords => 'और रिकॉर्ड लोड करें';

  @override
  String get downloadPdfInvoice => 'पीडीएफ चालान डाउनलोड करें';

  @override
  String get paymentStatus => 'भुगतान स्थिति';

  @override
  String get pendingCap => 'लंबित';

  @override
  String referenceInvoice(String invoiceNumber) {
    return 'संदर्भ $invoiceNumber';
  }

  @override
  String dueDateDesc(String date) {
    return 'नियत तिथि: $date';
  }

  @override
  String get secureEncryptedDesc =>
      'सुरक्षित 256-बिट एसएसएल एन्क्रिप्टेड लेनदेन';

  @override
  String get needAssistance => 'सहायता चाहिए?';

  @override
  String get needAssistanceDesc =>
      'हमारी दरबान टीम किसी भी भुगतान विसंगतियों या बिलिंग प्रश्नों में सहायता के लिए 24/7 उपलब्ध है।';

  @override
  String get autoReceipt => 'ऑटो-रसीद';

  @override
  String get autoReceiptDesc =>
      'प्रसंस्करण के तुरंत बाद इस चालान की एक डिजिटल प्रति आपके पंजीकृत ईमेल पर भेजी जाएगी।';

  @override
  String get enterValidUpiPin => 'कृपया एक वैध यूपीआई पिन दर्ज करें';

  @override
  String get paymentSuccessful => 'भुगतान सफल!';

  @override
  String get upiPayment => 'यूपीआई भुगतान';

  @override
  String get payingHomeGenny => 'होमजेनी को भुगतान';

  @override
  String get enterUpiPin => '4-अंकीय यूपीआई पिन दर्ज करें';

  @override
  String get paySecurely => 'सुरक्षित रूप से भुगतान करें';

  @override
  String get error => 'त्रुटि';

  @override
  String get errorLoadingInvoice => 'चालान विवरण लोड करने में त्रुटि';

  @override
  String get overview => 'अवलोकन';

  @override
  String welcomeBack(String name) {
    return 'वापसी पर स्वागत है,\n$name';
  }

  @override
  String get personalCareEcosystem =>
      'एक नज़र में आपका व्यक्तिगत देखभाल पारिस्थितिकी तंत्र।';

  @override
  String get newRequest => 'नया अनुरोध';

  @override
  String get activeNow => 'अब सक्रिय';

  @override
  String ratingValue(String rating) {
    return '$rating रेटिंग';
  }

  @override
  String get todaysShift => 'आज की शिफ्ट';

  @override
  String get currentTask => 'वर्तमान कार्य';

  @override
  String get attendanceCap => 'उपस्थिति';

  @override
  String percentageValue(String percentage) {
    return '$percentage%';
  }

  @override
  String daysPresent(String presentDays, String totalDays) {
    return '$presentDays/$totalDays दिन';
  }

  @override
  String get paymentsCap => 'भुगतान';

  @override
  String daysLeft(String days) {
    return '$days दिन बचे हैं';
  }

  @override
  String get ongoingTraining => 'चल रहा प्रशिक्षण';

  @override
  String get quickManagement => 'त्वरित प्रबंधन';

  @override
  String get myStaff => 'मेरे कर्मचारी';

  @override
  String get logs => 'लॉग्स';

  @override
  String get complain => 'शिकायत करें';

  @override
  String get premiumInsuranceActive => 'प्रीमियम बीमा\nसक्रिय';

  @override
  String get insuranceCoverDesc =>
      'आपके कर्मचारी होमजेनी के व्यापक देखभाल शील्ड द्वारा पूरी तरह से कवर किए गए हैं।';

  @override
  String get viewPolicyDetails => 'नीति विवरण देखें';

  @override
  String get homeCap => 'होम';

  @override
  String get staffCap => 'कर्मचारी';

  @override
  String get profileCap => 'प्रोफ़ाइल';

  @override
  String get attendanceSummary => 'उपस्थिति\nसारांश';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String daysPresentDesc(String presentDays, String totalDays) {
    return '$totalDays में से $presentDays दिन उपस्थित';
  }

  @override
  String get today => 'आज';

  @override
  String checkInTime(String time) {
    return 'में: $time';
  }

  @override
  String get noRecordsYet => 'अभी तक कोई रिकॉर्ड नहीं';

  @override
  String get presentCap => 'उपस्थित';

  @override
  String get todaysAttendance => 'आज की उपस्थिति';

  @override
  String get attendanceHistory => 'उपस्थिति इतिहास';

  @override
  String get raiseIssue => 'मुद्दा उठाएं';

  @override
  String get paymentRequired => 'भुगतान आवश्यक';

  @override
  String get viewInvoice => 'चालान देखें';

  @override
  String get pendingAuthorization => 'लंबित प्राधिकरण';

  @override
  String get confirmBooking => 'बुकिंग की पुष्टि करें';

  @override
  String get assignedStaff => 'नियुक्त कर्मचारी';

  @override
  String get staffProfile => 'कर्मचारी प्रोफ़ाइल';

  @override
  String get experience => 'अनुभव';

  @override
  String get skills => 'कौशल';

  @override
  String get attendance => 'उपस्थिति';

  @override
  String get performance => 'प्रदर्शन';

  @override
  String get premiumMember => 'प्रीमियम सदस्य';

  @override
  String get memberSince => 'अक्टूबर 2021 से सदस्य';

  @override
  String get services => 'सेवाएं';

  @override
  String get rating => 'रेटिंग';

  @override
  String get credits => 'क्रेडिट';

  @override
  String get accountSettings => 'खाता सेटिंग्स';

  @override
  String get personalDetails => 'व्यक्तिगत विवरण';

  @override
  String get addressBook => 'पता पुस्तिका';

  @override
  String get paymentMethods => 'भुगतान विधियां';

  @override
  String get paymentDetails => 'भुगतान विवरण';

  @override
  String get supportSafety => 'समर्थन और सुरक्षा';

  @override
  String get complaints => 'शिकायतें';

  @override
  String get helpCenter => 'सहायता केंद्र';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get logOut => 'लॉग आउट';

  @override
  String get profileManagement => 'प्रोफ़ाइल प्रबंधन';

  @override
  String get refineIdentity => 'अपनी पहचान परिष्कृत करें।';

  @override
  String get personalInfoDesc =>
      'आपकी जानकारी को अत्यंत विवेक के साथ व्यवहार किया जाता है, जो सुरक्षा और व्यक्तिगत लालित्य के प्रति हमारी प्रतिबद्धता को दर्शाता है।';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get secureData => 'सुरक्षित डेटा';

  @override
  String get privacyAssured => 'गोपनीयता सुनिश्चित';

  @override
  String get privacyDesc =>
      'आपके क्रेडेंशियल संस्थागत-ग्रेड प्रोटोकॉल के साथ एन्क्रिप्टेड हैं।';

  @override
  String get address => 'पता';

  @override
  String get profileDetails => 'प्रोफ़ाइल विवरण';

  @override
  String get primaryResidence => 'प्राथमिक निवास';

  @override
  String get addressUpdateDesc =>
      'निर्बाध वितरण सुनिश्चित करने के लिए अपना शिपिंग और सेवा स्थान अपडेट करें।';

  @override
  String get streetAddress => 'सड़क का पता';

  @override
  String get city => 'शहर';

  @override
  String get pincode => 'पिनकोड';

  @override
  String get locateOnMap => 'नक्शे पर खोजें';

  @override
  String get serviceSetup => 'सेवा: आंतरिक क्यूरेटेड सेटअप';

  @override
  String invoicePdfDesc(String invoiceNumber) {
    return '$invoiceNumber • पीडीएफ, 1.2एमबी';
  }

  @override
  String get preferences => 'प्राथमिकताएं';

  @override
  String get language => 'भाषा';

  @override
  String get languageDesc => 'अपनी प्राथमिक इंटरफ़ेस भाषा चुनें';

  @override
  String get appearance => 'दिखावट';

  @override
  String get appearanceDesc => 'हल्के और गहरे रंग के थीम के बीच स्विच करें';

  @override
  String get light => 'हल्का';

  @override
  String get dark => 'गहरा';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get pushNotifications => 'पुश सूचनाएं';

  @override
  String get pushNotificationsDesc =>
      'अपने मोबाइल डिवाइस पर अलर्ट प्राप्त करें';

  @override
  String get emailSummaries => 'ईमेल सारांश';

  @override
  String get emailSummariesDesc =>
      'साप्ताहिक रिपोर्ट आपके इनबॉक्स में वितरित की गई';

  @override
  String get attendanceAlerts => 'उपस्थिति अलर्ट';

  @override
  String get attendanceAlertsDesc => 'घटनाओं के लिए वास्तविक समय स्थिति अपडेट';

  @override
  String get legalPrivacy => 'कानूनी और गोपनीयता';

  @override
  String get privacyPolicyDesc => 'हम आपके डेटा को कैसे संभालते हैं';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get termsOfServiceDesc => 'हमारे समझौते के नियम';

  @override
  String get cookiePolicy => 'कुकी नीति';

  @override
  String get cookiePolicyDesc => 'ब्राउज़र कुकीज़ प्रबंधित करना';

  @override
  String get licenses => 'लाइसेंस';

  @override
  String get licensesDesc => 'तृतीय-पक्ष सॉफ़्टवेयर नोटिस';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get deleteAccountWarning =>
      'एक बार जब आप अपना खाता हटा देते हैं, तो वापस जाने का कोई रास्ता नहीं है। कृपया सुनिश्चित करें।';

  @override
  String get deactivateAccount => 'खाता निष्क्रिय करें';

  @override
  String get caregiver => 'देखभाल करने वाला';

  @override
  String get verifiedProfessional => 'सत्यापित पेशेवर';

  @override
  String get yearsExperience => 'वर्षों का\nअनुभव';

  @override
  String get projectsCompleted => 'परियोजनाएं\nपूरी हुईं';

  @override
  String get safetyScore => 'सुरक्षा स्कोर';

  @override
  String get professionalProfile => 'पेशेवर प्रोफ़ाइल';

  @override
  String get dDropcap => 'स';

  @override
  String get professionalProfileDesc =>
      'मर्पित देखभालकर्ता, जो बुजुर्गों और दिव्यांग व्यक्तियों के लिए करुणापूर्ण देखभाल प्रदान करने में एक दशक से अधिक का अनुभव रखते हैं। राजेश व्यक्तिगत स्वास्थ्य निगरानी, दवा प्रबंधन, और सक्रिय स्वास्थ्य प्रोटोकॉल में माहिर हैं। अपनी सहानुभूति और समस्या समाधान कौशल के लिए जाने जाते हैं।';

  @override
  String get workExperience => 'कार्य अनुभव';

  @override
  String get expDate1 => '2018 — वर्तमान';

  @override
  String get expTitle1 => 'वरिष्ठ देखभाल विशेषज्ञ';

  @override
  String get expCompany1 => 'सनराइज हेल्थ सर्विसेज';

  @override
  String get expDesc1 =>
      'वरिष्ठ निवासियों के लिए व्यापक दैनिक देखभाल, चिकित्सा सहायता और भौतिक चिकित्सा सहायता प्रदान करना।';

  @override
  String get expDate2 => '2014 — 2018';

  @override
  String get expTitle2 => 'पंजीकृत देखभाल प्रदाता';

  @override
  String get expCompany2 => 'मेट्रोपॉलिटन केयर होम';

  @override
  String get expDesc2 =>
      'अनुकूलित देखभाल योजनाओं का निर्देशन किया और रोगी के इष्टतम स्वास्थ्य को सुनिश्चित करने के लिए चिकित्सा पेशेवरों के साथ सहयोग किया।';

  @override
  String get expertiseSkills => 'विशेषज्ञता और कौशल';

  @override
  String get skill1 => 'दवा प्रबंधन';

  @override
  String get skill2 => 'भौतिक चिकित्सा सहायता';

  @override
  String get skill3 => 'बुजुर्गों की देखभाल';

  @override
  String get skill4 => 'आपातकालीन प्रतिक्रिया';

  @override
  String get skill5 => 'पोषण योजना';

  @override
  String get skill6 => 'करुणापूर्ण देखभाल';

  @override
  String get attendanceRecordLabel => 'उपस्थिति रिकॉर्ड';

  @override
  String get monthlyPunctuality => 'मासिक समयपालन';

  @override
  String get recentActivity => 'हाल की गतिविधि';

  @override
  String get activity1 => 'सुबह की दिनचर्या में सहायता';

  @override
  String get activityTime1 => 'आज, 09:00 AM';

  @override
  String get activity2 => 'दवा प्रशासन';

  @override
  String get activityTime2 => 'कल, 04:30 PM';

  @override
  String get homeCareSpecialist => 'होम केयर विशेषज्ञ';

  @override
  String get ratingLabel => 'रेटिंग';

  @override
  String get fullTime => 'पूर्णकालिक';

  @override
  String get workingHours => '9:00 AM - 6:00 PM';

  @override
  String get yearsInCare => 'देखभाल में 12 वर्ष';

  @override
  String get specialized => 'विशिष्ट';

  @override
  String get attendanceRecordSub => '98% रिकॉर्ड';

  @override
  String get topTier => 'शीर्ष स्तर';

  @override
  String get replacement => 'प्रतिस्थापन';

  @override
  String get manage => 'प्रबंधित करें';

  @override
  String get curatedCareer => 'क्यूरेटेड करियर';

  @override
  String get profJourneyExp => 'पेशेवर\nयात्रा और\nविशेषज्ञता';

  @override
  String get clinicalCare => 'नैदानिक देखभाल';

  @override
  String get patientAdvocacy => 'रोगी वकालत';

  @override
  String get gerontology => 'जराविज्ञान';

  @override
  String get caseManagement => 'मामला प्रबंधन';

  @override
  String get medicationAdmin => 'दवा प्रशासन';

  @override
  String get downloadDossier => 'पूर्ण दस्तावेज़ डाउनलोड करें';

  @override
  String get referencesAvailable => 'अनुरोध पर संदर्भ उपलब्ध हैं';

  @override
  String get mon => 'सो';

  @override
  String get tue => 'मं';

  @override
  String get wed => 'बु';

  @override
  String get thu => 'गु';

  @override
  String get fri => 'शु';

  @override
  String get sat => 'श';

  @override
  String get sun => 'र';

  @override
  String get experienceIssue => 'क्या आपको कोई समस्या है?';

  @override
  String get supportTeamDesc =>
      'हमारी समर्पित सहायता टीम आपकी दरबान संबंधी आवश्यकताओं के लिए निर्बाध समाधान प्रदान करने के लिए तैयार है।';

  @override
  String get describeIssue => 'समस्या का वर्णन करें';

  @override
  String get detailProblemHint => 'समस्या की प्रकृति का विवरण दें...';

  @override
  String get urgencyLevel => 'तात्कालिकता स्तर';

  @override
  String get urgencyLow => 'कम';

  @override
  String get urgencyStandard => 'सामान्य';

  @override
  String get urgencyCritical => 'गंभीर';

  @override
  String get uploadDocuments => 'दस्तावेज़ अपलोड करें';

  @override
  String get uploadDocsHint => 'JPEG, PNG, या PDF (अधिकतम 10MB)';

  @override
  String get submitIssue => 'समस्या जमा करें';

  @override
  String get priorityHandling => 'प्राथमिकता से संचालन';

  @override
  String get priorityHandlingDesc =>
      'गंभीर समस्याओं के लिए हमारी टीम 15 मिनट के भीतर प्रतिक्रिया देती है।';

  @override
  String get pleaseDescribeIssue => 'कृपया समस्या का वर्णन करें';

  @override
  String get issueSubmittedSuccess => 'समस्या सफलतापूर्वक जमा की गई';

  @override
  String get uploadImagesTitle => 'छवियां अपलोड करें';

  @override
  String get addPhoto => 'फ़ोटो जोड़ें';

  @override
  String get done => 'हो गया';

  @override
  String imagesAttached(int count) {
    return '$count छवि(यां) संलग्न';
  }

  @override
  String get complaintHistoryTitle => 'शिकायत इतिहास';

  @override
  String get newComplaintBtn => 'नई शिकायत';

  @override
  String get noComplaintsFound => 'कोई शिकायत नहीं मिली।';

  @override
  String get resolutionDetails => 'समाधान विवरण';

  @override
  String ref(String id) {
    return 'संदर्भ: $id';
  }
}
