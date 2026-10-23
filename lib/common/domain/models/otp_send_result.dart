import 'user_role.dart';

/// `POST /auth/otp/send` response.
class OtpSendResult {
  const OtpSendResult({
    required this.sent,
    required this.isRegistered,
    required this.usePasswordLogin,
    this.role,
    this.expiresAt,
  });

  factory OtpSendResult.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as String?;
    return OtpSendResult(
      sent: json['sent'] as bool? ?? true,
      isRegistered: json['is_registered'] as bool? ?? false,
      usePasswordLogin: json['use_password_login'] as bool? ?? false,
      role: role == null ? null : UserRole.fromString(role),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }

  final bool sent;

  /// The number already has an account (so it already has a role).
  final bool isRegistered;

  /// An office number (RM/BM/Admin/HR) — OTP login is refused.
  final bool usePasswordLogin;

  /// CLIENT or STAFF for an app account, else null.
  final UserRole? role;
  final DateTime? expiresAt;
}
