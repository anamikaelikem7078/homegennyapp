import 'package:equatable/equatable.dart';

/// JWT token pair returned from authentication.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.mustChangePassword = false,
  });

  final String accessToken;
  final String refreshToken;
  final bool mustChangePassword;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      mustChangePassword: json['must_change_password'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, mustChangePassword];
}
