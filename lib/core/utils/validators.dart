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
    if (value.length < 6) {
      return 'passwordTooShort';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'phoneRequired';
    }
    // Match optional '+' followed by digits, spaces, or hyphens, length 10-15 digits
    final phoneRegex = RegExp(r'^\+?[0-9\s\-]{10,15}$');
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
