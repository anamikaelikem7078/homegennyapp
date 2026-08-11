import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('en'),
    Locale('hi'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'HomeGenny'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Your home, simplified'**
  String get splashTagline;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to HomeGenny'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {phone}'**
  String otpSubtitle(String phone);

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendOtp;

  /// No description provided for @resendOtpIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendOtpIn(int seconds);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send reset instructions'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @biometricTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick sign in'**
  String get biometricTitle;

  /// No description provided for @biometricSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or face to sign in securely'**
  String get biometricSubtitle;

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get useBiometric;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Use password instead'**
  String get usePasswordInstead;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again to continue.'**
  String get sessionExpiredMessage;

  /// No description provided for @signInAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgain;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again.'**
  String get noInternetMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @updateAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get updateAppTitle;

  /// No description provided for @updateAppMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of HomeGenny is available. Please update to continue.'**
  String get updateAppMessage;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @staffDashboard.
  ///
  /// In en, this message translates to:
  /// **'Staff Dashboard'**
  String get staffDashboard;

  /// No description provided for @rmDashboard.
  ///
  /// In en, this message translates to:
  /// **'RM Dashboard'**
  String get rmDashboard;

  /// No description provided for @clientDashboard.
  ///
  /// In en, this message translates to:
  /// **'Client Dashboard'**
  String get clientDashboard;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @otpRequired.
  ///
  /// In en, this message translates to:
  /// **'OTP is required'**
  String get otpRequired;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 6-digit OTP'**
  String get otpInvalid;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing cached data where available.'**
  String get offlineBanner;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @themeSettings.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSettings;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get profileCompletion;

  /// No description provided for @unlockPremiumFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock premium coordinator features'**
  String get unlockPremiumFeatures;

  /// No description provided for @managementModules.
  ///
  /// In en, this message translates to:
  /// **'MANAGEMENT MODULES'**
  String get managementModules;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @verifiedIdTaxForms.
  ///
  /// In en, this message translates to:
  /// **'Verified ID & Tax forms'**
  String get verifiedIdTaxForms;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @modulesInProgress.
  ///
  /// In en, this message translates to:
  /// **'4 Modules in progress'**
  String get modulesInProgress;

  /// No description provided for @videoCertification.
  ///
  /// In en, this message translates to:
  /// **'Video Certification'**
  String get videoCertification;

  /// No description provided for @awaitingSubmission.
  ///
  /// In en, this message translates to:
  /// **'Awaiting submission'**
  String get awaitingSubmission;

  /// No description provided for @agreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get agreement;

  /// No description provided for @signatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Signature required'**
  String get signatureRequired;

  /// No description provided for @deployment.
  ///
  /// In en, this message translates to:
  /// **'Deployment'**
  String get deployment;

  /// No description provided for @viewCurrentAssignment.
  ///
  /// In en, this message translates to:
  /// **'View current assignment'**
  String get viewCurrentAssignment;

  /// No description provided for @salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get salary;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial overview'**
  String get financialOverview;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @conciergeAssistance.
  ///
  /// In en, this message translates to:
  /// **'Concierge assistance'**
  String get conciergeAssistance;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @logoutFromDevice.
  ///
  /// In en, this message translates to:
  /// **'Logout from Device'**
  String get logoutFromDevice;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @selectPreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language for the application interface.'**
  String get selectPreferredLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageUpdated;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'SAVE CHANGES'**
  String get saveChanges;

  /// No description provided for @financialCenter.
  ///
  /// In en, this message translates to:
  /// **'Financial Center'**
  String get financialCenter;

  /// No description provided for @manageInvoicesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your invoices, statements, and payment methods.'**
  String get manageInvoicesDesc;

  /// No description provided for @pendingInvoice.
  ///
  /// In en, this message translates to:
  /// **'PENDING INVOICE'**
  String get pendingInvoice;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get totalOutstanding;

  /// No description provided for @dueBy.
  ///
  /// In en, this message translates to:
  /// **'Due by {date}'**
  String dueBy(String date);

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment\nHistory'**
  String get paymentHistoryTitle;

  /// No description provided for @downloadStatements.
  ///
  /// In en, this message translates to:
  /// **'Download\nStatements'**
  String get downloadStatements;

  /// No description provided for @statementDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Statement downloaded successfully'**
  String get statementDownloaded;

  /// No description provided for @autoPaySettings.
  ///
  /// In en, this message translates to:
  /// **'Auto-Pay Settings'**
  String get autoPaySettings;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @invoiceCap.
  ///
  /// In en, this message translates to:
  /// **'INVOICE'**
  String get invoiceCap;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @securePaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Payments are processed securely via encrypted channels. By proceeding, you agree to our Terms of Billing.'**
  String get securePaymentDesc;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'No payment history found.'**
  String get noPaymentHistory;

  /// No description provided for @statementOverview.
  ///
  /// In en, this message translates to:
  /// **'STATEMENT OVERVIEW'**
  String get statementOverview;

  /// No description provided for @financialArchive.
  ///
  /// In en, this message translates to:
  /// **'Financial Archive'**
  String get financialArchive;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @loadMoreRecords.
  ///
  /// In en, this message translates to:
  /// **'Load More Records'**
  String get loadMoreRecords;

  /// No description provided for @downloadPdfInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download PDF invoice'**
  String get downloadPdfInvoice;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @pendingCap.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pendingCap;

  /// No description provided for @referenceInvoice.
  ///
  /// In en, this message translates to:
  /// **'Reference {invoiceNumber}'**
  String referenceInvoice(String invoiceNumber);

  /// No description provided for @dueDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Due date: {date}'**
  String dueDateDesc(String date);

  /// No description provided for @secureEncryptedDesc.
  ///
  /// In en, this message translates to:
  /// **'SECURE 256-BIT SSL ENCRYPTED TRANSACTION'**
  String get secureEncryptedDesc;

  /// No description provided for @needAssistance.
  ///
  /// In en, this message translates to:
  /// **'Need Assistance?'**
  String get needAssistance;

  /// No description provided for @needAssistanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Our concierge team is available 24/7 to help with any payment discrepancies or billing questions.'**
  String get needAssistanceDesc;

  /// No description provided for @autoReceipt.
  ///
  /// In en, this message translates to:
  /// **'Auto-Receipt'**
  String get autoReceipt;

  /// No description provided for @autoReceiptDesc.
  ///
  /// In en, this message translates to:
  /// **'A digital copy of this invoice will be sent to your registered email immediately after processing.'**
  String get autoReceiptDesc;

  /// No description provided for @enterValidUpiPin.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid UPI PIN'**
  String get enterValidUpiPin;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful!'**
  String get paymentSuccessful;

  /// No description provided for @upiPayment.
  ///
  /// In en, this message translates to:
  /// **'UPI Payment'**
  String get upiPayment;

  /// No description provided for @payingHomeGenny.
  ///
  /// In en, this message translates to:
  /// **'Paying HomeGenny'**
  String get payingHomeGenny;

  /// No description provided for @enterUpiPin.
  ///
  /// In en, this message translates to:
  /// **'ENTER 4-DIGIT UPI PIN'**
  String get enterUpiPin;

  /// No description provided for @paySecurely.
  ///
  /// In en, this message translates to:
  /// **'Pay Securely'**
  String get paySecurely;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @errorLoadingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Error loading invoice details'**
  String get errorLoadingInvoice;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get overview;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,\n{name}'**
  String welcomeBack(String name);

  /// No description provided for @personalCareEcosystem.
  ///
  /// In en, this message translates to:
  /// **'Your personal care ecosystem at a glance.'**
  String get personalCareEcosystem;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @activeNow.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE NOW'**
  String get activeNow;

  /// No description provided for @ratingValue.
  ///
  /// In en, this message translates to:
  /// **'{rating} Rating'**
  String ratingValue(String rating);

  /// No description provided for @todaysShift.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S SHIFT'**
  String get todaysShift;

  /// No description provided for @currentTask.
  ///
  /// In en, this message translates to:
  /// **'CURRENT TASK'**
  String get currentTask;

  /// No description provided for @attendanceCap.
  ///
  /// In en, this message translates to:
  /// **'ATTENDANCE'**
  String get attendanceCap;

  /// No description provided for @percentageValue.
  ///
  /// In en, this message translates to:
  /// **'{percentage}%'**
  String percentageValue(String percentage);

  /// No description provided for @daysPresent.
  ///
  /// In en, this message translates to:
  /// **'{presentDays}/{totalDays} days'**
  String daysPresent(String presentDays, String totalDays);

  /// No description provided for @paymentsCap.
  ///
  /// In en, this message translates to:
  /// **'PAYMENTS'**
  String get paymentsCap;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String daysLeft(String days);

  /// No description provided for @ongoingTraining.
  ///
  /// In en, this message translates to:
  /// **'ONGOING TRAINING'**
  String get ongoingTraining;

  /// No description provided for @quickManagement.
  ///
  /// In en, this message translates to:
  /// **'Quick Management'**
  String get quickManagement;

  /// No description provided for @myStaff.
  ///
  /// In en, this message translates to:
  /// **'My Staff'**
  String get myStaff;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @complain.
  ///
  /// In en, this message translates to:
  /// **'Complain'**
  String get complain;

  /// No description provided for @premiumInsuranceActive.
  ///
  /// In en, this message translates to:
  /// **'Premium Insurance\nActive'**
  String get premiumInsuranceActive;

  /// No description provided for @insuranceCoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Your staff members are fully covered by HomeGenny\'s Comprehensive Care Shield.'**
  String get insuranceCoverDesc;

  /// No description provided for @viewPolicyDetails.
  ///
  /// In en, this message translates to:
  /// **'View Policy Details'**
  String get viewPolicyDetails;

  /// No description provided for @homeCap.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get homeCap;

  /// No description provided for @staffCap.
  ///
  /// In en, this message translates to:
  /// **'STAFF'**
  String get staffCap;

  /// No description provided for @profileCap.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get profileCap;

  /// No description provided for @attendanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Attendance\nSummary'**
  String get attendanceSummary;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'THIS MONTH'**
  String get thisMonth;

  /// No description provided for @daysPresentDesc.
  ///
  /// In en, this message translates to:
  /// **'{presentDays} of {totalDays} days present'**
  String daysPresentDesc(String presentDays, String totalDays);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @checkInTime.
  ///
  /// In en, this message translates to:
  /// **'In: {time}'**
  String checkInTime(String time);

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecordsYet;

  /// No description provided for @presentCap.
  ///
  /// In en, this message translates to:
  /// **'PRESENT'**
  String get presentCap;

  /// No description provided for @todaysAttendance.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Attendance'**
  String get todaysAttendance;

  /// No description provided for @attendanceHistory.
  ///
  /// In en, this message translates to:
  /// **'Attendance History'**
  String get attendanceHistory;

  /// No description provided for @raiseIssue.
  ///
  /// In en, this message translates to:
  /// **'Raise Issue'**
  String get raiseIssue;

  /// No description provided for @paymentRequired.
  ///
  /// In en, this message translates to:
  /// **'PAYMENT REQUIRED'**
  String get paymentRequired;

  /// No description provided for @viewInvoice.
  ///
  /// In en, this message translates to:
  /// **'View Invoice'**
  String get viewInvoice;

  /// No description provided for @pendingAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Pending Authorization'**
  String get pendingAuthorization;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM BOOKING'**
  String get confirmBooking;

  /// No description provided for @assignedStaff.
  ///
  /// In en, this message translates to:
  /// **'Assigned Staff'**
  String get assignedStaff;

  /// No description provided for @staffProfile.
  ///
  /// In en, this message translates to:
  /// **'Staff Profile'**
  String get staffProfile;

  /// No description provided for @experience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// No description provided for @skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @premiumMember.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM MEMBER'**
  String get premiumMember;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member since Oct 2021'**
  String get memberSince;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get credits;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @addressBook.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBook;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @supportSafety.
  ///
  /// In en, this message translates to:
  /// **'Support & Safety'**
  String get supportSafety;

  /// No description provided for @complaints.
  ///
  /// In en, this message translates to:
  /// **'Complaints'**
  String get complaints;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @profileManagement.
  ///
  /// In en, this message translates to:
  /// **'PROFILE MANAGEMENT'**
  String get profileManagement;

  /// No description provided for @refineIdentity.
  ///
  /// In en, this message translates to:
  /// **'Refine your identity.'**
  String get refineIdentity;

  /// No description provided for @personalInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Your information is treated with the utmost discretion, reflecting our commitment to security and personal elegance.'**
  String get personalInfoDesc;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'FULL NAME'**
  String get fullName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'EMAIL ADDRESS'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get phoneNumber;

  /// No description provided for @secureData.
  ///
  /// In en, this message translates to:
  /// **'SECURE DATA'**
  String get secureData;

  /// No description provided for @privacyAssured.
  ///
  /// In en, this message translates to:
  /// **'Privacy Assured'**
  String get privacyAssured;

  /// No description provided for @privacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your credentials are encrypted with institutional-grade protocols.'**
  String get privacyDesc;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'PROFILE DETAILS'**
  String get profileDetails;

  /// No description provided for @primaryResidence.
  ///
  /// In en, this message translates to:
  /// **'Primary Residence'**
  String get primaryResidence;

  /// No description provided for @addressUpdateDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your shipping and service location to ensure seamless delivery.'**
  String get addressUpdateDesc;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode;

  /// No description provided for @locateOnMap.
  ///
  /// In en, this message translates to:
  /// **'Locate on map'**
  String get locateOnMap;

  /// No description provided for @serviceSetup.
  ///
  /// In en, this message translates to:
  /// **'Service: Interior Curated Setup'**
  String get serviceSetup;

  /// No description provided for @invoicePdfDesc.
  ///
  /// In en, this message translates to:
  /// **'{invoiceNumber} • PDF, 1.2MB'**
  String invoicePdfDesc(String invoiceNumber);

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDesc.
  ///
  /// In en, this message translates to:
  /// **'Select your primary interface language'**
  String get languageDesc;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark themes'**
  String get appearanceDesc;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive alerts on your mobile device'**
  String get pushNotificationsDesc;

  /// No description provided for @emailSummaries.
  ///
  /// In en, this message translates to:
  /// **'Email Summaries'**
  String get emailSummaries;

  /// No description provided for @emailSummariesDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekly reports delivered to your inbox'**
  String get emailSummariesDesc;

  /// No description provided for @attendanceAlerts.
  ///
  /// In en, this message translates to:
  /// **'Attendance Alerts'**
  String get attendanceAlerts;

  /// No description provided for @attendanceAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time status updates for events'**
  String get attendanceAlertsDesc;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get legalPrivacy;

  /// No description provided for @privacyPolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'How we handle your data'**
  String get privacyPolicyDesc;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceDesc.
  ///
  /// In en, this message translates to:
  /// **'The rules of our agreement'**
  String get termsOfServiceDesc;

  /// No description provided for @cookiePolicy.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get cookiePolicy;

  /// No description provided for @cookiePolicyDesc.
  ///
  /// In en, this message translates to:
  /// **'Managing browser cookies'**
  String get cookiePolicyDesc;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @licensesDesc.
  ///
  /// In en, this message translates to:
  /// **'Third-party software notices'**
  String get licensesDesc;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'Once you delete your account, there is no going back. Please be certain.'**
  String get deleteAccountWarning;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @caregiver.
  ///
  /// In en, this message translates to:
  /// **'CAREGIVER'**
  String get caregiver;

  /// No description provided for @verifiedProfessional.
  ///
  /// In en, this message translates to:
  /// **'Verified Professional'**
  String get verifiedProfessional;

  /// No description provided for @yearsExperience.
  ///
  /// In en, this message translates to:
  /// **'Years\nExperience'**
  String get yearsExperience;

  /// No description provided for @projectsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Projects\nCompleted'**
  String get projectsCompleted;

  /// No description provided for @safetyScore.
  ///
  /// In en, this message translates to:
  /// **'Safety Score'**
  String get safetyScore;

  /// No description provided for @professionalProfile.
  ///
  /// In en, this message translates to:
  /// **'Professional Profile'**
  String get professionalProfile;

  /// No description provided for @dDropcap.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get dDropcap;

  /// No description provided for @professionalProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'edicated Caregiver with over a decade of expertise in providing compassionate care for elderly and differently-abled individuals. Rajesh specializes in personalized health monitoring, medication management, and proactive wellness protocols. Known for his empathetic approach and strategic problem solving, he ensures every individual receives the highest standard of support and comfort.'**
  String get professionalProfileDesc;

  /// No description provided for @workExperience.
  ///
  /// In en, this message translates to:
  /// **'Work Experience'**
  String get workExperience;

  /// No description provided for @expDate1.
  ///
  /// In en, this message translates to:
  /// **'2018 — PRESENT'**
  String get expDate1;

  /// No description provided for @expTitle1.
  ///
  /// In en, this message translates to:
  /// **'Senior Care Specialist'**
  String get expTitle1;

  /// No description provided for @expCompany1.
  ///
  /// In en, this message translates to:
  /// **'Sunrise Health Services'**
  String get expCompany1;

  /// No description provided for @expDesc1.
  ///
  /// In en, this message translates to:
  /// **'Providing comprehensive daily care, medical assistance, and physical therapy support for senior residents.'**
  String get expDesc1;

  /// No description provided for @expDate2.
  ///
  /// In en, this message translates to:
  /// **'2014 — 2018'**
  String get expDate2;

  /// No description provided for @expTitle2.
  ///
  /// In en, this message translates to:
  /// **'Registered Care Provider'**
  String get expTitle2;

  /// No description provided for @expCompany2.
  ///
  /// In en, this message translates to:
  /// **'Metropolitan Care Home'**
  String get expCompany2;

  /// No description provided for @expDesc2.
  ///
  /// In en, this message translates to:
  /// **'Directed customized care plans and collaborated with medical professionals to ensure optimal patient health.'**
  String get expDesc2;

  /// No description provided for @expertiseSkills.
  ///
  /// In en, this message translates to:
  /// **'Expertise & Skills'**
  String get expertiseSkills;

  /// No description provided for @skill1.
  ///
  /// In en, this message translates to:
  /// **'Medication Management'**
  String get skill1;

  /// No description provided for @skill2.
  ///
  /// In en, this message translates to:
  /// **'Physical Therapy Support'**
  String get skill2;

  /// No description provided for @skill3.
  ///
  /// In en, this message translates to:
  /// **'Elderly Care'**
  String get skill3;

  /// No description provided for @skill4.
  ///
  /// In en, this message translates to:
  /// **'Emergency Response'**
  String get skill4;

  /// No description provided for @skill5.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Planning'**
  String get skill5;

  /// No description provided for @skill6.
  ///
  /// In en, this message translates to:
  /// **'Compassionate Care'**
  String get skill6;

  /// No description provided for @attendanceRecordLabel.
  ///
  /// In en, this message translates to:
  /// **'Attendance Record'**
  String get attendanceRecordLabel;

  /// No description provided for @monthlyPunctuality.
  ///
  /// In en, this message translates to:
  /// **'Monthly Punctuality'**
  String get monthlyPunctuality;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get recentActivity;

  /// No description provided for @activity1.
  ///
  /// In en, this message translates to:
  /// **'Morning Routine Assistance'**
  String get activity1;

  /// No description provided for @activityTime1.
  ///
  /// In en, this message translates to:
  /// **'Today, 09:00 AM'**
  String get activityTime1;

  /// No description provided for @activity2.
  ///
  /// In en, this message translates to:
  /// **'Medication Administration'**
  String get activity2;

  /// No description provided for @activityTime2.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, 04:30 PM'**
  String get activityTime2;

  /// No description provided for @homeCareSpecialist.
  ///
  /// In en, this message translates to:
  /// **'HOME CARE SPECIALIST'**
  String get homeCareSpecialist;

  /// No description provided for @ratingLabel.
  ///
  /// In en, this message translates to:
  /// **'RATING'**
  String get ratingLabel;

  /// No description provided for @fullTime.
  ///
  /// In en, this message translates to:
  /// **'Full Time'**
  String get fullTime;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'9:00 AM - 6:00 PM'**
  String get workingHours;

  /// No description provided for @yearsInCare.
  ///
  /// In en, this message translates to:
  /// **'12 YEARS IN CARE'**
  String get yearsInCare;

  /// No description provided for @specialized.
  ///
  /// In en, this message translates to:
  /// **'SPECIALIZED'**
  String get specialized;

  /// No description provided for @attendanceRecordSub.
  ///
  /// In en, this message translates to:
  /// **'98% RECORD'**
  String get attendanceRecordSub;

  /// No description provided for @topTier.
  ///
  /// In en, this message translates to:
  /// **'TOP TIER'**
  String get topTier;

  /// No description provided for @replacement.
  ///
  /// In en, this message translates to:
  /// **'Replacement'**
  String get replacement;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'MANAGE'**
  String get manage;

  /// No description provided for @curatedCareer.
  ///
  /// In en, this message translates to:
  /// **'CURATED CAREER'**
  String get curatedCareer;

  /// No description provided for @profJourneyExp.
  ///
  /// In en, this message translates to:
  /// **'Professional\nJourney &\nExpertise'**
  String get profJourneyExp;

  /// No description provided for @clinicalCare.
  ///
  /// In en, this message translates to:
  /// **'CLINICAL CARE'**
  String get clinicalCare;

  /// No description provided for @patientAdvocacy.
  ///
  /// In en, this message translates to:
  /// **'PATIENT ADVOCACY'**
  String get patientAdvocacy;

  /// No description provided for @gerontology.
  ///
  /// In en, this message translates to:
  /// **'GERONTOLOGY'**
  String get gerontology;

  /// No description provided for @caseManagement.
  ///
  /// In en, this message translates to:
  /// **'CASE MANAGEMENT'**
  String get caseManagement;

  /// No description provided for @medicationAdmin.
  ///
  /// In en, this message translates to:
  /// **'MEDICATION ADMIN'**
  String get medicationAdmin;

  /// No description provided for @downloadDossier.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD FULL DOSSIER'**
  String get downloadDossier;

  /// No description provided for @referencesAvailable.
  ///
  /// In en, this message translates to:
  /// **'REFERENCES AVAILABLE UPON REQUEST'**
  String get referencesAvailable;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sun;

  /// No description provided for @experienceIssue.
  ///
  /// In en, this message translates to:
  /// **'Experience an issue?'**
  String get experienceIssue;

  /// No description provided for @supportTeamDesc.
  ///
  /// In en, this message translates to:
  /// **'Our dedicated support team is ready to provide a seamless resolution for your concierge needs.'**
  String get supportTeamDesc;

  /// No description provided for @describeIssue.
  ///
  /// In en, this message translates to:
  /// **'DESCRIBE THE ISSUE'**
  String get describeIssue;

  /// No description provided for @detailProblemHint.
  ///
  /// In en, this message translates to:
  /// **'Detail the nature of the problem...'**
  String get detailProblemHint;

  /// No description provided for @urgencyLevel.
  ///
  /// In en, this message translates to:
  /// **'URGENCY LEVEL'**
  String get urgencyLevel;

  /// No description provided for @urgencyLow.
  ///
  /// In en, this message translates to:
  /// **'LOW'**
  String get urgencyLow;

  /// No description provided for @urgencyStandard.
  ///
  /// In en, this message translates to:
  /// **'STANDARD'**
  String get urgencyStandard;

  /// No description provided for @urgencyCritical.
  ///
  /// In en, this message translates to:
  /// **'CRITICAL'**
  String get urgencyCritical;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @uploadDocsHint.
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG, or PDF (Max 10MB)'**
  String get uploadDocsHint;

  /// No description provided for @submitIssue.
  ///
  /// In en, this message translates to:
  /// **'SUBMIT ISSUE'**
  String get submitIssue;

  /// No description provided for @priorityHandling.
  ///
  /// In en, this message translates to:
  /// **'Priority Handling'**
  String get priorityHandling;

  /// No description provided for @priorityHandlingDesc.
  ///
  /// In en, this message translates to:
  /// **'Our elite team responds within 15 minutes for critical issues.'**
  String get priorityHandlingDesc;

  /// No description provided for @pleaseDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue'**
  String get pleaseDescribeIssue;

  /// No description provided for @issueSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Issue submitted successfully'**
  String get issueSubmittedSuccess;

  /// No description provided for @uploadImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Images'**
  String get uploadImagesTitle;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @imagesAttached.
  ///
  /// In en, this message translates to:
  /// **'{count} image(s) attached'**
  String imagesAttached(int count);

  /// No description provided for @complaintHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Complaint History'**
  String get complaintHistoryTitle;

  /// No description provided for @newComplaintBtn.
  ///
  /// In en, this message translates to:
  /// **'NEW COMPLAINT'**
  String get newComplaintBtn;

  /// No description provided for @noComplaintsFound.
  ///
  /// In en, this message translates to:
  /// **'No complaints found.'**
  String get noComplaintsFound;

  /// No description provided for @resolutionDetails.
  ///
  /// In en, this message translates to:
  /// **'RESOLUTION DETAILS'**
  String get resolutionDetails;

  /// No description provided for @ref.
  ///
  /// In en, this message translates to:
  /// **'REF: {id}'**
  String ref(String id);
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
