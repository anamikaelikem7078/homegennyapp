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
    // Digits only (optionally a leading '+' with country code), 10-13 digits —
    // no embedded spaces/hyphens, which previously let malformed strings like
    // "12-345 678" pass through to the OTP-send API.
    final phoneRegex = RegExp(r'^\+?[0-9]{10,13}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'phoneInvalid';
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
