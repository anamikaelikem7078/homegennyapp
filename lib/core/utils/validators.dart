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
