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
}
