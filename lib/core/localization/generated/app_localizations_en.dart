// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HomeGenny';

  @override
  String get splashTagline => 'Your home, simplified';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue to HomeGenny';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get verifyOtp => 'Verify';

  @override
  String get resendOtp => 'Resend code';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send reset instructions';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get biometricTitle => 'Quick sign in';

  @override
  String get biometricSubtitle =>
      'Use your fingerprint or face to sign in securely';

  @override
  String get useBiometric => 'Authenticate';

  @override
  String get usePasswordInstead => 'Use password instead';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please sign in again to continue.';

  @override
  String get signInAgain => 'Sign in again';

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get noInternetMessage => 'Please check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get updateAppTitle => 'Update required';

  @override
  String get updateAppMessage =>
      'A new version of HomeGenny is available. Please update to continue.';

  @override
  String get updateNow => 'Update now';

  @override
  String get staffDashboard => 'Staff Dashboard';

  @override
  String get rmDashboard => 'RM Dashboard';

  @override
  String get clientDashboard => 'Client Dashboard';

  @override
  String get logout => 'Logout';

  @override
  String get loading => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get otpRequired => 'OTP is required';

  @override
  String get otpInvalid => 'Enter a valid 6-digit OTP';

  @override
  String get offlineBanner =>
      'You are offline. Showing cached data where available.';

  @override
  String get languageSettings => 'Language';

  @override
  String get themeSettings => 'Theme';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get systemDefault => 'System default';

  @override
  String get profile => 'Profile';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String get profileCompletion => 'Profile Completion';

  @override
  String get unlockPremiumFeatures => 'Unlock premium coordinator features';

  @override
  String get managementModules => 'MANAGEMENT MODULES';

  @override
  String get documents => 'Documents';

  @override
  String get verifiedIdTaxForms => 'Verified ID & Tax forms';

  @override
  String get training => 'Training';

  @override
  String get modulesInProgress => '4 Modules in progress';

  @override
  String get videoCertification => 'Video Certification';

  @override
  String get awaitingSubmission => 'Awaiting submission';

  @override
  String get agreement => 'Agreement';

  @override
  String get signatureRequired => 'Signature required';

  @override
  String get deployment => 'Deployment';

  @override
  String get viewCurrentAssignment => 'View current assignment';

  @override
  String get salary => 'Salary';

  @override
  String get financialOverview => 'Financial overview';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get conciergeAssistance => 'Concierge assistance';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get logoutFromDevice => 'Logout from Device';

  @override
  String get settings => 'Settings';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get selectPreferredLanguage =>
      'Select your preferred language for the application interface.';

  @override
  String get languageUpdated => 'Language updated';

  @override
  String get saveChanges => 'SAVE CHANGES';

  @override
  String get financialCenter => 'Financial Center';

  @override
  String get manageInvoicesDesc =>
      'Manage your invoices, statements, and payment methods.';

  @override
  String get pendingInvoice => 'PENDING INVOICE';

  @override
  String get totalOutstanding => 'Total Outstanding';

  @override
  String dueBy(String date) {
    return 'Due by $date';
  }

  @override
  String get payNow => 'Pay Now';

  @override
  String get paymentHistoryTitle => 'Payment\nHistory';

  @override
  String get downloadStatements => 'Download\nStatements';

  @override
  String get statementDownloaded => 'Statement downloaded successfully';

  @override
  String get autoPaySettings => 'Auto-Pay Settings';

  @override
  String get recentTransactions => 'Recent Transactions';

  @override
  String get invoiceDetails => 'Invoice Details';

  @override
  String get invoiceCap => 'INVOICE';

  @override
  String get pending => 'Pending';

  @override
  String get proceedToPayment => 'Proceed to Payment';

  @override
  String get share => 'Share';

  @override
  String get download => 'Download';

  @override
  String get help => 'Help';

  @override
  String get securePaymentDesc =>
      'Payments are processed securely via encrypted channels. By proceeding, you agree to our Terms of Billing.';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get noPaymentHistory => 'No payment history found.';

  @override
  String get statementOverview => 'STATEMENT OVERVIEW';

  @override
  String get financialArchive => 'Financial Archive';

  @override
  String get paid => 'Paid';

  @override
  String get loadMoreRecords => 'Load More Records';

  @override
  String get downloadPdfInvoice => 'Download PDF invoice';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get pendingCap => 'PENDING';

  @override
  String referenceInvoice(String invoiceNumber) {
    return 'Reference $invoiceNumber';
  }

  @override
  String dueDateDesc(String date) {
    return 'Due date: $date';
  }

  @override
  String get secureEncryptedDesc => 'SECURE 256-BIT SSL ENCRYPTED TRANSACTION';

  @override
  String get needAssistance => 'Need Assistance?';

  @override
  String get needAssistanceDesc =>
      'Our concierge team is available 24/7 to help with any payment discrepancies or billing questions.';

  @override
  String get autoReceipt => 'Auto-Receipt';

  @override
  String get autoReceiptDesc =>
      'A digital copy of this invoice will be sent to your registered email immediately after processing.';

  @override
  String get enterValidUpiPin => 'Please enter a valid UPI PIN';

  @override
  String get paymentSuccessful => 'Payment Successful!';

  @override
  String get upiPayment => 'UPI Payment';

  @override
  String get payingHomeGenny => 'Paying HomeGenny';

  @override
  String get enterUpiPin => 'ENTER 4-DIGIT UPI PIN';

  @override
  String get paySecurely => 'Pay Securely';

  @override
  String get error => 'Error';

  @override
  String get errorLoadingInvoice => 'Error loading invoice details';

  @override
  String get overview => 'OVERVIEW';

  @override
  String welcomeBack(String name) {
    return 'Welcome back,\n$name';
  }

  @override
  String get personalCareEcosystem =>
      'Your personal care ecosystem at a glance.';

  @override
  String get newRequest => 'New Request';

  @override
  String get activeNow => 'ACTIVE NOW';

  @override
  String ratingValue(String rating) {
    return '$rating Rating';
  }

  @override
  String get todaysShift => 'TODAY\'S SHIFT';

  @override
  String get currentTask => 'CURRENT TASK';

  @override
  String get attendanceCap => 'ATTENDANCE';

  @override
  String percentageValue(String percentage) {
    return '$percentage%';
  }

  @override
  String daysPresent(String presentDays, String totalDays) {
    return '$presentDays/$totalDays days';
  }

  @override
  String get paymentsCap => 'PAYMENTS';

  @override
  String daysLeft(String days) {
    return '$days days left';
  }

  @override
  String get ongoingTraining => 'ONGOING TRAINING';

  @override
  String get quickManagement => 'Quick Management';

  @override
  String get myStaff => 'My Staff';

  @override
  String get logs => 'Logs';

  @override
  String get complain => 'Complain';

  @override
  String get premiumInsuranceActive => 'Premium Insurance\nActive';

  @override
  String get insuranceCoverDesc =>
      'Your staff members are fully covered by HomeGenny\'s Comprehensive Care Shield.';

  @override
  String get viewPolicyDetails => 'View Policy Details';

  @override
  String get homeCap => 'HOME';

  @override
  String get staffCap => 'STAFF';

  @override
  String get profileCap => 'PROFILE';

  @override
  String get attendanceSummary => 'Attendance\nSummary';

  @override
  String get thisMonth => 'THIS MONTH';

  @override
  String daysPresentDesc(String presentDays, String totalDays) {
    return '$presentDays of $totalDays days present';
  }

  @override
  String get today => 'Today';

  @override
  String checkInTime(String time) {
    return 'In: $time';
  }

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get presentCap => 'PRESENT';

  @override
  String get todaysAttendance => 'Today\'s Attendance';

  @override
  String get attendanceHistory => 'Attendance History';

  @override
  String get raiseIssue => 'Raise Issue';

  @override
  String get paymentRequired => 'PAYMENT REQUIRED';

  @override
  String get viewInvoice => 'View Invoice';

  @override
  String get pendingAuthorization => 'Pending Authorization';

  @override
  String get confirmBooking => 'CONFIRM BOOKING';

  @override
  String get assignedStaff => 'Assigned Staff';

  @override
  String get staffProfile => 'Staff Profile';

  @override
  String get experience => 'Experience';

  @override
  String get skills => 'Skills';

  @override
  String get attendance => 'Attendance';

  @override
  String get performance => 'Performance';

  @override
  String get premiumMember => 'PREMIUM MEMBER';

  @override
  String get memberSince => 'Member since Oct 2021';

  @override
  String get services => 'Services';

  @override
  String get rating => 'Rating';

  @override
  String get credits => 'Credits';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get personalDetails => 'Personal Details';

  @override
  String get addressBook => 'Address Book';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get supportSafety => 'Support & Safety';

  @override
  String get complaints => 'Complaints';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get logOut => 'Log Out';

  @override
  String get profileManagement => 'PROFILE MANAGEMENT';

  @override
  String get refineIdentity => 'Refine your identity.';

  @override
  String get personalInfoDesc =>
      'Your information is treated with the utmost discretion, reflecting our commitment to security and personal elegance.';

  @override
  String get fullName => 'FULL NAME';

  @override
  String get emailAddress => 'EMAIL ADDRESS';

  @override
  String get phoneNumber => 'PHONE NUMBER';

  @override
  String get secureData => 'SECURE DATA';

  @override
  String get privacyAssured => 'Privacy Assured';

  @override
  String get privacyDesc =>
      'Your credentials are encrypted with institutional-grade protocols.';

  @override
  String get address => 'Address';

  @override
  String get profileDetails => 'PROFILE DETAILS';

  @override
  String get primaryResidence => 'Primary Residence';

  @override
  String get addressUpdateDesc =>
      'Update your shipping and service location to ensure seamless delivery.';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get city => 'City';

  @override
  String get pincode => 'Pincode';

  @override
  String get locateOnMap => 'Locate on map';

  @override
  String get serviceSetup => 'Service: Interior Curated Setup';

  @override
  String invoicePdfDesc(String invoiceNumber) {
    return '$invoiceNumber • PDF, 1.2MB';
  }

  @override
  String get preferences => 'Preferences';

  @override
  String get language => 'Language';

  @override
  String get languageDesc => 'Select your primary interface language';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceDesc => 'Switch between light and dark themes';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get pushNotificationsDesc => 'Receive alerts on your mobile device';

  @override
  String get emailSummaries => 'Email Summaries';

  @override
  String get emailSummariesDesc => 'Weekly reports delivered to your inbox';

  @override
  String get attendanceAlerts => 'Attendance Alerts';

  @override
  String get attendanceAlertsDesc => 'Real-time status updates for events';

  @override
  String get legalPrivacy => 'Legal & Privacy';

  @override
  String get privacyPolicyDesc => 'How we handle your data';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceDesc => 'The rules of our agreement';

  @override
  String get cookiePolicy => 'Cookie Policy';

  @override
  String get cookiePolicyDesc => 'Managing browser cookies';

  @override
  String get licenses => 'Licenses';

  @override
  String get licensesDesc => 'Third-party software notices';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'Once you delete your account, there is no going back. Please be certain.';

  @override
  String get deactivateAccount => 'Deactivate Account';

  @override
  String get caregiver => 'CAREGIVER';

  @override
  String get verifiedProfessional => 'Verified Professional';

  @override
  String get yearsExperience => 'Years\nExperience';

  @override
  String get projectsCompleted => 'Projects\nCompleted';

  @override
  String get safetyScore => 'Safety Score';

  @override
  String get professionalProfile => 'Professional Profile';

  @override
  String get dDropcap => 'D';

  @override
  String get professionalProfileDesc =>
      'edicated Caregiver with over a decade of expertise in providing compassionate care for elderly and differently-abled individuals. Rajesh specializes in personalized health monitoring, medication management, and proactive wellness protocols. Known for his empathetic approach and strategic problem solving, he ensures every individual receives the highest standard of support and comfort.';

  @override
  String get workExperience => 'Work Experience';

  @override
  String get expDate1 => '2018 — PRESENT';

  @override
  String get expTitle1 => 'Senior Care Specialist';

  @override
  String get expCompany1 => 'Sunrise Health Services';

  @override
  String get expDesc1 =>
      'Providing comprehensive daily care, medical assistance, and physical therapy support for senior residents.';

  @override
  String get expDate2 => '2014 — 2018';

  @override
  String get expTitle2 => 'Registered Care Provider';

  @override
  String get expCompany2 => 'Metropolitan Care Home';

  @override
  String get expDesc2 =>
      'Directed customized care plans and collaborated with medical professionals to ensure optimal patient health.';

  @override
  String get expertiseSkills => 'Expertise & Skills';

  @override
  String get skill1 => 'Medication Management';

  @override
  String get skill2 => 'Physical Therapy Support';

  @override
  String get skill3 => 'Elderly Care';

  @override
  String get skill4 => 'Emergency Response';

  @override
  String get skill5 => 'Nutritional Planning';

  @override
  String get skill6 => 'Compassionate Care';

  @override
  String get attendanceRecordLabel => 'Attendance Record';

  @override
  String get monthlyPunctuality => 'Monthly Punctuality';

  @override
  String get recentActivity => 'RECENT ACTIVITY';

  @override
  String get activity1 => 'Morning Routine Assistance';

  @override
  String get activityTime1 => 'Today, 09:00 AM';

  @override
  String get activity2 => 'Medication Administration';

  @override
  String get activityTime2 => 'Yesterday, 04:30 PM';

  @override
  String get homeCareSpecialist => 'HOME CARE SPECIALIST';

  @override
  String get ratingLabel => 'RATING';

  @override
  String get fullTime => 'Full Time';

  @override
  String get workingHours => '9:00 AM - 6:00 PM';

  @override
  String get yearsInCare => '12 YEARS IN CARE';

  @override
  String get specialized => 'SPECIALIZED';

  @override
  String get attendanceRecordSub => '98% RECORD';

  @override
  String get topTier => 'TOP TIER';

  @override
  String get replacement => 'Replacement';

  @override
  String get manage => 'MANAGE';

  @override
  String get curatedCareer => 'CURATED CAREER';

  @override
  String get profJourneyExp => 'Professional\nJourney &\nExpertise';

  @override
  String get clinicalCare => 'CLINICAL CARE';

  @override
  String get patientAdvocacy => 'PATIENT ADVOCACY';

  @override
  String get gerontology => 'GERONTOLOGY';

  @override
  String get caseManagement => 'CASE MANAGEMENT';

  @override
  String get medicationAdmin => 'MEDICATION ADMIN';

  @override
  String get downloadDossier => 'DOWNLOAD FULL DOSSIER';

  @override
  String get referencesAvailable => 'REFERENCES AVAILABLE UPON REQUEST';

  @override
  String get mon => 'M';

  @override
  String get tue => 'T';

  @override
  String get wed => 'W';

  @override
  String get thu => 'T';

  @override
  String get fri => 'F';

  @override
  String get sat => 'S';

  @override
  String get sun => 'S';

  @override
  String get experienceIssue => 'Experience an issue?';

  @override
  String get supportTeamDesc =>
      'Our dedicated support team is ready to provide a seamless resolution for your concierge needs.';

  @override
  String get describeIssue => 'DESCRIBE THE ISSUE';

  @override
  String get detailProblemHint => 'Detail the nature of the problem...';

  @override
  String get urgencyLevel => 'URGENCY LEVEL';

  @override
  String get urgencyLow => 'LOW';

  @override
  String get urgencyStandard => 'STANDARD';

  @override
  String get urgencyCritical => 'CRITICAL';

  @override
  String get uploadDocuments => 'Upload Documents';

  @override
  String get uploadDocsHint => 'JPEG, PNG, or PDF (Max 10MB)';

  @override
  String get submitIssue => 'SUBMIT ISSUE';

  @override
  String get priorityHandling => 'Priority Handling';

  @override
  String get priorityHandlingDesc =>
      'Our elite team responds within 15 minutes for critical issues.';

  @override
  String get pleaseDescribeIssue => 'Please describe the issue';

  @override
  String get issueSubmittedSuccess => 'Issue submitted successfully';

  @override
  String get uploadImagesTitle => 'Upload Images';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get done => 'Done';

  @override
  String imagesAttached(int count) {
    return '$count image(s) attached';
  }

  @override
  String get complaintHistoryTitle => 'Complaint History';

  @override
  String get newComplaintBtn => 'NEW COMPLAINT';

  @override
  String get noComplaintsFound => 'No complaints found.';

  @override
  String get resolutionDetails => 'RESOLUTION DETAILS';

  @override
  String ref(String id) {
    return 'REF: $id';
  }
}
