/// Input validation utilities.
abstract final class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'emailRequired';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'emailInvalid';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'passwordRequired';
    }
    // Backend requires 8-72 characters (see auth_datasource.dart change-password
    // comment) — a shorter client-side minimum lets a password pass here and
    // then fail server-side with a message that doesn't match what the UI told
    // the user.
    if (value.length < 8 || value.length > 72) {
      return 'passwordTooShort';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'phoneRequired';
    }
    // Exactly 10 digits, no country code, no embedded spaces/hyphens — this
    // app only deals in Indian mobile numbers (aadhaar_number/mobile are sent
    // raw to RM intake, eKYC, and login/OTP APIs, all of which expect a bare
    // 10-digit number).
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'phoneInvalid';
    }
    return null;
  }

  static String? aadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'aadhaarRequired';
    }
    final aadhaarRegex = RegExp(r'^[0-9]{12}$');
    if (!aadhaarRegex.hasMatch(value.trim())) {
      return 'aadhaarInvalid';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'nameRequired';
    }
    if (value.trim().length < 2) {
      return 'nameTooShort';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName}Required';
    }
    return null;
  }

  static String? otp(String? value, {int length = 6}) {
    if (value == null || value.isEmpty) {
      return 'otpRequired';
    }
    if (value.length != length || !RegExp(r'^\d+$').hasMatch(value)) {
      return 'otpInvalid';
    }
    return null;
  }
}
